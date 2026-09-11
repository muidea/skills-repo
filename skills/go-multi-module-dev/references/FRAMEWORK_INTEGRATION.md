# magicCommon Framework Integration

## 1. 运行单元定义

| 类型 | 核心判断 | 可以持有 | 不应持有 |
| --- | --- | --- | --- |
| Initiator | 一种进程级基础设施能力 | 实现该能力所需的 RouteRegistry、listener、client factory、scheduler 句柄 | 业务状态、业务策略、多种基础设施的综合容器 |
| Block | 单一资源聚合或单一技术能力 | 自己的正式状态、runtime、repository、后台任务 | 其它组件的 service/repository，以及跨 owner 业务流程 |
| Module | 组合多个独立组件合同形成业务闭环 | 自己的协调状态、用例编排、入站 facade | 其它 owner 的 repository 或可变资源对象 |

Initiator 的“无状态”指无业务状态，不要求结构体零字段。RouteRegistry Initiator 可以持有 router、server、listener 和 done channel，但只能围绕 HTTP 路由基础设施这一项能力。

所有使用 EventHub 的 Block/Module 必须把业务事件逻辑放入其 `biz`，并让 Biz 内嵌 `internal/modules/base/biz.Base`。Base 是共享业务基座，只封装 ID、observer、Hub 和 BackgroundRoutine；具体 Biz 仍负责自己的 topic、typed handler、状态和资源。Initiator 不得嵌入 Base。

## 2. 生命周期落点

- `Setup`：获取 Initiator helper，创建本单元资源，建立下游 Setup 阶段必需的 command subscription，并 fail-fast 校验依赖。
- `Run`：启动 route、listener、BackgroundRoutine、定时任务或对外服务。
- `BeginShutdown`：关闭新输入、请求取消，不释放在途操作依赖，也不阻塞等待。
- `Quiesce`：返回真实排空回执；失败保留依赖供重试。
- `Teardown`：全进程屏障和共享任务/事件排空成功后，取消订阅并关闭资源；按逆序遇错即停，重试跳过已完成阶段。

`application.Execute` 统一执行 Startup/Run 和检查式停机重试，每次停机预算独立于已取消的运行 context。Startup 失败已进入的插件（包括部分失败项）也参加统一清理；不能在局部 Setup/Run 错误分支提前销毁资源。直接调用 DefaultService/PluginMgr 的 owner 要自行完成屏障及检查式清理。

Application 的 `ShutdownChecked` 失败保持 stopping，不允许重新 Run/Startup；成功后保留已关闭 runtime，下一次 Startup 才建立新一代自有 runtime。重新使用 Application 自有的外部注入 runtime 时必须提供新实例。

如果 Initiator.Run 会在 Module.Run 注册 route 前启动 listener，需要调整其中一侧：在 Setup 完成路由声明，或把 listener activation 延后。不能接受启动瞬间的随机 404。

## 3. RouteRegistry 模式

推荐结构：

```text
internal/initiators/routeregistry/
  routeregistry.go
  pkg/common/common.go

internal/modules/application/<app>/
  module.go
  service/.../routes.go
```

`pkg/common` 只暴露窄 helper：

```go
type RouteRegistryHelper interface {
    GetRouteRegistry() engine.RouteRegistry
}
```

Module 在 Setup 使用 `initiator.GetEntity` 获取 helper，service 负责声明 routes。业务 Module 不得取得 `http.Server`、listener 或底层 handler。

magicEngine 使用 first-match 时：

- 优先注册明确的 method/path 白名单。
- 不用 `Weight()` 保证某个 `/**` 晚注册。
- 若确实需要 fallback，由一个明确的路由 owner 集中注册并测试顺序。

## 4. EventHub 合同

同步交互：

```text
caller -> Hub.Send(command) -> owner handler -> Result.Set(typed result, err)
```

异步通知：

```text
publisher -> Hub.Post(data) -> owner handler
```

关键约束：

- Subscribe/Unsubscribe 必须检查 `*def.Error`，必需订阅失败中止启动；具体回执和重入语义见 [EVENT_USAGE.md](EVENT_USAGE.md)。
- Post handler 的 `event.Result` 可能为 nil，禁止调用 `Set`。
- 强一致写入、鉴权裁决、配置激活和需要错误反馈的操作必须使用 Send。
- 允许丢失且可重建的观测或刷新通知才适合 Post。
- payload/result 使用具体类型，不用 `any`、map、JSON 或 reflect 分发。
- 不传 `io.Writer`、ResponseWriter、channel、数据库连接、repository、Registry、Store、Recorder 等运行期对象。

