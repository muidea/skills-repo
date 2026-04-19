---
name: go-module-initiator-lifecycle
description: 用于在基于 magicCommon framework/plugin 的 Go 服务中创建、接线和管理 initiator 与 module，覆盖 ID/Weight、Setup/Run/Teardown、依赖获取、启动顺序、listener/后台任务生命周期和验证；新增或调整插件生命周期时使用。
compatibility: Compatible with open_code
metadata:
  version: "1.0.0"
  author: "rangh"
  created_at: "2026-04-18T21:51:51+08:00"
---

# Go Module Initiator Lifecycle

这个 skill 是创建和管理 `initiator` / `module` 的通用入口。它面向基于 `magicCommon/framework/plugin` 与 `framework/service` 的 Go 服务，不绑定具体业务项目名。

## 使用边界

使用本 skill：

- 新增 `initiator`
- 新增 `module`
- 调整插件 `ID`、`Weight`、`Setup`、`Run`、`Teardown`
- 处理 module 依赖 initiator 的获取和类型断言
- 调整启动顺序、依赖注册、listener 启停、后台任务注册
- 排查插件重复 ID、类型不匹配、启动失败、关闭不彻底

不使用本 skill：

- 只创建业务模块目录和 `biz/service/pkg` 骨架，优先使用 `go-multi-module-dev`
- 只创建完整新项目，优先使用 `go-modular-project-bootstrap`
- 只排查 `magicCommon` 底层插件管理器实现，使用 `magiccommon-plugin-module`
- 只处理 HTTP、ORM、session、monitoring 的专项业务语义，使用对应专项 skill

## 必读实现

先核对当前仓库是否 vendored 或直接依赖 `magicCommon`，再读取对应版本：

- `framework/service/service.go`
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
- 重复 `ID` 会注册失败；同一类型的插件按权重升序执行，`Teardown` 反向执行。

## Initiator 规则

`initiator` 用于提供应用级基础能力和跨 module 依赖，例如 persistence、route registry、monitoring、pprof、cron、timer 或配置驱动 runtime 能力。

- 在 `init()` 中调用 `initiator.Register(New())`。
- `ID()` 返回稳定常量，常量放在该 initiator 的 `pkg/common` 或等价公共包。
- `Setup(eventHub, backgroundRoutine)` 只做依赖接线、配置解析、资源构造和预绑定。
- listener 型 initiator 必须在 `Setup` 完成 bind/listen，在 `Run` 启动 serve，在 `Teardown` 关闭 listener/server。
- 后台任务型 initiator 在 `Setup` 保存 `eventHub` / `backgroundRoutine`，在 `Run` 注册 timer/cron/task。
- 对外暴露能力时提供窄接口，例如 `GetRouteRegistry()`、`GetBaseClient()`，不要暴露整个实现对象。
- 常规失败返回 `*cd.Error`，不要用 `panic` 或裸 `log.Fatal`。

## Module 规则

`module` 用于承载业务能力和路由注册。推荐结构：

```text
internal/modules/{kernel|blocks}/{module}/
├── module.go
├── biz/
├── service/
└── pkg/
    ├── common/
    └── models/
```

- 在 `init()` 中调用 `module.Register(New())`。
- `ID()` 返回稳定模块常量。
- 需要调整模块顺序时实现 `Weight() int`，不要依赖 import 顺序。
- `Setup` 通过 `initiator.GetEntity` 获取基础能力，完成 `biz`、`service` 构造和依赖绑定。
- `Run` 先启动 biz，再注册 route 或启动对外服务。
- `Teardown` 做幂等释放；如果当前模块没有资源，也显式确认不需要清理。
- `biz` 处理业务、事件、后台任务和持久化编排；`service` 只做协议、路由、请求响应适配。

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

- 基础资源类 initiator 先于业务 module 准备。
- module 不应在 `init()` 中读取配置、连接数据库或注册路由。
- module 间依赖优先通过明确接口、事件或公共 client 表达，不要隐式依赖启动顺序。
- `Weight` 只解决同类插件内顺序，不应用来隐藏架构依赖。
- HTTP 暴露必须晚于必要依赖 ready；缺少核心依赖时不要启动半可用服务。
- ready 状态应由 service 生命周期统一标记，不要由单个 module 私自标记全局 ready。

## 常见模式

- listener 型 initiator：`Setup` 解析配置、构造 runtime、完成预绑定；`Run` 非阻塞启动 serve；`Teardown` 带超时 shutdown。
- background 型 initiator：`Setup` 保存 `eventHub` 与 `backgroundRoutine`；`Run` 注册 timer、cron 或常驻任务。
- route module：`Setup` 获取 route registry helper，构造 biz/service，绑定 registry；`Run` 先 `biz.Run()` 再 `service.RegisterRoute()`。
- event module：`Setup` 保存 event hub、注册 handler 所需依赖；`Run` 订阅事件或启动消费逻辑；`Teardown` 取消订阅或释放 worker。

## 验证

优先跑受影响范围：

```bash
GOCACHE=/tmp/go-module-initiator-gocache go test ./framework/plugin/... ./framework/service -count=1
```

业务仓库中新增或调整 plugin 时：

```bash
GOCACHE=/tmp/go-module-initiator-gocache go test ./internal/initiators/... ./internal/modules/... -count=1
```

如果仓库没有 `internal/initiators`，改跑实际 initiator 目录，例如：

```bash
GOCACHE=/tmp/go-module-initiator-gocache go test ./initiators/... ./internal/modules/... -count=1
```

交付前检查：

- 新插件 ID 唯一
- `Setup` / `Run` / `Teardown` 职责清晰
- listener 有关闭路径
- 后台任务挂在 `BackgroundRoutine`
- route 注册不早于依赖 ready
- 没有在 `init()` 中做重副作用
- 测试和文档覆盖新增生命周期行为
