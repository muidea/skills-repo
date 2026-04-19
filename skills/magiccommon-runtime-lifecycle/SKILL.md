---
name: magiccommon-runtime-lifecycle
description: 用于处理 magicCommon 中 execute、task、event、framework/application 底层运行时生命周期实现，覆盖等待、排空、关闭、取消和接口语义。业务服务中的 application/EventHub/BackgroundRoutine 接线和使用优先使用 go-application-event-runtime。
version: 1.0.1
---

# magicCommon Runtime Lifecycle

这个 skill 只关注运行时组件的底层生命周期一致性。业务服务中的 application、`EventHub`、`BackgroundRoutine` 接线和使用策略优先使用 `go-application-event-runtime`。

## 1. 先读这些文件

- `execute/execute.go`
- `execute/README.md`
- `task/background.go`
- `task/README.md`
- `event/hub.go`
- `event/README.md`
- `framework/application/application.go`
- `release-note-2026-03-lifecycle-cache-monitoring.md`

## 2. 当前稳定语义

- `execute.Wait()` 是兼容接口，本质仍是有限等待。
- 真正可判定结果的等待接口是：
  - `WaitTimeout(timeout)`
  - `WaitContext(ctx)`
  - `Idle()`
- `task` 现在有：
  - `TimerWithContext(...)`
  - `Shutdown(timeout)`
- `framework/application.Shutdown()` 会依次关闭：
  - service
  - `BackgroundRoutine`
  - `EventHub`
  - 然后重建新的默认实例

## 3. 改动原则

- 不直接改变 `Wait()` 这类历史接口的语义。
- 新能力优先通过新增 API 暴露。
- 关闭类接口必须明确三件事：
  - 是否停止新任务进入
  - 是否等待已提交任务排空
  - 超时或取消后返回什么结果

## 4. 默认检查表

- 是否存在长期 goroutine 没有退出路径
- 是否有 timer/ticker 没有停止
- 是否关闭后还能继续提交任务
- 是否有“超时返回但调用方误以为完全关闭”的误导语义
- 是否需要同步更新 `event/README.md`、`execute/README.md`、`task/README.md`

## 5. 推荐验证

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor \
go test ./execute ./task ./event ./framework/application -count 1
```

如果改到了 service/plugin 交互，再加：

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor \
go test ./framework/service ./framework/plugin/... -count 1
```
