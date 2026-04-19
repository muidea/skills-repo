---
name: magiccommon-app-bootstrap
description: 用于基于 magicCommon 快速搭建业务服务入口，处理 framework/application、framework/service 与 plugin 启动关闭流程。涉及 EventHub、BackgroundRoutine、Post/Send、后台任务和运行时协同时优先使用 go-application-event-runtime。
version: 1.0.1
---

# magicCommon App Bootstrap

这个 skill 用于搭业务服务入口，不做底层基础设施重构。涉及应用运行时、`EventHub`、`BackgroundRoutine`、事件发送选择或 shutdown 协同时，优先使用 `go-application-event-runtime`。

## 1. 先读这些文件

- `framework/application/application.go`
- `framework/service/service.go`
- `framework/plugin/initiator/initiator.go`
- `framework/plugin/module/module.go`
- 如涉及事件和后台任务细节，再读 `event/README.md`、`task/README.md`，并配合 `go-application-event-runtime`

## 2. 推荐搭建方式

优先使用 `framework/application` 作为统一入口：

1. 准备 `service.Service`
2. 在 `Startup()` 里完成插件注册与启动
3. 用 `application.Startup(service)`
4. 用 `application.Run()`
5. 退出时用 `application.Shutdown()`

默认行为已经包括：

- 创建 `BackgroundRoutine`
- 创建 `EventHub`
- 关闭时按顺序 shutdown service、background routine、event hub

## 3. 业务代码里该怎么做

- 业务初始化逻辑优先挂在 `initiator`
- 业务模块逻辑优先挂在 `module`
- 需要异步工作时用 `BackgroundRoutine`
- 需要跨模块解耦通信时用 `EventHub`
- 涉及 `EventHub` / `BackgroundRoutine` 的具体使用规则时，切换到 `go-application-event-runtime`

## 4. 不要这样做

- 不要在业务 main 里手工创建多套 `EventHub` / `BackgroundRoutine`，除非明确需要隔离。
- 不要绕开 `application.Shutdown()` 直接只关 service。
- 不要把长期定时任务直接写成裸 goroutine，优先挂到 `BackgroundRoutine`

## 5. 推荐验证

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor \
go test ./framework/application ./framework/service ./framework/plugin/... -count 1
```
