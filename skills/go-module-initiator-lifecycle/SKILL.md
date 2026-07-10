---
name: go-module-initiator-lifecycle
description: 用于在基于 magicCommon framework/plugin 的 Go 服务中创建、接线和管理 initiator 与运行单元生命周期，覆盖 ID/Weight、Setup/Run/Teardown、依赖获取、启动顺序、listener/后台任务生命周期和验证；新增或调整插件生命周期时使用。
compatibility: Compatible with open_code
metadata:
  version: 1.1.9
  author: "rangh"
  created_at: "2026-04-18T21:51:51+08:00"
---

# Go Module Initiator Lifecycle

这个 skill 是创建和管理 `initiator` 与基于 `magicCommon/framework/plugin/module` 的运行单元入口。这里的“运行单元”是通用术语；如果当前仓库使用 plugin `module` 机制，它在代码层就对应 `module.Register(...)` 那类实现。

## 使用边界

使用本 skill：

- 新增 `initiator`
- 新增基于 plugin `module` 的运行单元
- 调整插件 `ID`、`Weight`、`Setup`、`Run`、`Teardown`
- 处理运行单元依赖 initiator 的获取和类型断言
- 调整启动顺序、依赖注册、listener 启停、后台任务注册
- 排查插件重复 ID、类型不匹配、启动失败、关闭不彻底

不使用本 skill：

- 只创建业务运行单元目录和 `biz/service/pkg` 骨架，优先使用 `go-multi-module-dev`
- 只创建完整新项目，优先使用 `go-modular-project-bootstrap`
- 只排查 `magicCommon` 底层插件管理器实现，使用 `magiccommon-plugin-module`
- 只处理 HTTP、ORM、session、monitoring 的专项业务语义，使用对应专项 skill

## 占位符约定

- `<unit-root>`: 运行单元根目录，例如 `modules`、`features`
- `<group-path>`: 分组路径，例如 `shared`、`orchestration`
- `<unit>`: 单个运行单元目录名
- `<unit-entry-file>`: 主文件名，例如 `module.go`

如果仓库已经有固定术语，优先沿用仓库自己的命名。

## 必读实现

先核对当前仓库是否 vendored 或直接依赖 `magicCommon`，再读取对应版本：

- `framework/service/service.go`
- `framework/service/lifecycle.go`
- `framework/plugin/common/util.go`
- `framework/plugin/initiator/initiator.go`
- `framework/plugin/module/module.go`

当前通用约定：

- `service.Startup` 先执行 `initiator.Setup`，再检查 service dependencies，再执行 `module.Setup`。
- `service.Run` 先执行 `initiator.Run`，再执行 `module.Run`，成功后标记 ready。
- `service.Shutdown` 按 `module.Teardown`、`initiator.Teardown` 顺序关闭。
- 插件注册要求指针类型，并且至少实现 `ID() string` 与 `Run() *cd.Error`。
- `Setup` 和 `Teardown` 可选；缺失时由插件管理器忽略 `NotFound`。
- `Weight() int` 可选；未实现时使用默认权重。
- 重复 `ID` 会注册失败；同一类型插件按权重升序执行，`Teardown` 反向执行。
- 新版本框架提供 `RegisterE` 与 `MustRegister` 时，生产入口可继续使用现有 `Register(New())` 约定；需要在测试或脚手架中显式处理重复 ID / 非法插件错误时优先用 `RegisterE`。
- 普通进程级生命周期可以实现 `framework/service.LifecycleService`，再用 `service.AdaptLifecycle` 接入 `framework/service.Service`；plugin module 仍用于按入口选择启用的运行单元。
- 进程级 service 与 plugin module 是不同边界：service 负责可执行进程的启动模式、配置、`application.Startup/Run/Shutdown`、CLI/TUI/remote/server 编排；module 负责被 framework plugin manager 启用的运行单元生命周期、订阅、route/listener 或 owner 状态。
- process service、CLI/TUI adapter、REST client、port contract 和 backend implementation 可以是同一进程能力的一部分，但不是因为靠近 framework 就要注册为 plugin module；只有拥有 plugin lifecycle、订阅/listener/owner 状态或可按入口启停的运行单元才进入 `internal/modules`。

