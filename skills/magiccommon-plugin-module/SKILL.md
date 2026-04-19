---
name: magiccommon-plugin-module
description: 用于理解、评审和排查 magicCommon framework/plugin 的底层插件管理机制，覆盖 plugin/common、initiator、module 的注册、排序、反射调用、ID/Weight 和 Setup/Run/Teardown 调度；修改框架插件管理器时使用，业务插件生命周期优先使用 go-module-initiator-lifecycle。
version: 1.0.2
---

# magicCommon Plugin Module

这个 skill 用于理解和排查 `magicCommon` 底层插件管理机制。新增、接线或管理业务 `initiator` / `module` 时，优先使用 `go-module-initiator-lifecycle`；只有需要检查 `framework/plugin` 自身行为时再使用本 skill。

## 1. 先读这些文件

- `framework/service/service.go`
- `framework/plugin/common/util.go`
- `framework/plugin/initiator/initiator.go`
- `framework/plugin/module/module.go`

## 2. 典型任务

- 排查底层插件管理器注册、排序、反射调用行为
- 核对 `initiator` / `module` 管理器的公共接口
- 排查插件 ID、权重、类型匹配问题
- 评审 `framework/plugin/common`、`framework/plugin/initiator`、`framework/plugin/module` 的实现变更

## 3. 当前约定

- 插件必须有稳定 ID
- 重复 ID 会被拒绝
- `Setup` / `Run` / `Teardown` 由管理器统一调度
- 应用默认通过 `service -> initiator/module -> plugin/common` 这条链启动

## 4. 处理规则

- 不要在本 skill 中设计业务模块目录或业务路由；业务插件生命周期使用 `go-module-initiator-lifecycle`。
- 插件的初始化逻辑优先放 `Setup`
- 运行逻辑放 `Run`
- 清理逻辑放 `Teardown`
- 不要在插件内部自己重复持有另一套 event hub 或 background routine，除非明确需要隔离

## 5. 推荐验证

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor \
go test ./framework/plugin/common ./framework/plugin/initiator ./framework/plugin/module ./framework/service -count 1
```
