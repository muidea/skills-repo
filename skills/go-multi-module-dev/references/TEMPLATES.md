# Code Templates Reference

本文档提供magicCommon/framework框架下的代码模板参考。

> **注意**：以下模板仅供参考。magicBase和magicModulesRepo是可选依赖，请根据实际业务需求选择使用。

## 1. Module模板

### 1.1 标准module.go

```go
package module_name

import (
	"log/slog"

	// magicCommon框架 - 必须
	cd "github.com/muidea/magicCommon/def"
	"github.com/muidea/magicCommon/event"
	"github.com/muidea/magicCommon/framework/plugin/initiator"
	"github.com/muidea/magicCommon/framework/plugin/module"
	"github.com/muidea/magicCommon/task"

	// 可选导入，根据实际需求选择
	// 如果需要使用Persistence/RouteRegistry功能：
	// ipc "github.com/muidea/magicModulesRepo/initiators/persistence/pkg/common"
	// irc "github.com/muidea/magicModulesRepo/initiators/routeregistry/pkg/common"

	// 内部包
	"{module_path}/internal/modules/kernel/module_name/biz"
	"{module_path}/internal/modules/kernel/module_name/pkg/common"
	"{module_path}/internal/modules/kernel/module_name/service"
)

func init() {
	module.Register(New())
}

type ModuleName struct {
	bizPtr     *biz.ModuleName
	servicePtr *service.ModuleName
}

func New() *ModuleName {
	return &ModuleName{}
}

func (s *ModuleName) ID() string {
	return common.ModuleNameModule
}

func (s *ModuleName) Setup(eventHub event.Hub, backgroundRoutine task.BackgroundRoutine) (err *cd.Error) {
	var persistenceHelperVal ipc.PersistenceHelper
	persistenceHelperVal, persistenceHelperErr := initiator.GetEntity(ipc.PersistenceInitiator, persistenceHelperVal)
	if persistenceHelperErr != nil {
		err = persistenceHelperErr
		slog.Error("ModuleName setup failed, initiator.GetEntity error", "error", persistenceHelperErr.Error())
		return
	}

	var routeRegistryHelperVal irc.RouteRegistryHelper
	routeRegistryHelperVal, routeRegistryHelperErr := initiator.GetEntity(irc.RouteRegistryInitiator, routeRegistryHelperVal)
	if routeRegistryHelperErr != nil {
		err = routeRegistryHelperErr
		slog.Error("ModuleName setup failed, initiator.GetEntity error", "error", routeRegistryHelperErr.Error())
		return
	}

	s.bizPtr = biz.New(persistenceHelperVal.GetBaseClient(), eventHub, backgroundRoutine)

	s.servicePtr = service.New(routeRegistryHelperVal.GetRoleRouteRegistry(), s.bizPtr)

	return nil
}

func (s *ModuleName) Run() (err *cd.Error) {
	err = s.bizPtr.Initialize()
	if err != nil {
		return
	}

	s.servicePtr.RegisterRoute()
	return
}

func (s *ModuleName) Teardown() {
}
```

## 2. Biz层模板

### 2.1 标准biz.go

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
	"{module_path}/internal/modules/kernel/module_name/pkg/common"
	"{module_path}/internal/modules/kernel/module_name/pkg/models"
)

type ModuleName struct {
	// 如果使用magicModulesRepo的base biz：
	// biz.Base
	// baseClient client.Client
	// entityPtr  *bc.EntityView
}

// 如果使用magicModulesRepo的base biz：
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

	ptr.SubscribeFunc(common.EventName, ptr.handleEvent)

	return ptr
}
*/

func New(
	eventHub event.Hub,
	backgroundRoutine task.BackgroundRoutine,
) *ModuleName {
	ptr := &ModuleName{
		// 初始化逻辑
	}
	return ptr
}

func (s *ModuleName) Initialize() (err *cd.Error) {
	// 初始化逻辑
	return nil
}
		err = entityErr
		return
	}

	for _, val := range entityList {
		if val.GetPkgKey() == models.GetEntityPkgKey() {
			s.entityPtr = val
			break
		}
	}

	return nil
}

