---
name: go-multi-module-dev
description: 基于magicCommon/framework框架的Go Monorepo多模块项目开发规范。适用于创建新应用、新模块、添加模块组件(biz/service/pkg)的开发任务。使用此skill进行多项目多模块架构的开发工作。
compatibility: Go 1.21+, magicCommon框架, Git, Docker
metadata:
  author: rangh
  version: "1.2.1"
---

# Go Multi-Module Development Skill

本skill提供基于magicCommon/framework框架的Go Monorepo多模块项目开发规范。

## 0. 配置说明

### 占位符说明

本文档使用以下占位符，请根据实际项目进行替换：

| 占位符          | 说明                                         | 示例                          |
| --------------- | -------------------------------------------- | ----------------------------- |
| `{module_path}` | 当前仓库的module路径，来自go.mod中module定义 | `github.com/myorg/myproject`  |
| `{app_name}`    | 应用/服务名称                                | `service-a`, `myService`      |
| `{module_name}` | 模块名称（小写）                             | `panel`, `runner`, `myModule` |
| `{ModuleName}`  | 模块名称（PascalCase）                       | `Panel`, `Runner`, `MyModule` |

**示例：** 假设当前仓库的go.mod定义为 `module github.com/myorg/myproject`，则：

- `{module_path}/internal/modules/...` → `github.com/myorg/myproject/internal/modules/...`

### magicCommon框架模块说明

magicCommon框架由多个独立仓库组成，各模块说明如下：

| 模块             | 路径                                 | 必需     | 说明                                |
| ---------------- | ------------------------------------ | -------- | ----------------------------------- |
| magicCommon      | `github.com/muidea/magicCommon`      | **必须** | 框架核心，包含event、task等基础功能 |
| magicModulesRepo | `github.com/muidea/magicModulesRepo` | 可选     | 通用模块仓库，包含base、biz等       |
| magicEngine      | `github.com/muidea/magicEngine`      | 可选     | HTTP引擎                            |
| magicOrm         | `github.com/muidea/magicOrm`         | 可选     | ORM模块                             |

**说明：**

- **必须模块**：使用框架时必须依赖
- **可选模块**：根据实际业务需求选择使用，可以完全不引用这些模块

## 1. 项目架构概述

### 1.1 推荐目录结构

```
project-root/
├── Makefile                    # 构建脚本
├── README.md                   # 项目说明
├── go.mod                      # 模块定义（定义module路径）
├── go.sum                      # 依赖校验
├── application/                # 应用入口目录
│   └── {app_name}/            # 服务名
│       ├── README.md           # 服务说明
│       ├── cmd/                # 程序入口
│       │   └── main.go
│       └── docker/             # 容器编排
│           ├── Dockerfile
│           └── bootstrap.sh
├── docs/                       # 项目文档
├── internal/                   # 内部模块（私有）
│   ├── config/                 # 配置模块
│   │   └── config.go
│   └── modules/                # 功能模块
│       ├── kernel/             # 核心业务模块
│       │   └── {module_name}/
│       │       ├── module.go
│       │       ├── biz/
│       │       ├── service/
│       │       └── pkg/
│       └── blocks/             # 公共业务模块
│           └── {module_name}/
└── pkg/                       # 公共包（可导出）
```

**目录说明：**

| 目录                             | 说明                         |
| -------------------------------- | ---------------------------- |
| `application/{app_name}/`        | 可执行应用，每个服务一个目录 |
| `application/{app_name}/cmd/`    | 程序入口，包含main.go        |
| `application/{app_name}/docker/` | 容器化相关文件               |
| `internal/modules/kernel/`       | 核心业务模块                 |
| `internal/modules/blocks/`       | 公共业务模块                 |
| `pkg/`                           | 可导出的公共包               |
| `docs/`                          | 项目文档                     |

### 1.2 模块目录结构

每个业务模块的标准结构：

```
{module_name}/
├── module.go           # 模块入口（必需）
├── biz/                # 业务逻辑层
│   ├── biz.go          # 业务主类
│   └── *.go            # 其他业务文件
├── service/            # HTTP服务层
│   ├── service.go      # 服务主类
│   └── *.go            # 路由处理
└── pkg/
    ├── common/         # 公共定义
    │   ├── const.go    # 常量定义
    │   └── result.go   # 结果定义
    └── models/         # 数据模型
        └── *.go
```

### 1.3 go.mod示例

项目根目录的go.mod文件：

