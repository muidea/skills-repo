#!/bin/bash

set -euo pipefail

MODULE_NAME="${1:-}"
MODULE_TYPE="${2:-kernel}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$SKILL_DIR/../../.." && pwd)"

if [ -z "$MODULE_NAME" ]; then
    echo "usage: $0 <module_name> [kernel|blocks]"
    exit 1
fi

if [ "$MODULE_TYPE" != "kernel" ] && [ "$MODULE_TYPE" != "blocks" ]; then
    echo "error: module_type must be kernel or blocks"
    exit 1
fi

if ! command -v go >/dev/null 2>&1; then
    echo "error: go command not found"
    exit 1
fi

MODULE_PATH="$(cd "$PROJECT_ROOT" && go list -m -f '{{.Path}}')"
MODULE_DIR="$PROJECT_ROOT/internal/modules/$MODULE_TYPE/$MODULE_NAME"

if [ -d "$MODULE_DIR" ]; then
    echo "error: module already exists: $MODULE_DIR"
    exit 1
fi

to_pascal_case() {
    local input="$1"
    IFS='-_' read -r -a parts <<< "$input"
    local out=""
    for part in "${parts[@]}"; do
        [ -z "$part" ] && continue
        local first="${part:0:1}"
        local rest="${part:1}"
        out+="${first^^}${rest}"
    done
    echo "$out"
}

MODULE_PASCAL="$(to_pascal_case "$MODULE_NAME")"

mkdir -p "$MODULE_DIR/biz" "$MODULE_DIR/service" "$MODULE_DIR/pkg/common" "$MODULE_DIR/pkg/models"

cat > "$MODULE_DIR/module.go" <<EOF
package $MODULE_NAME

import (
    cd "github.com/muidea/magicCommon/def"
    "github.com/muidea/magicCommon/event"
    "github.com/muidea/magicCommon/framework/plugin/module"
    "github.com/muidea/magicCommon/task"

    "$MODULE_PATH/internal/modules/$MODULE_TYPE/$MODULE_NAME/biz"
    "$MODULE_PATH/internal/modules/$MODULE_TYPE/$MODULE_NAME/pkg/common"
    "$MODULE_PATH/internal/modules/$MODULE_TYPE/$MODULE_NAME/service"
)

func init() {
    module.Register(New())
}

type $MODULE_PASCAL struct {
    bizPtr     *biz.$MODULE_PASCAL
    servicePtr *service.$MODULE_PASCAL
}

func New() *$MODULE_PASCAL {
    return &$MODULE_PASCAL{}
}

func (s *$MODULE_PASCAL) ID() string {
    return common.${MODULE_PASCAL}Module
}

func (s *$MODULE_PASCAL) Setup(eventHub event.Hub, backgroundRoutine task.BackgroundRoutine) (err *cd.Error) {
    s.bizPtr = biz.New(eventHub, backgroundRoutine)
    s.servicePtr = service.New(s.bizPtr)
    return nil
}

func (s *$MODULE_PASCAL) Run() (err *cd.Error) {
    err = s.bizPtr.Initialize()
    if err != nil {
        return
    }
    s.servicePtr.RegisterRoute()
    return
}

func (s *$MODULE_PASCAL) Teardown() {}
EOF

cat > "$MODULE_DIR/biz/biz.go" <<EOF
package biz

import (
    cd "github.com/muidea/magicCommon/def"
    "github.com/muidea/magicCommon/event"
    "github.com/muidea/magicCommon/task"
)

type $MODULE_PASCAL struct {
    eventHub          event.Hub
    backgroundRoutine task.BackgroundRoutine
}

func New(eventHub event.Hub, backgroundRoutine task.BackgroundRoutine) *$MODULE_PASCAL {
    return &$MODULE_PASCAL{
        eventHub:          eventHub,
        backgroundRoutine: backgroundRoutine,
    }
}

func (s *$MODULE_PASCAL) Initialize() (err *cd.Error) {
    return nil
}
EOF

cat > "$MODULE_DIR/service/service.go" <<EOF
package service

import "$MODULE_PATH/internal/modules/$MODULE_TYPE/$MODULE_NAME/biz"

type $MODULE_PASCAL struct {
    bizPtr *biz.$MODULE_PASCAL
}

func New(bizPtr *biz.$MODULE_PASCAL) *$MODULE_PASCAL {
    return &$MODULE_PASCAL{bizPtr: bizPtr}
}

func (s *$MODULE_PASCAL) RegisterRoute() {}
EOF

cat > "$MODULE_DIR/pkg/common/const.go" <<EOF
package common

const (
    ${MODULE_PASCAL}Module = "$MODULE_NAME"
)
EOF

echo "created module: $MODULE_DIR"
echo "module path: $MODULE_PATH"
echo "next steps:"
echo "  1. add route registration in service/"
echo "  2. add models and common definitions"
echo "  3. add tests and docs"
