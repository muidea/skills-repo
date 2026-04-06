---
name: magiccas-service-readiness
description: 用于处理 magicCas 的服务级 ready 行为、对 magicBase 的强依赖、自举恢复和权限校验入口准备。涉及 persistence、routeregistry、health/ready、session/privilege 初始化时使用。
version: 1.0.1
---

# magicCas Service Readiness

这个 skill 只处理 `magicCas` 作为被依赖服务时的就绪语义。

## 先读这些文件

- `magicCas/internal/initiators/routeregistry/routeregistry.go`
- `magicCas/internal/initiators/persistence/persistence.go`
- `magicCas/docs/design-startup.md`
- `magicCas/docs/release-note-2026-03-hardening.md`

## 当前稳定规则

- `magicCas` 强依赖 `magicBase`
- `/health/ready` 必须走根路径
- 数据重置后，应用缺失时允许自动补建

## 内置恢复基线

### 启动依赖

- `magicCas -> magicBase`
- `magicFile -> magicCas`
- `magicRunner(panel) -> magicCas`

`magicCas` readiness 问题优先按这条依赖链理解，不要只看单服务日志。

### Health 约定

- `/health/live`
  只表示进程活着
- `/health/ready`
  表示 `Setup/Run` 成功，且 required 外部依赖都 ready

如果 `/health/ready` 返回 `404`，先检查 health 路由是否被错误挂成了带版本前缀的路径。

### 自举恢复

服务数据重置后，`magicCas` 在发现自己的 `Application` 不存在时，应自动在 `magicBase` 中补建应用记录。

补建时如果没有独立数据库配置，应回落到平台数据库配置，并注册 ORM。

### 常见故障模式

1. `/health/ready` 返回 `404`
   优先检查 health 路由是否注册错误。
2. 应用记录补建成功，但后续报 `can't find orm`
   说明只建了元数据，没有完成 ORM 注册。
3. 服务一直重启，但上游服务看起来正常
   先看 `serviceDependencies`、目标服务 `/health/ready`、以及启动日志里的 `dependency ... not ready`。

### 推荐核对顺序

1. `docker ps`
2. `docker logs` 看依赖检查失败点
3. 检查 `~/dataspace/services/config/*/application.toml`
4. 核对 `magicBase` 是否先 ready
5. 再看 `magicCas`
6. 最后看 `magicFile` / `magicRunner`

## 推荐验证

```bash
cd magicCas && GOCACHE=/tmp/magiccas-gocache \
go test ./internal/initiators/routeregistry ./internal/initiators/persistence ./internal/modules/kernel/cas -count 1
```
