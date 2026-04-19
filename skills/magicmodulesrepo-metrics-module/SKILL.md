---
name: magicmodulesrepo-metrics-module
description: "用于处理 `magicModulesRepo` 的 metrics 模块装配和后续扩展。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.2
  author: "rangh-codespace"
---
# magicmodulesrepo-metrics-module

用于处理 `magicModulesRepo` 的 metrics 模块装配和后续扩展。

## 适用场景

- 调整 metrics 模块 setup/run 流程
- 给 metrics 模块新增路由或事件入口
- 排查 route registry 依赖问题

## 重点文件

- [design-modules.md](magicModulesRepo/docs/design-modules.md)
- [module.go](magicModulesRepo/modules/blocks/metrics/module.go)
- [service.go](magicModulesRepo/modules/blocks/metrics/service/service.go)
- [biz.go](magicModulesRepo/modules/blocks/metrics/biz/biz.go)

## 工作方式

1. 先确认是模块装配问题还是未来新增的路由/事件问题
2. 当前模块没有 HTTP 路由，不要凭空补 handler
3. 如果新增路由，再补 service 级 direct test 和文档

## 验证

```bash
GOCACHE=/tmp/magicmodulesrepo-gocache go test ./modules/blocks/metrics/... -count 1
```
