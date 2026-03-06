#!/bin/bash

# go-multi-module-dev 辅助脚本 - 创建新模块
# 用法: ./create-module.sh [module_name] [module_type]
# module_type: kernel | blocks (默认: kernel)
#
# 注意: 此脚本生成最基础的模块模板
# magicBase和magicModulesRepo是可选依赖，请根据实际需求添加

set -e

MODULE_NAME="${1:-}"
MODULE_TYPE="${2:-kernel}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [ -z "$MODULE_NAME" ]; then
    echo "用法: $0 <module_name> [kernel|blocks]"
    echo "示例: $0 mymodule kernel"
    exit 1
fi

# 验证module_type
if [ "$MODULE_TYPE" != "kernel" ] && [ "$MODULE_TYPE" != "blocks" ]; then
    echo "错误: module_type 必须是 'kernel' 或 'blocks'"
    exit 1
fi

MODULE_DIR="$PROJECT_ROOT/internal/modules/$MODULE_TYPE/$MODULE_NAME"

# 检查模块是否已存在
if [ -d "$MODULE_DIR" ]; then
    echo "错误: 模块 '$MODULE_NAME' 已存在于 $MODULE_DIR"
    exit 1
fi

echo "创建新模块: $MODULE_NAME (类型: $MODULE_TYPE)"

# 创建目录结构
mkdir -p "$MODULE_DIR/biz"
mkdir -p "$MODULE_DIR/service"
mkdir -p "$MODULE_DIR/pkg/common"
mkdir -p "$MODULE_DIR/pkg/models"

# 转换模块名为PascalCase
MODULE_PASCAL=$(echo "$MODULE_NAME" | sed 's/^./\U&/' | sed 's/-[a-z]/\U&/g' | tr -d '-')

# 创建module.go
cat > "$MODULE_DIR/module.go" <<'EOF'
package ${MODULE_NAME}

import (
	"log/slog"

	// magicCommon框架 - 必须
	cd "github.com/muidea/magicCommon/def"
	"github.com/muidea/magicCommon/event"
	"github.com/muidea/magicCommon/framework/plugin/module"
	"github.com/muidea/magicCommon/task"

	// 以下为可选导入，根据实际需求选择
	// 如果需要使用Initiator功能：
	// "github.com/muidea/magicCommon/framework/plugin/initiator"
	// ipc "github.com/muidea/magicModulesRepo/initiators/persistence/pkg/common"
	// irc "github.com/muidea/magicModulesRepo/initiators/routeregistry/pkg/common"

	// 内部包 - 请将 {module_path} 替换为实际的项目module路径
	"github.com/{module_path}/internal/modules/${MODULE_TYPE}/${MODULE_NAME}/biz"
	"github.com/{module_path}/internal/modules/${MODULE_TYPE}/${MODULE_NAME}/pkg/common"
	"github.com/{module_path}/internal/modules/${MODULE_TYPE}/${MODULE_NAME}/service"
)

func init() {
	module.Register(New())
}

type ${MODULE_PASCAL} struct {
	bizPtr     *biz.${MODULE_PASCAL}
	servicePtr *service.${MODULE_PASCAL}
}

func New() *${MODULE_PASCAL} {
	return &${MODULE_PASCAL}{}
}

func (s *${MODULE_PASCAL}) ID() string {
	return common.${MODULE_PASCAL}Module
}

func (s *${MODULE_PASCAL}) Setup(eventHub event.Hub, backgroundRoutine task.BackgroundRoutine) (err *cd.Error) {
	// 如果需要使用magicModulesRepo的Initiator功能：
	// var persistenceHelperVal ipc.PersistenceHelper
	// persistenceHelperVal, persistenceHelperErr := initiator.GetEntity(ipc.PersistenceInitiator, persistenceHelperVal)
	// if persistenceHelperErr != nil {
	//     err = persistenceHelperErr
	//     slog.Error("${MODULE_PASCAL} setup failed", "error", persistenceHelperErr.Error())
	//     return
	// }

	// 初始化biz和service
	s.bizPtr = biz.New(eventHub, backgroundRoutine)
	s.servicePtr = service.New(s.bizPtr)

	return nil
}

