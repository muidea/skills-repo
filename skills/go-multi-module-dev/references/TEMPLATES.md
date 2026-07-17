# Templates

以下模板表达职责边界，不要求所有单元同时生成所有目录。

## 1. 运行单元入口骨架

```go
func init() {
    module.Register(New())
}

type Unit struct {
    bizPtr     *biz.Unit
    servicePtr *service.Unit
}

func New() *Unit { return &Unit{} }

func (s *Unit) ID() string { return common.UnitID }

func (s *Unit) Setup(_ context.Context, eventHub event.Hub, background task.BackgroundRoutine) (err *cd.Error) {
    s.bizPtr = biz.New(eventHub, background)
    s.servicePtr = service.New(s.bizPtr)
    return nil
}

func (s *Unit) Run(_ context.Context) (err *cd.Error) {
    err = s.bizPtr.Initialize()
    if err != nil {
        return
    }
    s.servicePtr.RegisterRoute()
    return
}

func (s *Unit) Teardown(context.Context) {}
```

## 2. biz 骨架

```go
type Unit struct {
    eventHub   event.Hub
    background task.BackgroundRoutine
}

func New(eventHub event.Hub, background task.BackgroundRoutine) *Unit {
    return &Unit{eventHub: eventHub, background: background}
}

func (s *Unit) Initialize() (err *cd.Error) {
    return nil
}
```

## 3. service 骨架

```go
type Unit struct {
    bizPtr *biz.Unit
}

func New(bizPtr *biz.Unit) *Unit {
    return &Unit{bizPtr: bizPtr}
}

func (s *Unit) RegisterRoute() {
}
```

## 4. RouteRegistry Initiator helper

```go
package common

import engine "github.com/muidea/magicEngine/http"

const RouteRegistryInitiator = "/internal/initiators/routeregistry"

type RouteRegistryHelper interface {
    GetRouteRegistry() engine.RouteRegistry
}
```

Module Setup 获取 helper：

```go
var helper common.RouteRegistryHelper
helper, err = initiator.GetEntity(common.RouteRegistryInitiator, helper)
if err != nil || helper.GetRouteRegistry() == nil {
    return cd.NewError(cd.Unexpected, "route registry unavailable")
}
servicePtr.BindRegistry(helper.GetRouteRegistry())
```

不要在 helper 中暴露 `http.Server`、listener 或业务 handler。

## 5. EventHub-backed port

```go
type UsagePort interface {
    Start(context.Context, events.StartCommand) error
}

type usageClient struct {
    hub    event.Hub
    source string
}

func (c usageClient) Start(ctx context.Context, command events.StartCommand) error {
    ev := event.NewEventWithContext(events.TopicStart, c.source, events.OwnerID, event.NewHeader(), ctx, command)
    result := c.hub.Send(ev)
    if result == nil || result.Error() != nil {
        return errors.New("usage start failed")
    }
    return nil
}
```

port client 只保存 hub/source，不保存 owner service、store 或 repository。

## 6. Post handler

```go
func (s *Biz) handleObserved(ev event.Event, _ event.Result) {
    data, ok := ev.Data().(events.ObservedData)
    if !ok {
        return
    }
    s.observe(data)
}
```

为该 handler 增加 `result=nil` 的直接测试。

## 7. create-module.sh

用 `scripts/create-module.sh <unit_name> [group_path] [unit_root] [entry_file]` 创建最小骨架。

脚本会自动：

- 读取当前仓库 `go.mod` 的 module path
- 在目标 `<unit-root>/<group-path>/<unit_name>/` 下生成骨架
- 生成 `<unit-entry-file>`
- 生成 `biz/biz.go`
- 生成 `service/service.go`
- 生成 `pkg/common/const.go`

生成后仍需要你按实际仓库补：

- route 注册
- session / auth
- ORM 模型与 helper
- 测试
- 文档
