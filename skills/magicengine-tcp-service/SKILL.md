---
name: magicengine-tcp-service
description: 用于处理 magicEngine 的 TCP Server、Client 和 Endpoint 交互，包括连接接入、收发数据和 observer 回调。实现 TCP 接入服务或排查连接行为时使用。
version: 1.0.0
---

# magicEngine TCP Service

这个 skill 重点面向 `tcp` 包的连接和数据收发。

## 1. 先看这些文件

- `README.md`
- `docs/design-realtime.md`
- `tcp/server.go`
- `tcp/client.go`
- `tcp/endpoint.go`

## 2. 核心关注点

- `NewServer(...)`
- `NewClient(...)`
- `SimpleEndpointManger`
- `Observer`
- `Endpoint.SendData(...)`
- `Endpoint.RecvData()`
- `execute.Execute` 在 TCP 收发里的调度作用

## 3. 处理规则

- 服务端改动先确认 `ServerSink.OnNewConnect(...)` 的并发调度语义
- 客户端问题先区分：
  - `Connect(...)` 失败
  - `endpoint` 尚未建立
  - `SendData(...)` 发送失败
  - `RecvData()` 触发断连
- 需要做连接广播或连接表管理时，优先基于 `SimpleEndpointManger`
- 修改收发逻辑时，注意 observer 回调是在 execute 中异步调度的

## 4. 推荐验证

```bash
GOCACHE=/tmp/magicengine-gocache go test ./tcp -count 1
```
