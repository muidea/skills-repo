---
name: go-multi-module-dev
description: 用于基于 magicCommon/framework 的 Go 多运行单元仓库开发，覆盖入口落点、`internal/<unit-root>/` 分层、运行单元职责边界、biz/service/pkg 拆分、事件集成、路由注册、文档与测试同步。新增或扩展运行单元、调整分组落点或做跨仓联动开发时使用。
version: 2.2.3
---

# Go Multi Module Development

这个 skill 用于基于 `magicCommon` 的 Go 仓库开发。它聚焦“运行单元如何落点、如何拆层、如何与事件/路由/生命周期协同”，而不是把某个现有项目的目录形状直接复制到目标仓库。

## 1. 占位符约定

本文中的占位符只表达职责，不表达固定目录规范：

- `<entry-root>`: 可执行入口根目录，例如 `cmd`、`application`、`apps`
- `<entry-name>`: 某个入口的职责名
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
   - 运行单元可能在 `internal/<unit-root>/<group-path>/<unit>/`
   - 仓库内共享 helper 常见于 `internal/pkg/`
   - 对外复用公共包常见于 `pkg/`
   - 如果仓库已经使用 `internal/modules/kernel`、`internal/modules/blocks` 这类分组，就沿用，不要改名
   - 如果仓库没有这些名字，不要强行引入
   - 如果应用自身承载业务编排、HTTP 服务、前端 assets、observed/presenter 等实现，并且仓库已有 `internal/modules/application` 分组，应落到 `internal/modules/application/<entry-name>/{biz,service,pkg}`，不要额外保留 `internal/<entry-name>` 作为中间实现根
   - `<entry-root>/<entry-name>` 只保留进程入口、入口测试、启动参数解析或少量进程级文件；不放 appservice、bootstrap、server、observed、presenter 等实现包
   - application module 可以保留面向 HTTP/CLI 的窄 facade；纯 DTO、投影、配置、owner command/read port、runtime support 等低层规则应下沉到 focused packages，避免 facade 变成 catch-all
3. 再判断运行单元的职责边界
   - 可复用基础能力单元：围绕单一资源或单一技术能力，提供稳定 CRUD、状态流转、基础校验、资源事件或公共封装
   - 编排/治理单元：组合多个基础能力或外部系统，完成策略、准入、授权、审核、运行态治理或跨资源一致性
   - 如果一个能力依赖多个低层能力才构成业务闭环，默认放入编排/治理分组
   - 不要因为一个能力带 CRUD 模型，就自动把它归入“基础能力分组”
4. 再判断粒度，不要把“拆分”当作默认答案
   - 需要独立 framework module：拥有独立生命周期、订阅自己的 EventHub topic、拥有正式状态或对外 route/listener，且可以被入口按需启用/禁用
   - 需要 block：只封装 runtime 技术能力或外部系统执行，输入输出是执行证据或能力结果，不拥有正式业务状态
   - 需要 initiator：提供进程级基础设施、repository provider、EventHub wrapper、runtime policy、route registry、client factory 或 background routine，不包含具体业务策略
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
- `internal/modules/application/<entry-name>/module.go` 负责把应用服务接入 plugin module 生命周期；该 module 的实现子包按职责放到 `biz/`、`service/`、`pkg/`，不要平铺在 module 根目录。
- 新增运行单元前先完成 `<entry-root>` / `<unit-root>` / `<group-path>` / `pkg` 落点判断，并把判断写入设计文档或变更说明。
- 如果仓库存在“基础能力分组”和“编排/治理分组”，沿用现有名字；不要把某个项目里的 `kernel`、`blocks` 当成所有仓库的默认规范。
- 新 module/block 的判断标准是生命周期和状态权威，不是文件行数；如果只是为了降低文件长度，优先包内 helper 或 focused package。
- 拆分后的 package 必须能用一句话说明职责；如果一个名字需要同时解释“读、写、治理、投影、运行期调度”，说明粒度过大。
- 如果两个 package 总是双向调用、共享同一批私有数据或必须按固定顺序修改同一状态，它们不应拆成两个 owner/module；应保留在一个 owner 内部，或抽出纯 helper。
- 如果一个 package 只包含一个很小的 wrapper、没有独立测试价值、没有清晰复用场景，也没有隔离边界价值，说明拆分过度。
- 共享 runtime execution/policy/artifact continuation 等跨模块契约应放在 `internal/pkg/<runtime-contract>` 这类基础契约包；initiator、blocks、kernel orchestration 和 application 可以共同依赖它，不要让基础 initiator 或 blocks 反向 import 某个 owner module 的 `pkg/models`。
- 基础层或共享 initiator 可以提供通用查询、绑定、client 构造能力，但不负责某个具体业务“缺失时如何初始化”的策略判断。
- “当前业务运行时缺失时如何处理”属于具体服务自己的启动治理逻辑，应放在该服务自己的 startup / persistence / system 类运行单元中，不要下沉到共享基础层。
- 如果启动链路中 `baseClient`、`persistence helper`、`route registry` 等基础依赖未就绪，后续运行单元必须 fail-fast 返回明确错误，禁止继续执行到 DAO / helper 再发生 nil pointer panic。
- `biz/bootstrap` 可以显式组合当前运行域所需对象，但不要复用 framework plugin manager 扫描全局注册表来装配局部 runtime；局部 runtime 应使用显式 lifecycle 列表和窄接口 exports。
- 局部 runtime / initiator helper 不能演变成跨 owner `Service` 注册表；不要导出 `ServiceExports`、`SetXService`、`XService()` 这类 facade 给 application/appservice 绕过 owner module。
- 如果 application、bootstrap、TUI、HTTP 或其他 module 需要读写另一个 owner module 的正式状态，生产路径必须发布该 owner 的同步 EventHub command topic，并要求收到 `events.Response`；owner module 在 `Run` 订阅 command topic，在 `Teardown` 取消订阅。
- owner module 负责把 command payload 翻译为自己的 service/repository 操作；调用方不要向 command payload 塞 owner service command 类型，优先使用稳定 payload key、owner model 或明确 DTO，避免 application 反向 import owner `service` 包。
- 测试可以用 repository fixture 或 fake port 覆盖局部算法，但生产扫描必须确认 application/appservice 不直接访问 kernel owner repository/service。
- blocks 只承载 runtime 技术能力或外部系统执行，不拥有正式业务状态；application 只做入口、HTTP/CLI、facade 和用例编排；formal owner state 必须留在对应 owner module。
- 运行配置、EventHub、BackgroundRoutine、repository/helper 等跨模块依赖优先通过构造参数、session/export 或窄接口传入，不要在 use-case 内散乱读取全局单例。
- `biz` 负责业务和事件，不直接堆 HTTP 细节。
- `service` 负责 route / handler / request-response。
- `pkg/common` 放单元 ID、常量、错误、过滤器、结果。
- `pkg/models` 放 DTO / entity / view model。
- 如果任务只是扩展已有运行单元，优先沿用现有目录，而不是再创建新运行单元。

