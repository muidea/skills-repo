---
name: magiccas-service-readiness
description: 用于处理 magicCas 的服务级 ready 行为、对 magicBase 的强依赖、自举恢复和权限校验入口准备。涉及 persistence、routeregistry、health/ready、session/privilege 初始化时使用。
version: 1.0.0
---

# magicCas Service Readiness

这个 skill 只处理 `magicCas` 作为被依赖服务时的就绪语义。

## 先读这些文件

- `internal/initiators/routeregistry/routeregistry.go`
- `internal/initiators/persistence/persistence.go`
- `docs/design-startup.md`
- `docs/release-note-2026-03-hardening.md`
- `../docs/service-reset-recovery-playbook.md`

## 当前稳定规则

- `magicCas` 强依赖 `magicBase`
- `/health/ready` 必须走根路径
- 数据重置后，应用缺失时允许自动补建

## 推荐验证

```bash
GOCACHE=/tmp/magiccas-gocache \
go test ./internal/initiators/routeregistry ./internal/initiators/persistence ./internal/modules/kernel/cas -count 1
```
