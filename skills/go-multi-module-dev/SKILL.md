---
name: go-multi-module-dev
description: 用于基于 magicCommon/framework 与可选 magicEngine 的 Go 多运行单元仓库开发，覆盖 Initiator、Block、Module 决策，入口和 process service 落点，EventHub 合同，HTTP 路由注册，biz/service/pkg 拆分以及结构验收。新增、迁移或收口 framework 运行单元时使用。
version: 2.3.0
---

# Go Multi Module Development

这个 skill 用于基于 `magicCommon` 的 Go 仓库开发。它聚焦“运行单元如何落点、如何拆层、如何与事件/路由/生命周期协同”，而不是把某个现有项目的目录形状直接复制到目标仓库。

## 1. 占位符约定

本文中的占位符只表达职责，不表达固定目录规范：

- `<entry-root>`: 可执行入口根目录，例如 `cmd`、`application`、`apps`
- `<entry-name>`: 某个入口的职责名
- `<service-root>`: 进程级 service 根目录，例如 `internal/services`
- `<unit-root>`: 运行单元根目录，例如 `modules`、`features`、`capabilities`
- `<group-path>`: 运行单元分组路径，例如 `shared`、`orchestration`、`platform/core`
- `<unit>`: 单个运行单元目录名
- `<unit-entry-file>`: 运行单元主文件名，例如 `module.go`、`unit.go`、`bootstrap.go`

如果目标仓库已经有既定术语，优先沿用目标仓库自己的命名。

## 2. 先看这些文件

- `go.mod`
- `README.md`
- `AGENTS.md`

## 3. 按任务读取这些 references

- 运行单元结构和落点：`references/MODULE_STRUCTURE.md`
- 事件协同：`references/EVENT_USAGE.md`
- magicCommon framework 与 magicEngine 集成收口：`references/FRAMEWORK_INTEGRATION.md`
- 最小模板和脚本：`references/TEMPLATES.md`
- 如果任务涉及 `initiator` 接线、plugin `module` 生命周期、`Setup` / `Run` / `Teardown` 顺序，配合使用 `go-module-initiator-lifecycle`

## 4. 工作流

1. 先确认仓库角色和依赖
   - `magicCommon` 是基础框架
   - `magicEngine` 负责 HTTP
   - `magicOrm` 负责模型和持久化
   - 业务仓库在这些基础库之上封装入口、运行单元和对外能力
   - 使用 `magicCommon/framework` 时，运行单元启用权归入口装配层，不归业务 bootstrap 或普通 package
2. 先确定当前仓库已经采用的目录与命名
   - 入口可能在 `<entry-root>/<entry-name>/`
   - 进程级 service 可能在 `<service-root>/<entry-name>/`
   - 运行单元可能在 `internal/<unit-root>/<group-path>/<unit>/`
   - 仓库内共享 helper 常见于 `internal/pkg/`
   - 对外复用公共包常见于 `pkg/`
   - 如果仓库已经使用 `internal/modules/kernel`、`internal/modules/blocks` 这类分组，就沿用，不要改名
   - 如果仓库没有这些名字，不要强行引入
   - 如果一个目录实现 `framework/plugin/module` 生命周期，且拥有 route/listener、EventHub 订阅或 owner 状态，应落到 `internal/modules/application/<entry-name>/{biz,service,pkg}`，并由 `<unit-entry-file>` 接入 module 生命周期
   - 如果一个目录只负责进程启动模式、参数解析、`framework/application` 启停、CLI/TUI/remote/server 编排，应落到 `<service-root>/<entry-name>`，不要放在 `internal/modules/application`
   - `<entry-root>/<entry-name>` 只保留进程入口、入口测试、启动参数解析或少量进程级文件；不放 appservice、bootstrap、server、observed、presenter 等实现包
   - application module 可以保留面向 HTTP/CLI 的窄 facade；纯 DTO、投影、配置、owner command/read port、runtime support 等低层规则应下沉到 focused packages，避免 facade 变成 catch-all
   - CLI/TUI/agent 使用的稳定端口契约优先放到 `internal/pkg/<entry-name>port`，REST/HTTP client 优先放到 `internal/pkg/<entry-name>client`；进程 service 内只保留这些 port 的具体实现
