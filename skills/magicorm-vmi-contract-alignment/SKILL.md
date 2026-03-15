---
name: magicorm-vmi-contract-alignment
description: 用于处理 magicOrm 中 VMI 定义、view/valueMask、validation、insert/update 约束与 magicTest/vmi 回归之间的契约对齐。涉及 req、ro、req,ro、ValueMask、View、安装包定义核对时使用。
version: 1.0.0
---

# magicOrm VMI Contract Alignment

这个 skill 用于收 `magicOrm/test/vmi`、运行中定义和 `magicTest/vmi` 断言之间的漂移。

## 先读这些文件

- `test/vmi/`
- `validation/manager.go`
- `orm/insert.go`
- `orm/update.go`
- `orm/query.go`
- `docs/design-models.md`
- `docs/design-orm.md`
- `../docs/vmi-definition-regression-playbook.md`

## 当前稳定规则

- `req` 只要求 `insert`
- `ro` 表示允许 `insert` 赋值、禁止 `update` 修改
- `req,ro` 表示创建必填且创建后只读
- `ValueMask` 优先于 `View`
- 没有 `ValueMask` 时按 `View` 决定返回边界

## 工作方式

1. 先核对 `magicOrm/test/vmi`
2. 再核对实际安装的 `vmi.zip`
3. 再核对运行中数据库定义
4. 最后再调 `magicTest/vmi`

## 推荐验证

```bash
GOCACHE=/tmp/magicorm-gocache GOFLAGS=-mod=mod \
go test ./validation ./orm -count 1
```
