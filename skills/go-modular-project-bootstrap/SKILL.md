---
name: go-modular-project-bootstrap
description: 用于初始化类似现有 Go 多应用、多运行单元服务套件的新项目骨架，覆盖仓库结构、应用入口、运行单元生命周期、配置、路由、健康检查、测试与文档基线；创建通用服务框架项目时使用。
compatibility: Compatible with open_code
metadata:
  version: 1.3.1
  author: "rangh"
  created_at: "2026-04-18T21:37:24+08:00"
---

# Go Modular Project Bootstrap

这个 skill 用于从现有 Go 服务仓库中抽象可复用模式，并初始化新的单入口或多入口项目骨架。它不是某个具体业务项目的复制清单，必须避免把源项目名称、固定目录层级、绝对路径、环境地址、账号密钥或业务专属命名带入新项目。

## 使用边界

使用本 skill 的场景：

- 创建新的 Go 服务仓库或服务套件仓库
- 搭建一个或多个可执行入口
- 初始化运行单元注册、应用生命周期、配置、路由、健康检查和测试基线
- 从现有参考实现提炼结构，但目标项目需要保持独立命名和独立语义

不使用本 skill 的场景：

- 只是在已有项目内新增一个业务运行单元，优先使用 `go-multi-module-dev`
- 只修复单个应用启动问题，优先使用对应的应用启动或生命周期 skill
- 只处理 ORM、HTTP、认证、监控等单一框架能力，优先使用对应专项 skill

## 先选仓库形态，不要先抄目录

先判断目标项目属于哪种形态，再决定目录和入口：

### 形态 A: 单服务单入口

适用于只有一个主执行入口、但内部仍有清晰 initiator/运行单元分层的项目。

常见入口：

- `<entry-root>/<entry-name>/main.go`
- 或 `<entry-root>/<entry-name>/cmd/main.go`

### 形态 B: 单仓多入口

适用于同一仓库内提供多个可执行程序、不同入口加载不同运行单元集合的项目。

常见入口：

- `<entry-root>/<entry-name>/cmd/main.go`
- 必要时也可以是 `<entry-root>/<entry-name>/main.go`

### 形态 C: 基础能力仓库

适用于入口少、但仓库本身承担平台级通用能力的项目。

特点：

- 更关注通用运行单元和基础 initiator
- 允许未来被其他仓库复用

### 形态 D: 混合复用

适用于当前仓库只保留自己的运行单元、把公共 initiator 或共享能力单元放到外部依赖仓库的组合形态。

结论：

- `application/` 不是必选
- `cmd/` 不是必选
- `internal/initiators/` 不是必选
- `internal/<unit-group>/<group-a>` 与 `internal/<unit-group>/<group-b>` 也不是必选组合

只有在职责边界明确、并且未来维护收益大于目录复杂度时，才引入这些层次。

## 命名规则

- 新项目名称必须由用户或当前任务明确给出；未给出时先使用占位符 `<project>`，不要猜测。
- 应用入口名称必须来自目标职责，不要直接复用参考项目名，也不要把 `admin`、`gateway`、`worker` 当作默认必选项。
- 如果只是占位，优先使用 `<app>`、`<public-api>`、`<console>`、`<job>` 这类职责占位名，而不是伪装成已经定稿的业务名字。
- Go module path、Docker service、配置文件、日志字段和文档标题必须与目标项目名一致。
- `magicCommon`、`magicEngine`、`magicOrm` 这类基础库和框架依赖可以直接引用，不需要改名。
- 从源实现复制代码前，先列出需要替换的名称映射；复制后用全文搜索确认没有残留源项目名。
- 文档和 skill 中不要写入本机绝对路径，统一使用相对路径或 `<workspace>` 占位符。

如果参考项目里存在业务色彩很重的目录名，默认把它们视为“职责样例”，不是“新项目模板”。

应用实现目录必须使用正式职责名和正式分层；禁止使用 `phase1`、`demo-only`、`fallback`、`internal/<app>` 这类中间态或兼容性命名作为最终结构。

## 占位符约定

本文中的占位符只表达职责角色，不表达固定目录规范：

