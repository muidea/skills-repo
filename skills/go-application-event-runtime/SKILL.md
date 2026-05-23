---
name: go-application-event-runtime
description: 用于在基于 magicCommon framework/application 的 Go 服务中创建、接线和管理应用运行时、service、event.Hub 与 task.BackgroundRoutine，覆盖 Startup/Run/Shutdown、EventHub Post/Send、lane 顺序、后台任务、关闭重建、健康状态和验证；处理应用框架与事件运行时协同时使用。
compatibility: Compatible with open_code
metadata:
  version: "1.0.1"
  author: "rangh"
  created_at: "2026-04-18T22:09:00+08:00"
---

# Go Application Event Runtime

这个 skill 是应用框架、`event.Hub` 和 `task.BackgroundRoutine` 协同管理的通用入口。它面向基于 `magicCommon/framework/application`、`framework/service`、`event`、`task` 的 Go 服务，不绑定具体业务项目名。

## 使用边界

使用本 skill：

- 创建或调整服务主入口的 `application.Startup`、`Run`、`Shutdown`
- 管理默认 `EventHub` 与 `BackgroundRoutine` 的传递、使用和关闭
- 决定事件使用 `Post` 还是 `Send`
- 设计跨运行单元的事件通知、同步结果、lane 顺序和后台任务协同
- 排查应用 shutdown 后任务、事件、timer、goroutine 残留
- 处理 `BG_TASK_QUEUE_SIZE`、`HUB_EVENT_QUEUE_SIZE` 等运行时容量配置

不使用本 skill：

- 只新增 `initiator` / plugin `module` 生命周期，优先使用 `go-module-initiator-lifecycle`
- 只处理底层 `event.Hub`、`execute`、`task` API 的实现重构，使用 `magiccommon-runtime-lifecycle`
- 只设计复杂业务事件流，使用 `magiccommon-event-driven-service`
- 只处理 `/health/live`、`/health/ready`、service dependencies，使用 `magiccommon-service-health`

## 必读实现

先读取当前仓库依赖的对应版本：

- `framework/application/application.go`
- `framework/service/service.go`
- `event/event.go`
- `event/hub.go`
- `task/background.go`
- `event/README.md`
- `task/README.md`

当前通用语义：

- `application.Get()` 创建默认 `BackgroundRoutine` 和 `EventHub`
- `application.Startup(service)` 初始化配置，并把同一组 `eventHub` / `backgroundRoutine` 传给 `service.Startup`
- `service.Startup` 再传给 `initiator.Setup` 和 plugin `module` 的 `Setup`
- `application.Run()` 调用 `service.Run()`
- `application.Shutdown()` 依次关闭 service、background routine、event hub，然后重建新的默认实例并重置配置和健康状态
- 默认队列容量可由 `BG_TASK_QUEUE_SIZE` 和 `HUB_EVENT_QUEUE_SIZE` 覆盖

## 应用入口规则

- 主入口优先使用 `framework/application`，不要在 `main` 里手工创建多套 hub 和 background routine。
- 一个进程默认只应有一套应用级 `EventHub` / `BackgroundRoutine`，除非明确需要隔离运行域。
- `Startup` 失败必须返回 `*cd.Error`，不要用 `panic` 或裸 `log.Fatal` 处理常规启动错误。
- `Run` 成功后才能认为服务 ready；不要在单个运行单元里私自标记全局 ready。
- 退出路径必须调用 `application.Shutdown()`，不要只关闭 HTTP server 或某个局部运行单元。
- 测试中需要重置单例时使用框架提供的 test reset 能力，不要直接改全局变量。

## EventHub 使用规则

事件结构：

- `ID()` 表示事件类型，使用稳定路径风格，例如 `/domain/action`
- `Source()` 表示来源运行单元或入口
- `Destination()` 表示目标观察者匹配范围
- `Header()` 放元信息
- `Data()` 放主载荷
- `Context()` 用于链路上下文透传
- `LaneKey()` 控制异步事件的顺序 lane，默认等于 destination

发送选择：

- 只通知、不依赖返回结果：用 `Post`
- 需要同步结果、错误或强一致反馈：用 `Send`
- 长耗时操作不要直接阻塞 observer；事件只传递关键信息，重活交给 `BackgroundRoutine`
- 需要链路上下文时，用 `NewEventWithContext` 或 `BindContext`
- 需要相同业务对象内顺序处理时，显式 `BindLaneKey`，不要误用全局 destination 造成不必要串行

订阅规则：

- 轻量回调用 `NewSimpleObserver`
- 需要把观察者 ID 与 destination 匹配分离时，用支持 matchID 的 observer 构造
- observer 内部必须防止长时间阻塞
- observer 错误要通过 `Result` 返回或记录为可排查日志，不要吞掉
- 取消订阅应放在运行单元或 runtime 的关闭路径中

## BackgroundRoutine 使用规则

- 运行单元或 initiator 不要裸起长期 goroutine，优先使用 `BackgroundRoutine`
- 一次性异步任务用 `AsyncTask` / `AsyncFunction`
- 需要同步等待时用 `SyncTaskWithTimeOut` / `SyncFunctionWithTimeOut`
- 定时任务用 `TimerWithContext`，并保证 context 有取消路径
- `Shutdown(timeout)` 会停止新任务进入、关闭任务队列并等待执行器；调用方必须理解 timeout 结果
- shutdown 后不能继续提交任务；如需新一轮运行，使用 application 重建后的默认实例

## 生命周期协同

- `initiator.Setup` 和运行单元 `Setup` 只能保存和接线 hub/background，不应启动长期阻塞逻辑
- `initiator.Run` / 运行单元 `Run` 才注册 timer、订阅事件或启动业务运行逻辑
- `Teardown` 或 `Shutdown` 要释放订阅、listener、timer context 和自持资源
- 事件发布不能早于订阅方依赖准备完成，除非业务明确允许丢弃或延迟处理
- 跨运行单元通信优先用事件或显式 helper 接口，不要通过全局变量偷取 hub
- 应用关闭时依赖顺序是 service 先停，再停 background routine，再 terminate event hub；不要反向关闭

## 验证

框架层改动：

```bash
GOCACHE=/tmp/go-application-event-runtime-gocache GOFLAGS=-mod=vendor \
go test ./framework/application ./framework/service ./event ./task -count=1
```

业务仓库改动时，按真实目录替换：

```bash
GOCACHE=/tmp/go-application-event-runtime-gocache go test ./internal/initiators/... ./internal/<unit-root>/... -count=1
```

交付前检查：

- 入口使用 `application.Startup` / `Run` / `Shutdown`
- 没有重复创建应用级 hub/background
- 事件 `Post` / `Send` 选择符合结果语义
- observer 没有长时间阻塞
- timer 有取消路径
- shutdown 后没有继续提交后台任务
- ready 状态不早于 `service.Run` 成功
- 相关 README、设计文档或 skill 已同步
