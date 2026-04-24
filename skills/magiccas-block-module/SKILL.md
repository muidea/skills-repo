---
name: magiccas-block-module
description: "用于处理 `magicCas` 的基础 block 模块，包括 `account`、`endpoint`、`namespace`、`role`、`totalizator`；不用于承载 `kernel/registration` 这类基于基础 block 编排的 CAS 治理流程。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.2
  author: "rangh-codespace"
---
# magiccas-block-module

用于处理 `magicCas` 的基础 block 模块，包括 `account`、`endpoint`、`namespace`、`role`、`totalizator`。

## 适用场景

- 新增或修改 block 模块
- 调整 block 的 `biz/service/module` 装配
- 统一 block 的参数错误语义
- 为 block HTTP 入口补 direct test

## 边界排除

- `RegistrationProfile`、`RegistrationPolicy`、`AccountRegistration` 属于 CAS 注册准入治理模型，不属于 `blocks/account`。
- 注册准入会组合 `account`、`role`、`namespace`、`endpoint` 等基础能力，因此应归属 `internal/modules/kernel/registration`，并按 kernel 治理模块接线。
- 不要因为 registration 拥有 CRUD 模型就新增 `blocks/registration`；block 只承载基础资源能力，跨 block 的策略编排应进入 `kernel/*`。
- 处理用户注册、注册模板、注册审核、默认 role 绑定时，主 skill 使用 `magiccas-cas-auth`，本 skill 只作为基础 block 依赖的 supporting skill。

## 重点文件

- `docs/design-modules.md`
- `internal/modules/blocks/account/module.go`
- `internal/modules/blocks/endpoint/module.go`
- `internal/modules/blocks/namespace/module.go`
- `internal/modules/blocks/role/module.go`
- `internal/modules/blocks/totalizator/module.go`

## 工作方式

1. 先判断需求是基础资源能力还是跨基础资源的治理流程
2. 基础资源能力再区分 CRUD 型还是事件/汇总型
3. 优先保持 `module -> biz -> service` 的统一装配模式
4. 对明显入参错误返回 `IllegalParam`
5. 至少补一层 handler 级回归
6. 如果发现功能依赖多个 block 完成准入、授权、模板或审核策略，停止放入 block，改按 `kernel/*` 治理模块处理

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

注册准入相关变更不要只跑 block 测试，必须补充：

```bash
GOCACHE=/tmp/magiccas-gocache go test ./internal/modules/kernel/registration/... -count 1
```