EventHub-backed port 可用于隐藏重复 Send/Post 代码，但它只能保存 EventHub 与 source，并把每个方法映射为明确事件；不能持有 owner 实现。测试 direct adapter 必须与生产装配分离。

## 5. Owner 与组件必要性

建立独立 Block 前至少满足一项：

- 有独立资源生命周期，如持久化 store、registry、listener 或外部 client。
- 是正式状态 owner，需要独立命令合同和一致性边界。
- 有多个独立消费者，且不能合理归属于某个 Module。
- 有必须独立启停、恢复、巡检或限流的后台能力。

如果只是单个 Module 使用的内存索引、纯算法、映射器或归档 helper，优先放回该 Module 或 focused package。不要用“未来可能复用”作为创建 Block 的唯一理由。

独立 Block 不能通过 Acquire 命令返回内部指针来伪造 EventHub 边界。返回原始 `*Registry`、`*Store`、`*Recorder` 后，后续调用已绕过 owner。

## 6. 业务分层

- `module.go`：注册、依赖获取和 lifecycle bridge。
- `biz/`：用例、事件 handler、跨组件编排、状态转换和持久化决策；一旦使用 Hub，Biz 必须内嵌 Base Biz。
- `service/`：route、请求响应和协议适配。
- `pkg/events/`：本 owner 的 topic、Command、Data、Result。
- `pkg/models/`：稳定 DTO/entity/view model。

入站 handler 不负责跨多个 owner 的完整业务流程。它应调用 Module biz 用例；Module 再通过 EventHub 驱动各 owner。单一 Block 也不应越权编排多个 owner。

`module.go` 只在 framework `Setup` 取得 Hub 并传给 `biz.New`，自身不保存 Hub/observer、不订阅 topic、不直接 `Send/Post`。`service/` 也不接收 Hub；需要跨 owner 操作时调用本 owner Biz，再由 Biz 经 typed contract 协作。

## 7. BackgroundRoutine

长期 goroutine、ticker、周期巡检和恢复任务应交给 framework `task.BackgroundRoutine`。自行启动 goroutine 时至少确认它属于单次请求、有 request context 取消、不会越过 Teardown 存活。

- SyncTask/SyncFunction 返回提交失败、panic（Unexpected）或真实完成结果，包装层不能吞掉错误。
- SyncTaskWithTimeOut 的预算只覆盖入队成功后的完成等待，`-1` 无限等待，其他负值拒绝；Timeout 不取消已接受任务，不等于完成。
- AsyncTaskContext 约束入队等待，已接受任务自行处理取消与清理。
- Timer 成功只证明注册成功；关闭应取消其 context，BackgroundRoutine.Shutdown 同时跟踪 timer 退出与实际任务排空。返回 false 时不得释放任务依赖。

## 8. 验收

- 入口显式 side-effect import 所需 Initiator、Block、Module。
- 搜索使用 Hub 的 Module/Block：每个都有 `biz/`，Biz 内嵌 Base；Module root、service 和其它 adapter 没有 Hub field、SimpleObserver 或订阅。
- 搜索 `internal/modules/base/biz`：没有 `init`、plugin register、业务 topic、业务 contract 或具体单元 import；Initiator 没有嵌入 Base。
- 搜索跨组件 raw pointer、service/repository import 和 AcquireX 返回实现对象。
- 搜索 `Payload any`、`map[string]any`、`io.Writer` 等 EventHub 合同。
- 搜索 Post handler 中的 `result.Set`。
- 搜索依赖 `Weight()` 或 `/**` 的路由顺序。
- 对 Post nil Result、缺失同步 Result、错误类型、Teardown 幂等和启动路由可用性补直接测试。
- 对 Setup 必需订阅失败、部分 Setup 清理、任务 panic/超时、取消不等于完成、排空失败保留依赖、关闭重试和重启资源代际补直接测试。
- 运行 `gofmt`、`go vet ./...`、`go test ./... -count=1` 和目标平台 build。