## 6. Module 边界核对清单

新增或调整运行单元时，至少核对：

- 入口装配：side-effect imports 是否只在入口层，是否能按需启用/禁用 module。
- 生命周期：`Setup` 只接线依赖，`Run` 启动订阅、route、listener 或任务，`Teardown` 幂等释放。
- 依赖边界：initiator/helper 获取失败是否 fail-fast，是否只暴露窄接口。
- 事件边界：同步裁决用 EventHub `Send` 或项目封装的同步发布；通知类事件用 `Post`；同一业务对象需要 lane key。
- owner 边界：正式状态 owner 是否只在本 module 内访问 repository/service；跨 owner 写入、读取、状态机转换和 evidence 查询是否都走 EventHub command/response。
- 契约边界：共享 runtime contract 是否位于基础包，是否不存在 initiator/blocks/application 反向 import owner module model 来表达通用运行期契约。
- 粒度边界：新增 package/module 是否有明确生命周期、状态权威、复用价值或边界隔离价值；是否避免了 catch-all 和 wrapper-only 两个极端。
- facade 扫描：是否不存在 `exports.Services.*`、`ServiceExports`、`SetXService`、`XService()`、appservice 直接 owner repository 访问等生产残留。
- 后台任务：长期任务、timer、恢复扫描、异步 continuation 是否挂在 framework `BackgroundRoutine` 或统一 scheduler。
- 状态权威：基础资源模块只维护自己的正式对象；跨模块状态机裁决放在编排/治理模块。
- 配置读取：入口、bootstrap、configuration service 可读取全局配置；业务 use-case 优先使用注入的 config accessor。
- 验证：补直接测试、受影响包测试、文档或 checklist。

## 7. 结构完成验收

完成目录调整或新建骨架后，必须做结构验收，不要只依赖 `go test`：

- 入口验收：`find <entry-root>/<entry-name> -maxdepth 3 -type f` 应只包含入口、入口测试、启动参数或少量进程级文件。
- 应用 module 验收：如果存在 `internal/modules/application/<entry-name>`，其实现应按 `biz/`、`service/`、`pkg/` 分层，`module.go` 保持生命周期桥接职责。
- 旧路径验收：用 `rg "internal/<entry-name>|<entry-root>/<entry-name>/(appservice|bootstrap|server|observed|presenter|demo)"` 检查中间态实现根和旧路径引用是否清零；历史归档文档可显式排除。
- 加载验收：入口文件应显式 import 本入口选择的 initiator、kernel、blocks、application module；新入口不能靠隐式依赖完成 module 注册。
- 文档验收：`README.md`、`docs/structure.md` 或状态文档必须描述最终正式路径，不能继续描述已删除的中间态路径。

## 8. WorkOrch 验证过的架构红线

这些规则来自 WorkOrch 对 `magicCommon/framework` 与 EventHub 边界的迁移收口，可作为多运行单元项目的通用红线：

- 入口显式选择启用哪些 initiator/module；业务 package 的间接 import 不承担启用责任。
- framework plugin manager 用于应用级 lifecycle，不用于组装嵌入式或局部 runtime；局部 runtime 使用显式 lifecycle 列表。
- initiator/helper 只暴露基础设施、repository provider、EventHub、runtime policy、config loader、route registry 或窄 adapter，不暴露跨 owner service。
- application/appservice/HTTP/TUI 生产代码访问正式 owner state 时必须走 EventHub-backed port 或 facade，不直接 import owner `biz`/`service`/正式 repository。
- command payload 使用稳定 DTO、owner model 或 primitive payload，不使用 owner service command 类型作为跨 module 契约。
- module/block 间同步状态裁决必须要求 `events.Response`；缺失 response 是装配或 lifecycle 问题，不能当成成功。
- `Weight()` 只表达同类插件的 lifecycle 顺序，不能隐藏架构依赖；依赖应通过 initiator/helper、EventHub contract 或显式构造参数表达。
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

- Markdown/YAML: run `skill-hub validate go-multi-module-dev --links` before feedback.
- Go examples: run `gofmt -w <files>` when adding real `.go` example files.
