---
name: go-application-event-runtime
description: 用于在基于 magicCommon framework/application 的 Go 服务中创建、接线和管理应用运行时、service、event.Hub 与 task.BackgroundRoutine，覆盖 Startup/Run/Shutdown、EventHub Post/Send、lane 顺序、后台任务、关闭重建、健康状态和验证；处理应用框架与事件运行时协同时使用。
compatibility: Compatible with open_code
metadata:
  version: 1.0.10
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
- `framework/service/lifecycle.go`
- `event/event.go`
- `event/hub.go`
- `task/background.go`
- `event/README.md`
- `task/README.md`

当前通用语义：

- `application.Get()` 创建默认 `BackgroundRoutine` 和 `EventHub`
- `application.Startup(service)` 初始化配置，并把同一组 `eventHub` / `backgroundRoutine` 传给 `service.Startup`
- `application.StartupWithOptions(service, Options)` 可显式传入 `ConfigDir`、`ServiceName`、外部 `EventHub`、外部 `BackgroundRoutine` 和 runtime ownership；应用入口已有明确配置目录时优先用它表达配置注入，而不是只依赖环境变量副作用
- `service.Startup` 再传给 `initiator.Setup` 和 plugin `module` 的 `Setup`
- `application.Run()` 调用 `service.Run()`
- `application.Shutdown()` 依次关闭 service、background routine、event hub，然后重建新的默认实例并重置配置和健康状态
- `framework/service.LifecycleService` 适合普通 Go `Startup(ctx) error` / `Run(ctx) error` / `Shutdown(ctx) error` 生命周期；需要接入 `framework/service.Service` 时使用 `service.AdaptLifecycle`
- 默认队列容量可由 `BG_TASK_QUEUE_SIZE` 和 `HUB_EVENT_QUEUE_SIZE` 覆盖

## 应用入口规则

- 主入口优先使用 `framework/application`，不要在 `main` 里手工创建多套 hub 和 background routine。
- `framework/plugin/initiator` 与 `framework/plugin/module` 的 side-effect imports 应集中在可执行入口 `main` 或明确入口装配文件中，表示该进程按需启用哪些运行单元。
- 业务 `app` 包、service 包和 `biz/bootstrap` 包不要通过空白 import 控制 module 启用；这些包应接收 framework 传入的依赖或显式 runtime exports。
- 入口如果需要在 server、interactive、remote 等模式间切换，可把每个模式实现为 `framework/service.LifecycleService`；本地不要再复制同形生命周期接口。
- 进程级 service 应放在 `internal/services/<entry-name>` 或仓库等价 service 根目录，而不是放在 `internal/modules/...` 伪装成 plugin module。
- 进程级 service 可以拆成 `service.go`、`runtime.go`、`options.go`、`config.go`、`logging.go`；它负责 mode selection、配置目录、`application.Startup/Run/Shutdown` 和 adapter 启动，不拥有正式业务状态。
- CLI/TUI/agent adapter 通过稳定 port 契约访问能力；remote backend 使用 REST client，embedded backend 使用 EventHub command/response。
- REST client 和 port 契约应放到 `internal/pkg/<entry>client` 与 `internal/pkg/<entry>port` 这类 focused package；process service 内只保留具体 backend 实现和进程编排。
- 一个进程默认只应有一套应用级 `EventHub` / `BackgroundRoutine`，除非明确需要隔离运行域。
- `Startup` 失败必须返回 `*cd.Error`，不要用 `panic` 或裸 `log.Fatal` 处理常规启动错误。
- 当把框架返回的 `*cd.Error` 桥接成 Go `error` 时必须显式判断 nil 后再返回；不要直接 `return application.Run(ctx)`，否则 typed nil 指针会变成非 nil `error` 接口，入口可能误判失败并提前 shutdown。
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
- module/block 间通信只能直接使用 framework 注入的 EventHub；禁止显式 helper 接口、service/repository/adapter/callback 注入或全局变量绕过
- 应用关闭时依赖顺序是 service 先停，再停 background routine，再 terminate event hub；不要反向关闭
- service 或 runtime 自己持有的局部 module lifecycle 在关闭时应尽量继续 teardown 后续模块并聚合错误，然后再释放 EventHub。
- 如果需要在 framework/service 外部构造局部 runtime，不要复用全局 plugin manager；使用显式 lifecycle 列表，并只通过窄接口 exports 暴露能力。
- 局部 runtime exports 只能暴露当前 runtime 自身的基础设施句柄；不能暴露 owner repositories、跨组件 adapter 或 `ServiceExports`，也不能让 initiator helper 成为 repository/EventHub/runtime policy 聚合容器。
- 共享 runtime policy、execution request/result、artifact continuation 等通用契约应位于基础 contract 包，供 initiator、blocks、kernel orchestration 和 application 共同依赖；不要让基础运行时依赖某个 owner module 的模型包。
- 配置、repository、client、scheduler 等运行时依赖优先从 Startup/Setup 注入到 service/runtime/use-case，不要在后台任务或事件 handler 中散乱读取全局单例。

## Module 通讯边界

