#!/bin/bash
# Go 质量与安全检测自动化脚本

TARGET=${1:-"./..."}

echo ">>> [1/4] 格式化检查 (go fmt)"
go fmt $TARGET

echo ">>> [2/4] 静态代码分析 (go vet)"
go vet $TARGET

echo ">>> [3/4] 漏洞扫描 (govulncheck)"
if command -v govulncheck &> /dev/null; then
    govulncheck $TARGET
else
    echo "跳过: 未安装 govulncheck (go install golang.org/x/vuln/cmd/govulncheck@latest)"
fi

echo ">>> [4/4] 深度 Lint (golangci-lint)"
if command -v golangci-lint &> /dev/null; then
    golangci-lint run $TARGET
else
    echo "跳过: 未安装 golangci-lint"
fi

echo ">>> [验证完毕]"