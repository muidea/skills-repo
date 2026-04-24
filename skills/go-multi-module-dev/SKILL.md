---
name: go-multi-module-dev
description: 用于基于 magicCommon/framework 的 Go 多运行单元仓库开发，覆盖入口落点、`internal/<unit-root>/` 分层、运行单元职责边界、biz/service/pkg 拆分、事件集成、路由注册、文档与测试同步。新增或扩展运行单元、调整分组落点或做跨仓联动开发时使用。
version: 2.1.0
---

# Go Multi Module Development

这个 skill 用于基于 `magicCommon` 的 Go 仓库开发。它聚焦“运行单元如何落点、如何拆层、如何与事件/路由/生命周期协同”，而不是把某个现有项目的目录形状直接复制到目标仓库。

## 1. 占位符约定

本文中的占位符只表达职责，不表达固定目录规范：

- `<entry-root>`: 可执行入口根目录，例如 `cmd`、`application`、`apps`
- `<entry-name>`: 某个入口的职责名
- `<unit-root>`: 运行单元根目录，例如 `modules`、`features`、`capabilities`
- `<group-path>`: 运行单元分组路径，例如 `shared`、`orchestration`、`platform/core`
- `<unit>`: 单个运行单元目录名
- `<unit-entry-file>`: 运行单元主文件名，例如 `module.go`、`unit.go`、`bootstrap.go`

如果目标仓库已经有既定术语，优先沿用目标仓库自己的命名。

## 2. 先看这些文件

- `go.mod`
- `README.md`
- `AGENTS.md`

## 3. 按任务读取这些 references

- 运行单元结构和落点：`references/MODULE_STRUCTURE.md`
- 事件协同：`references/EVENT_USAGE.md`
- 最小模板和脚本：`references/TEMPLATES.md`
- 如果任务涉及 `initiator` 接线、plugin `module` 生命周期、`Setup` / `Run` / `Teardown` 顺序，配合使用 `go-module-initiator-lifecycle`

## 4. 工作流

1. 先确认仓库角色和依赖
   - `magicCommon` 是基础框架
   - `magicEngine` 负责 HTTP
   - `magicOrm` 负责模型和持久化
   - 业务仓库在这些基础库之上封装入口、运行单元和对外能力
2. 先确定当前仓库已经采用的目录与命名
   - 入口可能在 `<entry-root>/<entry-name>/`
   - 运行单元可能在 `internal/<unit-root>/<group-path>/<unit>/`
   - 仓库内共享 helper 常见于 `internal/pkg/`
   - 对外复用公共包常见于 `pkg/`
   - 如果仓库已经使用 `internal/modules/kernel`、`internal/modules/blocks` 这类分组，就沿用，不要改名
   - 如果仓库没有这些名字，不要强行引入
3. 再判断运行单元的职责边界
   - 可复用基础能力单元：围绕单一资源或单一技术能力，提供稳定 CRUD、状态流转、基础校验、资源事件或公共封装
   - 编排/治理单元：组合多个基础能力或外部系统，完成策略、准入、授权、审核、运行态治理或跨资源一致性
   - 如果一个能力依赖多个低层能力才构成业务闭环，默认放入编排/治理分组
   - 不要因为一个能力带 CRUD 模型，就自动把它归入“基础能力分组”
4. 只补当前任务需要的最小层
   - `<unit-entry-file>`
   - `biz/`
   - `service/`
   - `pkg/common`
   - `pkg/models`
   - 上面这些都不是强制；缺哪层由任务边界决定
5. 涉及跨仓依赖时，同步核对对应仓库文档和 skill
   - `magicCommon`: 生命周期、event、task、session、monitoring
   - `magicEngine`: route、middleware、static、sse、tcp
   - `magicOrm`: provider、validation、query/update、remote
6. 代码完成后，同步补
   - 直接相关测试
   - 文档
   - 如有复用价值，再更新 skill

## 5. 开发规则

- 先看现有运行单元，不要凭空造新分层。
- 如果仓库使用 `magicCommon/framework/plugin/module` 生命周期，入口优先保持 `module.Register(New()) -> Setup() -> Run() -> Teardown()` 这条链。
- 新增运行单元前先完成 `<entry-root>` / `<unit-root>` / `<group-path>` / `pkg` 落点判断，并把判断写入设计文档或变更说明。
- 如果仓库存在“基础能力分组”和“编排/治理分组”，沿用现有名字；不要把某个项目里的 `kernel`、`blocks` 当成所有仓库的默认规范。
- 基础层或共享 initiator 可以提供通用查询、绑定、client 构造能力，但不负责某个具体业务“缺失时如何初始化”的策略判断。
- “当前业务运行时缺失时如何处理”属于具体服务自己的启动治理逻辑，应放在该服务自己的 startup / persistence / system 类运行单元中，不要下沉到共享基础层。
- 如果启动链路中 `baseClient`、`persistence helper`、`route registry` 等基础依赖未就绪，后续运行单元必须 fail-fast 返回明确错误，禁止继续执行到 DAO / helper 再发生 nil pointer panic。
- `biz` 负责业务和事件，不直接堆 HTTP 细节。
- `service` 负责 route / handler / request-response。
- `pkg/common` 放单元 ID、常量、错误、过滤器、结果。
- `pkg/models` 放 DTO / entity / view model。
- 如果任务只是扩展已有运行单元，优先沿用现有目录，而不是再创建新运行单元。

## 6. 常用脚本

- 创建最小运行单元骨架：`scripts/create-module.sh`

这个脚本只适用于同时满足下面条件的仓库：

- 当前仓库使用 `magicCommon/framework/plugin/module`
- 生成骨架的默认 `biz/service/pkg` 拆分符合目标仓库习惯
- 传入的 `<group-path>`、`<unit-root>`、`<unit-entry-file>` 能映射到目标仓库的真实目录

如果这些条件不成立，不要硬用脚本，直接按目标仓库现状手工落结构。

## 7. 推荐验证

先跑受影响范围，再跑全量：

```bash
GOCACHE=/tmp/go-multi-module-gocache go test ./... -count 1
```