3. 再判断运行单元的职责边界
   - module：功能闭环必须依赖多个独立组件合同的组合、聚合、治理或编排；允许管理自己的协调状态
   - block：只围绕单一资源聚合或单一技术能力；允许管理该资源或能力自己的正式状态、运行时状态
   - initiator：只提供一种无业务状态的基础设施能力；可持有该能力所需的单一进程级句柄，但不管理业务状态、策略或多能力状态
   - module 与 block 的区别由职责闭环决定，不由是否存在 repository、状态模型、调用方数量或文件规模决定
   - module/block 之间的运行期交互只能通过同一应用 `EventHub`；禁止直接注入或调用对方 service、repository、adapter、reader callback
   - “无状态 Initiator”是指不拥有业务状态；RouteRegistry、listener、client factory 可以持有实现该单一基础设施能力所必需的进程级句柄
   - 单消费者能力若没有独立启停、资源 owner 或后台任务，优先并回调用方或保留为 focused package，不要仅为目录对称创建 Block
4. 再判断粒度，不要把“拆分”当作默认答案
   - 需要独立 framework module：拥有独立生命周期，且其功能闭环需要组合多个独立组件合同；可拥有协调状态、订阅、route/listener，并可被入口按需启用/禁用
   - 需要 process service：负责一个可执行进程的 mode selection、配置目录、`application.Startup/Run/Shutdown`、CLI/TUI/remote/server 编排；它实现或组合 `framework/service.LifecycleService`，但不注册为 plugin module
   - 需要 block：围绕单一资源聚合或单一技术能力形成独立生命周期；可以管理自己的正式状态或运行时状态，但不编排多个组件完成业务闭环
   - 需要 initiator：只提供一种无业务状态基础设施能力，例如单一 route registry、client factory、listener 或 scheduler；不得同时聚合 repository set、EventHub wrapper、runtime policy 等多种职责
   - 只需要 focused package：纯 DTO、mapping、projection、query normalization、payload mapper、config helper、validation/scoring、路径/内容 helper，没有独立生命周期
   - 只需要同包 helper：当前文件职责清楚，只是局部流程较长；拆出后不会形成新的 owner、port 或可复用边界
   - 不应拆：拆分会制造反向依赖、共享可变状态、跨 owner service facade、或让状态机/activation/lifecycle 主流程分散到难以审计
5. 只补当前任务需要的最小层
   - `<unit-entry-file>`
   - `biz/`
   - `service/`
   - `pkg/common`
   - `pkg/models`
   - 上面这些都不是强制；缺哪层由任务边界决定
6. 涉及跨仓依赖时，同步核对对应仓库文档和 skill
   - `magicCommon`: 生命周期、event、task、session、monitoring
   - `magicEngine`: route、middleware、static、sse、tcp
   - `magicOrm`: provider、validation、query/update、remote
7. 代码完成后，同步补
   - 直接相关测试
   - 文档
   - 如有复用价值，再更新 skill

## 5. 开发规则

