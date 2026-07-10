---
name: magicfile-app-bootstrap
description: "用于处理 `magicFile` 的启动入口、模块装配和对 `magicModulesRepo` initiator 的依赖。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.3
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
4. `magicFile` 是否已绑定自身运行时应用、缺失时是否自动初始化或直接失败，必须由 `magicFile` 自己决定，不能把这类业务启动语义委托给共享 initiator 或 `magicBase`。
5. `internal/pkg/models.InitializeModel` 这类模型初始化 helper 不得假定 `baseClient` 一定存在；依赖未就绪时应 fail-fast 返回明确错误，避免在 helper 内部触发 nil pointer panic。

## 验证

```bash
GOCACHE=/tmp/magicfile-gocache go test ./internal/... -count 1
```
