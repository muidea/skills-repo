# Module Structure Reference

本文档详细说明magicCommon/framework框架下的模块结构。

## 1. 模块目录结构

### 1.1 完整目录结构

```
{module_name}/
├── module.go           # 模块入口（必需）
├── biz/                # 业务逻辑层
│   ├── biz.go          # 业务主类
│   ├── entity.go       # 实体操作
│   ├── database.go     # 数据库操作
│   └── *_test.go       # 测试文件
├── service/            # HTTP服务层
│   ├── service.go      # 服务主类
│   ├── handler.go      # 处理器
│   └── *_test.go
└── pkg/
    ├── common/          # 公共定义
    │   ├── const.go     # 常量定义
    │   ├── errors.go    # 错误定义
    │   ├── result.go    # 结果定义
    │   └── filter.go    # 过滤器定义
    └── models/         # 数据模型
        ├── model.go    # 模型定义
        └── dto.go     # 数据传输对象
```

### 1.2 各层职责

| 层级 | 目录 | 职责 |
|------|------|------|
| 入口 | `module.go` | 模块注册、生命周期管理 |
| 业务 | `biz/` | 业务逻辑、事件处理、数据操作 |
| 服务 | `service/` | HTTP路由、请求响应处理 |
| 公共 | `pkg/common/` | 常量、错误、结果定义 |
| 模型 | `pkg/models/` | 数据结构定义 |

## 2. Module层详解

### 2.1 module.go结构

```go
package module_name

// 导入（按顺序：标准库、第三方、项目内部）
import (
    // 标准库
    "log/slog"

    // magicCommon框架 - 必须
    cd "github.com/muidea/magicCommon/def"
    "github.com/muidea/magicCommon/event"
    "github.com/muidea/magicCommon/framework/plugin/initiator"
    "github.com/muidea/magicCommon/framework/plugin/module"
    "github.com/muidea/magicCommon/task"

    // 可选导入，根据实际需求选择
    // 如果需要使用magicModulesRepo：
    // ipc "github.com/muidea/magicModulesRepo/initiators/persistence/pkg/common"
    // irc "github.com/muidea/magicModulesRepo/initiators/routeregistry/pkg/common"

    // 内部包
    "{module_path}/internal/modules/xxx/xxx/biz"
    "{module_path}/internal/modules/xxx/xxx/pkg/common"
    "{module_path}/internal/modules/xxx/xxx/service"
)

// 模块注册
func init() {
    module.Register(New())
}

// 模块结构体
type ModuleName struct {
    bizPtr     *biz.ModuleName
    servicePtr *service.ModuleName
}

// 构造函数
func New() *ModuleName {
    return &ModuleName{}
}

// ID 返回模块唯一标识
func (s *ModuleName) ID() string {
    return common.ModuleNameModule
}

// Setup 初始化（获取依赖、创建实例）
func (s *ModuleName) Setup(eventHub event.Hub, backgroundRoutine task.BackgroundRoutine) (err *cd.Error) {
    // 获取Initiator依赖
    var persistenceHelperVal ipc.PersistenceHelper
    persistenceHelperVal, persistenceHelperErr := initiator.GetEntity(
        ipc.PersistenceInitiator, 
        persistenceHelperVal,
    )
    if persistenceHelperErr != nil {
        err = persistenceHelperErr
        return
    }

    // 创建biz和service实例
    s.bizPtr = biz.New(persistenceHelperVal.GetBaseClient(), eventHub, backgroundRoutine)
    s.servicePtr = service.New(routeRegistryHelperVal.GetRoleRouteRegistry(), s.bizPtr)

    return nil
}

// Run 启动（初始化数据、注册路由）
func (s *ModuleName) Run() (err *cd.Error) {
    err = s.bizPtr.Initialize()
    if err != nil {
        return
    }

    s.servicePtr.RegisterRoute()
    return
}

// Teardown 停止（清理资源）
func (s *ModuleName) Teardown() {
    // 清理逻辑
}
```

### 2.2 常用Initiator

