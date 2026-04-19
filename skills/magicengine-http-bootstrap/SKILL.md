---
name: magicengine-http-bootstrap
description: 用于搭建和调整 magicEngine 的 HTTP 服务入口，覆盖 HTTPServer、RouteRegistry、默认中间件、静态资源开关和启动流程。新增 HTTP 服务或调整服务启动参数时使用。
version: 1.0.0
---

# magicEngine HTTP Bootstrap

这个 skill 重点面向 `http/http_server.go` 的 HTTP 服务启动和绑定流程。

## 1. 先看这些文件

- `README.md`
- `docs/design-http.md`
- `http/http_server.go`
- `http/context.go`
- `http/middleware_chains.go`
- `example/http/main.go`

## 2. 核心关注点

- `NewHTTPServer(...)` 的 option 组合
- `WithPort(...)`
- `WithStatic(...)`
- `WithStaticEnabled(...)`
- 默认中间件 `logger` 和 `recovery`
- `Bind(...)` 和 `Run()`

## 3. 处理规则

- 默认启动链路是：创建 `RouteRegistry` -> 注册路由 -> 创建 `HTTPServer` -> `Bind(...)` -> `Run()`
- 需要全局中间件时，优先通过 `Use(...)` 注册
- 调整静态资源时，先确认 `enableStatic` 和 `StaticOptions`
- 需要改 HTTP 服务默认行为时，先检查是否会影响 `ServeHTTP(...)` 的 context 注入

## 4. 推荐验证

```bash
GOCACHE=/tmp/magicengine-gocache go test ./http -count 1
```
