---
name: magicorm-model-design
description: 用于基于 magicOrm 设计和调整业务模型，处理 models.Model、Field、Filter、View、关系字段、struct tag 和类型映射。编写或修改 ORM 模型定义时使用。
version: 1.0.1
---

# magicOrm Model Design

这个 skill 用于业务模型设计，不处理底层 SQL 或 provider 细节实现。应用端使用 Local/Remote Provider、`Object`、`ObjectValue` 或 helper 转换时，使用 `magicorm-provider-object-usage`。

## 1. 先读这些文档

- `docs/design-models.md`
- `docs/design-relation.md`
- `docs/tags-reference.md`
- `docs/type-mapping.md`
- `docs/error-codes.md`

## 2. 设计模型时的顺序

1. 先确定主键和基础字段
2. 再确定 view（`detail` / `lite`）
3. 再定义引用/包含关系
4. 最后补 `constraint` 和查询使用方式

## 3. 关键规则

- 模型语义最终以 `models` 抽象为准，不以单个 provider 的便利行为为准。
- 关系字段先区分：
  - 引用
  - 包含
  - 单值
  - 集合
- `view`、`constraint`、`orm` 是不同维度，不要混写理解。
- 设计字段时同时考虑：
  - Go 类型映射
  - models 类型映射
  - 数据库列类型
  - Remote 表达方式

## 4. 常见输出

- 新业务实体 struct
- tag 方案
- 关系设计说明
- 查询/更新时的赋值语义说明

## 5. 推荐验证

```bash
GOCACHE=/tmp/magicorm-gocache GOFLAGS=-mod=mod \
go test ./models ./provider ./validation -count 1
```