func (s *ModuleName) handleEvent(ctx context.Context, header *event.Values, param interface{}) (ret interface{}, err *cd.Error) {
	return
}

func (s *ModuleName) FilterEntity(ctx context.Context, filter *bc.Filter) (ret []*models.Entity, total int64, err *cd.Error) {
	ret, total, err = s.baseClient.FilterEntityWithNamespace(filter, common.ModuleNameModule)
	return
}

func (s *ModuleName) CreateEntity(ctx context.Context, entity *models.Entity) (ret *models.Entity, err *cd.Error) {
	ret, err = s.baseClient.CreateEntityWithNamespace(entity, common.ModuleNameModule)
	return
}

func (s *ModuleName) UpdateEntity(ctx context.Context, id int64, entity *models.Entity) (ret *models.Entity, err *cd.Error) {
	ret, err = s.baseClient.UpdateEntityWithNamespace(id, entity, common.ModuleNameModule)
	return
}

func (s *ModuleName) DeleteEntity(ctx context.Context, id int64) (err *cd.Error) {
	err = s.baseClient.DeleteEntityWithNamespace(id, common.ModuleNameModule)
	return
}

func (s *ModuleName) QueryEntity(ctx context.Context, id int64) (ret *models.Entity, err *cd.Error) {
	ret, err = s.baseClient.QueryEntityWithNamespace(id, common.ModuleNameModule)
	return
}
```

## 3. Service层模板

### 3.1 标准service.go

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
	"{module_path}/internal/modules/kernel/module_name/biz"
	"{module_path}/internal/modules/kernel/module_name/pkg/common"
	"{module_path}/internal/modules/kernel/module_name/pkg/models"
)

type ModuleName struct {
	// 如果使用magicBase：
	// roleRouteRegistry toolkit.RoleRouteRegistry
	bizPtr *biz.ModuleName
}

func New(roleRouteRegistry toolkit.RoleRouteRegistry, bizPtr *biz.ModuleName) *ModuleName {
	return &ModuleName{
		roleRouteRegistry: roleRouteRegistry,
		bizPtr:            bizPtr,
	}
}

func (s *ModuleName) getCurrentNamespace(ctx context.Context, req *http.Request) string {
	return toolkit.CurrentNamespace(ctx, req)
}

func (s *ModuleName) getCurrentEntity(ctx context.Context) (ret *bc.AuthEntity, err *cd.Error) {
	authSession, ok := ctx.Value(bc.ContextAuthSession{}).(session.Session)
	if !ok {
		err = cd.NewError(cd.Unexpected, "invalid session type")
		return
	}

	entityVal, ok := authSession.GetOption(bc.AuthEntity{}.Key())
	if !ok {
		err = cd.NewError(cd.InvalidAuthority, "invalid permission, please login first")
		return
	}

	ret = entityVal.(*bc.AuthEntity)
	return
}

func (s *ModuleName) RegisterRoute() {
	s.roleRouteRegistry.AddPrivilegeHandler(common.FilterEntity, engine.GET, bc.ReadPermission, s.filterEntity)
	s.roleRouteRegistry.AddPrivilegeHandler(common.QueryEntity, engine.GET, bc.ReadPermission, s.queryEntity)
	s.roleRouteRegistry.AddPrivilegeHandler(common.CreateEntity, engine.POST, bc.WritePermission, s.createEntity)
	s.roleRouteRegistry.AddPrivilegeHandler(common.UpdateEntity, engine.PUT, bc.WritePermission, s.updateEntity)
	s.roleRouteRegistry.AddPrivilegeHandler(common.DeleteEntity, engine.DELETE, bc.DeletePermission, s.deleteEntity)
}

func (s *ModuleName) filterEntity(ctx context.Context, res http.ResponseWriter, req *http.Request) {
	result := &common.FilterResult{Result: *cd.NewResult()}
	defer fn.PackageHTTPResponse(res, result)

	filter := bc.NewFilter()
	filter.Decode(req)

	valList, valPagination, valErr := s.bizPtr.FilterEntity(ctx, filter)
	if valErr != nil {
		result.Error = valErr
		return
	}

	result.Values = valList
	result.Pagination = valPagination
	result.Error = nil
}

func (s *ModuleName) queryEntity(ctx context.Context, res http.ResponseWriter, req *http.Request) {
	result := &common.Result{Result: *cd.NewResult()}
	defer fn.PackageHTTPResponse(res, result)

	id, err := strconv.ParseInt(req.PathValue("id"), 10, 64)
	if err != nil {
		result.Error = cd.NewError(cd.IllegalParam, "invalid entity id")
		return
	}

	val, valErr := s.bizPtr.QueryEntity(ctx, id)
	if valErr != nil {
		result.Error = valErr
		return
	}

	result.Value = val
	result.Error = nil
}

func (s *ModuleName) createEntity(ctx context.Context, res http.ResponseWriter, req *http.Request) {
	result := &common.Result{Result: *cd.NewResult()}
	defer fn.PackageHTTPResponse(res, result)

	param := &models.Entity{}
	err := fn.ParseJSONBody(req, nil, param)
	if err != nil {
		result.Error = cd.NewError(cd.IllegalParam, "invalid param")
		return
	}

	val, valErr := s.bizPtr.CreateEntity(ctx, param)
	if valErr != nil {
		result.Error = valErr
		return
	}

	result.Value = val
	result.Error = nil
}

func (s *ModuleName) updateEntity(ctx context.Context, res http.ResponseWriter, req *http.Request) {
	result := &common.Result{Result: *cd.NewResult()}
	defer fn.PackageHTTPResponse(res, result)

	id, err := strconv.ParseInt(req.PathValue("id"), 10, 64)
	if err != nil {
		result.Error = cd.NewError(cd.IllegalParam, "invalid entity id")
		return
	}

	param := &models.Entity{}
	err = fn.ParseJSONBody(req, nil, param)
	if err != nil {
		result.Error = cd.NewError(cd.IllegalParam, "invalid param")
		return
	}

	val, valErr := s.bizPtr.UpdateEntity(ctx, id, param)
	if valErr != nil {
		result.Error = valErr
		return
	}

	result.Value = val
	result.Error = nil
}

func (s *ModuleName) deleteEntity(ctx context.Context, res http.ResponseWriter, req *http.Request) {
	result := &common.Result{Result: *cd.NewResult()}
	defer fn.PackageHTTPResponse(res, result)

	id, err := strconv.ParseInt(req.PathValue("id"), 10, 64)
	if err != nil {
		result.Error = cd.NewError(cd.IllegalParam, "invalid entity id")
		return
	}

	valErr := s.bizPtr.DeleteEntity(ctx, id)
	if valErr != nil {
		result.Error = valErr
		return
	}

	result.Error = nil
}
```

