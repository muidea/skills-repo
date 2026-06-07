---
name: magiccommon-runtime-lifecycle
description: 用于处理 magicCommon 中 execute、task、event、framework/application 底层运行时生命周期实现，覆盖等待、排空、关闭、取消和接口语义。业务服务中的 application/EventHub/BackgroundRoutine 接线和使用优先使用 go-application-event-runtime。
version: 1.0.2
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
- `framework/service/service.go`
- `framework/service/lifecycle.go`
- `framework/plugin/common/util.go`
- `framework/plugin/initiator/initiator.go`
- `framework/plugin/module/module.go`
- `framework-lifecycle-improvement-plan.md`
- `release-note-2026-03-lifecycle-cache-monitoring.md`

## 2. 当前稳定语义

- `execute.Wait()` 是兼容接口，本质仍是有限等待。
- 真正可判定结果的等待接口是：
  - `WaitTimeout(timeout)`
  - `WaitContext(ctx)`
  - `Idle()`
- `task` 现在有：
  - `Timer(ctx, ...)`
  - `Shutdown(ctx)`
- `framework/application.Shutdown()` 会依次关闭：
  - service
  - `BackgroundRoutine`
  - `EventHub`
  - 然后重建新的默认实例
- `framework/application` 当前有内部状态语义：
  - `new`
  - `starting`
  - `running`
  - `failed`
  - `shutdown`
- `Run` 必须在成功 `Startup` 后调用。
- 重复 `Startup` 只有在前一次生命周期 `Shutdown` 后才允许。
- 启动失败会进入 `failed` 并执行 best-effort cleanup；调用方需要先
  `Shutdown` 再重试。
- `StartupWithOptions(ctx, svc, opts)` 可显式指定：
  - `ConfigDir`
  - `ServiceName`
  - `EventHubQueueSize`
  - `BackgroundQueueSize`
  - 注入的 `EventHub`
  - 注入的 `BackgroundRoutine`
  - `RuntimeOwnership`
- 注入的 runtime 组件默认外部拥有；只有 `Options.Ownership` 显式声明
  后，Application 才负责关闭。
- `framework/service.AdaptLifecycle(name, svc)` 可把本地 foreground
  `LifecycleService` 适配为 `service.Service`。
- `framework/plugin` 当前稳定语义：
  - `initiator.RegisterE` / `module.RegisterE` 返回注册错误
  - `initiator.MustRegister` / `module.MustRegister` 注册失败时 panic
  - 原 `Register` 保留兼容签名并记录错误
  - plugin manager 优先使用显式接口，反射路径继续兼容旧插件
  - `PluginMgr.Setup` 失败时只 rollback 已经完成 setup 的插件

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
- 如果改到 framework lifecycle，检查：
  - 旧 `application.Startup(ctx, service)` 是否兼容
  - `StartupWithOptions` 是否正确处理 config dir、service name 和 runtime ownership
  - `Run` before startup、重复 startup、failed startup、shutdown-before-startup 是否有测试
  - plugin `RegisterE` / `MustRegister` 是否覆盖 nil、非指针、重复 ID、无效签名
  - `PluginMgr.Setup` 是否只 rollback 已 setup 成功的插件
  - `service.AdaptLifecycle` 是否通过真实 Application startup/run/shutdown 测试
- 是否需要同步更新 `event/README.md`、`execute/README.md`、`task/README.md`、
  `README.md`、`framework-lifecycle-improvement-plan.md`、release note 和当前 skill

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

framework lifecycle 收口后建议跑：

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor \
go test ./framework/plugin/common ./framework/plugin/initiator ./framework/plugin/module ./framework/service ./framework/application -count=1
```

最终验收跑：

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor \
go test ./... -count=1
```