func (s *${MODULE_PASCAL}) Run() (err *cd.Error) {
	err = s.bizPtr.Initialize()
	if err != nil {
		return
	}

	s.servicePtr.RegisterRoute()
	return
}

func (s *${MODULE_PASCAL}) Teardown() {
}
EOF

# 创建biz/biz.go
cat > "$MODULE_DIR/biz/biz.go" <<'EOF'
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
	"github.com/{module_path}/internal/modules/${MODULE_TYPE}/${MODULE_NAME}/pkg/common"
)

type ${MODULE_PASCAL} struct {
	// 如果使用magicModulesRepo的base biz：
	// biz.Base
	// baseClient client.Client
}

func New(
	eventHub event.Hub,
	backgroundRoutine task.BackgroundRoutine,
	// 如果需要使用magicBase：
	// baseClient client.Client,
) *${MODULE_PASCAL} {
	ptr := &${MODULE_PASCAL}{
		// 如果使用magicModulesRepo的base biz：
		// Base: biz.New(common.${MODULE_PASCAL}Module, eventHub, backgroundRoutine),
	}

	// 注册事件处理
	// ptr.SubscribeFunc(common.EventName, ptr.handleEvent)

	return ptr
}

func (s *${MODULE_PASCAL}) Initialize() (err *cd.Error) {
	slog.Info("${MODULE_PASCAL} initializing...")
	return nil
}

// 如果需要处理事件：
/*
func (s *${MODULE_PASCAL}) handleEvent(ctx context.Context, header *event.Values, param interface{}) (ret interface{}, err *cd.Error) {
	// 事件处理逻辑
	return
}
*/
EOF

# 创建service/service.go
cat > "$MODULE_DIR/service/service.go" <<'EOF'
package service

import (
	"context"
	"net/http"

	"log/slog"

	// magicCommon框架 - 必须
	cd "github.com/muidea/magicCommon/def"
	fn "github.com/muidea/magicCommon/foundation/net"

	// 以下为可选导入，根据实际需求选择
	// 如果需要使用magicEngine的HTTP引擎：
	// engine "github.com/muidea/magicEngine/http"
	// 如果需要使用magicBase：
	// bc "github.com/muidea/magicBase/pkg/common"
	// "github.com/muidea/magicBase/pkg/toolkit"

	// 内部包
	"github.com/{module_path}/internal/modules/${MODULE_TYPE}/${MODULE_NAME}/biz"
	"github.com/{module_path}/internal/modules/${MODULE_TYPE}/${MODULE_NAME}/pkg/common"
)

type ${MODULE_PASCAL} struct {
	// 如果使用magicBase：
	// roleRouteRegistry toolkit.RoleRouteRegistry
	bizPtr *biz.${MODULE_PASCAL}
}

func New(bizPtr *biz.${MODULE_PASCAL}) *${MODULE_PASCAL} {
	// 如果使用magicBase：
	// roleRouteRegistry toolkit.RoleRouteRegistry,
	return &${MODULE_PASCAL}{
		// roleRouteRegistry: roleRouteRegistry,
		bizPtr: bizPtr,
	}
}

func (s *${MODULE_PASCAL}) RegisterRoute() {
	slog.Info("${MODULE_PASCAL} registering routes...")
	// 如果使用magicBase的路由注册：
	// s.roleRouteRegistry.AddPrivilegeHandler(common.RouteName, engine.GET, bc.ReadPermission, s.handler)
}
EOF

# 创建pkg/common/const.go
cat > "$MODULE_DIR/pkg/common/const.go" <<EOF
package common

const (
	\${MODULE_PASCAL}Module = "${MODULE_NAME}"
)
EOF

echo "模块创建完成: $MODULE_DIR"
echo ""
echo "创建的文件:"
echo "  - $MODULE_DIR/module.go"
echo "  - $MODULE_DIR/biz/biz.go"
echo "  - $MODULE_DIR/service/service.go"
echo "  - $MODULE_DIR/pkg/common/const.go"
echo ""
echo "注意: {module_path} 占位符需要替换为实际的go.mod中定义的module路径"
echo "      magicBase和magicModulesRepo是可选依赖，请根据实际需求取消注释相关代码"
