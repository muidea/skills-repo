# Event Usage Reference

本文档详细介绍magicCommon/event事件机制的使用方法。

## 1. Event核心概念

### 1.1 事件模型

magicCommon/event采用**发布-订阅(Pub/Sub)**模式：

```
Event流程：
[发送方] --PostEvent/SendEvent--> [EventHub] --Notify--> [订阅者]

PostEvent: 异步发送，无需等待响应
SendEvent: 同步发送，需要等待响应
```

### 1.2 核心接口

```go
// Event 事件
type Event interface {
    ID() string           // 事件ID
    Source() string       // 事件来源模块
    Destination() string  // 事件目标模块
    Header() Values       // 事件头信息
    Context() context.Context  // 上下文
    Data() any           // 事件数据
    SetData(key string, val any)  // 设置数据
    GetData(key string) any        // 获取数据
    Match(pattern string) bool      // 匹配模式
}

// Result 事件结果
type Result interface {
    Error() *cd.Error    // 错误信息
    Set(data any, err *cd.Error)  // 设置结果
    Get() (any, *cd.Error)        // 获取结果
    SetVal(key string, val any)   // 设置键值对
    GetVal(key string) any        // 获取键值
}
```

### 1.3 Event组成部分

| 组成部分 | 说明 | 示例 |
|----------|------|------|
| ID | 事件唯一标识 | `"Panel/FilterEntity"` |
| Source | 发送方模块ID | `"Panel"` |
| Destination | 接收方模块ID | `"Cas"` |
| Header | 头信息（键值对） | `{"namespace": "default"}` |
| Data | 事件携带的数据 | `id`, `filter`等 |

## 2. Event辅助函数

### 2.1 创建函数

```go
import "github.com/muidea/magicCommon/event"

// 创建Values（键值对）
values := event.NewValues()

// 创建Header（等同于NewValues）
header := event.NewHeader()

// 创建事件（无context）
ev := event.NewEvent(
    "EventID",           // 事件ID
    "SourceModule",      // 发送方
    "DestinationModule", // 接收方
    header,              // 头信息
    data,                // 数据
)

// 创建事件（带context）
ev := event.NewEventWithContext(
    "EventID",
    "SourceModule",
    "DestinationModule",
    header,
    ctx,                 // context.Context
    data,
)

// 创建结果对象
result := event.NewResult("EventID", "Source", "Destination")

// 创建简单观察者
observer := event.NewSimpleObserver("observerID", eventHub)
```

### 2.2 Values操作函数

```go
values := event.NewValues()

// 设置值
values.Set("key", value)

// 获取值
val := values.Get("key")

// 类型安全获取
str := values.GetString("key")    // string, 默认 ""
num := values.GetInt("key")      // int, 默认 0
boolVal := values.GetBool("key")  // bool, 默认 false

// 泛型获取
val := event.GetTypedValue[MyType](values, "key", defaultValue, "typeName")
```

### 2.3 类型转换辅助函数（重点）

event包提供了丰富的类型转换辅助函数：

```go
// ========== Result类型转换 ==========

// 从Result.Get()获取数据并转换为指定类型
func GetAs[T any](r Result) (T, *cd.Error)
    // 示例：
    value, err := event.GetAs[string](result)
    value, err := event.GetAs[*MyStruct](result)

// 从Result.GetVal(key)获取数据并转换为指定类型
func GetValAs[T any](r Result, key string) (T, bool)
    // 示例：
    value, ok := event.GetValAs[string](result, "name")

// ========== Event类型转换 ==========

// 从Event.Data()获取数据并转换为指定类型
func GetAsFromEvent[T any](e Event) (T, *cd.Error)
    // 示例：
    data, err := event.GetAsFromEvent[int64](ev)

// 从Event.GetData(key)获取数据并转换为指定类型
func GetValAsFromEvent[T any](e Event, key string) (T, bool)
    // 示例：
    data, ok := event.GetValAsFromEvent[string](ev, "name")

// 从Event.Header()获取数据并转换为指定类型
func GetHeaderValAsFromEvent[T any](e Event, key string) (T, bool)
    // 示例：
    namespace, ok := event.GetHeaderValAsFromEvent[string](ev, "namespace")

// 从Event.Context()获取数据并转换为指定类型
func GetContextValAsFromEvent[T any](e Event, key any) (T, bool)
    // 示例：
    userID, ok := event.GetContextValAsFromEvent[int64](ev, "userID")
```

