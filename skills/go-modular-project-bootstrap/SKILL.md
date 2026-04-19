---
name: go-modular-project-bootstrap
description: 用于初始化类似现有 Go 多应用、多模块服务套件的新项目骨架，覆盖仓库结构、应用入口、模块生命周期、配置、路由、健康检查、测试与文档基线；创建通用服务框架项目时使用。
compatibility: Compatible with open_code
metadata:
  version: 1.0.3
  author: "rangh"
  created_at: "2026-04-18T21:37:24+08:00"
---

# Go Modular Project Bootstrap

这个 skill 用于从现有 Go 多应用、多模块服务套件中抽象通用模式，并初始化一个新的同构项目。它不是某个具体业务项目的复制清单，必须避免把源项目名称、绝对路径、环境地址、账号密钥或业务专属命名带入新项目。

## 使用边界

使用本 skill 的场景：

- 创建新的 Go 服务套件仓库
- 搭建多个 `application/{app}` 入口
- 初始化 `internal/modules/kernel` 与 `internal/modules/blocks` 模块层
- 接入统一应用生命周期、插件初始化、模块注册、路由、健康检查和测试基线
- 从已有实现提炼结构，但目标项目需要保持独立命名和独立语义

不使用本 skill 的场景：

- 只是在已有项目内新增一个业务模块，优先使用 `go-multi-module-dev`
- 只修复单个应用启动问题，优先使用对应的应用启动或生命周期 skill
- 只处理 ORM、HTTP、认证、监控等单一框架能力，优先使用对应专项 skill

## 命名规则

- 新项目名称必须由用户或当前任务明确给出；未给出时先使用占位符 `<project>`，不要猜测。
- 应用入口使用通用职责命名，例如 `admin`、`gateway`、`worker`、`installer`、`studio`，不要沿用源项目专属名称。
- Go module path、Docker service、配置文件、日志字段和文档标题必须与目标项目名一致。
- `magicCommon`、`magicEngine`、`magicOrm` 这类基础库和框架依赖可以直接引用，不需要改名。
- 从源实现复制代码前，先列出需要替换的名称映射；复制后用全文搜索确认没有残留源项目名。
- 文档和 skill 中不要写入本机绝对路径，统一使用相对路径或 `<workspace>` 占位符。

## 初始化流程

### 1. 建立源实现认知

先读取目标工作区和参考实现里的最小上下文：

- `go.mod`
- `README.md`
- `AGENTS.md`
- `docs/` 中与启动、模块、路由、部署相关的文档
- `application/*/main.go`
- `internal/modules/**/module.go`
- `internal/modules/**/service/*.go`
- `internal/modules/**/biz/*.go`
- `config`、`config.d`、`deploy`、`scripts` 中与启动相关的文件

目标是确认架构模式，不是批量复制文件。

### 2. 定义项目蓝图

在写代码前明确这些决策：

- Go module path
- 应用入口清单
- kernel 模块清单
- blocks 模块清单
- 对外路由边界
- 认证和 session 边界
- 基于 `magicCommon` 的应用生命周期、事件、后台任务和监控接入点
- 基于 `magicEngine` 的 HTTP 路由、静态资源、SSE 或 TCP 接入点
- 基于 `magicOrm` 的持久化、模型和查询写入接入点
- 配置文件层级
- 本地启动和测试命令

如果用户只要求“基础框架”，默认只生成可启动、可测试、可扩展的最小骨架，不提前实现业务能力。

### 3. 创建目录结构

推荐基础结构：

```text
<project>/
├── application/
│   ├── admin/
│   ├── gateway/
│   └── worker/
├── internal/
│   ├── modules/
│   │   ├── kernel/
│   │   └── blocks/
│   └── pkg/
├── pkg/
├── config/
├── docs/
├── scripts/
├── test/
├── go.mod
└── README.md
```

只创建当前任务需要的入口和模块；不要为了“完整”生成空的大量目录。

### 4. 接入应用生命周期

每个 `application/{app}` 至少要完成：

