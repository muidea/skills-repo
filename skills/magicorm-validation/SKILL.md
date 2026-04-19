---
name: magicorm-validation
description: 用于处理 magicOrm 验证层，包括 ValidationManager、类型适配、约束校验、场景校验、provider validation extension 以及验证错误排查。处理 Insert/Update/Delete 报验证错误时使用。
version: 1.0.0
---

# magicOrm Validation

这个 skill 专门处理验证系统，不混入 ORM 其他逻辑。

## 1. 先读这些文档

- `docs/design-validation.md`
- `docs/tags-reference.md`
- `docs/error-codes.md`
- `VALIDATION_ARCHITECTURE.md`

## 2. 重点代码

- `validation/*.go`
- `validation/*/*.go`
- `provider/local/validation_ext.go`
- `provider/remote/validation_ext.go`
- `orm/orm.go`

## 3. 排查验证问题时先看什么

- 模型适配是不是保留了真实字段类型
- `ScenarioInsert / Update / Query / Delete` 是否匹配
- provider 扩展是否绕过或附加了额外规则
- 报错来自：
  - type mismatch
  - constraint
  - database validator
  - model cache / metadata

## 4. 修改原则

- 不要把验证失败 silently ignore。
- 对 Local/Remote 都要确认适配后类型是否一致。
- 如果调整了行为，必须同步文档和场景测试。

## 5. 推荐验证

```bash
GOCACHE=/tmp/magicorm-gocache GOFLAGS=-mod=mod \
go test ./validation/... ./provider/local ./provider/remote ./orm -count 1
```