- 先看现有运行单元，不要凭空造新分层。
- 如果仓库使用 `magicCommon/framework/plugin/module` 生命周期，入口优先保持 `module.Register(New()) -> Setup() -> Run() -> Teardown()` 这条链。
- 多运行单元应用入口应通过显式 import 选择本入口需要加载的 initiator 和 modules；不要依赖某个实现包被业务代码间接 import 来触发注册。
- framework side-effect import 只放在可执行入口 `main` 或明确入口装配文件中，用来按需启用 initiator/module；不要放在业务 `app` 包、`biz/bootstrap` 包或共享 helper 中。
- 进程级 service 不应伪装成 `internal/modules` 下的运行单元；是否存在正式状态不是 module 判据，只有多组件合同编排形成业务闭环的运行单元才归为 module。
- `internal/services/<entry-name>` 可以包含 `service.go`、`runtime.go`、`options.go`、`config.go`、`logging.go` 等 lifecycle shell 文件；业务启动策略应下沉到 `biz/session`、`biz/agent` 或 focused package。
- `service/cli`、`service/tui` 是 adapter/view 层，只依赖 port 契约；它们不直接 import backend 实现、REST client、kernel owner service 或 repository。
- `biz/backends` 这类实现包可以实现 `internal/pkg/<entry-name>port` 的接口；remote 实现使用 `<entry-name>client`，embedded/local 实现使用 EventHub command/response。
- `<entry-name>client` 只负责 HTTP path、request/response 编解码和 error mapping；不依赖 `internal/services/<entry-name>`、framework application、EventHub、CLI/TUI。
- `<entry-name>port` 只放稳定接口、DTO、事件和纯 helper；不依赖具体 backend 实现或进程 service。
- 当 Web/TUI/CLI 需要展示跨 owner 的复杂状态时，优先在服务端 application/appservice 内建立 ViewModel/projection focused package，由服务端维护 revision、health、baseline/rebuild 和 detail projection；端侧只消费 projection DTO，不自行 fan-out 聚合 owner 状态。
- ViewModel/projection 不是正式业务状态 owner：它可以缓存、重建、降级和发布刷新通知，但正式写入、状态机转换、evidence 接受仍由对应 module/block 在 EventHub handler 内完成。
- Workspace/detail/list 这类展示 API 不应在 request handler 或端侧逐 workspace 调用重型 owner reader；重型读取只能作为 projection manager 的 baseline/rebuild 内部路径。
- 如果 detail projection 需要 task progress、context bundle、blocker、usage、artifact summary 等派生数据，应放进同一个 detail projection contract，避免 Web/TUI 主视图再调用多个派生 endpoint 拼装同一屏状态。
- `internal/modules/application/<entry-name>/module.go` 负责把应用服务接入 plugin module 生命周期；该 module 的实现子包按职责放到 `biz/`、`service/`、`pkg/`，不要平铺在 module 根目录。
- 新增运行单元前先完成 `<entry-root>` / `<unit-root>` / `<group-path>` / `pkg` 落点判断，并把判断写入设计文档或变更说明。
- 如果仓库存在“基础能力分组”和“编排/治理分组”，沿用现有名字；不要把某个项目里的 `kernel`、`blocks` 当成所有仓库的默认规范。
- 新 module/block 的判断标准是职责闭环和生命周期，不是是否有状态、文件行数或复用方数量；如果只是为了降低文件长度，优先包内 helper 或 focused package。
- 拆分后的 package 必须能用一句话说明职责；如果一个名字需要同时解释“读、写、治理、投影、运行期调度”，说明粒度过大。
- 如果两个 package 总是双向调用、共享同一批私有数据或必须按固定顺序修改同一状态，它们不应拆成两个 owner/module；应保留在一个 owner 内部，或抽出纯 helper。
- 如果一个 package 只包含一个很小的 wrapper、没有独立测试价值、没有清晰复用场景，也没有隔离边界价值，说明拆分过度。
- 不带业务归属的 runtime execution/policy/artifact continuation 等基础值类型可放在 `internal/pkg/<runtime-contract>`；事件 command/data/result 必须由事件投递组件自己的 `pkg/events` 定义，消费组件按需导入该包。
- initiator 只能提供一种基础设施能力；如果同时需要 repository、EventHub、runtime policy、route registry 等能力，应拆成多个 initiator 或直接使用 framework 注入的基础设施，不能建立综合 runtime 容器。
- “当前业务运行时缺失时如何处理”属于具体服务自己的启动治理逻辑，应放在该服务自己的 startup / persistence / system 类运行单元中，不要下沉到共享基础层。
- 如果启动链路中 `baseClient`、`persistence helper`、`route registry` 等基础依赖未就绪，后续运行单元必须 fail-fast 返回明确错误，禁止继续执行到 DAO / helper 再发生 nil pointer panic。
- `biz/bootstrap` 可以显式组合当前运行域所需对象，但不要复用 framework plugin manager 扫描全局注册表来装配局部 runtime；局部 runtime 应使用显式 lifecycle 列表和窄接口 exports。
- 局部 runtime / initiator helper 不能演变成跨 owner `Service` 注册表；不要导出 `ServiceExports`、`SetXService`、`XService()` 这类 facade 给 application/appservice 绕过 owner module。
- module/block 间需要协同时，事件投递组件在自己的 `pkg/events` 定义稳定 topic 以及具体 `Command`、`Data`、`Result` 类型；消费组件只导入投递组件的事件包、订阅对应 command，并在 handler 内调用自己的内部 service/repository。
- 同步交互直接使用 magicCommon `event.Hub.Send` 与 `event.Result`；handler 通过 `event.Result.Set(<具体 Result>, err)` 返回结果，调用方必须校验结果存在、错误和值类型，禁止使用 `events.Response`、Envelope 或通用 command wrapper。
- 异步通知使用 `event.Hub.Post`；Post handler 收到的 `event.Result` 可能为 nil，禁止调用 `result.Set`。需要回执、失败判定或强一致记账时必须使用 `Send`。
- `Command`、`Data`、`Result` 中禁止用 `map[string]any`、`[]any` 或无约束 `any` 承载组件合同，也禁止通过 JSON marshal/unmarshal、反射类型表或兼容桥完成组件内传输。
- EventHub 合同只传数据，不传 `io.Writer`、`http.ResponseWriter`、channel、数据库连接、repository、Registry、Recorder 或其它可变资源句柄；大结果使用有界 DTO、分页、游标或专用流式基础设施。
- owner-specific port 可以作为易用接口存在，但生产实现必须只保存 EventHub、source 和 typed command mapping；不得包装或泄漏 owner 的 service/repository/可变对象。测试可提供 direct adapter，但生产装配必须扫描清零。
- 基础 EventHub 包只保留与 magicCommon EventHub 直接使用相关的 owner-neutral helper；不要保存业务 topic alias、Envelope、Response、payload mapper、通用 subscribe/send facade 或依赖 `reflect.Type` 的运行期合同分发。
- runtime block execute 等技术能力 topic 归 block/runtime owner 包定义；如果 contract 聚合需要识别该 topic，基础包只引用无反向依赖的 definitions 包，避免循环依赖。
- workspace-local ID、run-local ID、ticket ID、approval ID 等跨 workspace 可能重复的对象，在跨 module command、REST handler、CLI/TUI backend 和持久化 resolution/result ID 中必须携带足够 scope；无 scope 的读取/resolve 入口只能在能解析唯一 open 对象时继续，否则必须返回 conflict，不能误操作其他 workspace。
- REST client / server / e2e 脚本必须区分 path 与 query string；新增或修改 URL 时同时检查前端、client、handler 和验证脚本，避免把 `?waitState=` / `?limit=` 拼成 `&waitState=` 这类 path 片段。
- 测试可以用 repository fixture 或 fake port 覆盖局部算法，但生产扫描必须确认 application/appservice 不直接访问 kernel owner repository/service。
- block 可以管理单一资源或单一技术能力自己的正式状态、运行时状态；一旦需要组合多个独立组件合同完成闭环，应提升为 module 或由现有 module 编排。
- module/block 的构造参数只接收本组件内部依赖和 framework 基础设施；跨组件运行期依赖只能通过 EventHub 合同表达，不能通过 session/export、repository provider、adapter 或窄接口绕过。
- 跨 owner 的“保存、校验、激活、通知”若涉及多个组件，由 application Module 的 biz 用例编排；HTTP handler 只做请求响应，单一资源 Block 只修改自己的状态，不能把跨组件流程塞进 handler 或伪装成 Block 内部更新。
- framework 长期任务、周期巡检和恢复任务应使用 `task.BackgroundRoutine`；请求生命周期内且受 request context 管理的短 goroutine 可以保留，但必须有取消和回收路径。
- `Weight()` 不能表达路由优先级或隐藏组件依赖。对 first-match router 应注册显式路径、使用路由优先级能力，或集中声明顺序；禁止依赖“某 Module 先 Run，所以 `/**` 不会吞路由”。
- RouteRegistry Initiator 只向 Module/Block 暴露 `GetRouteRegistry()` 等窄 helper；业务组件不得取得 `http.Server`、listener 或 handler。路由由 service 层声明，listener 的启用时机必须保证路由已就绪，避免启动窗口返回 404。
- `biz` 负责业务和事件，不直接堆 HTTP 细节。
- `service` 负责 route / handler / request-response。
- `pkg/common` 放单元 ID、常量、错误、过滤器、结果。
- `pkg/models` 放 DTO / entity / view model。
- 如果任务只是扩展已有运行单元，优先沿用现有目录，而不是再创建新运行单元。

