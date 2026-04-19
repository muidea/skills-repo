---
name: magicrunner-panel-service
description: "用于处理 `kernel/panel/service` 的 handler、鉴权上下文和管理台入口语义；服务治理主链优先使用 magicrunner-service-governance，应用安装启停卸载主链优先使用 magicrunner-application-runtime-lifecycle。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.3
  author: "rangh-codespace"
---
# magicrunner-panel-service

用于处理 `kernel/panel/service` 的 handler、鉴权上下文和管理台入口语义。

如果任务是服务治理对象链路，优先使用 `magicrunner-service-governance`。如果任务是应用安装、schema、installer、compose、启停或卸载，优先使用 `magicrunner-application-runtime-lifecycle`。

## 适用场景

- 修正 `panel` handler 的错误码
- 增加应用/实体/数据库/反馈/订阅的 direct test
- 排查 `ContextAuthSession` 或 `AuthEntity` 类型错误

## 重点文件

- [design-http-entrypoints.md](magicRunner/docs/design-http-entrypoints.md)
- [service.go](magicRunner/internal/modules/kernel/panel/service/service.go)
- [application.go](magicRunner/internal/modules/kernel/panel/service/application.go)
- [database.go](magicRunner/internal/modules/kernel/panel/service/database.go)
- [feedback.go](magicRunner/internal/modules/kernel/panel/service/feedback.go)
- [subscription.go](magicRunner/internal/modules/kernel/panel/service/subscription.go)

## 工作方式

1. 明显客户端入参错误统一返回 `IllegalParam`
2. 不要把上游查询失败只写日志后继续覆盖成成功
3. session/entity 类型断言必须安全
4. 优先补 handler 级 direct test

## 验证

```bash
GOCACHE=/tmp/magicrunner-gocache go test ./internal/modules/kernel/panel/service -count 1
```
