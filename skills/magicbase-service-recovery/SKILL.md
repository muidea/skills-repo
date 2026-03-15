---
name: magicbase-service-recovery
description: 用于处理 magicBase 在服务数据重置、自举恢复、Application 自动补建、默认数据库回落、routeregistry health 路由等场景下的恢复链。涉及 CreateApplication、routeregistry、persistence 恢复时使用。
version: 1.0.0
---

# magicBase Service Recovery

这个 skill 聚焦 `magicBase` 作为平台底座在重置后的恢复行为。

## 先读这些文件

- `internal/modules/kernel/base/biz/application.go`
- `internal/initiators/routeregistry/routeregistry.go`
- `docs/design-startup.md`
- `docs/release-note-2026-03-hardening.md`
- `../docs/service-reset-recovery-playbook.md`

## 当前稳定规则

- 应用记录缺失时，上层服务可以自动补建
- 缺省数据库配置会回落到平台数据库配置
- `/health/live`、`/health/ready` 走无版本根路径

## 推荐检查表

- 是否只建了 Application 元数据，没有注册 ORM
- health 路由是否误挂到 `/api/v1/health/*`
- `CreateApplication` 是否仍会在失败后留下半成功状态

## 推荐验证

```bash
GOCACHE=/tmp/magicbase-gocache \
go test ./internal/modules/kernel/base/biz ./internal/initiators/routeregistry -count 1
```