## 6. Module 边界核对清单

新增或调整运行单元时，至少核对：

- 入口装配：side-effect imports 是否只在入口层，是否能按需启用/禁用 module。
- 生命周期：`Setup` 只接线依赖，`Run` 启动订阅、route、listener 或任务，`Teardown` 幂等释放。
- 依赖边界：initiator 是否只提供一种无业务状态基础设施能力；module/block 是否未注入其他组件的 service/repository/adapter/callback。
- 事件边界：同步裁决用 EventHub `Send` 或项目封装的同步发布；通知类事件用 `Post`；同一业务对象需要 lane key。
- Post 边界：异步 handler 是否完全不依赖 `event.Result`；是否有 result=nil 的直接回归测试。
- owner 边界：module/block 是否只访问自己的 repository/service；跨组件写入、读取、状态机转换和 evidence 查询是否都走 EventHub。
- scope 边界：workspace/run/ticket/approval/result/artifact 等 ID 是否携带足够 scope；无 scope API 是否对重复 open 对象返回冲突；生成 resolution/result/artifact ID 时是否避免跨 workspace 碰撞。
- 契约边界：事件投递组件是否定义了具体 command/data/result；消费组件是否只导入投递组件 `pkg/events`；是否不存在 map/any、JSON、reflect 或兼容桥传输。
- topic 边界：业务 topic 是否只在事件投递组件 `pkg/events` 定义；基础 events 包是否没有业务 topic alias 或通用投递/订阅封装。
- 粒度边界：module 是否确实组合多个组件合同，block 是否只承担单一资源/技术能力，initiator 是否单一且无业务状态。
- facade 扫描：是否不存在 `exports.Services.*`、`ServiceExports`、`SetXService`、`XService()`、appservice 直接 owner repository 访问等生产残留。
- 后台任务：长期任务、timer、恢复扫描、异步 continuation 是否挂在 framework `BackgroundRoutine` 或统一 scheduler。
- 路由边界：是否不存在依赖 Module Weight 的 first-match 顺序；RouteRegistry helper 是否没有暴露 server/listener/handler。
- 资源边界：EventHub payload/result 和 EventHub-backed port 是否都没有泄漏 owner 的可变资源或 I/O 句柄。
- 状态权威：block 可以维护自己的正式对象；module 只维护编排闭环所需的协调状态，不能直接持有其他组件状态仓库。
- ViewModel 边界：端侧展示是否只读服务端 projection；projection store 是否带 revision/health；handler 是否只读 store，不做请求时重型聚合。
- 配置读取：入口、bootstrap、configuration service 可读取全局配置；业务 use-case 优先使用注入的 config accessor。
- 验证：补直接测试、受影响包测试、文档或 checklist。

