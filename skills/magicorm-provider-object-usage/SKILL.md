---
name: magicorm-provider-object-usage
description: 用于在应用端正确使用 magicOrm Local Provider、Remote Provider、remote.Object、ObjectValue、SliceObjectValue 和 provider/helper 转换，覆盖模型注册、GetObject/GetObjectValue、UpdateEntity、Query/Insert/Update 输入边界、nil/empty/assigned 语义和验证；接入 magicOrm 动态模型或远端对象时使用。
compatibility: Compatible with open_code
metadata:
  version: "1.0.0"
  author: "rangh"
  created_at: "2026-04-18T22:26:00+08:00"
---

# magicOrm Provider Object Usage

这个 skill 是应用端使用 magicOrm provider 和 remote object 的通用入口。它不负责重构 provider 内部实现；内部 provider、codec、builder 行为偏差再切换到专项 skill。

## 使用边界

使用本 skill：

- 在应用端选择 `NewLocalProviderWithOptions` 或 `NewRemoteProviderWithOptions`
- 把 Go struct 转成 `remote.Object` / `ObjectValue` / `SliceObjectValue`
- 把 remote object value 回填到本地 struct
- 注册本地模型或远端 JSON/VMI 模型
- 使用 provider 生成 `models.Model`、`models.Filter`、`models.Value`
- 明确 ORM `Query` / `BatchQuery` / `Insert` / `Update` 输入对象应是什么
- 排查应用端手写 `ObjectValue` 导致的类型、assigned、nil/empty 语义错误

不使用本 skill：

- 修改 `provider/remote`、`provider/local`、`provider/helper` 内部实现，使用 `magicorm-provider-remote`
- 设计 struct tag、view、关系字段，使用 `magicorm-model-design` 或 `magicorm-entity-definition`
- 验证 VMI JSON 样例、builder SQL、远端回归，使用 `magicorm-vmi-remote`
- 修复 Query/Insert/Update 响应投影，使用 `magicorm-query-write-contract`

## 必读实现

先读取当前仓库版本：

- `provider/provider.go`
- `provider/options.go`
- `provider/local/provider.go`
- `provider/remote/provider.go`
- `provider/remote/object.go`
- `provider/helper/remote.go`
- `provider/helper/remote_helper.go`
- `provider/helper/readme.md`
- `provider/remote/readme.md`

## Provider 选择

Local Provider：

- 输入是 Go struct、struct pointer、slice 或 filter struct。
- 用于应用端直接拥有 Go 类型定义的场景。
- 通过 struct tag 生成 `models.Model`、`models.Value`、`models.Filter`。
- 常用入口是 `NewLocalProviderWithOptions(owner, ...)`；旧的 `NewLocalProvider(owner, validator)` 只是兼容入口。

Remote Provider：

- 输入是 `remote.Object`、`remote.ObjectValue`、`remote.SliceObjectValue`。
- 用于动态模型、跨服务模型定义、VMI JSON、远端 schema。
- 模型定义必须先以 `remote.Object` 注册，后续值才能按 `ObjectValue` 投影到模型。
- 常用入口是 `NewRemoteProviderWithOptions(owner, ...)`；旧的 `NewRemoteProvider(owner, validator)` 只是兼容入口。

通用规则：

- provider 有独立 model cache；使用前先 `RegisterModel`。
- 需要自定义校验时通过 `WithValueValidator` 注入。
- 不要绕过 provider 直接拼 `models.Model`。
- `SetModelValue` 只应用已注册模型的值；未注册模型必须 fail-fast。

## Object 和 ObjectValue

`remote.Object` 是模型定义：

- 来源可以是远端 JSON/VMI，也可以由 Go struct 通过 `helper.GetObject(entity)` 生成。
- 包含 `Name`、`PkgPath`、`Fields`、字段类型、view、constraint 等定义。
- 应先注册到 Remote Provider：`remoteProvider.RegisterModel(object)`。

`remote.ObjectValue` 是单个对象值：

- 来源优先使用 `helper.GetObjectValue(entity)`。
- 对于 remote Object，也可以用 `object.Interface(true)` 生成。
- `ID` 来自主键字段的有效值。
- 字段值通过 `FieldValue.Assigned`、`IsValid`、`IsZero` 区分未赋值、空值和显式清空。

