#!/bin/bash

set -euo pipefail

UNIT_NAME="${1:-}"
GROUP_PATH="${2:-shared}"
UNIT_ROOT="${3:-internal/modules}"
ENTRY_FILE="${4:-module.go}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$SKILL_DIR/../../.." && pwd)"

if [ -z "$UNIT_NAME" ]; then
    echo "usage: $0 <unit_name> [group_path] [unit_root] [entry_file]"
    exit 1
fi

if [[ "$ENTRY_FILE" != *.go ]]; then
    echo "error: entry_file must end with .go"
    exit 1
fi

if ! command -v go >/dev/null 2>&1; then
    echo "error: go command not found"
    exit 1
fi

trim_path() {
    local path="$1"
    path="${path#/}"
    path="${path%/}"
    echo "$path"
}

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

to_package_name() {
    local input="$1"
    input="${input//-/_}"
    echo "$input"
}

GROUP_PATH="$(trim_path "$GROUP_PATH")"
UNIT_ROOT="$(trim_path "$UNIT_ROOT")"
UNIT_PASCAL="$(to_pascal_case "$UNIT_NAME")"
PACKAGE_NAME="$(to_package_name "$UNIT_NAME")"
MODULE_PATH="$(cd "$PROJECT_ROOT" && go list -m -f '{{.Path}}')"

UNIT_DIR="$PROJECT_ROOT/$UNIT_ROOT"
IMPORT_ROOT="$MODULE_PATH/$UNIT_ROOT"

if [ -n "$GROUP_PATH" ]; then
    UNIT_DIR="$UNIT_DIR/$GROUP_PATH"
    IMPORT_ROOT="$IMPORT_ROOT/$GROUP_PATH"
fi

UNIT_DIR="$UNIT_DIR/$UNIT_NAME"
IMPORT_ROOT="$IMPORT_ROOT/$UNIT_NAME"

if [ -d "$UNIT_DIR" ]; then
    echo "error: runtime unit already exists: $UNIT_DIR"
    exit 1
fi

mkdir -p "$UNIT_DIR/biz" "$UNIT_DIR/service" "$UNIT_DIR/pkg/common" "$UNIT_DIR/pkg/models"

cat > "$UNIT_DIR/$ENTRY_FILE" <<EOF
package $PACKAGE_NAME

import (
    cd "github.com/muidea/magicCommon/def"
    "github.com/muidea/magicCommon/event"
    "github.com/muidea/magicCommon/framework/plugin/module"
    "github.com/muidea/magicCommon/task"

    "$IMPORT_ROOT/biz"
    "$IMPORT_ROOT/pkg/common"
    "$IMPORT_ROOT/service"
)

func init() {
    module.Register(New())
}

type $UNIT_PASCAL struct {
    bizPtr     *biz.$UNIT_PASCAL
    servicePtr *service.$UNIT_PASCAL
}

func New() *$UNIT_PASCAL {
    return &$UNIT_PASCAL{}
}

func (s *$UNIT_PASCAL) ID() string {
    return common.${UNIT_PASCAL}Unit
}

func (s *$UNIT_PASCAL) Setup(eventHub event.Hub, backgroundRoutine task.BackgroundRoutine) (err *cd.Error) {
    s.bizPtr = biz.New(eventHub, backgroundRoutine)
    s.servicePtr = service.New(s.bizPtr)
    return nil
}

func (s *$UNIT_PASCAL) Run() (err *cd.Error) {
    err = s.bizPtr.Initialize()
    if err != nil {
        return
    }
    s.servicePtr.RegisterRoute()
    return
}

func (s *$UNIT_PASCAL) Teardown() {}
EOF

cat > "$UNIT_DIR/biz/biz.go" <<EOF
package biz

import (
    cd "github.com/muidea/magicCommon/def"
    "github.com/muidea/magicCommon/event"
    "github.com/muidea/magicCommon/task"
)

type $UNIT_PASCAL struct {
    eventHub          event.Hub
    backgroundRoutine task.BackgroundRoutine
}

func New(eventHub event.Hub, backgroundRoutine task.BackgroundRoutine) *$UNIT_PASCAL {
    return &$UNIT_PASCAL{
        eventHub:          eventHub,
        backgroundRoutine: backgroundRoutine,
    }
}

func (s *$UNIT_PASCAL) Initialize() (err *cd.Error) {
    return nil
}
EOF

cat > "$UNIT_DIR/service/service.go" <<EOF
package service

import "$IMPORT_ROOT/biz"

type $UNIT_PASCAL struct {
    bizPtr *biz.$UNIT_PASCAL
}

func New(bizPtr *biz.$UNIT_PASCAL) *$UNIT_PASCAL {
    return &$UNIT_PASCAL{bizPtr: bizPtr}
}

func (s *$UNIT_PASCAL) RegisterRoute() {}
EOF

cat > "$UNIT_DIR/pkg/common/const.go" <<EOF
package common

const (
    ${UNIT_PASCAL}Unit = "$UNIT_NAME"
)
EOF

echo "created runtime unit: $UNIT_DIR"
echo "import root: $IMPORT_ROOT"
echo "next steps:"
echo "  1. add route registration in service/"
echo "  2. add models and common definitions"
echo "  3. add tests and docs"