```go
module {module_path}

go 1.24.0

toolchain go1.24.11

require (
    // 必须：magicCommon框架
    github.com/muidea/magicCommon v1.5.0

    // 可选：根据业务需求选择
    // github.com/muidea/magicBase v1.4.0
    // github.com/muidea/magicModulesRepo v0.0.0-00010101000000-000000000000
    // github.com/muidea/magicEngine v1.4.0
    // github.com/muidea/magicOrm v1.4.0
)
```

### 1.4 magicCommon/framework框架架构

框架核心组件：

| 组件          | 包路径                                   | 说明             |
| ------------- | ---------------------------------------- | ---------------- |
| Module接口    | `magicCommon/framework/plugin/module`    | 模块生命周期管理 |
| Initiator     | `magicCommon/framework/plugin/initiator` | 依赖服务获取     |
| Application   | `magicCommon/framework/application`      | 应用入口         |
| Configuration | `magicCommon/framework/configuration`    | 配置管理         |
| Event         | `magicCommon/event`                      | 事件机制         |
| Task          | `magicCommon/task`                       | 后台任务         |

**可选组件（根据业务需求）：**

| 组件      | 包路径                              | 说明         |
| --------- | ----------------------------------- | ------------ |
| Base(Biz) | `magicModulesRepo/modules/base/biz` | 业务逻辑基类 |
| Client    | `magicBase/pkg/client`              | 数据库客户端 |
| ORM       | `magicOrm`                          | ORM功能      |

## 2. 模块开发流程

### 2.1 新增模块步骤

**步骤1：确定模块位置**

- 核心模块：`internal/modules/kernel/{module_name}/`
- 业务模块：`internal/modules/blocks/{module_name}/`

**步骤2：创建目录结构**

```bash
internal/modules/kernel/
└── {module_name}/
    ├── module.go       # 模块入口（必需）
    ├── biz/           # 业务逻辑层
    │   ├── biz.go      # 业务主类
    │   └── *.go        # 其他业务文件
    ├── service/        # HTTP服务层
    │   ├── service.go  # 服务主类
    │   └── *.go        # 其他路由处理
    └── pkg/
        ├── common/     # 公共定义
        │   ├── const.go     # 常量定义
        │   ├── errors.go   # 错误定义
        │   └── result.go   # 结果定义
        └── models/     # 数据模型
            └── *.go
```

**步骤3：实现Module接口**

```go
package {module_name}

import (
    // magicCommon框架 - 必须
    cd "github.com/muidea/magicCommon/def"
    "github.com/muidea/magicCommon/event"
    "github.com/muidea/magicCommon/framework/plugin/initiator"
    "github.com/muidea/magicCommon/framework/plugin/module"
    "github.com/muidea/magicCommon/task"

    // 以下为可选导入，根据实际需求选择
    // 如果需要使用Persistence/RouteRegistry功能：
    // ipc "github.com/muidea/magicModulesRepo/initiators/persistence/pkg/common"
    // irc "github.com/muidea/magicModulesRepo/initiators/routeregistry/pkg/common"

    // 内部包
    "{module_path}/internal/modules/kernel/{module_name}/biz"
    "{module_path}/internal/modules/kernel/{module_name}/pkg/common"
    "{module_path}/internal/modules/kernel/{module_name}/service"
)

func init() {
    module.Register(New())
}

type {ModuleName} struct {
    bizPtr     *biz.{ModuleName}
    servicePtr *service.{ModuleName}
}

func New() *{ModuleName} {
    return &{ModuleName}{}
}

func (s *{ModuleName}) ID() string {
    return common.{ModuleName}Module
}

func (s *{ModuleName}) Setup(eventHub event.Hub, backgroundRoutine task.BackgroundRoutine) (err *cd.Error) {
    // 如果需要使用magicModulesRepo的Initiator功能：
    // var persistenceHelperVal ipc.PersistenceHelper
    // persistenceHelperVal, persistenceHelperErr := initiator.GetEntity(ipc.PersistenceInitiator, persistenceHelperVal)
    // if persistenceHelperErr != nil {
    //     err = persistenceHelperErr
    //     return
    // }

    // var routeRegistryHelperVal irc.RouteRegistryHelper
    // routeRegistryHelperVal, routeRegistryHelperErr := initiator.GetEntity(irc.RouteRegistryInitiator, routeRegistryHelperVal)
    // if routeRegistryHelperErr != nil {
    //     err = routeRegistryHelperErr
    //     return
    // }

    // 初始化biz和service（根据实际需要传递参数）
    s.bizPtr = biz.New(eventHub, backgroundRoutine)
    s.servicePtr = service.New(s.bizPtr)

    return nil
}

func (s *{ModuleName}) Run() (err *cd.Error) {
    err = s.bizPtr.Initialize()
    if err != nil {
        return
    }

    s.servicePtr.RegisterRoute()
    return
}

func (s *{ModuleName}) Teardown() {
}
```

