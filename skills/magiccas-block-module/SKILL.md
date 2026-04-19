---
name: magiccas-block-module
description: "用于处理 `magicCas` 的 block 模块，包括 `account`、`endpoint`、`namespace`、`role`、`totalizator`。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.1
  author: "rangh-codespace"
---
# magiccas-block-module

用于处理 `magicCas` 的 block 模块，包括 `account`、`endpoint`、`namespace`、`role`、`totalizator`。

## 适用场景

- 新增或修改 block 模块
- 调整 block 的 `biz/service/module` 装配
- 统一 block 的参数错误语义
- 为 block HTTP 入口补 direct test

## 重点文件

- `docs/design-modules.md`
- `internal/modules/blocks/account/module.go`
- `internal/modules/blocks/endpoint/module.go`
- `internal/modules/blocks/namespace/module.go`
- `internal/modules/blocks/role/module.go`
- `internal/modules/blocks/totalizator/module.go`

## 工作方式

1. 先看模块是 CRUD 型还是事件/汇总型
2. 优先保持 `module -> biz -> service` 的统一装配模式
3. 对明显入参错误返回 `IllegalParam`
4. 至少补一层 handler 级回归

## 验证

```bash
GOCACHE=/tmp/magiccas-gocache go test \
  ./internal/modules/blocks/account/service \
  ./internal/modules/blocks/endpoint/service \
  ./internal/modules/blocks/namespace/service \
  ./internal/modules/blocks/role/service \
  ./internal/modules/blocks/totalizator/service \
  -count 1
```
