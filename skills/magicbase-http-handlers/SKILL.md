---
name: magicbase-http-handlers
description: "用于处理 `magicBase` 的 HTTP handler、请求解码、错误包装和分页响应。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.2
  author: "rangh-codespace"
---
# magicbase-http-handlers

用于处理 `magicBase` 的 HTTP handler、请求解码、错误包装和分页响应。

## 适用场景

- 调整 `kernel/base/service` 或 `kernel/public/service`
- 调整 `blocks/*/service`
- 统一 `IllegalParam` / `Unexpected` 的入口语义
- 补 handler 级 direct test

## 重点文件

- [design-http-entrypoints.md](magicBase/docs/design-http-entrypoints.md)
- [testing-guide.md](magicBase/docs/testing-guide.md)
- [kernel/base/service](magicBase/internal/modules/kernel/base/service)
- [kernel/public/service](magicBase/internal/modules/kernel/public/service)
- [internal/modules/blocks](magicBase/internal/modules/blocks)

## 当前稳定语义

- 明显客户端错误优先返回 `IllegalParam`
- 无效 JSON、无效 ID、非法 `ObjectValue` 不应包装成 `Unexpected`
- 依赖应用上下文的 block 接口缺上下文时 fail-closed
- 分页 handler 要正确回填 `pagination.total`

## 验证

```bash
GOCACHE=/tmp/magicbase-gocache go test ./internal/modules/kernel/base/service ./internal/modules/kernel/public/service -count 1
GOCACHE=/tmp/magicbase-gocache go test ./internal/modules/blocks/generator/service ./internal/modules/blocks/interpreter/service ./internal/modules/blocks/logger/service ./internal/modules/blocks/totalizator/service -count 1
```
