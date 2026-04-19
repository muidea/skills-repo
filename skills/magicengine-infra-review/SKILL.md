---
name: magicengine-infra-review
description: 用于评审和修复 magicEngine 的基础设施代码，重点覆盖 HTTP、SSE、TCP、静态资源和中间件链的行为正确性、并发边界和测试补充。对 magicEngine 做代码评审或质量加固时使用。
version: 1.0.0
---

# magicEngine Infra Review

这个 skill 重点面向 `magicEngine` 的基础设施评审和修复。

## 1. 先读这些文件

- `AGENTS.md`
- `README.md`
- `docs/design-http.md`
- `docs/design-realtime.md`
- `docs/testing-guide.md`

## 2. 先看这些代码

- `http/*.go`
- `sse/*.go`
- `tcp/*.go`
- `example/http/*.go`
- `example/sse/*.go`

## 3. 核心关注点

- 中间件是否会提前终止链路
- 路由匹配、动态参数和版本前缀是否一致
- 静态资源和上传路径是否安全
- SSE 的 holder 生命周期、心跳和重试是否稳定
- TCP 的连接、断连和 observer 回调是否存在并发边界问题

## 4. 评审顺序

- 先看运行入口和 example，确认真实使用方式
- 再看 HTTP 路由和 middleware 链
- 然后看静态资源、上传、代理、恢复逻辑
- 最后看 SSE / TCP 的连接生命周期

## 5. 推荐验证

```bash
GOCACHE=/tmp/magicengine-gocache go test ./... -count 1
```
