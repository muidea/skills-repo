---
name: magicorm-provider-remote
description: 用于修改和排查 magicOrm provider/local、provider/remote、provider/helper、codec、mask/filter 的内部实现偏差。应用端选择 Local/Remote Provider、创建和使用 Object/ObjectValue/SliceObjectValue 时优先使用 magicorm-provider-object-usage。
version: 1.0.1
---

# magicOrm Provider Remote

这个 skill 重点面向 `provider/local`、`provider/remote`、`provider/helper` 和 codec 的内部实现偏差。应用端选择 provider、创建或使用 `Object` / `ObjectValue` / `SliceObjectValue` 时，优先使用 `magicorm-provider-object-usage`。

## 1. 先读这些文档

- `docs/design-provider.md`
- `docs/design-remote-provider.md`
- `docs/technical-note-remote-update-query.md`
- `provider/helper/readme.md`

## 2. 先看这些代码

- `provider/remote/*.go`
- `provider/helper/remote.go`
- `provider/provider.go`
- `database/codec/codec.go`

## 3. 核心关注点

- provider 内部如何处理 `Object` / `ObjectValue` / `SliceObjectValue`
- `nil` / `[]` / zero / assigned 语义
- `MaskModel` / `ValueMask`
- `EncodeValue` / `DecodeValue`
- 本地 struct 和 remote object 的往返一致性

## 4. 处理 remote 问题时的规则

- 先区分“未赋值”和“显式清空”。
- 先确认问题发生在：
  - helper 导出
  - provider 映射
  - codec 编解码
  - orm runner
  - builder SQL
- Remote 行为以 `test/vmi` 样例和现有回归测试为准。
- 不要在业务 handler 中绕过 `provider/helper` 手写转换来补偿 provider 缺陷。

## 5. 推荐验证

```bash
GOCACHE=/tmp/magicorm-gocache GOFLAGS=-mod=mod \
go test ./provider/remote ./provider/helper ./test/consistency -count 1
```