### 2.4 事件匹配函数

```go
// 匹配事件ID模式
func MatchValue(pattern, val string) bool
    // 示例：
    if event.MatchValue("Panel/+", "Panel/Filter") {
        // 匹配
    }

// Event自带的匹配
func (e Event) Match(pattern string) bool
    // 示例：
    if ev.Match("Panel/+") {
        // 匹配
    }
```

## 3. Event创建

### 3.1 基本创建

```go
import "github.com/muidea/magicCommon/event"

// 创建事件头
header := event.NewValues()
header.Set("key", "value")

// 创建事件（无context）
ev := event.NewEvent(
    "EventID",           // 事件ID
    "SourceModule",      // 发送方
    "DestinationModule", // 接收方
    header,              // 头信息
    data,                // 数据
)

// 创建事件（带context）
ev := event.NewEventWithContext(
    "EventID",
    "SourceModule",
    "DestinationModule",
    header,
    ctx,                 // context.Context
    data,
)
```

### 3.2 Event事件常量

event包预定义了一些常用常量：

```go
const (
    Action = "_action_"
    Add    = "add"    // 添加操作
    Del    = "del"    // 删除操作
    Mod    = "mod"    // 修改操作
    Notify = "notify" // 通知操作
)
```

## 4. 事件订阅与处理

### 4.1 订阅事件（使用magicModulesRepo的Base）

如果使用magicModulesRepo的base biz，事件订阅非常简单：

```go
import (
    "github.com/muidea/magicCommon/event"
    "github.com/muidea/magicModulesRepo/modules/base/biz"
)

type MyModule struct {
    biz.Base  // 嵌入Base，获得事件处理能力
}

func New(...) *MyModule {
    ptr := &MyModule{
        Base: biz.New("MyModule", eventHub, backgroundRoutine),
    }

    // 订阅事件
    ptr.SubscribeFunc("EventID", ptr.handleEvent)

    return ptr
}

// 事件处理函数
func (s *MyModule) handleEvent(ev event.Event, result event.Result) {
    // 获取事件数据
    data := ev.Data()
    
    // 处理业务逻辑
    // ...
    
    // 设置返回结果（如果是SendEvent）
    result.Set(responseData, nil)
}
```

### 4.2 事件处理函数签名

```go
type ObserverFunc func(ev event.Event, result event.Result)
```

### 4.3 取消订阅

```go
// 取消订阅特定事件
ptr.UnsubscribeFunc("EventID")
```

## 5. 事件发送

### 5.1 PostEvent（异步）

异步发送事件，不等待响应：

```go
// 创建事件
header := event.NewValues()
header.Set("namespace", "default")
ev := event.NewEvent("EventID", s.ID(), "TargetModule", header, data)

// 异步发送
s.PostEvent(ev)

// 继续执行后续逻辑
```

### 5.2 SendEvent（同步）

同步发送事件，等待响应：

```go
// 创建事件
header := event.NewValues()
header.Set("namespace", "default")
ev := event.NewEvent("EventID", s.ID(), "TargetModule", header, data)

// 同步发送，等待结果
result := s.SendEvent(ev)

// 获取结果
if result.Error() != nil {
    // 处理错误
    return nil, result.Error()
}

// 使用辅助函数类型转换获取结果
value, err := event.GetAs[ResponseType](result)
```

### 5.3 事件ID命名规范

建议使用模块前缀：

```go
const (
    FilterEntity   = "Panel/FilterEntity"
    QueryEntity    = "Panel/QueryEntity"
    CreateEntity   = "Panel/CreateEntity"
    UpdateEntity   = "Panel/UpdateEntity"
    DeleteEntity   = "Panel/DeleteEntity"
    
    // 跨模块事件
    InnerInstall   = "Installer/InnerInstall"
)
```

