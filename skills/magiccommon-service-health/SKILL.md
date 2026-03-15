---
name: magiccommon-service-health
description: 用于处理 magicCommon 中 framework/service、framework/health、framework/configuration 驱动的服务依赖、health/live、health/ready、启动状态和 fail-fast 机制。涉及 serviceDependencies、ready 判定、启动回滚时使用。
version: 1.0.0
---

# magicCommon Service Health

这个 skill 只关注统一服务状态和依赖检查，不处理具体业务模块逻辑。

## 先读这些文件

- `framework/health/health.go`
- `framework/service/service.go`
- `framework/configuration/manager.go`
- `framework/application/application.go`
- `../docs/service-dependency-health-design.md`
- `../docs/service-dependency-health-implementation-plan.md`

## 当前稳定规则

- `/health/live` 只表示进程存活
- `/health/ready` 依赖：
  - `Setup/Run` 成功
  - `serviceDependencies` 中 `required` 目标服务 ready
- 外部依赖来自配置，不来自业务模块代码
- 启动任一步失败时要统一回滚

## 改动原则

- 不把服务级依赖声明塞回业务模块
- 优先保持 `starting/ready/failed` 三态稳定
- 失败优先 `fail-fast`，不要半启动

## 推荐验证

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor \
go test ./framework/... -count 1
```
