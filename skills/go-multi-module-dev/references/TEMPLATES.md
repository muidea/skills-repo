# Templates

## 1. 模块入口骨架

```go
func init() {
    module.Register(New())
}

type Module struct {
    bizPtr *biz.Module
    servicePtr *service.Module
}

func New() *Module { return &Module{} }

func (s *Module) ID() string { return common.ModuleID }

func (s *Module) Setup(eventHub event.Hub, background task.BackgroundRoutine) (err *cd.Error) {
    s.bizPtr = biz.New(eventHub, background)
    s.servicePtr = service.New(s.bizPtr)
    return nil
}

func (s *Module) Run() (err *cd.Error) {
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
type Module struct {
    eventHub event.Hub
    background task.BackgroundRoutine
}

func New(eventHub event.Hub, background task.BackgroundRoutine) *Module {
    return &Module{eventHub: eventHub, background: background}
}

func (s *Module) Initialize() (err *cd.Error) {
    return nil
}
```

## 3. service 骨架

```go
type Module struct {
    bizPtr *biz.Module
}

func New(bizPtr *biz.Module) *Module {
    return &Module{bizPtr: bizPtr}
}

func (s *Module) RegisterRoute() {
}
```

## 4. create-module.sh

用 `scripts/create-module.sh <module_name> [kernel|blocks]` 创建最小骨架。

脚本会自动：

- 读取当前仓库 `go.mod` 的 module path
- 生成 `module.go`
- 生成 `biz/biz.go`
- 生成 `service/service.go`
- 生成 `pkg/common/const.go`

生成后仍需要你按实际仓库补：

- route 注册
- session / auth
- ORM 模型与 helper
- 测试
- 文档