### 5.4 事件目标模块

```go
// 发送给特定模块
ev := event.NewEvent("EventID", s.ID(), "TargetModule", header, data)

// 广播给所有模块
ev := event.NewEvent("EventID", s.ID(), "/#", header, data)  // /# 为广播地址
```

## 6. 事件数据获取

### 6.1 从Event获取数据

```go
func (s *MyModule) handleEvent(ev event.Event, result event.Result) {
    // 直接获取Data
    data := ev.Data()
    
    // 类型转换获取
    entityID, ok := ev.Data().(int64)
    
    // 使用辅助函数（推荐）
    value, err := event.GetAsFromEvent[MyDataType](ev)
    
    // 从Header获取
    namespace := ev.Header().GetString("namespace")
    // 或使用辅助函数
    namespace, ok := event.GetHeaderValAsFromEvent[string](ev, "namespace")
    
    // 从Context获取
    ctx := ev.Context()
    userID := ctx.Value("userID")
    // 或使用辅助函数
    userID, ok := event.GetContextValAsFromEvent[int64](ev, "userID")
    
    // 从Event.GetData(key)获取
    customData := ev.GetData("key")
    // 或使用辅助函数
    customData, ok := event.GetValAsFromEvent[string](ev, "key")
}
```

### 6.2 从Result获取数据

```go
func handleResult(result event.Result) {
    // 检查错误
    if result.Error() != nil {
        slog.Error("event failed", "error", result.Error())
        return
    }
    
    // 获取数据
    value, err := result.Get()
    
    // 使用辅助函数（推荐）
    data, err := event.GetAs[ResponseType](result)
    
    // 使用Key-Value形式获取
    data := result.GetVal("key")
    data, ok := event.GetValAs[ResponseType](result, "key")
}
```

## 7. 完整示例

### 7.1 模块间事件通信示例

```go
package mymodule

import (
    "context"
    
    cd "github.com/muidea/magicCommon/def"
    "github.com/muidea/magicCommon/event"
    
    "github.com/muidea/magicModulesRepo/modules/base/biz"
    
    "{module_path}/internal/modules/kernel/mymodule/pkg/common"
)

type MyModule struct {
    biz.Base
    // 其他字段
}

func New(eventHub event.Hub, backgroundRoutine task.BackgroundRoutine) *MyModule {
    ptr := &MyModule{
        Base: biz.New(common.MyModuleModule, eventHub, backgroundRoutine),
    }

    // 订阅事件
    ptr.SubscribeFunc(common.QueryData, ptr.handleQueryData)

    return ptr
}

// 处理查询事件
func (s *MyModule) handleQueryData(ctx context.Context, ev event.Event, result event.Result) {
    // 使用辅助函数获取数据
    param, err := event.GetAsFromEvent[*QueryParam](ev)
    if err != nil {
        result.Set(nil, err)
        return
    }
    
    // 从Header获取namespace
    namespace, _ := event.GetHeaderValAsFromEvent[string](ev, "namespace")
    
    // 业务处理
    data, err := s.doQuery(ctx, param, namespace)
    if err != nil {
        result.Set(nil, err)
        return
    }
    
    // 返回结果
    result.Set(data, nil)
}

// 发送事件给其他模块
func (s *MyModule) QueryOtherModule(ctx context.Context, id int64) (*Response, *cd.Error) {
    header := event.NewValues()
    header.Set("namespace", "default")
    
    // 创建事件
    ev := event.NewEventWithContext(
        common.QueryData,    // 事件ID
        s.ID(),              // 源模块
        "OtherModule",       // 目标模块
        header,
        ctx,
        id,
    )
    
    // 发送并等待结果
    result := s.SendEvent(ev)
    
    // 使用辅助函数获取结果
    return event.GetAs[*Response](result)
}
```

### 7.2 常量定义示例

