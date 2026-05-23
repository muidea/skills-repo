---
name: skill-capability-index
description: 用于在当前任务中选择唯一主 skill 并降低重复触发歧义，覆盖 skill 管理、通用 Go 服务初始化、运行单元生命周期、应用运行时、基础框架能力与通用重构场景；当任务可能同时命中多个 skill 或需要判断 canonical/supporting skill 时使用。
compatibility: Compatible with open_code
metadata:
  version: "1.3.0"
  author: "rangh-codespace"
  created_at: "2026-04-18T23:12:34+08:00"
---

# Skill Capability Index

这个 skill 只用于选择 skill，不替代具体 skill 的实现指引。先选一个主 skill，再按证据补充 supporting skill，避免同时加载多个重叠 skill 造成指令冲突。

这个全局版本只保留跨项目稳定成立的通用路由规则，不内置任何具体业务项目、业务仓库或项目私有技能矩阵。像 `magicCommon`、`magicOrm`、`magicEngine` 这类基础框架能力可以保留；像具体业务产品、业务服务或项目仓库名则不应写入全局索引。只要当前项目存在自己的 `.agents/skills/`、本地 capability index 或项目专属 skill，应优先使用项目本地定义；本 skill 只负责兜底。

## 选择规则

- 每个任务默认只指定一个主 skill。
- 只有任务明确跨越多个能力域，才组合多个 skill。
- canonical skill 优先于 supporting skill。
- 当前项目如果存在本地 `.agents/skills/`，优先使用项目本地 skill，再决定是否回退到全局 skill。
- 只要任务直接修改当前项目 `.agents/skills/`，优先选择 `skillhub-skill-lifecycle` 作为主 skill，再补内容类 supporting skill。
- 项目专属 skill 只应在当前项目明确提供且任务确实落到该项目实现时使用；不要在全局 skill 中预置某个具体项目的路由矩阵。
- 标记为 deprecated 的 skill 不用于新建能力，只能作为既有维护参考。
- 如果用户明确点名 skill，以用户点名为准；若点名 skill 与任务目标冲突，先说明冲突并选择更安全的主 skill。

## Skill 管理

| 任务 | 主 skill | supporting skill |
| --- | --- | --- |
| 编辑、刷新、批量同步当前项目 `.agents/skills/` 下已有 skill | `skillhub-skill-lifecycle` | 具体内容 skill，必要时再参考 `skill-creator` |
| 判断某个 skill 更新后是否需要 `create` / `validate` / `feedback` / `push` | `skillhub-skill-lifecycle` | 无 |
| 批量收集、去重、归档项目本地 skill | `skillhub-skill-lifecycle` | 无 |
| 设计新的通用 skill 结构、说明和边界 | `skill-creator` | `skillhub-skill-lifecycle` |

## 通用 Go 服务

| 任务 | 主 skill | supporting skill |
| --- | --- | --- |
| 初始化新的 Go 服务仓库或服务套件 | `go-modular-project-bootstrap` | `go-multi-module-dev`, `go-module-initiator-lifecycle`, `go-application-event-runtime` |
| 在已有仓库新增运行单元、调整运行单元落点或分层 | `go-multi-module-dev` | `go-module-initiator-lifecycle` |
| 创建、接线或调整 initiator / plugin / module 生命周期 | `go-module-initiator-lifecycle` | 无 |
| 应用启动、运行时、EventHub、后台任务、Shutdown 协同 | `go-application-event-runtime` | 无 |
| 代码质量、架构重构、去重和解耦 | `go-refactor-pro` | 相关主 skill |

## 基础框架能力

| 任务 | 主 skill | supporting skill |
| --- | --- | --- |
| `magicCommon` 服务入口、framework/service/plugin 接线 | `magiccommon-app-bootstrap` | `go-application-event-runtime` |
| `magicCommon` 底层 event/task/execute 生命周期实现 | `magiccommon-runtime-lifecycle` | `go-application-event-runtime` |
| `magicCommon` 插件框架内部注册、排序、反射调度 | `magiccommon-plugin-module` | `go-module-initiator-lifecycle` |
| `magicCommon` 配置热加载 | `magiccommon-config-hotreload` | `magiccommon-service-health` |
| `magicCommon` DAO、缓存、HTTP、session、monitoring 等基础设施能力 | 对应 `magiccommon-*` 专项 skill | `magiccommon-infra-review` |
| `magicOrm` provider/object/value 使用与应用侧接线 | `magicorm-provider-object-usage` | 无 |
| `magicOrm` 模型、字段、关系和 entity 定义 | `magicorm-model-design` | `magicorm-entity-definition` |
| `magicOrm` Query/Insert/Update/Delete 与校验约束 | `magicorm-query-write-contract` | `magicorm-orm-query-update`, `magicorm-validation-write-safety` |
| `magicOrm` schema、测试、性能诊断和错误观测 | 对应 `magicorm-*` 专项 skill | 无 |
| `magicEngine` HTTP 服务启动 | `magicengine-http-bootstrap` | `magicengine-http-routing-middleware` |
| `magicEngine` 路由和中间件 | `magicengine-http-routing-middleware` | `magicengine-root-routes` |
| `magicEngine` SSE、TCP、静态资源和上传 | 对应 `magicengine-*` 专项 skill | `magicengine-infra-review` |

## 通用判定

- “完善 skill”“刷新 skill”“同步 skill”“修改 `.agents/skills` 下的 `SKILL.md` / `agents/openai.yaml` / `references` / `scripts`” 优先用 `skillhub-skill-lifecycle`，不要直接走纯内容编辑路径。
- “创建新 skill”或“重写 skill 定义”优先判定是否属于 skill-hub 管理场景；是的话先用 `skillhub-skill-lifecycle`，内容设计再参考 `skill-creator`。
- “项目初始化”优先判定是否是在创建新仓库或新服务套件；如果是，优先用 `go-modular-project-bootstrap`。
- “module”先判断是生命周期问题还是运行单元落点问题；生命周期用 `go-module-initiator-lifecycle`，分层和目录落点用 `go-multi-module-dev`。
- “event_hub”“后台任务”“启动/关闭协同”优先用 `go-application-event-runtime`。
- `magicCommon`、`magicOrm`、`magicEngine` 这类基础框架名可以作为全局路由信号保留；但不要把具体业务项目或业务仓库名写进本全局索引。
- 如果任务已经明显落在某个项目本地 skill 里，而当前项目也提供了对应 skill，优先使用项目本地 skill，不要让全局索引覆盖本地定义。
- 如果当前项目没有对应 skill，再回退到本全局索引中列出的通用 skill。

## 使用步骤

1. 先判断当前项目是否存在本地 `.agents/skills/` 或本地 capability index。
2. 如果有本地定义，优先从本地定义选择主 skill。
3. 如果没有，再从本索引选择一个主 skill。
4. 只在任务跨域或出现明确证据时追加 supporting skill。
5. 打开主 skill 的 `SKILL.md`，按其流程执行。