## Framework 接线边界

- `framework/plugin/initiator` 与 `framework/plugin/module` 的 side-effect import 只放在可执行入口 `main` 或明确的入口装配文件中，用来按需启用运行单元。
- 不要把 process service 放在 `internal/modules/...`，除非它确实实现 `module.go` 并作为 plugin module 注册。没有 `Setup/Run/Teardown` 运行单元语义的 CLI/TUI/remote/server 编排应放到 `internal/services/<entry-name>` 或仓库等价位置。
- 不要为了“接近 framework”把 CLI/TUI/agent adapter 注册成 plugin module；它们通常是 process service 的 adapter，依赖 port 契约即可。
- 业务 `app` 包、`biz/bootstrap` 包和普通运行单元包不要通过空白 import 偷偷启用其他 module；运行单元是否启用应由入口装配决定。
- 如果代码运行在 `framework/service` 外部的测试或内嵌 runtime 中，不要复用 framework plugin manager 扫描全局注册表来组装局部模块；应使用显式 lifecycle 列表，并保持 `Setup -> Run -> Teardown` 语义一致。
- 显式 lifecycle runner 必须按声明顺序 `Setup` / `Run`，按反向顺序 `Teardown`；关闭时应尽量继续释放后续模块并聚合错误。
- framework plugin manager 只负责应用级 service lifecycle；业务 bootstrap 不应把它当成普通依赖注入容器或局部 module registry。
- 一个 initiator 只能暴露一种无业务状态基础设施能力，例如单一 route registry、client factory、listener 或 scheduler；可持有该能力的进程级句柄，但不能聚合 repository set、EventHub wrapper、runtime policy 等多种职责。
- 不要在 helper 上增加 `SetXService` / `XService()` 或在 bootstrap exports 中增加跨组件 `ServiceExports`；也不要用 EventHub-backed adapter 形成第二套组件通信接口。
- 一个 module/block 需要另一个组件的状态或能力时，生产路径只能通过 EventHub command 通讯；不能在 `Setup` 中直接注入对方 service、repository、adapter 或 callback。
- module/block 的生产构造器不能注入其他组件的 repository provider、service、adapter、reader callback 或 contract provider；跨组件运行期协作只能使用 framework 注入的 EventHub。workspace/run/ticket/approval 等 scope 必须通过具体事件类型传递，不能依赖全局当前 workspace。
- owner-neutral 的 runtime policy、execution request/result、artifact continuation 等基础值类型可放在共享 contract 包；事件 command/data/result 必须留在事件投递组件的 `pkg/events`，initiator 不负责聚合或代理这些合同。
- framework plugin manager 不能作为业务 bootstrap 的 service locator；如果某个测试、CLI 或嵌入式 runtime 必须局部启动模块，使用显式 lifecycle runner，并通过窄 exports 传入基础能力。

## Initiator 规则

`initiator` 只用于提供一种无业务状态的应用级基础设施能力，例如单一 persistence provider、route registry、monitoring listener、pprof listener、cron/timer scheduler 或 client factory。

- 在 `init()` 中调用 `initiator.Register(New())`。
- `ID()` 返回稳定常量，常量放在该 initiator 的 `pkg/common` 或等价公共包。
- `Setup(eventHub, backgroundRoutine)` 只做依赖接线、配置解析、资源构造和预绑定。
- `Setup` 必须保存 framework 传入的 `eventHub` / `backgroundRoutine`，不要自行创建第二套应用级 EventHub 或后台任务队列。
- listener 型 initiator 必须在 `Setup` 完成 bind/listen，在 `Run` 启动 serve，在 `Teardown` 关闭 listener/server。
- 后台任务型 initiator 在 `Setup` 保存 `eventHub` / `backgroundRoutine`，在 `Run` 注册 timer/cron/task。
- 对外暴露能力时提供窄接口，例如 `GetRouteRegistry()`、`GetBaseClient()`，不要暴露整个实现对象。
- 对外只暴露该单一基础设施能力的窄句柄；不承担业务状态转换、业务策略、多能力聚合或跨组件 service facade。
- 如果一个 initiator 同时提供 repository set、EventHub wrapper、runtime policy、route registry 等能力，必须拆分；module/block 直接使用 framework 传入的 EventHub，不经 initiator 再包装。
- 常规失败返回 `*cd.Error`，不要用 `panic` 或裸 `log.Fatal`。

