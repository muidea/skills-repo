---
name: magicrunner-portal-service
description: "用于处理 `kernel/portal/service` 的门户接口、订阅入口和鉴权边界；服务治理主链和订阅凭据语义优先使用 magicrunner-service-governance，gateway 访问授权优先使用 magicrunner-service-gateway-auth。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.4
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
4. 新增或调整 portal HTTP API 时，先定义最终 REST 路径，再同步前端 service 映射和文档；不要把历史 `/filter/`、`/query/:id`、`/insert/` 伪 CRUD 路径暴露给前端，避免被 `NormalizeURI` 改写后出现 404。
5. 如果只需要登录态，使用 `AddCasHandler`；如果需要功能权限控制，使用 `AddPrivilegeHandler`。
6. 变更后跑 portal service 包测试。

## 路由准入检查

- 路由常量必须和实际对外路径一致，例如当前用户访问日志使用 `/portal/access-logs/`，不要使用会被标准化的 `/portal/access-log/filter/`。
- 注册时会追加 `bc.ApiVersion`，真实浏览器路径是 `/api/v1/...`。
- 新增 route 后除了 handler direct test，还要补一个 route dispatch test，请求 `/api/v1/...` 的真实路径，验证 registry 能命中而不是 404。
- route dispatch test 里调用 registry 时，`httptest.ResponseRecorder` 需要用 `engine.NewResponseWriter(rec)` 包装。
- 排查 404 时先核对启动日志 `addRoute apiVersion=... pattern=... method=...` 和浏览器 Network 的请求路径、方法是否完全一致。

## 验证

```bash
GOCACHE=/tmp/magicrunner-gocache go test ./internal/modules/kernel/portal/service -count 1
```
