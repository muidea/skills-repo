# Event Usage

## 1. 什么时候用 event

- 运行单元间异步通知：`Post`
- 需要同步结果：`Send`
- 运行单元内部后台处理：结合 `task.BackgroundRoutine`
- 强一致写入、鉴权、配置激活、状态转换等需要失败反馈的操作不能使用 `Post`

## 2. 处理顺序

1. 维护对应资源或状态的能力 owner 在自己的 `pkg/events` 定义事件 ID 和具体 `Command`、`Data`、`Result`
2. 调用方导入能力 owner 的 `pkg/events`，按需投递或订阅对应合同；同一能力不能因调用方不同复制 topic、DTO 或 handler
3. 投递与消费由具体单元的 `biz` 调用 magicCommon `event.Hub` 的 `Send`、`Post`、`Subscribe`；Biz 必须内嵌 `internal/modules/base/biz.Base`
4. 同步 handler 使用 `event.Result.Set(<具体 Result>, err)` 返回，不增加通用 response 或 command wrapper
5. 在 `biz` 层承载订阅、投递和 handler 逻辑；`module.go` 仅接线，`service` 不接收 Hub、也不堆复杂事件流程
6. 为 Post handler 单独检查 result=nil，禁止调用 `result.Set`

## 3. 推荐模式

```go
func (s *Unit) Setup(_ context.Context, eventHub event.Hub, background task.BackgroundRoutine) (err *cd.Error) {
    s.bizPtr = biz.New(eventHub, background)
    return nil
}
```

```go
type UnitBiz struct {
    basebiz.Base
}

func New(eventHub event.Hub, background task.BackgroundRoutine) *UnitBiz {
    return &UnitBiz{
        Base: basebiz.New(common.UnitID, eventHub, background),
    }
}
```

## 4. 经验规则

- 使用 Hub 的 Module/Block 必须有自身 `biz`，并通过内嵌的 `basebiz.Base` 负责 `Send/Post/Subscribe`；禁止在 Module root、service 或其它 adapter 平行保存 Hub/observer
- Initiator 不使用 Base Biz；它只实现无业务状态的基础设施生命周期
- module/block 间所有运行期交互只能通过 EventHub，不直接注入或调用对方 service、repository、adapter、reader callback
- 事件合同必须使用具体类型；禁止用 `map[string]any`、`[]any` 或无约束 `any` 承载 command/data/result
- 禁止 Envelope、`events.Response`、JSON marshal/unmarshal、reflect 类型表或通用 Send/Subscribe facade 作为组件交互兼容层
- 共享基础包只能提供跨合同复用且不可变的 owner-neutral 纯值类型或 EventHub helper；纯值包不得定义 topic、`Command`、`Data`、`Result`、业务逻辑或可变资源，业务合同仍由能力 owner 拥有
- EventHub payload/result 只传数据，不传 `io.Writer`、`http.ResponseWriter`、channel、store、repository、Registry、Recorder 或其它可变资源句柄
- owner-specific EventHub-backed port 可以封装重复调用，但只能保存 hub/source 和 typed mapping，不得保存 owner 实现
- `Post` handler 的 `event.Result` 可能为 nil；普通 Hub 会恢复 panic 并记录告警，因此必须补直接调用 handler(result=nil) 的回归测试
- `Send` 失败和 `Post` 丢失处理要分开考虑
- 事件语义变更时，同步补测试和文档

## 5. Send 与 Post 示例

同步 handler：

```go
func (s *Biz) handleQuery(ev event.Event, result event.Result) {
    if result == nil {
        return
    }
    command, ok := ev.Data().(events.QueryCommand)
    if !ok {
        result.Set(nil, cd.NewError(cd.IllegalParam, "invalid query command"))
        return
    }
    value, err := s.query(command)
    result.Set(events.QueryResult{Value: value}, err)
}
```

异步 handler：

```go
func (s *Biz) handleRecorded(ev event.Event, _ event.Result) {
    data, ok := ev.Data().(events.RecordedData)
    if !ok {
        return
    }
    s.observe(data)
}
```

## 6. 跨仓联动时先核对

- `magicCommon/event`
- `magicCommon/task`
- 如果事件会驱动持久化或协议适配，再看对应基础库