## 4. Common层模板

### 4.1 const.go

```go
package common

const (
	ModuleNameModule = "module_name"

	FilterEntity   = "ModuleName/FilterEntity"
	QueryEntity    = "ModuleName/QueryEntity"
	CreateEntity   = "ModuleName/CreateEntity"
	UpdateEntity   = "ModuleName/UpdateEntity"
	DeleteEntity   = "ModuleName/DeleteEntity"
)
```

### 4.2 result.go

```go
package common

import (
	bc "github.com/muidea/magicBase/pkg/common"
	cd "github.com/muidea/magicCommon/def"
)

type Result struct {
	cd.Result
	Value interface{} `json:"value"`
}

type FilterResult struct {
	cd.Result
	Values     interface{}    `json:"values"`
	Pagination *bc.Pagination `json:"pagination"`
}

type CreateResult struct {
	cd.Result
	Value interface{} `json:"value"`
}

type UpdateResult struct {
	cd.Result
	Value interface{} `json:"value"`
}

type DeleteResult struct {
	cd.Result
}
```

## 5. Models层模板

### 5.1 model.go

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
	Namespace string    `json:"namespace"`
	CreateAt  time.Time `json:"createAt"`
	UpdateAt  time.Time `json:"updateAt"`
}

func (s *Entity) GetPkgKey() string {
	return GetEntityPkgKey()
}

