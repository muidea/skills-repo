---
name: go-application-event-runtime
description: 用于在基于 magicCommon framework/application 的 Go 服务中创建、接线和管理应用运行时、service、event.Hub 与 task.BackgroundRoutine，覆盖 Startup/Run/Shutdown、EventHub Post/Send、lane 顺序、后台任务、关闭重建、健康状态和验证；处理应用框架与事件运行时协同时使用。
compatibility: Compatible with open_code
metadata:
  version: "1.0.5"
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
- `framework/plugin/initiator` 与 `framework/plugin/module` 的 side-effect imports 应集中在可执行入口 `main` 或明确入口装配文件中，表示该进程按需启用哪些运行单元。
- 业务 `app` 包、service 包和 `biz/bootstrap` 包不要通过空白 import 控制 module 启用；这些包应接收 framework 传入的依赖或显式 runtime exports。
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
- service 或 runtime 自己持有的局部 module lifecycle 在关闭时应尽量继续 teardown 后续模块并聚合错误，然后再释放 EventHub。
- 如果需要在 framework/service 外部构造局部 runtime，不要复用全局 plugin manager；使用显式 lifecycle 列表，并只通过窄接口 exports 暴露能力。
- 局部 runtime exports 只能暴露 repository/infrastructure/config loader 等必要基础能力；不要导出跨 owner module 的 `ServiceExports`，也不要让 initiator helper 成为 `SetXService` / `XService()` service registry。
- 共享 runtime policy、execution request/result、artifact continuation 等通用契约应位于基础 contract 包，供 initiator、blocks、kernel orchestration 和 application 共同依赖；不要让基础运行时依赖某个 owner module 的模型包。
- 配置、repository、client、scheduler 等运行时依赖优先从 Startup/Setup 注入到 service/runtime/use-case，不要在后台任务或事件 handler 中散乱读取全局单例。

## Module 通讯边界

- 状态机裁决类事件使用同步通道，确保发布方拿到错误或拒绝结果；纯 UI/observability 通知使用异步通道。
- 跨运行单元读写正式状态、触发状态机转换或查询 owner evidence 时，使用同步 EventHub command event；owner module 必须返回 `events.Response`，调用方不能把缺失 response 当成成功。
- owner module 在 command handler 内调用自己的 service/repository，并把结果放入 response payload；调用方只使用稳定 payload key 或 DTO，不直接 import owner `service` command 类型来构造 payload。
- 一个 command topic 对应一个清晰意图，例如 read/list/create/update/transition/purge；不要把无关动作塞进一个万能 command payload。
- payload 粒度应匹配 owner 的公开契约：跨 module 使用 contract DTO、owner model 或 primitive payload map；owner 内部 service command 可以存在，但不作为 EventHub 跨模块契约。
- 读模型聚合可以在 application/facade 层组合多个 EventHub-backed reader；正式写入和状态机转换仍由 owner command 完成。
- workspace/run/step 等有作用域的事件必须携带对应 ID，并为同一业务对象绑定稳定 lane key。
- observer 中只做轻量转发或状态投影；长耗时 resume、recovery、snapshot warm、governance continuation 应提交到 `BackgroundRoutine`。
- shutdown 或 teardown 后不得继续向 `BackgroundRoutine` 提交任务；scheduler helper 应能感知关闭状态。
- HTTP/TUI handler 不直接操作跨模块状态机；它们应调用 appservice 或明确的 service 接口，由对应 owner 模块完成转换。
- HTTP/TUI/appservice 生产代码不直接访问 kernel owner repository/service；读模型和快照也应通过 EventHub-backed reader 或 appservice query entrypoint 获取 owner state。
- block 与 application 只能执行技术能力、外部系统操作或用户入口编排；formal owner state、状态机转换和 evidence 权威记录必须留在 owner module 或治理/编排 module。

## WorkOrch 验证过的 EventHub 收口检查

- command topic 的发布方必须检查同步 response，不能把无 response 当成成功。
- owner command handler 只在 owner module 内翻译 DTO 并调用自己的 service/repository。
- 跨 module command payload 不使用 owner service command 类型；优先使用稳定 contract DTO、owner model 或 primitive payload map。
- 运行期注入只注入基础设施、contract provider 或 EventHub-backed adapter，不注入跨 owner service。
- 嵌入式 runtime 和测试 runtime 使用显式 lifecycle 列表，不复用 framework plugin manager 扫描全局注册表。
- 大文件拆分不是 EventHub 合规条件；真正需要收口的是边界违规、职责混杂、状态权威不清和通信契约过宽。
- 信息交互粒度应避免两个极端：不要用一个全能 Event 承载所有动作，也不要为每个字段变化创建一个 topic；按业务意图、状态权威和一致性需求分 topic。
- module/block 粒度应服务通信边界：如果两个单元总是同步互调并共享同一状态，它们可能应该属于同一 owner；如果只是纯算法或投影，应留在 focused package。

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
- 跨 owner command topics 使用同步路径并检查 `events.Response`
- command payload 不引用 owner service command 类型，基础 runtime contract 不反向依赖 owner module model
- command topic 与 payload 粒度清晰，没有万能 command，也没有无语义的过细 topic
- runtime/session/bootstrap 未暴露跨 owner `ServiceExports` 或 service registry
- appservice/HTTP/TUI 没有直接 owner repository/service 访问的生产残留
- 相关 README、设计文档或 skill 已同步

## Formatter

- Markdown/YAML: run `skill-hub validate go-application-event-runtime --links` before feedback.
- Go examples: run `gofmt -w <files>` when adding real `.go` example files.
