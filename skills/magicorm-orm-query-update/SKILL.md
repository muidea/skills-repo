---
name: magicorm-orm-query-update
description: 用于处理 magicOrm 的 Query、BatchQuery、Insert、Update、Delete 及关系更新精度，重点覆盖 QueryRunner、UpdateRunner、关系 diff、mask 和回填语义。修改 ORM 读写逻辑时使用。
version: 1.0.0
---

# magicOrm ORM Query Update

这个 skill 用于 ORM 读写路径，不处理 provider 协议细节本身。

## 1. 先读这些文档

- `docs/design-orm.md`
- `docs/design-relation.md`
- `docs/design-database.md`
- `docs/release-note-2026-03-remote-update-query.md`
- `docs/technical-note-remote-update-query.md`

## 2. 重点代码

- `orm/query.go`
- `orm/update.go`
- `orm/update_diff.go`
- `orm/insert.go`
- `orm/delete.go`

## 3. 默认检查表

- Query 的 filter 和返回 mask 是否被混淆
- Update 是否做了不必要的 delete + insert
- 引用关系和包含关系是否被区分处理
- `nil` / `[]` / 未赋值 是否符合当前语义
- runner 和 builder 的行为是否一致

## 4. 修改原则

- 优先减少无意义 SQL 和无意义关系重建
- 不直接改变已稳定的 Remote 赋值语义
- 先补回归测试再改逻辑

## 5. 推荐验证

```bash
GOCACHE=/tmp/magicorm-gocache GOFLAGS=-mod=mod \
go test ./orm ./database/codec ./database/postgres ./database/mysql -count 1
```