`remote.SliceObjectValue` 是对象列表值：

- 来源优先使用 `helper.GetSliceObjectValue(slice)`。
- nil slice 和 assigned empty slice 语义不同，不能混写。
- `[]*T` 中 nil item 不支持，应提前过滤或返回错误。

## 应用端转换规则

Go struct -> remote.Object：

```go
object, err := helper.GetObject((*Entity)(nil))
```

Go struct -> remote.ObjectValue：

```go
value, err := helper.GetObjectValue(entity)
```

Go slice -> remote.SliceObjectValue：

```go
sliceValue, err := helper.GetSliceObjectValue(entities)
```

remote.ObjectValue -> Go struct：

```go
var entity Entity
err := helper.UpdateEntity(value, &entity)
```

remote.SliceObjectValue -> Go slice：

```go
var entities []Entity
err := helper.UpdateSliceEntity(sliceValue, &entities)
```

不要在应用端手写完整 `ObjectValue`，除非测试或接收远端 payload 后已验证结构。手写时必须保证 `Name`、`PkgPath`、字段名、嵌套 `ObjectValue` / `SliceObjectValue` 与已注册 `Object` 一致。

## ORM 输入边界

- 本地 struct 走 Local Provider，适合编译期已知模型。
- 远端动态模型走 Remote Provider，使用 `remote.Object` 注册模型，使用 `remote.ObjectValue` 或 `SliceObjectValue` 承载值。
- `Query(model)` 是单对象查询入口，不处理 `ValueMask`。
- `BatchQuery(filter)` 是多对象查询入口，按 filter/mask/view 处理。
- `Insert` / `Update` 输入不要混用本地 struct 和 remote value；同一路径内 provider 类型应保持一致。
- 业务服务不要在 handler 里补偿 provider 行为；发现 provider 偏差应修 magicOrm。

## nil / empty / assigned 语义

- nil pointer 字段表示未赋值或空值，具体以 generated `FieldValue.Assigned` 和 `IsValid` 为准。
- nil slice 表示未赋值列表。
- empty slice 表示显式赋值为空列表。
- pointer-to-slice 可以表达 assigned empty，回填时应保持空 slice 而不是 nil。
- 更新本地实体时，只处理 remote value 中有效或显式 assigned 的字段。
- 不要把 zero value 一律当成未赋值；主键、bool、数字字段尤其需要区分。

## 常见错误

- 未 `RegisterModel` 就调用 `GetEntityModel` 或 `GetTypeModel`。
- 用 Local Provider 处理 `remote.ObjectValue`。
- 用 Remote Provider 处理普通 Go struct。
- 手写 `ObjectValue` 时 `PkgPath` 和已注册 `Object` 不一致。
- 嵌套对象字段传普通 map，而不是 `*remote.ObjectValue`。
- 列表对象字段传普通 slice，而不是 `*remote.SliceObjectValue`。
- 把 `Post` 或 HTTP payload 中的 JSON map 直接塞进 provider，未先 decode 成 remote value。
- 在业务层手写 relation/detail 展开，绕过 provider 和 ORM 视图规则。

## 验证

优先验证 provider 和 helper：

```bash
GOCACHE=/tmp/magicorm-provider-object-gocache GOFLAGS=-mod=mod \
go test ./provider ./provider/local ./provider/remote ./provider/helper -count=1
```

涉及 ORM query/write 时追加：

```bash
GOCACHE=/tmp/magicorm-provider-object-gocache GOFLAGS=-mod=mod \
go test ./orm ./test -count=1
```

涉及 VMI 或远端 JSON 定义时追加：

```bash
GOCACHE=/tmp/magicorm-provider-object-gocache GOFLAGS=-mod=mod \
go test ./provider ./test/consistency -count=1
```

交付前检查：

- provider 类型和输入对象类型一致
- 模型已注册
- Object/ObjectValue 的 `Name`、`PkgPath`、字段名一致
- nil / empty / assigned 语义有测试覆盖
- remote payload decode 后再进入 provider
- 不在应用层绕过 magicOrm provider、helper、query/write contract
