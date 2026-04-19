---
name: magicorm-vmi-remote
description: 用于基于 magicOrm/test/vmi 的 remote schema 样例做设计、验证和回归，覆盖 VMI JSON 定义、Remote Provider、ObjectValue 往返、query/write runner 和 builder SQL。处理远端模型定义一致性时使用。
version: 1.0.1
---

# magicOrm VMI Remote

这个 skill 用于 `test/vmi` 驱动的 remote 设计和验证。应用端使用 Local/Remote Provider 或 Object/ObjectValue 转换时，优先使用 `magicorm-provider-object-usage`。

## 1. 先读这些文档

- `docs/design-remote-provider.md`
- `docs/technical-note-remote-update-query.md`
- `docs/testing-guide.md`
- `test/README.md`

## 2. 重点目录

- `test/vmi/`
- `provider/remote/`
- `provider/helper/`
- `provider/`
- `orm/`
- `database/mysql/`
- `database/postgres/`

## 3. 典型任务

- 校验 VMI JSON 定义能否注册为 remote model
- 检查 `ObjectValue` / `SliceObjectValue` 的序列化闭环
- 检查 remote filter/mask/query/update 的真实行为
- 检查 MySQL/Postgres builder 对 VMI relation 的 SQL
- 如果只是应用端 provider 选择或 helper 转换，不使用本 skill

## 4. 处理顺序

1. 先确认定义层
2. 再确认 provider/helper 往返
3. 再确认 orm runner
4. 最后确认 database builder

## 5. 推荐验证

```bash
GOCACHE=/tmp/magicorm-gocache GOFLAGS=-mod=mod \
go test ./provider ./provider/remote ./provider/helper ./orm ./test/consistency ./database/codec ./database/postgres ./database/mysql -count 1
```
