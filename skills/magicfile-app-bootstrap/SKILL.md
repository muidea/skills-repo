---
name: magicfile-app-bootstrap
description: "用于处理 `magicFile` 的启动入口、模块装配和对 `magicModulesRepo` initiator 的依赖。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.2
  author: "rangh-codespace"
---
# magicfile-app-bootstrap

用于处理 `magicFile` 的启动入口、模块装配和对 `magicModulesRepo` initiator 的依赖。

## 适用场景

- 调整 `cmd/magicFile/main.go`
- 排查 `file` 模块 `Setup/Run`
- 处理 `magicModulesRepo` initiator 集成问题

## 重点文件

- [main.go](magicFile/cmd/magicFile/main.go)
- [design-startup.md](magicFile/docs/design-startup.md)
- [module.go](magicFile/internal/modules/file/module.go)
- [helper.go](magicFile/internal/pkg/models/helper.go)

## 工作方式

1. 先确认失败是在模型初始化、route registry 绑定还是业务模块启动
2. `file` 模块只做文件域逻辑，不重复实现通用 initiator
3. 变更后至少跑 `internal/...` 包测试

## 验证

```bash
GOCACHE=/tmp/magicfile-gocache go test ./internal/... -count 1
```
