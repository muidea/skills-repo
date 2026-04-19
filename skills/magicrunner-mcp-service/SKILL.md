---
name: magicrunner-mcp-service
description: "用于处理 `kernel/mcp` 的 SSE 接入和 MCP 路由装配。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.2
  author: "rangh-codespace"
---
# magicrunner-mcp-service

用于处理 `kernel/mcp` 的 SSE 接入和 MCP 路由装配。

## 适用场景

- 调整 `MCPSSE` / `MCPMessage` 路由
- 排查 MCP server 初始化和 SSE 挂载
- 处理 `magicPanel` / `magicRunner` 中的 MCP 接入

## 重点文件

- [design-modules.md](magicRunner/docs/design-modules.md)
- [module.go](magicRunner/internal/modules/kernel/mcp/module.go)
- [service.go](magicRunner/internal/modules/kernel/mcp/service/service.go)

## 工作方式

1. 先确认 `persistence` 和 `routeregistry` 是否已可用
2. 修改 `mcp-go` SSE 配置时同步检查路由常量
3. 对外入口只做路由和 server 绑定，不要把业务逻辑塞进 handler

## 验证

```bash
GOCACHE=/tmp/magicrunner-gocache go test ./internal/modules/kernel/mcp/... -count 1
```
