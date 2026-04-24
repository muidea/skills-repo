# Event Usage

## 1. 什么时候用 event

- 运行单元间异步通知：`Post`
- 需要同步结果：`Send`
- 运行单元内部后台处理：结合 `task.BackgroundRoutine`

## 2. 处理顺序

1. 先定义事件 ID 和归属运行单元
2. 再定义传输数据结构
3. 在 `biz` 层订阅 / 发送
4. 不要在 `service` 层直接堆复杂事件逻辑

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
- 事件 payload 尽量是明确结构，不要到处传 `map[string]any`
- `Send` 失败和 `Post` 丢失处理要分开考虑
- 事件语义变更时，同步补测试和文档

## 5. 跨仓联动时先核对

- `magicCommon/event`
- `magicCommon/task`
- 如果事件会驱动 ORM 或 HTTP，再看 `magicOrm` / `magicEngine`
