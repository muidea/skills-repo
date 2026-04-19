---
name: magicbase-module-dev
description: "用于处理 `magicBase` 的 kernel/block 模块开发、路由装配和模块生命周期；如果只是定义应用侧 BlockInfo 能力并接入数据存储，优先使用 magicbase-data-capability-definition。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.3
  author: "rangh-codespace"
---
# magicbase-module-dev

用于处理 `magicBase` 的 kernel/block 模块开发、路由装配和模块生命周期。

如果任务是应用侧定义 `Application`、`Entity`、`BlockInfo` 并通过 magicBase 存储业务值，优先使用 `magicbase-data-capability-definition`；本 skill 只处理 magicBase 内部 module/block 的代码结构和生命周期。

## 适用场景

- 新增 module
- 调整 kernel/base 或 public 模块
- 调整 block 模块的 biz/service 装配
- 调整 block service 的 HTTP 错误处理
- 排查模块 `Setup/Run` 顺序问题
- 新增或调整 block 模块自身的 route、biz、service 或事件接线

## 重点文件

- [design-modules.md](magicBase/docs/design-modules.md)
- [kernel/base/module.go](magicBase/internal/modules/kernel/base/module.go)
- [kernel/public/module.go](magicBase/internal/modules/kernel/public/module.go)
- [internal/modules/blocks](magicBase/internal/modules/blocks)
- [masking/module.go](magicBase/internal/modules/blocks/masking/module.go)

## 工作方式

1. 优先保持 `Setup` 只做装配，`Run` 负责业务启动和路由注册
2. 通过 initiator 获取 `RouteRegistryHelper`
3. service 负责路由，biz 负责业务和事件
4. HTTP handler 对明显客户端错误优先返回 `IllegalParam`
5. 对依赖应用上下文的 block 接口，缺上下文时 fail-closed
6. `masking` 是事件型 block，没有对外 HTTP 路由，不要强行补 service 路由
7. `blockInfo` 能力声明属于实体能力定义；不要把它当成 block module 路由开发问题处理
8. 新模块同步更新文档和 skill

## 验证

```bash
GOCACHE=/tmp/magicbase-gocache go test ./internal/modules/... -count 1
```