- `<entry-root>`: 可执行入口根目录，例如 `cmd`、`application`、`apps`
- `<entry-name>`: 某个入口的职责名，例如 `<console>`、`<public-api>`、`<job>`
- `<unit-group>`: 运行单元根目录，例如 `modules`、`features`、`capabilities`
- `<platform-group>`: 平台级或跨入口共享分组
- `<domain-group>`: 领域能力或业务能力分组
- `<unit>`: 单个运行单元目录名
- `<unit-entry-file>`: 运行单元主文件名，例如 `module.go`、`unit.go`、`bootstrap.go`

如果目标项目已经有既定术语，优先沿用目标项目自己的命名，不要反过来套用这里的占位符名字。

## 初始化流程

### 1. 建立源实现认知

先读取目标工作区和参考实现里的最小上下文：

- `go.mod`
- `README.md`
- `AGENTS.md`
- `docs/` 中与启动、运行单元、路由、部署相关的文档
- 常见入口文件，例如 `<entry-root>/*/main.go`、`<entry-root>/*/cmd/main.go`
- `internal/initiators/**/*.go`
- `internal/<unit-group>/**/<unit-entry-file>`
- `internal/<unit-group>/**/service/*.go`
- `internal/<unit-group>/**/biz/*.go`
- `config`、`config.d`、`deploy`、`scripts` 中与启动相关的文件

如果参考仓库把公共 initiator 或运行单元拆到外部依赖仓库，也要读取对应依赖仓库中的最小启动链路，而不是误以为当前仓库缺少这些层。

目标是确认架构模式，不是批量复制文件。

### 2. 定义项目蓝图

在写代码前明确这些决策：

- Go module path
- 仓库形态: 单入口、多入口、基础能力仓库或混合复用
- 入口布局: `<entry-root>/<entry-name>/main.go` 还是 `<entry-root>/<entry-name>/cmd/main.go`
- 应用入口清单，以及每个入口加载哪些 initiator/运行单元
- 每个入口的显式加载清单：哪些 initiator、`internal/modules/application/<app>`、`kernel`、`blocks` 需要通过 blank import 注册
- 哪些能力放本仓库，哪些能力复用外部依赖仓库
- 运行单元分层: 使用 `internal/<unit-group>/`，再按 `<group-a>/<group-b>` 或更贴近领域的名字分组
- 对外路由边界
- 认证和 session 边界
- 基于 `magicCommon` 的应用生命周期、事件、后台任务和监控接入点
- 基于 `magicEngine` 的 HTTP 路由、静态资源、SSE 或 TCP 接入点
- 基于 `magicOrm` 的持久化、模型和查询写入接入点
- 配置文件层级
- 本地启动和测试命令

如果用户只要求“基础框架”，默认只生成可启动、可测试、可扩展的最小骨架，不提前实现业务能力，也不要为了向参考项目看齐而补齐多余入口或目录。

### 3. 创建目录结构

按选定形态创建最小目录。以下都是“可选模板”，不是固定标准。

方案 A，单入口项目：

```text
<project>/
├── <entry-root>/
│   └── <entry-name>/
│       └── main.go
├── internal/
│   ├── config/
│   ├── initiators/          # 可选
│   └── <unit-group>/
├── pkg/
├── config/
├── docs/
├── test/
├── go.mod
└── README.md
```

方案 B，多入口项目：

```text
<project>/
├── <entry-root>/
│   ├── <console>/cmd/main.go
│   ├── <public-api>/cmd/main.go
│   └── <job>/cmd/main.go
├── internal/
│   ├── config/
│   └── <unit-group>/
├── pkg/
├── config/
├── docs/
├── test/
├── go.mod
└── README.md
```

方案 C，带分层运行单元的项目：

```text
internal/
└── <unit-group>/
    ├── <platform-group>/    # 平台级、跨入口、基础能力
    └── <domain-group>/      # 领域能力或可选能力
```

方案 C2，应用自身也是运行单元：

```text
<project>/
├── <entry-root>/
│   └── <entry-name>/
│       └── main.go          # 只做进程入口、显式加载和 application 生命周期
└── internal/
    ├── initiators/
    │   └── <runtime>/
    └── <unit-group>/
        ├── application/
        │   └── <entry-name>/
        │       ├── module.go
        │       ├── biz/
        │       ├── service/
        │       └── pkg/
        ├── <platform-group>/
        └── <domain-group>/
```

当入口对应的应用服务需要承载 HTTP server、前端 assets、运行时装配、observed/presenter 或应用级 orchestration 时，优先采用该结构。不要把这些实现放在 `<entry-root>/<entry-name>/` 或新建 `internal/<entry-name>/` 中间根目录。

