---
name: magicbase-client-integration
description: "用于处理 `pkg/client` 的请求封装、接口对接和集成测试。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.2
  author: "rangh-codespace"
---
# magicbase-client-integration

用于处理 `pkg/client` 的请求封装、接口对接和集成测试。

## 适用场景

- 修改 `pkg/client` API
- 调整 HTTP 请求封装
- 修复本地服务集成测试
- 处理环境依赖测试的 `Skip` 规则

## 重点文件

- [client.go](magicBase/pkg/client/client.go)
- [client_internal_test.go](magicBase/pkg/client/client_internal_test.go)
- [application_test.go](magicBase/pkg/client/application_test.go)
- [entity_test.go](magicBase/pkg/client/entity_test.go)
- [testing-guide.md](magicBase/docs/testing-guide.md)

## 当前测试约定

- 默认探测 `127.0.0.1:8080`
- 服务不可达时自动 `Skip`
- 不把缺少本地服务误报成回归
- 公共请求/解码 helper 优先复用，不要重复散落在 CRUD 方法里

## 验证

```bash
GOCACHE=/tmp/magicbase-gocache go test ./pkg/client -count 1
```
