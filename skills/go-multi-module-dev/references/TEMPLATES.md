# Templates

模板表达职责边界。不要为了目录对称生成空 `service`、`events` 或 `models`；但只要 Module/Block 使用 EventHub，`biz` 和 Base Biz 嵌入是强制的。

## 1. 共享 Base Biz

仓库应先提供 `internal/modules/base/biz/base.go`。它是共享 library，不是 Plugin Module：没有 `init`、`Register`、业务 topic 或具体运行单元 import。

```go
type Base struct {
    id                string
    eventHub          event.Hub
    simpleObserver    event.SimpleObserver
    backgroundRoutine task.BackgroundRoutine
}

func New(id string, hub event.Hub, background task.BackgroundRoutine) Base {
    return Base{
        id:                id,
        eventHub:          hub,
        simpleObserver:    event.NewSimpleObserver(id, hub),
        backgroundRoutine: background,
    }
}
```

它可以提供 `ID`、`SubscribeFunc`、`UnsubscribeFunc`、`SendEvent`、`PostEvent` 和 BackgroundRoutine 包装；不得提供业务 topic alias、`any`/map payload helper、跨 owner Service registry 或业务状态。

## 2. Module / Block Biz 骨架

```go
package biz

import (
    "context"

    basebiz "<module-path>/internal/modules/base/biz"
    "<unit-import>/pkg/common"
    "<unit-import>/pkg/events"
    cd "github.com/muidea/magicCommon/def"
    "github.com/muidea/magicCommon/event"
    "github.com/muidea/magicCommon/task"
)

type Unit struct {
    basebiz.Base
    // 仅本 owner 的状态和私有依赖
}

func New(hub event.Hub, background task.BackgroundRoutine) *Unit {
    unit := &Unit{Base: basebiz.New(common.UnitID, hub, background)}
    unit.SubscribeFunc(events.TopicCommand, unit.handleCommand)
    return unit
}

func (s *Unit) Run(context.Context) *cd.Error { return nil }

func (s *Unit) Teardown(context.Context) {
    s.UnsubscribeFunc(events.TopicCommand)
}
```

`module.go` 不嵌入 Base，不保存 Hub/observer，也不实现 handler；它只构造 Biz、Service 和调用 Biz 生命周期。

## 3. Module / Block 入口骨架

```go
func init() { module.Register(New()) }

type Unit struct {
    bizPtr     *biz.Unit
    servicePtr *service.Unit // 没有入站 adapter 时删除
}

func New() *Unit { return &Unit{} }
func (s *Unit) ID() string { return common.UnitID }

func (s *Unit) Setup(_ context.Context, hub event.Hub, background task.BackgroundRoutine) *cd.Error {
    s.bizPtr = biz.New(hub, background)
    s.servicePtr = service.New(s.bizPtr) // 可选
    return nil
}

func (s *Unit) Run(ctx context.Context) *cd.Error {
    if s.bizPtr == nil {
        return cd.NewError(cd.IllegalParam, "unit biz is not configured")
    }
    if err := s.bizPtr.Run(ctx); err != nil {
        return err
    }
    if s.servicePtr != nil {
        s.servicePtr.RegisterRoutes()
    }
    return nil
}

func (s *Unit) Teardown(ctx context.Context) {
    if s.bizPtr != nil {
        s.bizPtr.Teardown(ctx)
    }
    s.bizPtr = nil
    s.servicePtr = nil
}
```

## 4. Service 骨架

```go
type Unit struct {
    bizPtr *biz.Unit
}

func New(bizPtr *biz.Unit) *Unit { return &Unit{bizPtr: bizPtr} }
func (s *Unit) RegisterRoutes() {}
```

Service 不能接收 `event.Hub`，不能订阅 topic，不能直接调用其它 owner 的 repository/service。需要跨 owner 操作时，调用本单元 Biz 的窄用例；Biz 再经 typed EventHub 合同协作。

## 5. Initiator 骨架

```go
func init() { initiator.Register(New()) }

type Capability struct {
    // 完成这一项基础设施能力的进程级句柄
}

func (s *Capability) Setup(context.Context, event.Hub, task.BackgroundRoutine) *cd.Error { return nil }
func (s *Capability) Run(context.Context) *cd.Error { return nil }
func (s *Capability) Teardown(context.Context) {}
```

Initiator 不嵌入 `basebiz.Base`，不定义业务 observer；`pkg/common` 仅导出它的 ID 和窄 helper interface，例如 `GetRouteRegistry()`。

## 6. RouteRegistry Initiator helper

```go
package common

import engine "github.com/muidea/magicEngine/http"

const RouteRegistryInitiator = "/internal/initiators/routeregistry"

type RouteRegistryHelper interface {
    GetRouteRegistry() engine.RouteRegistry
}
```

Module Setup 获取 helper 后，将 Registry 传给 Service；不要在 helper 中暴露 `http.Server`、listener 或业务 handler。listener 的启用要晚于所有路由注册。

## 7. EventHub-backed port

```go
type UnitPort interface {
    Execute(context.Context, events.ExecuteCommand) error
}

type unitClient struct {
    hub    event.Hub
    source string
}
```

Port client 只保存 Hub/source 和 typed command mapping，不保存 owner service、store 或 repository。它不是替代具体 Biz 的通用 Hub facade。

## 8. Generator

使用 `scripts/create-module.sh <unit_name> <group_path> [unit_root] [entry_file] [--with-service]` 创建 Module/Block 最小骨架。

脚本默认生成 `module.go`、`biz/biz.go` 与 `pkg/common/const.go`；生成的 Biz 已内嵌 `internal/modules/base/biz.Base`。仅传入 `--with-service` 时生成 `service/`。它不生成业务 `pkg/events`、DTO 或 Initiator，必须由实际 owner 和任务边界决定。
