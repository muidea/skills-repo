# Event Usage

## 1. 什么时候用 event

- 运行单元间异步通知：`Post`
- 需要同步结果：`Send`
- 运行单元内部后台处理：结合 `task.BackgroundRoutine`

## 2. 处理顺序

1. 事件投递组件在自己的 `pkg/events` 定义事件 ID 和具体 `Command`、`Data`、`Result`
2. 消费组件导入投递组件的 `pkg/events`，按需订阅对应 command
3. 投递与消费直接调用 magicCommon `event.Hub` 的 `Send`、`Post`、`Subscribe`
4. 同步 handler 使用 `event.Result.Set(<具体 Result>, err)` 返回，不增加通用 response 或 command wrapper
5. 在 `biz` 层承载订阅、投递和 handler 逻辑，不要在 `service` 层堆复杂事件流程

## 3. 推荐模式

```go
func (s *Unit) Setup(eventHub event.Hub, background task.BackgroundRoutine) (err *cd.Error) {
    s.bizPtr = biz.New(eventHub, background)
    return nil
}
```

```go
type UnitBiz struct {
    eventHub   event.Hub
    background task.BackgroundRoutine
}
```

## 4. 经验规则

- `biz` 负责 `Send/Post/Subscribe`
- module/block 间所有运行期交互只能通过 EventHub，不直接注入或调用对方 service、repository、adapter、reader callback
- 事件合同必须使用具体类型；禁止用 `map[string]any`、`[]any` 或无约束 `any` 承载 command/data/result
- 禁止 Envelope、`events.Response`、JSON marshal/unmarshal、reflect 类型表或通用 Send/Subscribe facade 作为组件交互兼容层
- 共享基础包可以提供 owner-neutral 值类型或 EventHub helper，但不能定义业务 topic alias 或代替投递组件拥有事件合同
- `Send` 失败和 `Post` 丢失处理要分开考虑
- 事件语义变更时，同步补测试和文档

## 5. 跨仓联动时先核对

- `magicCommon/event`
- `magicCommon/task`
- 如果事件会驱动 ORM 或 HTTP，再看 `magicOrm` / `magicEngine`
