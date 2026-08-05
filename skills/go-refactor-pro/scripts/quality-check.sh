#!/usr/bin/env bash
set -euo pipefail

targets=("$@")
if [[ ${#targets[@]} -eq 0 ]]; then
  targets=(./...)
fi

echo ">>> [1/5] 工作区状态（只读）"
git status --short

echo ">>> [2/5] 依赖完整性"
go mod verify

echo ">>> [3/5] 格式检查（不改写）"
unformatted="$({
  while IFS= read -r -d '' file; do
    [[ "$file" == vendor/* ]] && continue
    [[ -f "$file" ]] && gofmt -l "$file"
  done < <(git ls-files -z -- '*.go')
})"
if [[ -n "$unformatted" ]]; then
  printf '以下 Go 文件需要 gofmt：\n%s\n' "$unformatted" >&2
  exit 1
fi

echo ">>> [4/5] vet 与测试"
go vet "${targets[@]}"
go test "${targets[@]}" -count=1

echo ">>> [5/5] 构建"
go build "${targets[@]}"

if [[ "${GO_REFACTOR_STATICCHECK:-0}" == "1" ]]; then
  command -v staticcheck >/dev/null 2>&1 || {
    echo "GO_REFACTOR_STATICCHECK=1，但未安装 staticcheck" >&2
    exit 1
  }
  staticcheck "${targets[@]}"
fi

if [[ "${GO_REFACTOR_VULNCHECK:-0}" == "1" ]]; then
  command -v govulncheck >/dev/null 2>&1 || {
    echo "GO_REFACTOR_VULNCHECK=1，但未安装 govulncheck" >&2
    exit 1
  }
  govulncheck "${targets[@]}"
fi

echo ">>> 质量检查通过"