| Initiator | 用途 | 获取方式 |
|------------|------|----------|
| PersistenceInitiator | 数据库操作 | `initiator.GetEntity(ipc.PersistenceInitiator, ...)` |
| RouteRegistryInitiator | 路由注册 | `initiator.GetEntity(irc.RouteRegistryInitiator, ...)` |

## 3. Biz层详解

### 3.1 biz.go结构

```go
package biz

import (
    "context"

    "log/slog"

    // magicCommon框架 - 必须
    cd "github.com/muidea/magicCommon/def"
    "github.com/muidea/magicCommon/event"
    "github.com/muidea/magicCommon/task"

    // 可选导入，根据实际需求选择
    // 如果需要使用magicBase：
    // "github.com/muidea/magicBase/pkg/client"
    // bc "github.com/muidea/magicBase/pkg/common"
    // 如果需要使用magicModulesRepo的base biz：
    // "github.com/muidea/magicModulesRepo/modules/base/biz"

    // 内部包
    "{module_path}/internal/modules/xxx/xxx/pkg/common"
)

type ModuleName struct {
    // 如果使用magicModulesRepo的base biz：
    // biz.Base
    // baseClient client.Client
    // 其他依赖
}

/*
func New(
    baseClient client.Client,
    eventHub event.Hub,
    backgroundRoutine task.BackgroundRoutine,
) *ModuleName {
    ptr := &ModuleName{
        Base:       biz.New(common.ModuleNameModule, eventHub, backgroundRoutine),
        baseClient: baseClient,
    }

    // 注册事件处理
    ptr.SubscribeFunc(common.EventName, ptr.handleEvent)
*/

    return ptr
}

func (s *ModuleName) Initialize() (err *cd.Error) {
    // 初始化：加载数据、缓存等
    return nil
}

// 事件处理
func (s *ModuleName) handleEvent(ctx context.Context, ...) (ret interface{}, err *cd.Error) {
    // 处理逻辑
    return
}

// 业务方法
func (s *ModuleName) BusinessMethod(ctx context.Context, ...) (ret interface{}, err *cd.Error) {
    // 业务逻辑
    return
}
```

### 3.2 Biz.Base方法

| 方法 | 说明 |
|------|------|
| `SubscribeFunc(event string, handler func(...))` | 订阅事件 |
| `SendEvent(event *Event) *EventResult` | 发送事件 |
| `PostEvent(event *Event)` | 发布事件 |
| `ID() string` | 获取模块ID |

### 3.3 数据操作

```go
// 查询
entityList, total, err := s.baseClient.FilterEntity(filter)

// 创建
result, err := s.baseClient.CreateEntity(entity)

// 更新
result, err := s.baseClient.UpdateEntity(entity)

// 删除
err := s.baseClient.DeleteEntity(id)
```

## 4. Service层详解

### 4.1 service.go结构

```go
package service

import (
    "context"
    "net/http"

    "log/slog"

    // magicCommon框架 - 必须
    cd "github.com/muidea/magicCommon/def"
    fn "github.com/muidea/magicCommon/foundation/net"
    "github.com/muidea/magicCommon/session"

    // 可选导入，根据实际需求选择
    // 如果需要使用magicEngine：
    // engine "github.com/muidea/magicEngine/http"
    // 如果需要使用magicBase：
    // bc "github.com/muidea/magicBase/pkg/common"
    // "github.com/muidea/magicBase/pkg/toolkit"

    // 内部包
    "{module_path}/internal/modules/xxx/xxx/biz"
    "{module_path}/internal/modules/xxx/xxx/pkg/common"
)

type ModuleName struct {
    // 如果使用magicBase：
    // roleRouteRegistry toolkit.RoleRouteRegistry
    bizPtr *biz.ModuleName
}

/*
func New(roleRouteRegistry toolkit.RoleRouteRegistry, bizPtr *biz.ModuleName) *ModuleName {
    return &ModuleName{
        roleRouteRegistry: roleRouteRegistry,
        bizPtr:            bizPtr,
    }
}
*/

func New(bizPtr *biz.ModuleName) *ModuleName {
    return &ModuleName{
        bizPtr: bizPtr,
    }
}

func (s *ModuleName) RegisterRoute() {
    // 如果使用magicBase的路由注册：
    // s.roleRouteRegistry.AddHandler(common.RouteName, engine.GET, s.handler)

    // 权限路由
    s.roleRouteRegistry.AddPrivilegeHandler(
        common.RouteName, 
        engine.GET,           // HTTP方法
        bc.ReadPermission,    // 权限级别
        s.handler,
    )
}

func (s *ModuleName) handler(ctx context.Context, res http.ResponseWriter, req *http.Request) {
    // 创建响应结构
    result := &common.ResultType{Result: *cd.NewResult()}
    defer fn.PackageHTTPResponse(res, result)

    // 获取请求参数
    filter := bc.NewFilter()
    filter.Decode(req)

    // 调用biz层
    values, pagination, err := s.bizPtr.BusinessMethod(ctx, filter)
    if err != nil {
        result.Error = err
        return
    }

    // 返回结果
    result.Values = values
    result.Pagination = pagination
    result.Error = nil
}
```