**步骤4：实现Biz层**

```go
package biz

import (
    "context"

    "log/slog"

    // magicCommon框架 - 必须
    cd "github.com/muidea/magicCommon/def"
    "github.com/muidea/magicCommon/event"
    "github.com/muidea/magicCommon/task"

    // 以下为可选导入，根据实际需求选择
    // 如果需要使用magicBase：
    // "github.com/muidea/magicBase/pkg/client"
    // 如果需要使用magicModulesRepo的base biz：
    // "github.com/muidea/magicModulesRepo/modules/base/biz"

    // 内部包
    "{module_path}/internal/modules/kernel/{module_name}/pkg/common"
)

type {ModuleName} struct {
    // 如果使用magicModulesRepo的base biz：
    // biz.Base
    // baseClient client.Client
}

func New(
    eventHub event.Hub,
    backgroundRoutine task.BackgroundRoutine,
    // 如果需要使用magicBase：
    // baseClient client.Client,
) *{ModuleName} {
    ptr := &{ModuleName}{
        // 如果使用magicModulesRepo的base biz：
        // Base: biz.New(common.{ModuleName}Module, eventHub, backgroundRoutine),
    }

    // 注册事件处理
    // ptr.SubscribeFunc(common.{ActionName}, ptr.handle{ActionName})

    return ptr
}

func (s *{ModuleName}) Initialize() (err *cd.Error) {
    // 初始化逻辑
    return nil
}

func (s *{ModuleName}) handle{ActionName}(ctx context.Context, ... ) (ret interface{}, err *cd.Error) {
    // 事件处理逻辑
    return
}
```

**步骤5：实现Service层**

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

    // 以下为可选导入，根据实际需求选择
    // 如果需要使用magicEngine的HTTP引擎：
    // engine "github.com/muidea/magicEngine/http"
    // 如果需要使用magicBase：
    // bc "github.com/muidea/magicBase/pkg/common"
    // "github.com/muidea/magicBase/pkg/toolkit"

    // 内部包
    "{module_path}/internal/modules/kernel/{module_name}/biz"
    "{module_path}/internal/modules/kernel/{module_name}/pkg/common"
)

type {ModuleName} struct {
    // 如果使用magicBase：
    // roleRouteRegistry toolkit.RoleRouteRegistry
    bizPtr *biz.{ModuleName}
}

func New(bizPtr *biz.{ModuleName}) *{ModuleName} {
    // 如果使用magicBase：
    // roleRouteRegistry toolkit.RoleRouteRegistry,
    return &{ModuleName}{
        // roleRouteRegistry: roleRouteRegistry,
        bizPtr: bizPtr,
    }
}

func (s *{ModuleName}) RegisterRoute() {
    // 如果使用magicBase的路由注册：
    // s.roleRouteRegistry.AddPrivilegeHandler(common.{EndpointName}, engine.GET, bc.ReadPermission, s.handler)
}

func (s *{ModuleName}) handler(ctx context.Context, res http.ResponseWriter, req *http.Request) {
    result := &common.{ResultType}{Result: *cd.NewResult()}
    defer fn.PackageHTTPResponse(res, result)

    filter := bc.NewFilter()
    filter.Decode(req)

    valList, valPagination, valErr := s.bizPtr.{BizMethod}(ctx, filter)
    if valErr != nil {
        result.Error = valErr
        return
    }

    result.Pagination = valPagination
    result.Values = valList
    result.Error = nil
}
```

### 2.2 新增应用步骤

**步骤1：创建应用目录**

```bash
application/
└── magic{AppName}/
    ├── cmd/
    │   └── main.go
    └── docker/
        └── Dockerfile
```

**步骤2：编写main.go**

```go
package main

import (
    "log"

    "github.com/muidea/magicCommon/framework/application"
    "github.com/muidea/magicCommon/framework/service"

    "{module_path}/internal/config"
    _ "{module_path}/internal/modules/kernel/base"
    _ "{module_path}/internal/modules/kernel/panel"
    // 导入其他模块
)

