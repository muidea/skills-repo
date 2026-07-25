# Runtime Unit Structure

## 1. 默认目录与共享 Biz 基座

目标仓库没有既定约定时，使用下面的默认形态；已有仓库优先沿用已存在的分组名和入口文件名。

```text
project-root/
├── <entry-root>/<entry-name>/
├── internal/
│   ├── initiators/<capability>/
│   │   ├── initiator.go
│   │   ├── pkg/common/
│   │   └── internal/                 # 可选：该 Initiator 私有实现
│   └── modules/
│       ├── base/biz/
│       │   └── base.go                # 共享业务基座，不是运行单元
│       ├── blocks/<unit>/
│       │   ├── module.go
│       │   ├── biz/
│       │   ├── service/               # 可选
│       │   ├── pkg/{common,events,models}/ # 按需创建
│       │   └── internal/              # 可选
│       └── {kernel,application}/<unit>/
│           └── ...                    # 与 Block 相同的单元结构
├── internal/pkg/
├── pkg/
└── docs/
```

`internal/modules/base/biz` 是 Module/Block 的共享业务基座：它只封装 owner ID、`event.Hub`、`event.SimpleObserver` 与 `task.BackgroundRoutine` 的 owner-neutral 操作。它没有 `init`、不注册 framework plugin、不声明业务 topic，也不能 import 具体运行单元、HTTP 或业务配置。

创建或迁移该目录时，`base.go` 的完整代码、Teardown 责任和测试清单以 [BASE_BIZ.md](BASE_BIZ.md) 为准；不要从结构示例中推导或删减 Base API。

## 2. Initiator / Block / Module 决策

| 类型 | 根目录 | 核心职责 | EventHub Base Biz |
| --- | --- | --- | --- |
| Initiator | `internal/initiators/<capability>` | 一种进程级基础设施能力 | 不使用；不得嵌入 Base |
| Block | `internal/modules/blocks/<unit>` | 单一资源聚合或单一技术能力 owner | 使用 Hub 时必须在 `biz` 内嵌 Base |
| Module | `internal/modules/{kernel,application}/<unit>` | 组合多个独立组件合同的业务闭环 | 使用 Hub 时必须在 `biz` 内嵌 Base |

Initiator 可以持有完成一项基础设施能力所需的 router、listener、client factory 或 scheduler 句柄，但不能持有业务状态、业务策略或多能力容器。若一个“Initiator”需要订阅业务 command、维护业务状态或编排 owner，应将业务部分拆为 Block/Module。

Block 可以拥有自己的正式状态、runtime、repository、后台任务和命令合同；但不编排多个 owner 完成业务闭环。Module 可以拥有协调状态和用例编排，但只能经 EventHub 与其它 owner 协作。

## 3. Module / Block 单元形态

```text
<unit>/
├── module.go
├── biz/
│   ├── biz.go
│   └── handlers.go                 # 按需拆分
├── service/                        # 仅在有入站协议适配时创建
├── pkg/
│   ├── common/                     # ID、窄常量、错误、filter
│   ├── events/                     # 本 owner 的 typed topic/Command/Data/Result
│   └── models/                     # 稳定 DTO/读模型；不放私有可变状态
└── internal/                       # 私有 repository adapter、实体、helper
```

只要单元使用 `event.Hub`，`biz/` 就是必需目录，并遵守：

```go
type Biz struct {
    basebiz.Base
    // 仅本 owner 的状态和依赖
}

func New(hub event.Hub, background task.BackgroundRoutine) *Biz {
    b := &Biz{Base: basebiz.New(common.UnitID, hub, background)}
    b.SubscribeFunc(events.TopicCommand, b.handleCommand)
    return b
}
```

这里的“派生”是 Go 的组合/嵌入，而非把 Base 复制到每个单元。具体 Biz 负责其 topic 的订阅与解除订阅、typed handler、状态和资源清理；Base 不知道任何业务 topic。

## 4. 层级依赖

```text
module.go ──constructs──> biz.Biz(Base) ──uses──> EventHub / BackgroundRoutine
       │                         │
       └──constructs──> service ─┘
```

- `module.go`：注册、获取 Initiator helper、构造 Biz/Service、生命周期桥接；`Setup` 仅把 Hub 和 BackgroundRoutine 传给 `biz.New`。
- `biz/`：业务用例、owner 状态、EventHub `Send/Post/Subscribe`、handler、后台任务、持久化决策。
- `service/`：route、请求响应和协议适配；只依赖本单元 Biz 或稳定 port，不接收 `event.Hub`。
- `pkg/events/`：由维护资源或状态的能力 owner 定义具体 topic、Command、Data、Result；调用方导入并使用该合同，不得复制同一能力的 topic、DTO 或 handler。禁止 `any`、map、JSON 或通用 envelope。
- `internal/`：只能被本单元使用的实现细节。

禁止在 `module.go`、`service/` 或其它 adapter 中保存 `event.Hub`、创建 `event.SimpleObserver`、订阅 topic 或直接调用 `Send/Post`。如果该逻辑存在，应下沉到自身 Biz。

## 5. 何时创建可选目录

- 没有入站协议 adapter，不创建 `service/`。
- 没有跨 owner 的事件合同，不创建 `pkg/events/`；一旦有合同，必须由该 owner 定义。
- 私有 entity、repository adapter、mapper 不应放入 `pkg/models`；放入 `internal/` 或 Biz 私有文件。
- 纯 DTO、view model、filter 可以留在 `pkg/models` / `pkg/common`，但不能借此暴露 owner 的可变资源。
- 单消费者、无独立 lifecycle 的索引或算法通常是 focused package，不是 Block。

## 6. 验收

- 使用 Hub 的每个 Module/Block 都有 `biz/`，且业务类型内嵌 `internal/modules/base/biz.Base`。
- 除 Base Biz 与单元 `biz/` 外，`internal/modules` 下没有 `event.Hub` field、`event.NewSimpleObserver` 或订阅调用；`module.go` 的 framework `Setup` 参数是唯一允许的 Hub 接线点。
- Initiator 没有嵌入 Base Biz，也没有业务 topic/业务 observer。
- `module.go` 不含业务 handler、状态机或跨 owner 用例；`service/` 不直接访问其它 owner 的 service/repository。
- `Teardown` 委托 Biz 解除其订阅并关闭自身资源，且可重复调用。
