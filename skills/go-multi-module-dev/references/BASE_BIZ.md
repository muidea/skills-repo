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

下面的代码以已完成结构验收的共享 Base Biz 为标准实现：

```go
package biz

import (
	"context"
	"time"

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
	s.eventHub.Subscribe(eventID, observer)
}

func (s *Base) Unsubscribe(eventID string, observer event.Observer) {
	s.eventHub.Unsubscribe(eventID, observer)
}

func (s *Base) SubscribeFunc(eventID string, observerFunc event.ObserverFunc) {
	s.simpleObserver.Subscribe(eventID, observerFunc)
}

func (s *Base) UnsubscribeFunc(eventID string) {
	s.simpleObserver.Unsubscribe(eventID)
}

func (s *Base) PostEvent(event event.Event) {
	s.eventHub.Post(event)
}

func (s *Base) SendEvent(event event.Event) event.Result {
	return s.eventHub.Send(event)
}

func (s *Base) SyncTask(funcPtr func()) {
	taskPtr := &routineTask{funcPtr: funcPtr}

	s.backgroundRoutine.SyncTask(taskPtr)
}

func (s *Base) AsyncTask(funcPtr func()) {
	taskPtr := &routineTask{funcPtr: funcPtr}
	s.backgroundRoutine.AsyncTask(taskPtr)
}

func (s *Base) Timer(ctx context.Context, intervalValue time.Duration, offsetValue time.Duration, funcPtr func()) {
	taskPtr := &routineTask{funcPtr: funcPtr}
	s.backgroundRoutine.Timer(ctx, taskPtr, intervalValue, offsetValue)
}
```

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

Base 不自动记录业务 topic，也不替具体 Biz 猜测关闭顺序。具体 Biz 的 `Teardown` 必须：

1. 停止新的业务输入或后台调度。
2. 对每个 `SubscribeFunc` 调用对应 `UnsubscribeFunc`。
3. 对每个自定义 Observer 调用对应 `Unsubscribe`。
4. 取消 Timer 使用的 context。
5. 关闭本 owner 的资源并清空引用。

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