func main() {
    log.Println("Starting magic{AppName}...")

    cfg := config.Load()

    app := application.New(cfg)
    service.Setup(app)
    app.Execute()
}
```

**步骤3：更新go.mod**

如果新应用需要新依赖，在项目根目录的go.mod中添加replace指令：

```go
replace (
    // 根据实际需要的模块添加
    github.com/muidea/magicCommon => ../magicCommon
    // github.com/muidea/magicBase => ../magicBase
    // github.com/muidea/magicModulesRepo => ../magicModulesRepo
)
```

## 3. 框架使用规范

### 3.1 Module接口

所有模块必须实现以下接口：

```go
type Module interface {
    ID() string                          // 模块唯一标识
    Setup(eventHub event.Hub, backgroundRoutine task.BackgroundRoutine) *cd.Error  // 初始化
    Run() *cd.Error                      // 启动
    Teardown()                           // 停止
}
```

### 3.2 Initiator依赖获取

框架通过Initiator提供依赖服务：

```go
// 获取Persistence Helper
var persistenceHelperVal ipc.PersistenceHelper
persistenceHelperVal, err := initiator.GetEntity(ipc.PersistenceInitiator, persistenceHelperVal)

// 获取Route Registry
var routeRegistryHelperVal irc.RouteRegistryHelper
routeRegistryHelperVal, err := initiator.GetEntity(irc.RouteRegistryInitiator, routeRegistryHelperVal)
```

常用Initiator：

- `ipc.PersistenceInitiator` - 数据库持久化
- `irc.RouteRegistryInitiator` - 路由注册

### 3.3 Event事件机制

Biz层通过事件进行通信：

```go
// 订阅事件
ptr.SubscribeFunc(common.{EventName}, ptr.handle{EventName})

// 发送事件
queryEvent := event.NewEventWithContext(mbcc.QueryEntity, s.ID(), mbcc.CasModule, header, ctx, id)
queryResult := s.SendEvent(queryEvent)
ret, err := event.GetAs[*bc.AuthEntity](queryResult)

// 发布事件
s.PostEvent(event.NewEvent(eid, common.PanelModule, imkbc.BaseModule, headers, logPtr))
```

### 3.4 路由注册模式

Service层注册HTTP路由：

```go
func (s *{ModuleName}) RegisterRoute() {
    // 公开路由
    s.roleRouteRegistry.AddHandler(common.{RouteName}, engine.GET, s.handler)

    // 权限路由
    s.roleRouteRegistry.AddPrivilegeHandler(common.{RouteName}, engine.GET, bc.ReadPermission, s.handler)
    s.roleRouteRegistry.AddPrivilegeHandler(common.{RouteName}, engine.POST, bc.WritePermission, s.handler)
    s.roleRouteRegistry.AddPrivilegeHandler(common.{RouteName}, engine.DELETE, bc.DeletePermission, s.handler)
    s.roleRouteRegistry.AddPrivilegeHandler(common.{RouteName}, engine.PUT, bc.WritePermission, s.handler)
}
```

权限级别：

- `bc.ReadPermission` - 读权限
- `bc.WritePermission` - 写权限
- `bc.DeletePermission` - 删除权限

## 4. 代码规范

### 4.1 命名规范

| 类型   | 规则       | 示例                   |
| ------ | ---------- | ---------------------- |
| 模块名 | 小写字母   | panel, runner, gateway |
| 包名   | 小写字母   | biz, service, pkg      |
| 结构体 | PascalCase | Panel, PanelService    |
| 变量   | camelCase  | baseClient, bizPtr     |
| 常量   | PascalCase | PanelModule            |

### 4.2 导入顺序（Import Grouping）

本项目采用严格的import分组规范，**同一库的不同组件必须按路径字母顺序排序**，不同库之间用空行分隔。

**分组顺序（自上而下）：**

1. **标准库**（Go标准包）
2. **第三方包**（外部依赖库）
   - 同一库的不同组件按路径字母顺序排序
   - 不同库之间用**一个空行**分隔
3. **本项目内部包**（当前仓库的代码）
   - 必须放置在最底端

**示例：**

```go
import (
	"context"
	"fmt"
	"strings"

	cd "github.com/example/magicCommon/def"
	"github.com/example/magicCommon/event"
	"github.com/example/magicCommon/task"

	bc "github.com/example/magicBase/pkg/common"

	"github.com/example/magicModulesRepo/modules/base/biz"
	mbcc "github.com/example/magicModulesRepo/modules/blocks/cas/pkg/common"
	mbtc "github.com/example/magicModulesRepo/modules/blocks/totalizator/pkg/common"

	imkpc "github.com/example/project/internal/modules/kernel/panel/pkg/common"
	imkpm "github.com/example/project/internal/modules/kernel/panel/pkg/models"
	"github.com/example/project/internal/modules/kernel/portal/config"
	"github.com/example/project/internal/modules/kernel/portal/pkg/common"
)
```

**分组说明：**

| 分组   | 示例                                                                                 | 规则                   |
| ------ | ------------------------------------------------------------------------------------ | ---------------------- |
| 标准库 | `"context"`, `"fmt"`                                                                 | 按字母顺序             |
| 同一库 | `cd "github.com/example/magicCommon/def"` + `"github.com/example/magicCommon/event"` | 按路径字母顺序排序     |
| 不同库 | `magicCommon` → 空行 → `magicBase` → 空行 → `magicModulesRepo`                       | 库之间空行分隔         |
| 本项目 | `github.com/example/project/...`                                                     | 放在最底端，按路径排序 |

**关键原则：**

- **必须排序**：同一库下的多个import必须按路径字母顺序排列
- **必须分组**：不同库之间必须用空行分隔
- **本项目最末**：内部包必须放在import块的最底部

### 4.3 错误处理与日志规范

#### 错误处理

本项目遵循现代Go错误处理规范，优先使用Go 1.13+的错误包装和多错误聚合。

```go
// 使用框架错误
err = cd.NewError(cd.IllegalParam, "invalid parameter")

