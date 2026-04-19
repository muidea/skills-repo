---
name: magiccas-base-integration
description: "用于处理 `magicCas` 与 `magicBase` 之间的应用绑定、模型初始化和 client 集成。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.1
  author: "rangh-codespace"
---
# magiccas-base-integration

用于处理 `magicCas` 与 `magicBase` 之间的应用绑定、模型初始化和 client 集成。

## 适用场景

- 调整 `internal/initiators/persistence` 初始化流程
- 排查 `magicBase/pkg/client` 调用
- 调整应用绑定、模型初始化、默认 namespace 依赖
- 为模型初始化和 client 边界补测试

## 重点文件

- `docs/design-startup.md`
- `internal/initiators/persistence/persistence.go`
- `internal/pkg/models/helper.go`
- `internal/pkg/models/helper_test.go`

## 工作方式

1. 先确认失败点在应用绑定、实体筛选还是实体创建
2. 模型初始化失败必须直接返回错误，不允许吞掉
3. 对 nil pagination 和空结果保持稳健处理
4. 变更后至少跑模型初始化和全仓测试

## 验证

```bash
GOCACHE=/tmp/magiccas-gocache go test ./internal/pkg/models ./internal/initiators/persistence -count 1
```