方案 D，不拆双层分组，直接按领域分组：

```text
internal/
└── <unit-group>/
    ├── <unit-a>/
    ├── <unit-b>/
    └── <unit-c>/
```

只创建当前任务需要的入口和运行单元；不要为了“完整”生成空的大量目录。目录是否通用，取决于它是否表达稳定职责，而不是它是否长得像参考项目。

### 4. 接入应用生命周期

每个入口至少要完成：

- 加载配置
- 创建 service 实例
- 注册 initiator
- 注册运行单元
- 启动 application
- 等待退出信号
- 按顺序 shutdown

生命周期依赖应集中在应用 bootstrap 或 initiator 中，业务运行单元不要直接控制全局进程退出。

参考项目共同验证过的最小启动链是：

- 匿名导入注册
- `application.Startup(...)`
- `application.Run()`
- `application.Shutdown()`

保留这个链路即可，不必复制参考项目的所有导入项。

入口文件必须显式选择加载项：

- 通过 blank import 加载本入口需要的 initiator 和运行单元。
- 只加载当前入口职责需要的 module/block，不要全量导入无关运行单元。
- `internal/modules/application/<entry-name>/module.go` 负责把应用服务接入 plugin module 生命周期；入口不直接拼装业务依赖。

按入口职责区分启动模式：

- 管理类入口只加载管理端需要的 initiator、运行单元、路由和鉴权边界。
- 网关类入口只加载转发、鉴权、订阅校验、代理和公开服务所需运行单元，不要混入管理端或门户端私有单元。
- Worker 类入口只加载后台任务、事件消费和必要的持久化依赖，不暴露无关 HTTP 路由。
- Installer / migrator 等动作型入口必须先做路径、配置、目标环境和幂等性预检，再执行一次性动作。
- Studio / devtools 类入口必须把开发辅助能力和生产入口隔离。

如果一个入口只是为了演示或临时兼容存在，不要把它写进默认骨架。

启动失败应保留在 `Setup` / `Run` 的错误返回链中，不要用 `panic` 或裸 `log.Fatal` 掩盖具体单元和阶段。

### 5. 接入运行单元生命周期

每个运行单元至少提供一个主文件，常见命名是 `<unit-entry-file>`，其余目录按需要增加。不要强行要求所有运行单元都长成一样。

可选结构：

```text
{unit}/
├── <unit-entry-file>        # 例如 module.go、unit.go、bootstrap.go
├── biz/                     # 可选
├── service/                 # 可选
├── dao/                     # 可选
├── auth/                    # 可选
└── pkg/                     # 可选
```

上面这些子目录只是常见拆分方式，不是必须命名；如果目标项目已经有更稳定的术语，优先沿用目标项目自己的目录名。

运行单元职责：

- 主文件: 运行单元 ID、依赖获取、`Setup`、`Run`、`Teardown`
- `biz`: 业务编排、事件、后台任务、持久化调用
- `service`: route、handler、request/response 适配
- `dao`: 数据访问或外部依赖封装
- `auth`: 单元局部鉴权逻辑
- `pkg`: 仅放跨子目录复用、且确实稳定的公共结构

`Setup` 只做依赖接线，`Run` 做可失败的启动动作和路由注册，`Teardown` 做幂等释放。

从当前参考项目抽出的稳定共性只有这些：

- 如果使用 `magicCommon/framework/plugin/module` 机制，运行单元通常在 `<unit-entry-file>` 中通过 `init()` 注册
- `Setup` 中解析依赖并构造 `biz/service`
- `Run` 中启动业务逻辑并注册路由
- `Teardown` 负责幂等释放

不要把 `pkg/common`、`pkg/models`、`service`、`biz` 当作所有项目都必须存在的强约束。

但对于 `internal/modules/application/<entry-name>` 这类应用运行单元，推荐固定使用 `biz/`、`service/`、`pkg/`，因为它通常同时承载应用编排、协议适配、展示/观察模型和 assets。

### 6. 接入路由和健康检查

基础项目至少保留：

- `GET /health/live`
- `GET /health/ready`
- API 版本前缀策略
- 管理入口和公开入口的路由边界
- 认证中间件接入点
- 未实现路由的明确错误返回