// 错误包装（保留错误链）
if err != nil {
    return fmt.Errorf("operation failed: %w", err)
}

// 多错误聚合（Go 1.20+）
var errs []error
// ... collect errors
return errors.Join(errs...)

// NEVER ignore errors
// BAD: _ = someFunction()
// GOOD: if err := someFunction(); err != nil { ... }
```

#### 日志规范

使用结构化日志 `slog`（Go 1.21+）进行日志记录。

```go
import "log/slog"

// 在业务代码中使用slog
func (s *{ModuleName}) DoSomething(ctx context.Context) {
    slog.Info("doing something", "module", s.ID(), "timestamp", time.Now())

    slog.Debug("debug info", "key", value)
    slog.Warn("warning message", "error", err)
    slog.Error("error occurred", "error", err)
}
```

**日志原则：**

- 使用 `slog` 替代 `log.Printf`
- 包含上下文信息（module名、operation名等）
- 错误日志应包含error字段

### 4.4 编码原则

本项目遵循以下编码原则以保证代码质量和可维护性。

#### DRY原则（Don't Repeat Yourself）

当代码逻辑重复出现**3次及以上**时，必须进行重构：

```go
// BAD: 重复逻辑
if user.Status == "active" {
    notify(user)
}
if order.Status == "active" {
    notify(order)
}
if product.Status == "active" {
    notify(product)
}

// GOOD: 提取为通用函数
func notifyIfActive(entity Entity) {
    if entity.GetStatus() == "active" {
        notify(entity)
    }
}
```

#### Functional Options模式

当构造函数参数超过**3个**时，优先使用Functional Options模式：

```go
type Server struct {
    host string
    port int
    timeout time.Duration
    maxConn int
}

type ServerOption func(*Server)

func WithHost(host string) ServerOption {
    return func(s *Server) { s.host = host }
}

func WithTimeout(timeout time.Duration) ServerOption {
    return func(s *Server) { s.timeout = timeout }
}

func NewServer(opts ...ServerOption) *Server {
    s := &Server{host: "localhost", port: 8080}
    for _, opt := range opts {
        opt(s)
    }
    return s
}
```

#### 泛型使用

当多个类型使用相同逻辑时，使用泛型减少重复：

```go
// BAD: 重复代码
func FindUser(users []User, id string) *User {
    for _, u := range users {
        if u.ID == id {
            return &u
        }
    }
    return nil
}

func FindOrder(orders []Order, id string) *Order {
    for _, o := range orders {
        if o.ID == id {
            return &o
        }
    }
    return nil
}