### 4.2 权限级别

| 权限 | 说明 | 使用场景 |
|------|------|----------|
| `bc.ReadPermission` | 读权限 | GET请求 |
| `bc.WritePermission` | 写权限 | POST/PUT请求 |
| `bc.DeletePermission` | 删除权限 | DELETE请求 |

### 4.3 请求参数解析

```go
// Query参数
filter := bc.NewFilter()
filter.Decode(req)

// JSON Body
param := &ParamType{}
err := fn.ParseJSONBody(req, nil, param)

// Path参数
id := req.PathValue("id")
```

### 4.4 响应处理

```go
// 标准响应
result := &common.ResultType{Result: *cd.NewResult()}
defer fn.PackageHTTPResponse(res, result)

// 设置结果
result.Values = values
result.Pagination = pagination
result.Error = nil
```

## 5. Common层详解

### 5.1 const.go

```go
package common

const (
    ModuleNameModule = "module_name"

    // 事件名称
    EventName = "ModuleName/Event"

    // 路由名称
    RouteName   = "ModuleName/Route"
    RouteNameGET   = "ModuleName/Route"
    RouteNamePOST  = "ModuleName/Route"
)
```

### 5.2 result.go

```go
package common

import cd "github.com/muidea/magicCommon/def"

type ResultType struct {
    cd.Result
    Values     interface{}     `json:"values"`
    Pagination *bc.Pagination  `json:"pagination,omitempty"`
}

type FilterResult struct {
    cd.Result
    Values     interface{}     `json:"values"`
    Pagination *bc.Pagination  `json:"pagination"`
}

type Result struct {
    cd.Result
    Value interface{} `json:"value"`
}
```

## 6. Models层详解

### 6.1 model.go

```go
package models

import (
    "time"

    "github.com/muidea/magicOrm/model"
)

type Entity struct {
    model.Entity
    Name      string    `json:"name"`
    Status    int       `json:"status"`
    CreateAt  time.Time `json:"createAt"`
    UpdateAt  time.Time `json:"updateAt"`
}

func (s *Entity) GetPkgKey() string {
    return "module_name/entity"
}
```

## 7. 模块生命周期

```
┌─────────────────────────────────────────────────────────────┐
│                     Application Start                       │
├─────────────────────────────────────────────────────────────┤
│  1. main.go 调用 application.New()                         │
│  2. service.Setup() 加载所有已注册的module                  │
│  3. module.Register() 被调用（init）                        │
│  4. app.Execute() 启动                                      │
│     ├── module.Setup()                                      │
│     │   └── 获取Initiator依赖                               │
│     │   └── 创建biz/service实例                              │
│     └── module.Run()                                        │
│         └── biz.Initialize()                               │
│         └── service.RegisterRoute()                         │
├─────────────────────────────────────────────────────────────┤
│                     Application Stop                         │
├─────────────────────────────────────────────────────────────┤
│  5. module.Teardown()                                       │
│     └── 清理资源                                            │
└─────────────────────────────────────────────────────────────┘
```
