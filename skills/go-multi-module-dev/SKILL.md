---
name: go-multi-module-dev
description: 用于基于 magicCommon/framework 的 Go 多模块仓库开发，覆盖 application、internal/modules、biz/service/pkg 分层、事件集成、路由注册、文档与测试同步。新增模块、扩展业务模块或做跨仓联动开发时使用。
version: 2.0.2
---

# Go Multi Module Development

这个 skill 用于基于 `magicCommon` 的多应用、多模块 Go 仓库。

## 1. 先看这些文件

- `go.mod`
- `README.md`
- `AGENTS.md`

## 2. 按任务读取这些 references

- 模块结构和落点：`references/MODULE_STRUCTURE.md`
- 事件与生命周期：`references/EVENT_USAGE.md`
- 最小模板和脚本：`references/TEMPLATES.md`
- 如果任务涉及 `initiator` 接线、module 生命周期、`Setup` / `Run` / `Teardown` 顺序，配合使用 `go-module-initiator-lifecycle`

## 3. 工作流

1. 先确认仓库角色和依赖
   - `magicCommon` 是基础框架
   - `magicEngine` 负责 HTTP
   - `magicOrm` 负责模型和持久化
   - 业务仓库在这些基础库之上封装应用入口和模块能力
2. 先确定改动落点
   - 应用入口：`application/{app}/`
   - 核心模块：`internal/modules/kernel/{module}/`
   - 公共模块：`internal/modules/blocks/{module}/`
   - 公共能力：`pkg/`
3. 只补当前任务需要的最小层
   - `module.go`
   - `biz/`
   - `service/`
   - `pkg/common`
   - `pkg/models`
4. 涉及跨仓依赖时，同步核对对应仓库文档和 skill
   - `magicCommon`: 生命周期、event、task、session、monitoring
   - `magicEngine`: route、middleware、static、sse、tcp
   - `magicOrm`: provider、validation、query/update、remote
5. 代码完成后，同步补：
   - 直接相关测试
   - 文档
   - 如有复用价值，再更新 skill

## 4. 开发规则

- 先看现有模块，不要凭空造新分层。
- 模块入口优先保持 `module.Register(New()) -> Setup() -> Run() -> Teardown()` 这条生命周期。
- `biz` 负责业务和事件，不直接堆 HTTP 细节。
- `service` 负责 route / handler / request-response。
- `pkg/common` 放模块 ID、常量、错误、过滤器、结果。
- `pkg/models` 放 DTO / entity / view model。
- 新增模块前先确认是否应该落在 `kernel` 还是 `blocks`。
- 如果任务只是扩展已有模块，优先沿用现有目录，而不是再创建新模块。

## 5. 常用脚本

- 创建最小模块骨架：`scripts/create-module.sh`

## 6. 推荐验证

先跑改动包，再跑全量：

```bash
GOCACHE=/tmp/go-multi-module-gocache go test ./... -count 1
```
