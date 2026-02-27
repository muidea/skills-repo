#!/bin/bash
# Go 增强型质量检测脚本 (归档版)

TARGET=${1:-"./..."}
# 跨平台 NUL 设备处理
NULL_DEVICE="/dev/null"
[[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]] && NULL_DEVICE="NUL"

echo ">>> [1/5] 整理依赖 (go mod tidy)"
go mod tidy && go mod verify

echo ">>> [2/5] 格式化与基础检查 (fmt/vet)"
go fmt $TARGET
go vet $TARGET

echo ">>> [3/5] 漏洞扫描 (govulncheck)"
if command -v govulncheck &> /dev/null; then
    govulncheck $TARGET
else
    echo "跳过: 未安装 govulncheck (建议: go install golang.org/x/vuln/cmd/govulncheck@latest)"
fi

echo ">>> [4/5] 深度代码检查 (golangci-lint)"
if command -v golangci-lint &> /dev/null; then
    golangci-lint run $TARGET
else
    echo "跳过: 未安装 golangci-lint"
fi

echo ">>> [5/5] 最终编译尝试"
go build -o $NULL_DEVICE $TARGET && echo ">>> [结果] 编译成功，逻辑完整！" || echo ">>> [结果] 编译失败，请检查重构逻辑。"