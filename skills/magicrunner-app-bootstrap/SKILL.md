---
name: magicrunner-app-bootstrap
description: "DEPRECATED: 旧的项目专属应用启动 skill。新建通用 Go 多应用、多模块服务套件时改用 go-modular-project-bootstrap；仅维护既有 magicRunner 项目入口时临时参考。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.3
  author: "rangh-codespace"
  deprecated: true
  replacement: "go-modular-project-bootstrap"
---
# magicrunner-app-bootstrap

Deprecated: 这个 skill 已被 `go-modular-project-bootstrap` 合并替代，不再用于新项目初始化或通用服务框架搭建。

保留本文件只用于追溯旧项目入口问题。新建类似项目、抽象通用启动框架或整理应用入口时，优先使用 `go-modular-project-bootstrap`；新增或扩展单个模块时，使用 `go-multi-module-dev`。

## 适用场景

- 仅在维护既有 magicRunner 项目时调整 `application/*/cmd/main.go`
- 排查 `magicPanel` / `magicRunner` / `magicGateway` / `magicInstaller` / `magicCodeStudio` 启动失败
- 处理模块 `Setup` / `Run` 返回链
- 补启动说明文档

## 重点文件

- [README.md](magicRunner/README.md)
- [design-startup.md](magicRunner/docs/design-startup.md)
- [main.go](magicRunner/application/magicPanel/cmd/main.go)
- [main.go](magicRunner/application/magicRunner/cmd/main.go)
- [main.go](magicRunner/application/magicGateway/cmd/main.go)
- [main.go](magicRunner/application/magicInstaller/cmd/main.go)
- [main.go](magicRunner/application/magicCodeStudio/cmd/main.go)
- [module.go](magicRunner/internal/modules/kernel/gateway/module.go)

## 工作方式

1. 先确认问题是否属于既有 magicRunner 项目维护；如果是新项目初始化，立即切换到 `go-modular-project-bootstrap`
2. 先确认应用入口实际加载了哪些 initiator 和模块
3. 优先把失败留在 `Setup/Run` 的 `*cd.Error` 返回链
4. 对 `magicGateway`，确认只加载 gateway 所需 initiator/module，不把 panel/portal 入口混入独立网关进程
5. 对 `installer` 这种动作型应用，先看 `action` 和路径配置
6. 变更后至少跑一次受影响入口包测试；跨入口依赖变化再跑全仓测试

## 验证

```bash
GOCACHE=/tmp/magicrunner-gocache go test ./... -count 1
```