- 加载配置
- 创建 service 实例
- 注册 initiator
- 注册模块
- 启动 application
- 等待退出信号
- 按顺序 shutdown

生命周期依赖应集中在应用 bootstrap 或 initiator 中，业务模块不要直接控制全局进程退出。

按入口职责区分启动模式：

- 管理类入口只加载管理端需要的 initiator、模块、路由和鉴权边界。
- 网关类入口只加载转发、鉴权、订阅校验、代理和公开服务所需模块，不要混入管理端或门户端私有模块。
- Worker 类入口只加载后台任务、事件消费和必要的持久化依赖，不暴露无关 HTTP 路由。
- Installer / migrator 等动作型入口必须先做路径、配置、目标环境和幂等性预检，再执行一次性动作。
- Studio / devtools 类入口必须把开发辅助能力和生产入口隔离。

启动失败应保留在 `Setup` / `Run` 的错误返回链中，不要用 `panic` 或裸 `log.Fatal` 掩盖具体模块和阶段。

### 5. 接入模块生命周期

每个模块保持一致结构：

```text
{module}/
├── module.go
├── biz/
├── service/
└── pkg/
    ├── common/
    └── models/
```

模块职责：

- `module.go`: 模块 ID、依赖获取、`Setup`、`Run`、`Teardown`
- `biz`: 业务编排、事件、后台任务、持久化调用
- `service`: route、handler、request/response 适配
- `pkg/common`: 常量、错误、过滤器、结果结构
- `pkg/models`: DTO、entity、view model

`Setup` 只做依赖接线，`Run` 做可失败的启动动作和路由注册，`Teardown` 做幂等释放。

### 6. 接入路由和健康检查

基础项目至少保留：

- `GET /health/live`
- `GET /health/ready`
- API 版本前缀策略
- 管理入口和公开入口的路由边界
- 认证中间件接入点
- 未实现路由的明确错误返回

不要让应用入口绕过底层服务契约；handler 只做协议适配，业务语义留在 biz 或更底层能力中。

### 7. 配置与部署基线

至少准备：

- 默认本地配置
- 环境变量覆盖规则
- 每个应用入口的启动参数
- 本地运行脚本
- 容器或进程部署占位说明
- 日志级别和监控开关

配置示例必须使用占位值，不写入真实环境地址和凭据。

### 8. 测试与验证

完成初始化后至少验证：

```bash
gofmt -w ./application ./internal ./pkg
go test ./... -count=1
```

再做一致性检查：

```bash
rg -n "<source-project-name>|/home/|file://|vscode://" .
rg -n "TODO|panic\\(|log.Fatal" application internal pkg
```

如果初始化只完成骨架，允许保留明确的 TODO，但 TODO 必须说明待实现边界，不能掩盖启动失败。

## 配合 Skill

- 新增或扩展单个模块时，使用 `go-multi-module-dev`。
- 新增或管理 `initiator` / `module` 生命周期时，使用 `go-module-initiator-lifecycle`。
- 接线或管理 application、`EventHub`、`BackgroundRoutine`、`Post` / `Send` 和 shutdown 协同时，使用 `go-application-event-runtime`。
- 涉及 `magicCommon` 应用生命周期、插件、事件、后台任务时，选择当前工作区中覆盖 `framework/application`、`framework/service`、`plugin/initiator`、`plugin/module` 的生命周期类 skill。
- 涉及 `magicEngine` HTTP 路由、静态资源、SSE、TCP，或 `magicOrm` ORM、认证、监控等专项能力时，只加载对应专项 skill，不要把所有相关 skill 一次性读入上下文。

配合 skill 的名称和内容也应保持通用表达；如果必须引用已有项目实现，只把它当作参考实现，不把项目名写入新项目产物。

## 交付标准

一次合格的项目初始化至少交付：

- 可解释的项目蓝图
- 最小可启动应用入口
- 至少一个可注册模块骨架
- 基础配置和启动命令
- live/ready 健康检查
- 基础测试或编译验证
- README 中的本地启动说明
- 源项目名、绝对路径、真实环境信息的残留检查结果
