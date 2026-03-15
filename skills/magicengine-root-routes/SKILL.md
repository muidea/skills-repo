---
name: magicengine-root-routes
description: 用于处理 magicEngine 中不应被 API version 包裹的根路径路由，例如 health、static 或其他框架级入口。涉及 AddRoute、ApiVersion、根路径匹配时使用。
version: 1.0.0
---

# magicEngine Root Routes

这个 skill 处理 HTTP 引擎里“根路径路由”和“版本化业务路由”的边界。

## 先读这些文件

- `http/route.go`
- `http/server.go`
- `docs/design-http.md`

## 当前稳定规则

- 框架级路由如 `/health/live`、`/health/ready` 应保持根路径
- 不能因为后续 `SetApiVersion(...)` 被动变成 `/api/v1/health/*`
- 需要版本化的业务路由再单独走 API version

## 推荐验证

```bash
GOCACHE=/tmp/magicengine-gocache go test ./http -count 1
```
