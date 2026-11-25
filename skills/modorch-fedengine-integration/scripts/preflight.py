#!/usr/bin/env python3
"""Offline identity check for the host's resolved FedEngine Facade and Modorch."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys


def digest(files):
    return hashlib.sha256("".join(f"{p}\0{h}\n" for p, h in sorted(files.items())).encode()).hexdigest()


def source_files(base, prefix="", readme=False):
    paths = [base / "Cargo.toml", *sorted((base / "src").rglob("*.rs"))]
    if readme:
        paths.append(base / "README.md")
    files = {}
    for path in paths:
        if path.is_symlink() or not path.is_file():
            raise ValueError("missing or symlinked source: " + str(path))
        files[prefix + path.relative_to(base).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
    return files


def evaluate(metadata, snapshot):
    packages = metadata["packages"]
    facades = [p for p in packages if p["name"] == "modorch-fedengine"]
    frameworks = [p for p in packages if p["name"] == "modorch"]
    if len(facades) != 1 or len(frameworks) != 1:
        raise ValueError("expected one resolved FedEngine Facade and one Modorch Facade")
    facade, framework = facades[0], frameworks[0]
    expected = snapshot["framework"]
    if facade["version"] != snapshot["library"]["version"]:
        raise ValueError("FedEngine package version mismatch")
    if framework["version"] != expected["version"] or framework["source"] != expected["source"]:
        raise ValueError("Modorch version/Git Source/revision mismatch")
    node = next(n for n in metadata["resolve"]["nodes"] if n["id"] == framework["id"])
    features = sorted(node["features"])
    if "runtime" not in features or set(features) - set(expected["allowed_features"]):
        raise ValueError("unsupported Modorch features")
    actual = {}
    names = set()
    for package in packages:
        if package["name"] in expected["packages"]:
            if package["name"] in names:
                raise ValueError("duplicate framework package identity")
            names.add(package["name"])
            actual.update(source_files(Path(package["manifest_path"]).parent, package["name"] + "/"))
    subset = {p: h for p, h in expected["files"].items() if p.split("/")[0] in names}
    if not subset or actual != subset:
        raise ValueError("framework source fingerprint mismatch")
    library = source_files(Path(facade["manifest_path"]).parent, readme=True)
    if library != snapshot["library"]["files"]:
        raise ValueError("FedEngine Facade source fingerprint mismatch; revalidate contracts and Skill")
    return {"status": "Passed", "framework_version": framework["version"],
            "framework_source": framework["source"], "features": features,
            "framework_sha256": digest(actual), "library_version": facade["version"],
            "library_sha256": digest(library), "skill_revision": snapshot["skill_revision"],
            "library_contracts_revision": snapshot["library_contracts_revision"]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest-path", type=Path, required=True)
    parser.add_argument("--identity", type=Path, default=Path(__file__).resolve().parents[1] / "references/compatibility.json")
    args = parser.parse_args()
    report = {"status": "Blocked", "validation_status": "NotRun"}
    try:
        rustc = subprocess.check_output(["rustc", "-vV"], text=True, timeout=30)
        target = next(line.split(": ", 1)[1] for line in rustc.splitlines() if line.startswith("host: "))
        target = os.environ.get("CARGO_BUILD_TARGET", target)
        result = subprocess.run(["cargo", "metadata", "--locked", "--offline", "--format-version=1",
                                 "--filter-platform", target, "--manifest-path", str(args.manifest_path)],
                                capture_output=True, text=True, timeout=60, check=False)
        if result.returncode:
            raise ValueError("Cargo metadata failed; verify lockfile/cache/version before API work")
        report = evaluate(json.loads(result.stdout), json.loads(args.identity.read_text()))
    except (OSError, ValueError, KeyError, StopIteration, subprocess.SubprocessError) as error:
        report["reason"] = str(error)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report["status"] == "Passed" else 2


if __name__ == "__main__":
    sys.exit(main())