不要让应用入口绕过底层服务契约；handler 只做协议适配，业务语义留在 biz 或更底层能力中。

如果项目不是 HTTP 服务，health/ready 可以换成等价的进程健康探针或服务状态接口，但必须有明确的可观测入口。

### 7. 配置与部署基线

至少准备：

- 默认本地配置
- 环境变量覆盖规则
- 每个应用入口的启动参数
- 本地运行脚本
- 容器或进程部署占位说明
- 日志级别和监控开关

配置示例必须使用占位值，不写入真实环境地址和凭据。

如果项目需要被其他仓库复用，优先保证：

- 配置名表达职责，而不是表达来源项目
- 外部依赖通过接口或独立配置接入，而不是把参考仓库路径写死
- Docker、脚本、README 都只绑定当前仓库的真实入口，不假设一定存在某组固定角色名

### 8. 结构验收基线

新建或重构完成后必须执行结构验收：

- `find <entry-root>/<entry-name> -maxdepth 3 -type f`：确认入口目录没有业务实现包。
- `find internal/<unit-group>/application/<entry-name> -maxdepth 3 -type d`：确认应用运行单元使用 `biz/service/pkg` 分层。
- `rg "internal/<entry-name>|<entry-root>/<entry-name>/(appservice|bootstrap|server|observed|presenter|demo)"`：确认没有中间态路径和旧路径引用残留。
- `rg "phase1|fallback|temporary|compatibility" --glob '!docs/archive/**'`：确认最终代码没有非正式业务命名；历史归档文档除外。
- 运行受影响测试、全量测试和本地服务验证，并同步 README / docs 中的最终结构描述。

### 9. 测试与验证

完成初始化后至少验证：

```bash
gofmt -w ./<entry-root> ./internal ./pkg
go test ./... -count=1
```

再做一致性检查：

```bash
rg -n "<source-project-name>|/home/|file://|vscode://" .
rg -n "TODO|panic\\(|log.Fatal" <entry-root> internal pkg
```

如果仓库同时存在多个入口根目录，按真实目录展开，例如 `cmd application internal pkg`。

如果初始化只完成骨架，允许保留明确的 TODO，但 TODO 必须说明待实现边界，不能掩盖启动失败。

## 配合 Skill

- 新增或扩展单个运行单元时，使用 `go-multi-module-dev`。
- 新增或管理 `initiator` / `module` 生命周期时，使用 `go-module-initiator-lifecycle`。
- 接线或管理 application、`EventHub`、`BackgroundRoutine`、`Post` / `Send` 和 shutdown 协同时，使用 `go-application-event-runtime`。
- 涉及 `magicCommon` 应用生命周期、插件、事件、后台任务时，选择当前工作区中覆盖 `framework/application`、`framework/service`、`plugin/initiator`、`plugin/module` 的生命周期类 skill。
- 涉及 `magicEngine` HTTP 路由、静态资源、SSE、TCP，或 `magicOrm` ORM、认证、监控等专项能力时，只加载对应专项 skill，不要把所有相关 skill 一次性读入上下文。

配合 skill 的名称和内容也应保持通用表达；如果必须引用已有项目实现，只把它当作参考实现，不把项目名写入新项目产物。

## 参考实现只提炼共性，不复制形状

结合当前工作区，至少记住这几点：

- “平台能力仓库 + 本地 initiator/运行单元 + 单入口”是可行形态。
- “单服务仓库 + `<entry-root>/<entry-name>` 入口 + 本地 initiator/运行单元”也是可行形态。
- “多入口仓库 + 本地运行单元 + 外部公共 initiator/运行单元仓库复用”同样成立。

因此，初始化新项目时必须先回答：

- 我是在做单服务，还是服务套件？
- 公共 initiator/运行单元放本仓库，还是抽到共享依赖？
- 入口名是否真的来自目标职责，而不是沿用参考项目历史名字？
- `<platform-group>/<domain-group>` 这种分层是否能长期稳定表达职责？

如果这些问题还没回答，就不要急着生成目录。

## 交付标准

一次合格的项目初始化至少交付：

- 可解释的项目蓝图
- 与仓库形态匹配的最小可启动入口
- 至少一个可注册运行单元骨架
- 基础配置和启动命令
- live/ready 健康检查
- 基础测试或编译验证
- README 中的本地启动说明
- 源项目名、绝对路径、真实环境信息的残留检查结果
