# Custom Framework Service

## 1. 先判断是否真的需要定制

`framework/application` 持有进程级 `event.Hub`、`task.BackgroundRoutine`、配置管理器和一个 `framework/service.Service`。优先按下面顺序选择：

1. 标准 Initiator/Module 生命周期已经满足要求：直接使用 `service.DefaultService()`。
2. 标准生命周期顺序不变，只需增加启动前检查、启动后激活、前台等待或额外关闭动作：包装并委托 `DefaultService()`。
3. 需要改变 Initiator/Module 的调用顺序、选择性运行插件、插入自定义依赖检查，或直接使用注入的 Hub/BackgroundRoutine：实现完整 `service.Service`。
4. 进程完全不使用 framework plugin，只需要一个普通前台生命周期：实现 `service.LifecycleService` 并使用 `service.AdaptLifecycle`。

不要因为入口参数多、文件较长或存在协议适配器就定制 Service。定制的判据是进程级生命周期语义与 DefaultService 不一致。

## 2. framework Service 合同

当前 `service.Service` 合同为：

```go
type Service interface {
    Startup(
        ctx context.Context,
        serviceName string,
        eventHub event.Hub,
        background task.BackgroundRoutine,
    ) *cd.Error
    Run(ctx context.Context) *cd.Error
    Shutdown(ctx context.Context)
}
```

`application.Startup` 创建或注入进程级 runtime 后调用 `Service.Startup`；`application.Run` 调用 `Service.Run`；`application.Shutdown` 先调用 `Service.Shutdown`，再按 ownership 释放 Application 持有的 runtime。

定制 Service 应落到：

```text
internal/services/<entry-name>/
├── service.go       # Service 合同实现和阶段状态
├── runtime.go       # 可选：进程级资源与等待逻辑
├── options.go       # 可选：构造参数
└── *_test.go
```

它不是 plugin module，不调用 `module.Register`，也不通过 `init` 注册。可执行入口显式构造它并传给 `application.Startup`。

## 3. DefaultService 的标准顺序

定制前先明确 DefaultService 已提供的行为：

```text
Startup:
  initiator.Setup
  configured dependency check
  module.Setup

Run:
  initiator.Run
  module.Run
  mark service ready

Shutdown:
  module.Teardown
  initiator.Teardown
```

Setup 或 Run 失败时，DefaultService 会按已进入的阶段执行清理。若定制 Service 复制这条链，必须保留等价的失败回滚和健康状态语义，或者明确记录为何不需要这些能力。

## 4. 包装 DefaultService

标准插件顺序不变时，使用包装式定制，避免复制 framework 内部逻辑：

```go
type ProcessService struct {
    base service.Service

    mu      sync.Mutex
    started bool
    runtime *Runtime
}

func New(runtime *Runtime) *ProcessService {
    return &ProcessService{
        base:    service.DefaultService(),
        runtime: runtime,
    }
}

func (s *ProcessService) Startup(
    ctx context.Context,
    serviceName string,
    hub event.Hub,
    background task.BackgroundRoutine,
) *cd.Error {
    if s.runtime == nil {
        return cd.NewError(cd.IllegalParam, "process runtime is not configured")
    }
    if err := s.runtime.Preflight(ctx); err != nil {
        return cd.NewError(cd.Unexpected, err.Error())
    }
    if err := s.base.Startup(ctx, serviceName, hub, background); err != nil {
        return err
    }
    s.mu.Lock()
    s.started = true
    s.mu.Unlock()
    return nil
}

func (s *ProcessService) Run(ctx context.Context) *cd.Error {
    s.mu.Lock()
    started := s.started
    s.mu.Unlock()
    if !started {
        return cd.NewError(cd.IllegalParam, "process service is not started")
    }
    if err := s.base.Run(ctx); err != nil {
        s.Shutdown(ctx)
        return err
    }
    if err := s.runtime.Activate(ctx); err != nil {
        s.Shutdown(ctx)
        return cd.NewError(cd.Unexpected, err.Error())
    }
    if err := s.runtime.Wait(ctx); err != nil {
        s.Shutdown(ctx)
        return cd.NewError(cd.Unexpected, err.Error())
    }
    return nil
}

func (s *ProcessService) Shutdown(ctx context.Context) {
    s.mu.Lock()
    started := s.started
    s.started = false
    s.mu.Unlock()
    if s.runtime != nil {
        s.runtime.Stop(ctx)
    }
    if started {
        s.base.Shutdown(ctx)
    }
}
```

