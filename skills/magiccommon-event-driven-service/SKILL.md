---
name: magiccommon-event-driven-service
description: 用于基于 magicCommon event 和 task 设计复杂业务事件驱动流程，包括事件 ID、订阅发布、同步结果、异步编排和跨模块通知链路。涉及应用级 EventHub/BackgroundRoutine 接线、Startup/Shutdown 或运行时容量时优先使用 go-application-event-runtime。
version: 1.0.1
---

# magicCommon Event Driven Service

这个 skill 用于业务事件流设计和实现。应用级 `EventHub` / `BackgroundRoutine` 接线、生命周期和关闭语义由 `go-application-event-runtime` 负责。

## 1. 先读这些文件

- `event/README.md`
- `event/event.go`
- `event/hub.go`
- `task/README.md`

## 2. 业务场景里怎么选

- 只通知，不关心返回值：`Post`
- 需要同步结果：`Send`
- 需要轻量订阅回调：`NewSimpleObserver`
- 需要复杂异步后处理：事件里只放关键信息，重活交给 `BackgroundRoutine`
- 如果问题是应用启动、关闭、默认 hub/background 获取或容量配置，切换到 `go-application-event-runtime`

## 3. 推荐模式

- 事件 ID 用稳定路径风格，例如：
  - `/order/create`
  - `/inventory/reduce`
  - `/user/notify`
- `Header()` 放元信息
- `Data()` 放主载荷
- 需要透传链路信息时用 `BindContext`

## 4. 设计约束

- 不要把超大对象直接塞进事件。
- 不要让 observer 做长时间阻塞操作。
- 需要强一致结果时优先 `Send()`，不要把 `Post()` 当同步调用。
- 复杂流程里，事件负责解耦，后台任务负责耗时执行。

## 5. 推荐验证

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor \
go test ./event ./task -count 1
```