func GetEntityPkgKey() string {
	return "module_name/entity"
}

func (s *Entity) GetView() *Entity {
	return s
}
```

### 5.2 dto.go

```go
package models

type CreateParam struct {
	Name   string `json:"name"`
	Status int    `json:"status"`
}

type UpdateParam struct {
	Name   string `json:"name"`
	Status int    `json:"status"`
}

type Filter struct {
	bc.Filter
}
```

## 6. Application模板

### 6.1 main.go

```go
package main

import (
	"log"

	"github.com/muidea/magicCommon/framework/application"
	"github.com/muidea/magicCommon/framework/service"

	// 内部包 - 请将 {module_path} 替换为实际的项目module路径
	"{module_path}/internal/config"
	_ "{module_path}/internal/modules/kernel/base"
	_ "{module_path}/internal/modules/kernel/panel"
	_ "{module_path}/internal/modules/kernel/portal"
	_ "{module_path}/internal/modules/kernel/runner"
	_ "{module_path}/internal/modules/kernel/gateway"
	_ "{module_path}/internal/modules/kernel/mcp"
	_ "{module_path}/internal/modules/blocks/installer"
	_ "{module_path}/internal/modules/blocks/compose"
	_ "{module_path}/internal/modules/blocks/database"
)

func main() {
	log.Println("Starting {app_name}...")

	cfg := config.Load()

	app := application.New(cfg)
	service.Setup(app)
	app.Execute()
}
```

## 7. 测试模板

### 7.1 biz_test.go

```go
package biz

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestModuleName_Initialize(t *testing.T) {
	bizPtr := New(nil, nil, nil)
	err := bizPtr.Initialize()
	assert.NoError(t, err)
}

func TestModuleName_FilterEntity(t *testing.T) {
	ctx := context.Background()
	bizPtr := New(nil, nil, nil)

	result, total, err := bizPtr.FilterEntity(ctx, nil)
	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.GreaterOrEqual(t, total, int64(0))
}
```

## 8. 导入速查表

```go
import (
	// 标准库
	"context"
	"log/slog"
	"net/http"
	"strconv"

	// magicCommon框架 - 必须
	cd "github.com/muidea/magicCommon/def"
	fn "github.com/muidea/magicCommon/foundation/net"
	"github.com/muidea/magicCommon/event"
	"github.com/muidea/magicCommon/session"
	"github.com/muidea/magicCommon/task"

	// magicCommon/framework
	"github.com/muidea/magicCommon/framework/plugin/initiator"
	"github.com/muidea/magicCommon/framework/plugin/module"

	// 可选导入，根据实际需求选择
	// magicEngine:
	// engine "github.com/muidea/magicEngine/http"

	// magicBase:
	// "github.com/muidea/magicBase/pkg/client"
	// bc "github.com/muidea/magicBase/pkg/common"
	// "github.com/muidea/magicBase/pkg/toolkit"

	// magicModulesRepo:
	// "github.com/muidea/magicModulesRepo/modules/base/biz"
	// ipc "github.com/muidea/magicModulesRepo/initiators/persistence/pkg/common"
	// irc "github.com/muidea/magicModulesRepo/initiators/routeregistry/pkg/common"

	// 内部包
	"{module_path}/internal/modules/kernel/module_name/biz"
	"{module_path}/internal/modules/kernel/module_name/pkg/common"
	"{module_path}/internal/modules/kernel/module_name/pkg/models"
)
```

	// magicModulesRepo
	"github.com/muidea/magicModulesRepo/modules/base/biz"
	ipc "github.com/muidea/magicModulesRepo/initiators/persistence/pkg/common"
	irc "github.com/muidea/magicModulesRepo/initiators/routeregistry/pkg/common"

	// 内部包
	"{module_path}/internal/modules/kernel/module_name/biz"
	"{module_path}/internal/modules/kernel/module_name/pkg/common"
	"{module_path}/internal/modules/kernel/module_name/pkg/models"
)
```