典型用途：所有 Module Run 完成后再激活对外入口、在标准插件启动前做进程级 preflight、让 `Run` 阻塞等待退出信号。包装层不能再次调用 Initiator/Module 生命周期，否则会重复启动。

## 5. 完整实现 service.Service

只有必须改变标准顺序或插件集合时才完整实现。至少跟踪每个成功阶段，以便回滚：

```go
type ProcessService struct {
    initiatorsSetup bool
    modulesSetup    bool
    running         bool
}

func (s *ProcessService) Startup(
    ctx context.Context,
    _ string,
    hub event.Hub,
    background task.BackgroundRoutine,
) *cd.Error {
    if err := initiator.Setup(ctx, hub, background); err != nil {
        return err
    }
    s.initiatorsSetup = true

    if err := s.checkDependencies(ctx); err != nil {
        s.rollback(ctx)
        return err
    }

    if err := module.Setup(ctx, hub, background); err != nil {
        module.Teardown(ctx)
        s.rollback(ctx)
        return err
    }
    s.modulesSetup = true
    return nil
}

func (s *ProcessService) Run(ctx context.Context) *cd.Error {
    if !s.initiatorsSetup || !s.modulesSetup {
        return cd.NewError(cd.IllegalParam, "process service is not started")
    }
    if err := initiator.Run(ctx); err != nil {
        s.rollback(ctx)
        return err
    }
    if err := module.Run(ctx); err != nil {
        s.rollback(ctx)
        return err
    }
    s.running = true
    return nil
}

func (s *ProcessService) Shutdown(ctx context.Context) {
    s.rollback(ctx)
}

func (s *ProcessService) rollback(ctx context.Context) {
    if s.modulesSetup {
        module.Teardown(ctx)
        s.modulesSetup = false
    }
    if s.initiatorsSetup {
        initiator.Teardown(ctx)
        s.initiatorsSetup = false
    }
    s.running = false
}
```

实际实现还应根据需要接入 `framework/health`。不要静默丢失 DefaultService 已有的 dependency check、ready/failed 状态或 panic recovery；若选择替换，测试必须覆盖对应行为。

## 6. AdaptLifecycle 的边界

`service.LifecycleService` 是更窄的普通生命周期：

```go
type LifecycleService interface {
    Startup(ctx context.Context) error
    Run(ctx context.Context) error
    Shutdown(ctx context.Context) error
}
```

通过 `service.AdaptLifecycle(name, lifecycle)` 转为 `service.Service` 时，adapter 不把 Application 创建的 EventHub 和 BackgroundRoutine 传给业务生命周期，也不会自动调用 Initiator/Module 的 Setup、Run、Teardown。

因此它适合不使用 plugin runtime 的独立前台进程；若仍需标准 plugin 编排，应包装 DefaultService 或实现完整 Service。

## 7. Application Options 与 runtime ownership

Service 定制和 Application runtime 定制是两个维度。只需修改配置目录、服务名、队列大小或注入外部 runtime 时，优先使用 `application.Options`，不必替换 Service：

```go
opts := application.Options{
    ConfigDir:           configDir,
    ServiceName:         serviceName,
    EventHubQueueSize:   eventQueueSize,
    BackgroundQueueSize: backgroundQueueSize,
}

err := application.StartupWithOptions(ctx, service.DefaultService(), opts)
```

外部注入 EventHub 或 BackgroundRoutine 时，明确设置 `Options.Ownership`。未声明 ownership 的外部 runtime 由调用方关闭；错误的 ownership 会导致泄漏或重复关闭。

## 8. 定制 Service 验收

- Service 位于 `internal/services/<entry-name>`，入口只负责构造和调用 Application。
- Service 没有 plugin `init`/Register，也不伪装成 Module。
- 明确记录 DefaultService 不满足的生命周期差异。
- Startup 对必需依赖 fail-fast，并跟踪已完成阶段。
- Startup/Run 任一失败都会按逆序释放已启动资源。
- Shutdown 幂等，可在部分启动、启动失败和完整运行后调用。
- 对外入口只在依赖与路由就绪后激活。
- Run 的阻塞、退出和 context 取消语义有直接测试。
- 外部 EventHub/BackgroundRoutine 的 ownership 有直接测试。
- 若完整替换 DefaultService，dependency health、ready/failed 状态和 panic recovery 不会被无意丢失。
