---
name: magicbase-kernel-entity
description: "用于处理 `kernel/base` 和 `kernel/public` 内部的应用、实体、Block、值对象和 `extData` 实现逻辑；应用侧定义 Application/Entity/Block 并接入数据存储时优先使用 magicbase-data-capability-definition。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.3
  author: "rangh-codespace"
---
# magicbase-kernel-entity

用于处理 `kernel/base` 和 `kernel/public` 内部的应用、实体、Block、值对象和 `extData` 实现逻辑。

如果任务是应用侧能力定义、Application 绑定、Entity 声明、Block 能力声明或业务值存储接入，优先使用 `magicbase-data-capability-definition`。

## 适用场景

- 调整 `kernel/base/biz`
- 调整 `kernel/public/biz`
- 处理 `Application` / `Entity` / `Value` 的默认值刷新
- 修复 `$referenceExtData` 语义
- 调整 public 值写入和关系字段转换
- 排查与 `magicOrm remote.ObjectValue` 的交互
- 修复 `CreateApplication`、`CreateEntity`、`UpdateEntityBlock` 等内部实现

## 重点文件

- [biz.go](magicBase/internal/modules/kernel/base/biz/biz.go)
- [application.go](magicBase/internal/modules/kernel/base/biz/application.go)
- [entity.go](magicBase/internal/modules/kernel/base/biz/entity.go)
- [value.go](magicBase/internal/modules/kernel/public/biz/value.go)
- [application_test.go](magicBase/internal/modules/kernel/base/biz/application_test.go)
- [value_test.go](magicBase/internal/modules/kernel/public/biz/value_test.go)
- [design-http-entrypoints.md](magicBase/docs/design-http-entrypoints.md)
- [design-routing-auth.md](magicBase/docs/design-routing-auth.md)

## 当前稳定语义

- `$referenceExtData.xxx` 只应返回基础值
- 不直接把 `map` / `slice` / `struct` 作为默认字段值注入
- 涉及 `remote.ObjectValue` 时优先保持字段类型稳定
- `CreateApplication` 在数据库注册失败时应回滚应用记录
- `CreateEntity` 应先持久化实体元数据，再按应用 UUID 注册 remote model，并在 schema 创建失败时清理不完整状态
- `blockInfo` 是实体能力声明，不应混入普通业务字段
- `kernel/public` 的关系字段支持主键简写，但非法复杂值要尽早报错

## 验证

```bash
GOCACHE=/tmp/magicbase-gocache go test ./internal/modules/kernel/base/... -count 1
```
