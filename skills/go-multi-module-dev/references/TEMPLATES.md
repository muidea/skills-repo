# Templates

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

func (s *Unit) Setup(eventHub event.Hub, background task.BackgroundRoutine) (err *cd.Error) {
    s.bizPtr = biz.New(eventHub, background)
    s.servicePtr = service.New(s.bizPtr)
    return nil
}

func (s *Unit) Run() (err *cd.Error) {
    err = s.bizPtr.Initialize()
    if err != nil {
        return
    }
    s.servicePtr.RegisterRoute()
    return
}
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

## 4. create-module.sh

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
