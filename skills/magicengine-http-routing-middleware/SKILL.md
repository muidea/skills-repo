---
name: magicengine-http-routing-middleware
description: 用于处理 magicEngine 的 HTTP 路由、版本前缀、动态路径和中间件链。新增 API、排查匹配问题或调整路由中间件执行顺序时使用。
version: 1.0.0
---

# magicEngine HTTP Routing Middleware

这个 skill 重点面向 `RouteRegistry`、`PatternFilter` 和中间件执行链。

## 1. 先看这些文件

- `README.md`
- `docs/design-http.md`
- `http/route.go`
- `http/middleware_chains.go`
- `http/context.go`
- `http/route_test.go`
- `http/patternFilter_test.go`
- `example/http/routes.go`

## 2. 核心关注点

- `CreateRoute(...)`
- `AddRoute(...)` / `AddHandler(...)`
- `SetApiVersion(...)`
- `PatternFilter` 对 `:param` 和 `**` 的匹配规则
- 路由级 middleware 和全局 middleware 的叠加顺序

## 3. 处理规则

- 新增 API 优先走 `RouteRegistry.AddRoute(...)` 或 `AddHandler(...)`
- 改动态路由前，先确认 `PatternFilter` 的正则语义
- 排查路由未命中时，先区分：
  - method 不匹配
  - api version 前缀不匹配
  - pattern 动态段不匹配
  - middleware 提前终止
- 修改路由注册逻辑时，保持 duplicate route 检查有效

## 4. 推荐验证

```bash
GOCACHE=/tmp/magicengine-gocache go test ./http -run 'TestPatternFilter|TestRoute' -count 1
```