## 7. 结构完成验收

完成目录调整或新建骨架后，必须做结构验收，不要只依赖 `go test`：

- 入口验收：`find <entry-root>/<entry-name> -maxdepth 3 -type f` 应只包含入口、入口测试、启动参数或少量进程级文件。
- process service 验收：如果存在 `<service-root>/<entry-name>`，它应清楚区分 lifecycle shell、adapter、use-case/session、backend implementation；不能注册为 plugin module，不能直接访问 owner repository/service。
- 应用 module 验收：如果存在 `internal/modules/application/<entry-name>`，其实现应按 `biz/`、`service/`、`pkg/` 分层，`module.go` 保持生命周期桥接职责。
- 旧路径验收：用 `rg "internal/<entry-name>|<entry-root>/<entry-name>/(appservice|bootstrap|server|observed|presenter|demo)"` 检查中间态实现根和旧路径引用是否清零；历史归档文档可显式排除。
- 加载验收：入口文件应显式 import 本入口选择的 initiator、kernel、blocks、application module；新入口不能靠隐式依赖完成 module 注册。
- 文档验收：`README.md`、`docs/structure.md` 或状态文档必须描述最终正式路径，不能继续描述已删除的中间态路径。

## 8. Framework 架构红线

以下规则用于约束 `magicCommon/framework`、EventHub 与运行单元边界，可直接用于设计评审和迁移验收：