- 状态机裁决类事件使用同步通道，确保发布方拿到错误或拒绝结果；纯 UI/observability 通知使用异步通道。
- module/block 间读写状态、触发状态转换、查询 evidence 或执行技术能力时，只能使用 EventHub；同步 handler 必须通过 magicCommon `event.Result.Set(<具体 Result>, err)` 返回，调用方不能把缺失结果、错误或类型不匹配当成成功。
- 事件投递组件在自己的 `pkg/events` 定义 topic 以及具体 `Command`、`Data`、`Result`；消费组件按需导入投递组件事件包、订阅 command，并在 handler 内调用自己的内部 service/repository。
- 一个 command topic 对应一个清晰意图，例如 read/list/create/update/transition/purge；不要把无关动作塞进一个万能 command payload。
- command/data/result 必须是具体类型；禁止 `map[string]any`、`[]any`、无约束 `any`、owner service command、JSON marshal/unmarshal 或 reflect 类型表作为跨组件合同。
- 业务 command/notification topic 与对应具体类型必须定义在事件投递组件的 `pkg/events` 中；基础 EventHub 包不定义、alias、反射聚合或运行期分发业务合同。
- 消费组件 import 投递组件的 `pkg/events` 使用 topic 和类型；不要复制类型，也不要通过共享 `events.Topic*`、Envelope 或通用 contract registry 获取业务 topic。
- runtime/block execute 这类技术能力 topic 归 block/runtime owner 包定义；避免为了“方便”放回基础 EventHub 包造成反向依赖或循环依赖。
- 读模型聚合可以在 application/facade 层组合多个 EventHub command/result；不得注入 EventHub-backed reader facade 作为第二套组件通信协议。
- workspace/run/step 等有作用域的事件必须携带对应 ID，并为同一业务对象绑定稳定 lane key。
- workspace-local run/ticket/approval/result/artifact 等对象在 command payload、HTTP adapter、CLI/TUI backend 和持久化派生 ID 中必须携带足够 scope；无 workspace scope 的 resolve/get 入口只能在能解析唯一 open 对象时继续，否则返回 conflict。
- command handler 必须先把 command context 绑定到明确 workspace/run scope，再执行 owner repository get/create/update，避免相同 `run-001` 或 `run-001-step-1-decision` 在不同 workspace 间串扰。
- observer 中只做轻量转发或状态投影；长耗时 resume、recovery、snapshot warm、governance continuation 应提交到 `BackgroundRoutine`。
- 服务端 ViewModel/projection manager 可以订阅 owner notification event，但 observer 内只做轻量分类、幂等 patch 或提交 rebuild task；baseline、gap repair、detail warmup 等重活必须进入 framework 注入的 `BackgroundRoutine`。
- projection manager 应维护 revision、updatedAt、rebuiltAt、ready/degraded/failed 状态，并发布 projection changed notification；Web/TUI/SSE 只把该 notification 作为刷新信号。
- 同一 workspace/run 的 projection rebuild 使用稳定 lane 或 per-object de-duplication；不同 workspace 的无共享状态 rebuild 不应绑定到同一全局 lane。
- shutdown 或 teardown 后不得继续向 `BackgroundRoutine` 提交任务；scheduler helper 应能感知关闭状态。
- HTTP/TUI handler 不直接操作跨模块状态机；它们应调用当前 application module 内部用例，由该用例通过 EventHub 与相关组件协作。
- HTTP/TUI/appservice 生产代码不直接访问 kernel owner repository/service；读模型和快照也应通过 EventHub-backed reader 或 appservice query entrypoint 获取 owner state。
- block 围绕单一资源或单一技术能力，可以管理自己的正式状态或运行时状态；module 负责组合多个组件合同并可管理协调状态。两者之间仍只能通过 EventHub 交互。

## WorkOrch 验证过的 EventHub 收口检查

- command topic 的发布方必须检查同步 response，不能把无 response 当成成功。
- 消费 handler 只在消费组件内部调用自己的 service/repository，并通过 `event.Result` 返回投递组件定义的具体 result。
- 跨组件 command/data/result 不使用 owner service command、map/any、JSON/reflect 转换或兼容 wrapper。
- 运行期注入只允许当前组件内部依赖和单一基础设施句柄；module/block 间不注入 contract provider、EventHub-backed adapter、repository 或 service。
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
- 服务端 projection 初始 baseline 完成或明确 degraded 可服务后，ready/readiness response 能表达 projection 状态；端侧不因 projection failed 而自行 fallback 重型聚合
- ViewModel/projection 的 startup full load、workspace rebuild、gap repair、detail warmup 通过 framework `BackgroundRoutine` 调度，observer 和 handler 不裸起长期 goroutine
- 同步 command 使用 `event.Hub.Send` 并检查 magicCommon `event.Result` 的错误、存在性和具体结果类型
- command/data/result 由投递组件定义且为具体类型；基础 runtime contract 不反向依赖业务组件模型
- command topic 与 payload 粒度清晰，没有万能 command，也没有无语义的过细 topic
- command payload 和持久化派生 ID 有明确 workspace/run scope；无 scope API 对重复 open 对象返回 conflict
- `internal/pkg/events`、`event` wrapper 或同类基础包中不存在业务 `Topic* = "/..."` 定义或迁移 alias；业务 topic 字符串只在事件投递组件 `pkg/events` 中出现
- REST client、server handler、前端和 e2e 脚本的 query string 使用 `?` 分隔，并与路径参数契约一致
- runtime/session/bootstrap 未暴露 owner repositories、跨组件 adapter、`ServiceExports` 或 service registry
- appservice/HTTP/TUI 没有直接 owner repository/service 访问的生产残留
- process service 没有被注册成 plugin module；`internal/modules` 中只保留真正拥有 framework plugin lifecycle 的运行单元
- CLI/TUI/agent 没有直接 import REST client 或 backend implementation，remote/embedded 细节留在 process service backend 实现
- 相关 README、设计文档或 skill 已同步
- 不存在 Envelope、`events.Response`、业务 topic alias、map/any payload、JSON/reflect 合同或通用 Send/Subscribe facade 兼容层

## Formatter

- Markdown/YAML: run `skill-hub validate go-application-event-runtime --links` before feedback.
- Go examples: run `gofmt -w <files>` when adding real `.go` example files.
