#!/bin/bash

set -euo pipefail

UNIT_NAME="${1:-}"
GROUP_PATH="${2:-}"
UNIT_ROOT="internal/modules"
ENTRY_FILE="module.go"
WITH_SERVICE=false

usage() {
    echo "usage: $0 <unit_name> <group_path> [unit_root] [entry_file] [--with-service]"
}

if [ -z "$UNIT_NAME" ] || [ -z "$GROUP_PATH" ]; then
    usage
    exit 1
fi

shift 2
if [ "${1:-}" != "" ] && [ "${1:-}" != "--with-service" ]; then
    UNIT_ROOT="$1"
    shift
fi
if [ "${1:-}" != "" ] && [ "${1:-}" != "--with-service" ]; then
    ENTRY_FILE="$1"
    shift
fi
if [ "${1:-}" = "--with-service" ]; then
    WITH_SERVICE=true
    shift
fi
if [ "$#" -ne 0 ]; then
    usage
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

GO_MOD="$(go env GOMOD)"
if [ "$GO_MOD" = "/dev/null" ] || [ ! -f "$GO_MOD" ]; then
    echo "error: run this script from a Go module"
    exit 1
fi
PROJECT_ROOT="$(dirname "$GO_MOD")"
MODULE_PATH="$(cd "$PROJECT_ROOT" && go list -m -f '{{.Path}}')"

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
    echo "${input//-/_}"
}

GROUP_PATH="$(trim_path "$GROUP_PATH")"
UNIT_ROOT="$(trim_path "$UNIT_ROOT")"
UNIT_PASCAL="$(to_pascal_case "$UNIT_NAME")"
PACKAGE_NAME="$(to_package_name "$UNIT_NAME")"
UNIT_DIR="$PROJECT_ROOT/$UNIT_ROOT/$GROUP_PATH/$UNIT_NAME"
IMPORT_ROOT="$MODULE_PATH/$UNIT_ROOT/$GROUP_PATH/$UNIT_NAME"
BASE_BIZ_IMPORT="$MODULE_PATH/internal/modules/base/biz"

if [ -d "$UNIT_DIR" ]; then
    echo "error: runtime unit already exists: $UNIT_DIR"
    exit 1
fi

mkdir -p "$UNIT_DIR/biz" "$UNIT_DIR/pkg/common"

SERVICE_IMPORT=""
SERVICE_FIELD=""
SERVICE_SETUP=""
SERVICE_RUN=""
SERVICE_TEARDOWN=""
if [ "$WITH_SERVICE" = true ]; then
    mkdir -p "$UNIT_DIR/service"
    SERVICE_IMPORT="    \"$IMPORT_ROOT/service\""
    SERVICE_FIELD="    servicePtr *service.$UNIT_PASCAL"
    SERVICE_SETUP="    s.servicePtr = service.New(s.bizPtr)"
    SERVICE_RUN=$'    if s.servicePtr != nil {\n        s.servicePtr.RegisterRoutes()\n    }'
    SERVICE_TEARDOWN="    s.servicePtr = nil"
fi

cat > "$UNIT_DIR/$ENTRY_FILE" <<EOF
package $PACKAGE_NAME

import (
    "context"

    "$IMPORT_ROOT/biz"
    "$IMPORT_ROOT/pkg/common"
$SERVICE_IMPORT
    cd "github.com/muidea/magicCommon/def"
    "github.com/muidea/magicCommon/event"
    "github.com/muidea/magicCommon/framework/plugin/module"
    "github.com/muidea/magicCommon/task"
)

func init() { module.Register(New()) }

type $UNIT_PASCAL struct {
    bizPtr *biz.$UNIT_PASCAL
$SERVICE_FIELD
}

func New() *$UNIT_PASCAL { return &$UNIT_PASCAL{} }
func (s *$UNIT_PASCAL) ID() string { return common.UnitID }

func (s *$UNIT_PASCAL) Setup(_ context.Context, hub event.Hub, background task.BackgroundRoutine) *cd.Error {
    s.bizPtr = biz.New(hub, background)
$SERVICE_SETUP
    return nil
}

func (s *$UNIT_PASCAL) Run(ctx context.Context) *cd.Error {
    if s.bizPtr == nil {
        return cd.NewError(cd.IllegalParam, "unit biz is not configured")
    }
    if err := s.bizPtr.Run(ctx); err != nil {
        return err
    }
$SERVICE_RUN
    return nil
}

func (s *$UNIT_PASCAL) Teardown(ctx context.Context) {
    if s.bizPtr != nil {
        s.bizPtr.Teardown(ctx)
    }
    s.bizPtr = nil
$SERVICE_TEARDOWN
}
EOF

cat > "$UNIT_DIR/biz/biz.go" <<EOF
package biz

import (
    "context"

    basebiz "$BASE_BIZ_IMPORT"
    "$IMPORT_ROOT/pkg/common"
    cd "github.com/muidea/magicCommon/def"
    "github.com/muidea/magicCommon/event"
    "github.com/muidea/magicCommon/task"
)

type $UNIT_PASCAL struct {
    basebiz.Base
}

func New(hub event.Hub, background task.BackgroundRoutine) *$UNIT_PASCAL {
    return &$UNIT_PASCAL{Base: basebiz.New(common.UnitID, hub, background)}
}

func (s *$UNIT_PASCAL) Run(context.Context) *cd.Error { return nil }
func (s *$UNIT_PASCAL) Teardown(context.Context) {}
EOF

if [ "$WITH_SERVICE" = true ]; then
    cat > "$UNIT_DIR/service/service.go" <<EOF
package service

import "$IMPORT_ROOT/biz"

type $UNIT_PASCAL struct {
    bizPtr *biz.$UNIT_PASCAL
}

func New(bizPtr *biz.$UNIT_PASCAL) *$UNIT_PASCAL { return &$UNIT_PASCAL{bizPtr: bizPtr} }
func (s *$UNIT_PASCAL) RegisterRoutes() {}
EOF
fi

cat > "$UNIT_DIR/pkg/common/const.go" <<EOF
package common

const UnitID = "$UNIT_NAME"
EOF

find "$UNIT_DIR" -type f -name '*.go' -exec gofmt -w {} +

echo "created runtime unit: $UNIT_DIR"
echo "import root: $IMPORT_ROOT"
echo "next steps:"
echo "  1. add typed cross-owner contracts in pkg/events only when needed"
echo "  2. add route registration only when an Initiator helper is available"
echo "  3. add Biz subscriptions and matching Teardown cleanup"
echo "  4. add tests and docs"