- 入口显式选择启用哪些 initiator/module；业务 package 的间接 import 不承担启用责任。
- 进程级 service 落到 `internal/services/<entry>`；framework plugin module 落到 `internal/modules/...`。不要因为 service 目录里有 CLI/TUI/remote/server 编排就把它定义成 module。
- CLI/TUI/agent 应依赖 `internal/pkg/<entry>port`；REST client 应在 `internal/pkg/<entry>client`；backend 实现留在 process service 内。
- Web/TUI/CLI 是 View/Presenter，不是 ViewModel owner；跨 owner 展示状态由服务端 projection manager 维护并通过 REST/SSE 或 port contract 输出。
- 服务端 projection manager 应在启动时全量构建 baseline，并通过 owner notification event 或明确 rebuild task 维护 revision；端侧收到 projection changed event 后刷新 projection，不自行重新推导正式状态。
- framework plugin manager 用于应用级 lifecycle，不用于组装嵌入式或局部 runtime；局部 runtime 使用显式 lifecycle 列表。
- initiator 只暴露一种无业务状态基础设施能力；不得把 repository provider、EventHub wrapper、runtime policy、config loader、route registry 等聚合到一个 initiator。
- application/appservice/HTTP/TUI 生产代码访问正式 owner state 时必须走 EventHub-backed port 或 facade，不直接 import owner `biz`/`service`/正式 repository。
- 每个事件的 topic、具体 command/data/result 由投递组件定义；消费组件导入投递组件 `pkg/events` 并按需订阅，不复制类型或通过共享 alias 获取。
- module/block 间同步交互直接使用 magicCommon `event.Result` 返回具体 result；缺失结果、类型不匹配或错误都不能当成成功。
- 禁止 Envelope、`events.Response`、`map[string]any`/`[]any` payload、JSON 编解码、反射合同和通用 Send/Subscribe facade 作为组件交互兼容层。
- 跨 workspace 的 run/ticket/approval/result/artifact 操作必须有 scope contract；HTTP/CLI/TUI 如果暂时无法提供 workspace scope，只能选择唯一 open 对象或返回 conflict。
- e2e 暴露的 URL、状态等待、scope 解析、governance resolution 等问题必须回填到架构文档、验证 checklist 和 skill；不要只在脚本中绕过失败。
- `Weight()` 只表达同类插件的 lifecycle 顺序，不能隐藏架构依赖；依赖应通过 initiator/helper、EventHub contract 或显式构造参数表达。
- EventHub `Post` 没有同步 Result；Post observer 调用 `result.Set` 会产生 nil pointer panic，而且 Hub 可能只记录告警而不让普通测试失败，必须补直接回归测试。
- 单消费者的内存索引、归档 helper 等若没有独立生命周期，不应为了“组件化”强行建 Block；独立 Block 必须有清晰 owner、生命周期或多个 EventHub 消费方。
- Metrics、Usage 等 Block 不得返回 `*Registry`、`*Store`、`*Recorder`；对外提供 typed EventHub command/result 或 EventHub-backed port。
- magicEngine first-match 路由不应使用依赖注册先后的全局 `/**` 兜底；协议网关优先显式注册允许的 method/path 白名单。
- 是否继续拆分大文件取决于职责混杂、状态权威不清、复用价值和边界风险，不以行数作为 framework/EventHub 合规标准。
- 合理粒度通常表现为：单一 owner、单一生命周期、单一通信契约或单一纯算法族；过大通常表现为 catch-all facade，过小通常表现为只有转调 wrapper 且无独立语义。

## 9. 常用脚本

- 创建最小运行单元骨架：`scripts/create-module.sh`

这个脚本只适用于同时满足下面条件的仓库：

- 当前仓库使用 `magicCommon/framework/plugin/module`
- 生成骨架的默认 `biz/service/pkg` 拆分符合目标仓库习惯
- 传入的 `<group-path>`、`<unit-root>`、`<unit-entry-file>` 能映射到目标仓库的真实目录

如果这些条件不成立，不要硬用脚本，直接按目标仓库现状手工落结构。

## 10. 推荐验证

先跑受影响范围，再跑全量：

```bash
GOCACHE=/tmp/go-multi-module-gocache go test ./... -count 1
```

## Formatter

- Markdown/YAML: run `skill-hub validate --pattern go-multi-module-dev --links` before feedback.
- Go examples: run `gofmt -w <files>` when adding real `.go` example files.
