---
name: magicrunner-runner-proxy
description: "用于处理 `kernel/runner` 的公开值代理路由注册和请求头注入。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.2
  author: "rangh-codespace"
---
# magicrunner-runner-proxy

用于处理 `kernel/runner` 的公开值代理路由注册和请求头注入。

## 适用场景

- 调整 `runner` 动态路由注册
- 排查 `Application` / `Namespace` / `EntityExtData` header 注入
- 处理公开实体 `filter/query/insert/delete/update/count` 代理规则

## 重点文件

- [design-modules.md](magicRunner/docs/design-modules.md)
- [design-http-entrypoints.md](magicRunner/docs/design-http-entrypoints.md)
- [module.go](magicRunner/internal/modules/kernel/runner/module.go)
- [service.go](magicRunner/internal/modules/kernel/runner/service/service.go)

## 工作方式

1. 先确认实体列表是否来自 `LoadEntity()`
2. 路径规则和目标 URL 要一起改
3. `query/update/delete` 这类动态路由要同步维护 `DynamicTag` / `DynamicValue`
4. 留意 `EntityExtData` 的编码和降级日志

## 验证

```bash
GOCACHE=/tmp/magicrunner-gocache go test ./internal/modules/kernel/runner/... -count 1
```
