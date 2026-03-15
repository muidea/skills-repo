---
name: magicmodulesrepo-routeregistry-health
description: 用于处理 magicModulesRepo 中 routeregistry、persistence 与统一 health/live、health/ready 暴露的接入。涉及无版本 health 路由、服务启动承载、公共 initiator 健康检查时使用。
version: 1.0.0
---

# magicModulesRepo Routeregistry Health

这个 skill 处理共享 initiator 如何承载统一 health 能力。

## 先读这些文件

- `initiators/routeregistry/routeregistry.go`
- `initiators/persistence/persistence.go`
- `docs/design-startup.md`
- `../docs/service-dependency-health-design.md`

## 当前稳定规则

- health 路由注册在根路径：
  - `/health/live`
  - `/health/ready`
- 不能被 API version 包进去
- `routeregistry` 是大多数服务暴露 health 的承载层

## 推荐验证

```bash
GOCACHE=/tmp/magicmodulesrepo-gocache GOFLAGS=-mod=mod \
go test ./initiators/routeregistry ./initiators/persistence -count 1
```