// GOOD: 使用泛型
func Find[T any](items []T, id string, getID func(T) string) *T {
    for _, item := range items {
        if getID(item) == id {
            return &item
        }
    }
    return nil
}
```

#### Context透传

所有IO操作必须透传 `context.Context`：

```go
// GOOD: 透传context
func (s *{ModuleName}) QueryData(ctx context.Context, id string) (*Data, error) {
    return s.db.QueryContext(ctx, "SELECT ... WHERE id = ?", id)
}

// BAD: 不透传context
func (s *{ModuleName}) QueryData(id string) (*Data, error) {
    return s.db.Query("SELECT ... WHERE id = ?", id)
}
```

### 4.5 重构安全规范

在进行代码重构时，必须遵循以下安全规范以确保业务逻辑不被破坏。

#### 重构前检查

1. **Git状态检查**：开始重构前执行 `git status`，确保所有改动已提交
2. **分支建议**：大规模重构前建议创建 `refactor/` 分支
3. **测试覆盖**：确保关键路径有测试覆盖，若无测试先补齐

#### 重构原则

1. **小步原子化**：每次commit只解决一个逻辑问题
2. **逻辑完整性**：重构前后业务行为必须一致
3. **渐进式改进**：优先小范围重构，避免大规模重写

#### 禁用行为

- **禁止过度抽象**：不为抽象而抽象，拒绝过度工程化
- **禁止省略Context**：未透传context.Context的情况下重构IO调用
- **禁止破坏性变更**：不改变公开接口的语义

#### 重构工作流

1. **分析识别**：识别代码异味（Code Smells）
2. **方案设计**：制定重构方案及影响评估
3. **实施改动**：执行重构，遵循Import分组规范
4. **验证测试**：运行测试确保功能正常
5. **质量检查**：执行 `make lint` 和 `go vet`

### 5.1 架构说明

本项目采用**单仓库Go Module架构**，在一个Git仓库中管理多个服务和多个模块（详见1.1目录结构）。

### 5.2 go.mod使用说明

项目go.mod的详细说明见 **1.3 go.mod示例**。

### 5.3 replace指令说明

`replace`指令用于将远程依赖替换为本地仓库。**此指令是可选的**：

```go
replace (
    // 格式: 模块路径 => 本地路径
    github.com/muidea/magicCommon => ../magicCommon
)
```

**使用场景：**

- 本地开发调试时使用本地代码
- 避免发布到Go proxy

**注意：**

- 发布到生产环境时建议删除replace指令，使用正式的版本号
- 如果直接使用远程正式版本（如v1.5.0），无需使用replace

### 5.4 新增依赖模块

当需要新增对magicCommon相关模块的依赖时，根据 **1.3 go.mod示例** 中的说明，在go.mod中添加相应的replace和require语句，然后执行：

```bash
go mod tidy
```

## 6. 构建与测试

### 6.1 构建命令

```bash
# 构建所有应用
make build

# 构建单个应用（根据实际服务名）
make service-a
make service-b
```

### 6.2 测试命令

```bash
# 运行所有测试
go test ./...

# 运行特定包测试
go test ./internal/modules/kernel/panel/biz

# 运行单个测试
go test -v -run Test{TestName} ./...

# 带覆盖率
go test -cover ./...
```

### 6.3 代码质量

```bash
# 格式化代码
go fmt ./...

# 静态分析
go vet ./...

# 漏洞扫描
govulncheck ./...

# 完整质量检查（推荐）
./.agents/skills/go-refactor-pro/scripts/quality-check.sh

# 使用Makefile
make lint             # 综合lint检查
make vet              # Go vet检查
make fmt              # 代码格式化
```

**质量检查说明：**

| 命令               | 说明                   |
| ------------------ | ---------------------- |
| `go fmt`           | 格式化代码             |
| `go vet`           | 静态分析               |
| `govulncheck`      | 漏洞扫描               |
| `quality-check.sh` | 综合检查（推荐）       |
| `make lint`        | Makefile封装的lint检查 |

## 7. 参考资料

详细模块结构和模板请参考：

- [MODULE_STRUCTURE.md](references/MODULE_STRUCTURE.md)
- [TEMPLATES.md](references/TEMPLATES.md)

创建模块辅助脚本：

- [create-module.sh](scripts/create-module.sh)

详细模块结构和模板请参考：

- [MODULE_STRUCTURE.md](references/MODULE_STRUCTURE.md)
- [TEMPLATES.md](references/TEMPLATES.md)
- [EVENT_USAGE.md](references/EVENT_USAGE.md) - Event事件机制使用详解