```go
// pkg/common/const.go
package common

const (
    MyModuleModule = "mymodule"
    
    // 事件ID
    QueryData    = "MyModule/QueryData"
    CreateData   = "MyModule/CreateData"
    UpdateData   = "MyModule/UpdateData"
    DeleteData   = "MyModule/DeleteData"
    FilterData   = "MyModule/FilterData"
)
```

## 8. 事件匹配模式

### 8.1 精确匹配

```go
// 精确匹配 "Panel/FilterEntity"
Subscribe("Panel/FilterEntity", handler)
```

### 8.2 通配符匹配

```go
// + 匹配单个路径段
Subscribe("Panel/+", handler)  // 匹配 Panel/Filter, Panel/Query 等

// # 匹配多个路径段
Subscribe("Panel/#", handler)  // 匹配 Panel/FilterEntity, Panel/Filter/All 等

// :id 命名参数
Subscribe("Panel/:id", handler)  // 匹配任意单段
```

### 8.3 MatchValue函数

```go
// 手动匹配
if event.MatchValue("Panel/+", "Panel/Filter") {
    // 处理匹配的事件
}
```

## 9. Base提供的事件方法

| 方法 | 说明 |
|------|------|
| `Subscribe(eventID string, observer event.Observer)` | 订阅事件 |
| `Unsubscribe(eventID string, observer event.Observer)` | 取消订阅 |
| `SubscribeFunc(eventID string, observerFunc event.ObserverFunc)` | 订阅事件（函数形式） |
| `UnsubscribeFunc(eventID string)` | 取消订阅（函数形式） |
| `PostEvent(event event.Event)` | 异步发送事件 |
| `SendEvent(event event.Event) event.Result` | 同步发送事件 |
| `BroadCast(eid string, header event.Values, val interface{})` | 广播事件 |
| `SyncTask(funcPtr func())` | 同步执行任务 |
| `AsyncTask(funcPtr func())` | 异步执行任务 |
| `Timer(interval, offset time.Duration, funcPtr func())` | 定时任务 |

## 10. 辅助函数速查表

### 10.1 创建函数

| 函数 | 说明 |
|------|------|
| `event.NewValues()` | 创建Values |
| `event.NewHeader()` | 创建Header |
| `event.NewEvent(id, source, dest, header, data)` | 创建事件 |
| `event.NewEventWithContext(id, source, dest, header, ctx, data)` | 创建带Context的事件 |
| `event.NewResult(id, source, dest)` | 创建Result |
| `event.NewSimpleObserver(id, hub)` | 创建观察者 |

### 10.2 Values操作

| 函数 | 说明 |
|------|------|
| `values.Set(key, value)` | 设置值 |
| `values.Get(key)` | 获取值 |
| `values.GetString(key)` | 获取string |
| `values.GetInt(key)` | 获取int |
| `values.GetBool(key)` | 获取bool |

### 10.3 类型转换（重要）

| 函数 | 说明 |
|------|------|
| `event.GetAs[T](result)` | Result.Get()转为T |
| `event.GetValAs[T](result, key)` | Result.GetVal(key)转为T |
| `event.GetAsFromEvent[T](ev)` | Event.Data()转为T |
| `event.GetValAsFromEvent[T](ev, key)` | Event.GetData(key)转为T |
| `event.GetHeaderValAsFromEvent[T](ev, key)` | Event.Header()[key]转为T |
| `event.GetContextValAsFromEvent[T](ev, key)` | Event.Context().Value(key)转为T |
| `event.MatchValue(pattern, val)` | 匹配事件ID模式 |

## 11. 最佳实践

1. **事件ID命名**：使用 `源模块/操作` 格式，如 `Panel/FilterEntity`
2. **类型转换**：始终使用 `event.GetAs[T]` 辅助函数进行类型转换，避免panic
3. **Header传参**：使用Header传递上下文信息（namespace等）
4. **错误处理**：SendEvent必须检查result.Error()
5. **取消订阅**：在Teardown中取消订阅，避免内存泄漏
6. **Context传递**：需要传递context时使用 `NewEventWithContext`
