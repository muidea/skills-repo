---
name: magicengine-sse-streaming
description: 用于处理 magicEngine 的 SSE 服务端和客户端，包括 HolderRegistry、心跳、断线重连和 Last-Event-ID 续传。实现事件推送或排查 SSE 行为时使用。
version: 1.0.0
---

# magicEngine SSE Streaming

这个 skill 重点面向 `sse` 包的事件流收发。

## 1. 先看这些文件

- `README.md`
- `docs/design-realtime.md`
- `sse/server.go`
- `sse/client.go`
- `example/sse/main.go`

## 2. 核心关注点

- `Holder` / `HolderRegistry`
- `OnRecv(...)` / `heartbeat()`
- `EchoSSEID()`
- `Client.Get(...)` / `Client.Post(...)`
- `Last-Event-ID`
- 重试等待和最大重试次数

## 3. 处理规则

- 服务端排查先区分：
  - holder 注册是否成功
  - SSE ID 是否带回
  - 心跳是否正常刷新 `lastActive`
  - sink 的关闭回调是否触发
- 客户端排查先区分：
  - 建链失败
  - HTTP 状态非 200
  - 事件流解析失败
  - 重试逻辑提前终止
- 修改 SSE 协议字段时，保持 `Accept: text/event-stream`、`Last-Event-ID` 和事件分隔空行语义一致

## 4. 推荐验证

```bash
GOCACHE=/tmp/magicengine-gocache go test ./sse -count 1
```
