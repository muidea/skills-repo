---
name: magicrunner-portal-service
description: "用于处理 `kernel/portal/service` 的门户接口、订阅入口和鉴权边界；服务治理主链和订阅凭据语义优先使用 magicrunner-service-governance，gateway 访问授权优先使用 magicrunner-service-gateway-auth。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.3
  author: "rangh-codespace"
---
# magicrunner-portal-service

用于处理 `kernel/portal/service` 的门户接口、订阅入口和鉴权边界。

如果任务是服务目录、服务订阅、凭据或 panel/portal 进入服务语义，优先使用 `magicrunner-service-governance`。如果问题已经落到 `/api/v1/gateway/services/*` 或 `Sig <token>` 访问授权，使用 `magicrunner-service-gateway-auth`。

## 适用场景

- 修复 portal 服务订阅、反馈、会话接口
- 处理 `CurrentAuthEntity` 缺失或类型非法
- 增加 portal handler 的 direct tests

## 重点文件

- [design-http-entrypoints.md](magicRunner/docs/design-http-entrypoints.md)
- [service.go](magicRunner/internal/modules/kernel/portal/service/service.go)
- [feedback.go](magicRunner/internal/modules/kernel/portal/service/feedback.go)
- [profile.go](magicRunner/internal/modules/kernel/portal/service/profile.go)

## 工作方式

1. 缺失鉴权会话时 fail-closed
2. 解析 body 或 `:id` 失败时返回 `IllegalParam`
3. 不在 handler 层把明显客户端错误包装成 `Unexpected`
4. 变更后跑 portal service 包测试

## 验证

```bash
GOCACHE=/tmp/magicrunner-gocache go test ./internal/modules/kernel/portal/service -count 1
```