## 运行单元规则

推荐结构：

```text
internal/<unit-root>/<group-path>/<unit>/
├── <unit-entry-file>        # 常见为 module.go
├── biz/
├── service/
└── pkg/
    ├── common/
    └── models/
```

- 如果使用 plugin `module` 机制，在 `init()` 中调用 `module.Register(New())`。
- `ID()` 返回稳定单元常量。
- 需要调整顺序时实现 `Weight() int`，不要依赖 import 顺序。
- `Setup` 通过 `initiator.GetEntity` 获取基础能力，完成 `biz`、`service` 构造和依赖绑定。
- `Setup` 获取不到必要 initiator/helper 时必须 fail-fast 返回明确错误，不要构造半可用 service 或延迟到 handler 才失败。
- `Run` 先启动 biz，再注册 route 或启动对外服务。
- event 型运行单元必须在 `Run` 订阅 command/notification topic，在 `Teardown` 取消订阅；同步 handler 直接通过 magicCommon `event.Result.Set(<具体 Result>, err)` 返回，缺失结果应视为装配或生命周期错误。
- 事件投递组件在自己的 `pkg/events` 定义 topic 和具体 command/data/result；消费组件导入该事件包并订阅。禁止 command envelope、`events.Response`、map/any payload、JSON/reflect 转换和通用订阅封装。
- module/block 间只能通过 EventHub 交互；两者都只能直接访问自己的 repository/service。block 可以管理单一资源或单一技术能力自己的正式状态、运行时状态。
- `Teardown` 做幂等释放；如果当前单元没有资源，也显式确认不需要清理。
- `biz` 处理业务、事件、后台任务和持久化编排；`service` 只做协议、路由、请求响应适配。

### 生命周期粒度判断

新增或拆分 module/block/initiator 前，先回答这些问题：

- 是否需要被入口按需启用/禁用？如果不需要，通常不是新的 framework module。
- 是否只是进程启动壳、mode selection 或 CLI/TUI 编排？如果是，通常是 process service，不是 plugin module。
- 是否拥有自己的 `Setup`/`Run`/`Teardown` 资源、订阅、listener、timer 或后台任务？如果没有，优先 focused package。
- 功能闭环是否必须组合多个独立组件合同？如果是 module；如果只围绕单一资源或单一技术能力，即使有正式状态，也应是 block。
- 是否只是 mapping、projection、payload DTO、validation、query helper 或路径 helper？如果是，放在 owner/application 内部 focused package，不要做 module。
- 是否只有一层转调 wrapper？如果是，优先删除 wrapper 或合并回调用方。
- 是否拆分后必须通过 `Weight` 或隐式 import 保证正确性？如果是，说明依赖没有表达清楚，不应先拆。
- 是否拆分后需要跨组件 service/repository/adapter 注入？如果是，说明边界设计错误，应改为直接 EventHub 事件合同。

### 分组落点

生命周期接线前必须先确认运行单元落点，避免把治理流程错误塞进基础能力分组。

- 共享能力分组：承载单一基础资源或单一技术能力，允许管理自己的状态，并提供可复用 CRUD、状态流转、基础校验、资源事件
- 编排/治理分组：承载核心业务治理、跨能力编排、策略、模板、审核、准入、授权或运行态控制
- 如果运行单元需要同时调用多个低层能力才完成业务闭环，默认属于编排/治理分组
- 如果运行单元只是为一个基础资源提供可被复用的底层能力，才属于共享能力分组

如果仓库已经把这些分组命名成 `kernel/blocks` 或其他名字，直接沿用；不要为了套 skill 重命名目录。

依赖 initiator 的标准方式：

```go
var helper common.RouteRegistryHelper
helper, err = initiator.GetEntity(common.RouteRegistryInitiator, helper)
if err != nil {
    return err
}
```

