# magicCommon Framework Integration

## 1. 运行单元定义

| 类型 | 核心判断 | 可以持有 | 不应持有 |
| --- | --- | --- | --- |
| Initiator | 一种进程级基础设施能力 | 实现该能力所需的 RouteRegistry、listener、client factory、scheduler 句柄 | 业务状态、业务策略、多种基础设施的综合容器 |
| Block | 单一资源聚合或单一技术能力 | 自己的正式状态、runtime、repository、后台任务 | 其它组件的 service/repository，以及跨 owner 业务流程 |
| Module | 组合多个独立组件合同形成业务闭环 | 自己的协调状态、用例编排、HTTP/CLI facade | 其它 owner 的 repository 或可变资源对象 |

Initiator 的“无状态”指无业务状态，不要求结构体零字段。RouteRegistry Initiator 可以持有 router、server、listener 和 done channel，但只能围绕 HTTP 路由基础设施这一项能力。

所有使用 EventHub 的 Block/Module 必须把业务事件逻辑放入其 `biz`，并让 Biz 内嵌 `internal/modules/base/biz.Base`。Base 是共享业务基座，只封装 ID、observer、Hub 和 BackgroundRoutine；具体 Biz 仍负责自己的 topic、typed handler、状态和资源。Initiator 不得嵌入 Base。

## 2. 生命周期落点

- `Setup`：获取 Initiator helper，创建本单元资源，建立下游 Setup 阶段必需的 command subscription，并 fail-fast 校验依赖。
- `Run`：启动 route、listener、BackgroundRoutine、定时任务或对外服务。
- `Teardown`：先停止新请求和事件订阅，再取消后台任务，最后关闭 store、listener、文件和 client；必须幂等。

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

- Post handler 的 `event.Result` 可能为 nil，禁止调用 `Set`。
- 强一致写入、鉴权裁决、配置激活和需要错误反馈的操作必须使用 Send。
- metrics、刷新提示等允许丢失且可重建的通知才适合 Post。
- payload/result 使用具体类型，不用 `any`、map、JSON 或 reflect 分发。
- 不传 `io.Writer`、ResponseWriter、channel、数据库连接、repository、Registry、Store、Recorder 等运行期对象。

EventHub-backed port 可用于隐藏重复 Send/Post 代码，但它只能保存 EventHub 与 source，并把每个方法映射为明确事件；不能持有 owner 实现。测试 direct adapter 必须与生产装配分离。

## 5. Owner 与组件必要性

建立独立 Block 前至少满足一项：

- 有独立资源生命周期，如 DuckDB、registry/SLO、listener 或持久化 store。
- 是正式状态 owner，需要独立命令合同和一致性边界。
- 有多个独立消费者，且不能合理归属于某个 Module。
- 有必须独立启停、恢复、巡检或限流的后台能力。

如果只是单个 Module 使用的内存索引、纯算法、映射器或归档 helper，优先放回该 Module 或 focused package。不要用“未来可能复用”作为创建 Block 的唯一理由。

独立 Block 不能通过 Acquire 命令返回内部指针来伪造 EventHub 边界。返回原始 `*Registry`、`*Store`、`*Recorder` 后，后续调用已绕过 owner。

## 6. 业务分层

- `module.go`：注册、依赖获取和 lifecycle bridge。
- `biz/`：用例、事件 handler、跨组件编排、状态转换和持久化决策；一旦使用 Hub，Biz 必须内嵌 Base Biz。
- `service/`：route、HTTP/CLI 输入输出、协议适配。
- `pkg/events/`：本 owner 的 topic、Command、Data、Result。
- `pkg/models/`：稳定 DTO/entity/view model。

HTTP handler 不负责“写文件 -> 更新配置 owner -> 更新代理 -> 更新鉴权”这类流程。它应调用 Module biz 用例；Module 再通过 EventHub 驱动各 owner。单一 Block 也不应越权编排多个 owner。

`module.go` 只在 framework `Setup` 取得 Hub 并传给 `biz.New`，自身不保存 Hub/observer、不订阅 topic、不直接 `Send/Post`。`service/` 也不接收 Hub；需要跨 owner 操作时调用本 owner Biz，再由 Biz 经 typed contract 协作。

## 7. BackgroundRoutine

长期 goroutine、ticker、SLO 巡检、恢复任务应交给 framework `task.BackgroundRoutine`。自行启动 goroutine 时至少确认它属于单次请求、有 request context 取消、不会越过 Teardown 存活。

## 8. 验收

- 入口显式 side-effect import 所需 Initiator、Block、Module。
- 搜索使用 Hub 的 Module/Block：每个都有 `biz/`，Biz 内嵌 Base；Module root、service 和其它 adapter 没有 Hub field、SimpleObserver 或订阅。
- 搜索 `internal/modules/base/biz`：没有 `init`、plugin register、业务 topic、业务 contract 或具体单元 import；Initiator 没有嵌入 Base。
- 搜索跨组件 raw pointer、service/repository import 和 AcquireX 返回实现对象。
- 搜索 `Payload any`、`map[string]any`、`io.Writer` 等 EventHub 合同。
- 搜索 Post handler 中的 `result.Set`。
- 搜索依赖 `Weight()` 或 `/**` 的路由顺序。
- 对 Post nil Result、缺失同步 Result、错误类型、Teardown 幂等和启动路由可用性补直接测试。
- 运行 `gofmt`、`go vet ./...`、`go test ./... -count=1` 和目标平台 build。
