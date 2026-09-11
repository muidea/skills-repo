# Shared Base Biz

## 1. 职责

`internal/modules/base/biz` 是所有使用 EventHub 的 Module/Block 的共享业务基座。它只提供：

- owner ID
- 当前 Application 注入的 `event.Hub`
- owner 对应的 `event.SimpleObserver`
- 当前 Application 注入的 `task.BackgroundRoutine`
- owner-neutral 的订阅、投递和后台任务包装

它不是 framework plugin，不包含 `init`、Register、业务 topic、业务 DTO、配置、持久化 helper 或具体运行单元 import。Initiator 不使用它。

## 2. 完整 base.go

下面是基于 magicCommon v1.5.16 的 Base Biz 参考实现；已有包装若使用不同的返回签名，升级时必须同步调整调用方并验证错误不被吞掉：

```go
package biz

import (
	"context"
	"time"

	cd "github.com/muidea/magicCommon/def"
	"github.com/muidea/magicCommon/event"
	"github.com/muidea/magicCommon/task"
)

type Base struct {
	id                string
	eventHub          event.Hub
	simpleObserver    event.SimpleObserver
	backgroundRoutine task.BackgroundRoutine
}

type routineTask struct {
	funcPtr func()
}

func (s *routineTask) Run() {
	s.funcPtr()
}

func New(
	id string,
	eventHub event.Hub,
	backgroundRoutine task.BackgroundRoutine) Base {
	return Base{
		id:                id,
		eventHub:          eventHub,
		simpleObserver:    event.NewSimpleObserver(id, eventHub),
		backgroundRoutine: backgroundRoutine,
	}
}

func (s *Base) ID() string {
	return s.id
}

// EventHub exposes the owner Hub only to a Biz derived from Base. It exists for
// typed EventHub-backed contract helpers; Module roots and adapters must not
// retain the returned Hub.
func (s *Base) EventHub() event.Hub {
	return s.eventHub
}

func (s *Base) BackgroundRoutine() task.BackgroundRoutine {
	return s.backgroundRoutine
}

func (s *Base) Subscribe(eventID string, observer event.Observer) {
	if err := s.eventHub.Subscribe(eventID, observer); err != nil {
		panic(err)
	}
}

func (s *Base) Unsubscribe(eventID string, observer event.Observer) {
	if err := s.eventHub.Unsubscribe(eventID, observer); err != nil {
		panic(err)
	}
}

func (s *Base) SubscribeFunc(eventID string, observerFunc event.ObserverFunc) {
	if err := s.simpleObserver.Subscribe(eventID, observerFunc); err != nil {
		panic(err)
	}
}

func (s *Base) UnsubscribeFunc(eventID string) {
	if err := s.simpleObserver.Unsubscribe(eventID); err != nil {
		panic(err)
	}
}

func (s *Base) PostEvent(event event.Event) {
	s.eventHub.Post(event)
}

func (s *Base) SendEvent(event event.Event) event.Result {
	return s.eventHub.Send(event)
}

func (s *Base) SyncTask(funcPtr func()) error {
	return s.backgroundRoutine.SyncFunction(funcPtr)
}

func (s *Base) AsyncTask(funcPtr func()) error {
	return s.backgroundRoutine.AsyncFunction(funcPtr)
}

func (s *Base) Timer(ctx context.Context, intervalValue time.Duration, offsetValue time.Duration, funcPtr func()) error {
	if funcPtr == nil {
		return cd.NewError(cd.IllegalParam, "timer function is required")
	}
	taskPtr := &routineTask{funcPtr: funcPtr}
	return s.backgroundRoutine.Timer(ctx, taskPtr, intervalValue, offsetValue)
}
```

上述无返回值订阅包装是“必需生命周期订阅”：仅在 framework guard 管理的 Setup/Run/Teardown 内使用，错误必须中断调用链，由 guard 转成生命周期错误。不得在包装层 catch 后只记日志、继续启动；普通可恢复流程应在 Biz 内检查 Hub/SimpleObserver 错误，或将 Base 包装与调用链一并改成显式返回错误，不能只改返回签名而让上层继续忽略。

构造函数订阅多个 topic 时，部分失败后的资源仍须可清理。若 Biz 已持有资源，应先把 Biz 保存到 owner，再调用其返回错误的初始化方法；不要让构造中途 panic 导致 owner 无法获得已创建对象。

任务包装返回错误，调用方必须检查；`SyncTask` 的超时/失败不能当作任务已停止。Timer 的成功仅指注册，不是每次业务执行成功。

## 3. 具体 Biz 的构造方式

具体 Biz 负责指定 owner ID 并订阅自己的业务 topic：

```go
type Unit struct {
    basebiz.Base
    // 仅本 owner 的状态和私有依赖
}

func New(hub event.Hub, background task.BackgroundRoutine) *Unit {
    unit := &Unit{
        Base: basebiz.New(common.UnitID, hub, background),
    }
    unit.SubscribeFunc(events.TopicCommand, unit.handleCommand)
    return unit
}
```

`module.go` 只在 framework `Setup` 中把 Hub 和 BackgroundRoutine 传给 Biz；Module root、service 和其它 adapter 不保存这些对象。

## 4. Teardown 责任

Base 不自动记录业务 topic，也不替具体 Biz 猜测关闭顺序。具体 Biz 的关闭生命周期必须：

1. BeginShutdown 停止新的业务输入或后台调度，取消 Timer context，但保留在途任务需要的 command handler 与依赖。
2. Quiesce 等待本 owner 在途操作；错误/超时保留资源以便重试。
3. Application 确认共享任务和事件排空后，最终 Teardown 逐项取消 ObserverFunc 与自定义 Observer 订阅。
4. 取消失败必须返回/中断，不能继续关闭所需资源；取消成功也不单独证明所有在途通知结束。
5. 只在相关操作真实结束后关闭资源并清空引用；部分 Setup 与重复清理都须安全。

不要在 Base 中调用 `event.Hub.Terminate` 或 `BackgroundRoutine.Shutdown`；这些进程级 runtime 由 `framework/application` 或显式 owner 关闭。

## 5. 明确禁止放入 Base 的能力

- 业务 topic、Command、Data、Result 或 alias
- root destination、全局 broadcast 或无类型 payload helper
- repository、provider、DAO、配置读取或 Initiator 查询
- 当前用户、租户、请求对象等上下文解析
- 跨 owner query、Service registry 或实现对象导出
- HTTP、路由、listener 或协议 DTO

这些能力一旦进入 Base，就会把共享基座变成隐式业务容器并制造跨 owner 耦合。

## 6. 最小测试清单

- `ID`、`EventHub`、`BackgroundRoutine` 返回构造时的对象。
- `SubscribeFunc` 后能够接收目标 owner/topic 的事件。
- `UnsubscribeFunc` 后不再调用 handler。
- `Subscribe` / `Unsubscribe` 能处理自定义 Observer。
- `SendEvent` 返回同步 handler 设置的 typed result。
- `PostEvent` 的 handler 在 result=nil 时不 panic。
- Sync、Async 和 Timer 包装会把任务提交给注入的 BackgroundRoutine。
- 关闭具体 Biz 不会终止 Application 共享的 Hub 或 BackgroundRoutine。
- 必需订阅失败让 Setup 返回错误，取消失败后本地/Hub 状态保留，重试成功。
- SyncTask 提交失败、panic、超时不会被 Base 包装吞掉。
