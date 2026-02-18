import os
import re
import json
import argparse
from pathlib import Path

class IntegrityAuditor:
    def __init__(self, root_path):
        self.root_path = Path(root_path).absolute()
        # 定义审计关注的特征模式
        self.patterns = {
            "version": r'(?i)(?:version[:=]\s*["\']?|v)(\d+\.\d+\.\d+(?:-[a-zA-Z0-9.]+)?)(?=["\']?|$)',
            "port": r'(?i)(?:port|addr|listen)[:=]\s*["\']?(\d{2,5})(?=["\']?|$)',
            "timeout": r'(?i)(?:timeout|duration)[:=]\s*["\']?(\d+)(?:ms|s)?(?=["\']?|$)',
            "protocol": r'(?i)(https|http|ftp|ssh|oauth2|jwt|tls)',
            "env_var": r'(?i)([A-Z_]{3,30})\s*[:=]\s*["\']?([^"\'\n\s,]+)["\']?'
        }

    def extract_facts(self, content):
        """从文本或文件中提取核心事实点"""
        facts = {}
        for key, pattern in self.patterns.items():
            matches = re.findall(pattern, content)
            if matches:
                if key == "env_var":
                    facts[key] = {m[0]: m[1] for m in matches}
                else:
                    facts[key] = list(set(matches))
        return facts

    def audit(self, anchor_content, anchor_name="Anchor"):
        anchor_facts = self.extract_facts(anchor_content)
        report = {
            "anchor_source": anchor_name,
            "anchor_facts": anchor_facts,
            "findings": [],
            "summary": {"scanned": 0, "conflicts": 0}
        }

        # 扫描范围：代码、文档、脚本、测试、CI
        target_extensions = {'.py', '.js', '.ts', '.go', '.md', '.sh', '.yaml', '.yml', 'Dockerfile', '.env', '.json'}
        ignore_dirs = {'.git', 'node_modules', 'dist', '__pycache__', 'venv'}

        for root, dirs, files in os.walk(self.root_path):
            dirs[:] = [d for d in dirs if d not in ignore_dirs]
            for file in files:
                file_path = Path(root) / file
                if file_path.suffix in target_extensions or file in target_extensions:
                    report["summary"]["scanned"] += 1
                    try:
                        target_content = file_path.read_text(errors='ignore')
                        target_facts = self.extract_facts(target_content)
                        
                        file_issues = self.compare_facts(anchor_facts, target_facts)
                        if file_issues:
                            report["findings"].append({
                                "file": str(file_path.relative_to(self.root_path)),
                                "domain": self.get_domain(file_path),
                                "issues": file_issues
                            })
                            report["summary"]["conflicts"] += len(file_issues)
                    except Exception: continue
        return report

    def compare_facts(self, anchor_facts, target_facts):
        """对比事实点，识别不一致"""
        issues = []
        for category, a_vals in anchor_facts.items():
            t_vals = target_facts.get(category)
            if not t_vals: continue # 目标未提及该维度，跳过（或根据需要标记为缺失）

            if category == "env_var":
                for k, v in a_vals.items():
                    if k in t_vals and t_vals[k] != v:
                        issues.append({"type": category, "key": k, "expected": v, "actual": t_vals[k]})
            else:
                # 检查锚点要求的值是否在目标文件中被违反
                for val in a_vals:
                    if val not in t_vals:
                        issues.append({"type": category, "expected": val, "actual": t_vals, "msg": "Value mismatch"})
        return issues

    def get_domain(self, path):
        """根据路径识别所属域"""
        p = str(path).lower()
        if 'test' in p: return 'Testing'
        if 'docker' in p or 'workflow' in p or 'ci' in p: return 'CI/CD'
        if p.endswith(('.sh', '.py', '.make')) and ('script' in p or 'bin' in p): return 'Scripts'
        if p.endswith('.md'): return 'Documentation'
        return 'Code'

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--anchor_file", help="Path to the anchor file")
    parser.add_argument("--anchor_text", help="Raw text to use as anchor")
    parser.add_argument("--path", default=".")
    args = parser.parse_args()

    auditor = IntegrityAuditor(args.path)
    
    if args.anchor_file:
        content = Path(args.anchor_file).read_text()
        name = args.anchor_file
    elif args.anchor_text:
        content = args.anchor_text
        name = "User Provided Text"
    else:
        print(json.dumps({"error": "No anchor provided"}))
        exit(1)

    print(json.dumps(auditor.audit(content, name), indent=2))