获取依赖失败必须 fail-fast，不要降级成空 route、空 client 或延迟到 handler 才失败。

## 顺序和依赖

- 基础资源类 initiator 先于业务运行单元准备。
- 应用入口负责通过显式 import 选择要注册的 initiator 和 module；不要让业务实现包的间接 import 决定运行单元是否注册。
- 如果应用需要多种基础设施能力，应分别由单一职责 initiator 提供；不要新增聚合 repository、EventHub、runtime policy、route registry 的应用 runtime initiator。EventHub 直接使用 framework `Setup` 参数。
- 运行单元不应在 `init()` 中读取配置、连接数据库或注册路由。
- module/block 间的运行期依赖只能通过 EventHub 表达；公共 client 仅用于访问组件边界之外的外部系统，不能代替内部 EventHub 合同。
- `Weight` 只解决同类插件内顺序，不应用来隐藏架构依赖。
- 不要通过提高/降低 `Weight` 来弥补缺失依赖；缺失依赖应在 `Setup` 中 fail-fast，或通过明确 initiator/helper/EventHub contract 补齐。
- HTTP 暴露必须晚于必要依赖 ready；缺少核心依赖时不要启动半可用服务。
- ready 状态应由 service 生命周期统一标记，不要由单个运行单元私自标记全局 ready。

## 常见模式

- listener 型 initiator：`Setup` 解析配置、构造 runtime、完成预绑定；`Run` 非阻塞启动 serve；`Teardown` 带超时 shutdown
- background 型 initiator：`Setup` 保存 `eventHub` 与 `backgroundRoutine`；`Run` 注册 timer、cron 或常驻任务
- route 型运行单元：`Setup` 获取 route registry helper，构造 biz/service，绑定 registry；`Run` 先 `biz.Run()` 再 `service.RegisterRoute()`
- event 型运行单元：`Setup` 保存 event hub、注册 handler 所需依赖；`Run` 订阅事件或启动消费逻辑；`Teardown` 取消订阅或释放 worker

## 验证

优先跑受影响范围：

```bash
GOCACHE=/tmp/go-module-initiator-gocache go test ./framework/plugin/... ./framework/service -count=1
```

业务仓库中新增或调整 plugin 时，按真实目录替换：

```bash
GOCACHE=/tmp/go-module-initiator-gocache go test ./internal/initiators/... ./internal/<unit-root>/... -count=1
```

交付前检查：

- 新插件 ID 唯一
- side-effect import 只出现在入口装配层
- `Setup` / `Run` / `Teardown` 职责清晰
- listener 有关闭路径
- 后台任务挂在 `BackgroundRoutine`
- 消费组件已在 `Run` 订阅投递组件 command topic、在 `Teardown` 释放，且调用方验证 magicCommon `event.Result` 中的具体结果类型
- workspace-local ID 的 command、resolve、read 和派生持久化 ID 有明确 scope；无 scope 场景对重复 open 对象返回 conflict
- shared runtime contract 不依赖具体 owner module model，基础 initiator/blocks 没有反向 import owner module
- module/block/initiator 粒度合理：module 组合多个组件合同，block 只承担单一资源/技术能力且可持有自身状态，initiator 单一且无业务状态
- initiator/helper/bootstrap 没有 `ServiceExports`、`SetXService`、`XService()` 这类跨 owner service facade
- module/block 间没有直接 service/repository/adapter/callback 注入；事件合同没有 Envelope、map/any、JSON、reflect 或通用 wrapper
- route 注册不早于依赖 ready
- 没有在 `init()` 中做重副作用
- 测试和文档覆盖新增生命周期行为
- 入口显式 import 清单与预期加载模块一致
- 旧实现根目录和旧 import 路径已清零，例如不再残留 `<entry-root>/<entry-name>/server` 或 `internal/<entry-name>` 中间态实现包

## Formatter

- Markdown/YAML: run `skill-hub validate go-module-initiator-lifecycle --links` before feedback.
- Go examples: run `gofmt -w <files>` when adding real `.go` example files.
