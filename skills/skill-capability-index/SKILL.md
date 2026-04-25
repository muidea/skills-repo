---
name: skill-capability-index
description: 用于在当前多项目 skill 集合中选择唯一主 skill 并降低重复触发歧义，覆盖项目初始化、module/initiator、application/event、magicOrm、magicBase、magicRunner、magicCas、magicFile、magicModulesRepo、magicEngine 等能力边界；当任务可能同时命中多个 skill 或需要判断 canonical/supporting skill 时使用。
compatibility: Compatible with open_code
metadata:
  version: "1.1.2"
  author: "rangh-codespace"
  created_at: "2026-04-18T23:12:34+08:00"
---

# Skill Capability Index

这个 skill 只用于选择 skill，不替代业务 skill 的实现指引。先选一个主 skill，再按证据补充 supporting skill，避免同时加载多个重叠 skill 造成指令冲突。

## 选择规则

- 每个任务默认只指定一个主 skill。
- 只有任务明确跨越多个能力域，才组合多个 skill。
- canonical skill 优先于项目专属 supporting skill。
- 只要任务直接修改当前项目 `.agents/skills/`，优先选择 skill 生命周期类 skill 作为主 skill，再补内容类 supporting skill。
- 项目专属 skill 只在任务落到该项目实现、排障或历史兼容时使用。
- 标记为 deprecated 的 skill 不用于新建能力，只能作为既有项目维护参考。
- 如果用户明确点名 skill，以用户点名为准；若点名 skill 与任务目标冲突，先说明冲突并选择更安全的主 skill。

## Skill 管理

| 任务 | 主 skill | supporting skill |
| --- | --- | --- |
| 编辑、刷新、批量同步当前项目 `.agents/skills/` 下已有 skill | `skillhub-skill-lifecycle` | 具体业务 skill，必要时再参考通用 skill 创建规范 |
| 判断某个 skill 更新后是否需要 `create` / `validate` / `feedback` / `push` | `skillhub-skill-lifecycle` | 无 |
| 批量收集、去重、归档项目本地 skill | `skillhub-skill-lifecycle` | 无 |

## 通用 Go 服务

| 任务 | 主 skill | supporting skill |
| --- | --- | --- |
| 初始化新 Go 多应用、多模块服务套件 | `go-modular-project-bootstrap` | `go-multi-module-dev`, `go-module-initiator-lifecycle`, `go-application-event-runtime` |
| 在已有项目新增业务模块、判断 kernel/blocks 落点、扩展 biz/service/pkg 分层 | `go-multi-module-dev` | `go-module-initiator-lifecycle` |
| 让已有 Go 服务“符合 go-multi-module-dev / magicCommon 基础框架”，且发现 `go.mod` 无 magicCommon/magicEngine、入口直接 `net/http`、本地 EventHub 或手写 lifecycle | `go-application-event-runtime` | `go-multi-module-dev`, magicEngine HTTP 相关 skill |
| 创建、接线或调整 initiator/module 生命周期 | `go-module-initiator-lifecycle` | `magiccommon-plugin-module` |
| 应用启动、EventHub、BackgroundRoutine、Shutdown 协同 | `go-application-event-runtime` | `magiccommon-app-bootstrap`, `magiccommon-event-driven-service`, `magiccommon-runtime-lifecycle` |
| 代码质量、架构重构、去重和解耦 | `go-refactor-pro` | 具体项目 skill |

## magicCommon 与 magicEngine

| 任务 | 主 skill | supporting skill |
| --- | --- | --- |
| magicCommon 服务入口与 framework/service/plugin 接线 | `magiccommon-app-bootstrap` | `go-application-event-runtime` |
| magicCommon 底层 event/task/execute 生命周期实现 | `magiccommon-runtime-lifecycle` | `go-application-event-runtime` |
| magicCommon 插件框架内部注册、排序、反射调度 | `magiccommon-plugin-module` | `go-module-initiator-lifecycle` |
| magicCommon 配置热加载 | `magiccommon-config-hotreload` | `magiccommon-service-health` |
| magicCommon DAO、缓存、HTTP、session、monitoring | 对应 `magiccommon-*` 专项 skill | `magiccommon-infra-review` |
| magicEngine HTTP 服务启动 | `magicengine-http-bootstrap` | `magicengine-http-routing-middleware` |
| magicEngine 路由和中间件 | `magicengine-http-routing-middleware` | `magicengine-root-routes` |
| magicEngine SSE、TCP、静态资源和上传 | 对应 `magicengine-*` 专项 skill | `magicengine-infra-review` |

## magicOrm

| 任务 | 主 skill | supporting skill |
| --- | --- | --- |
| 应用端选择 Local/Remote Provider，创建 Object/ObjectValue/SliceObjectValue | `magicorm-provider-object-usage` | `magicorm-provider-remote` |
| provider/local、provider/remote、helper、codec 内部实现排查 | `magicorm-provider-remote` | `magicorm-provider-object-usage` |
| 模型、字段、View、关系字段、struct tag | `magicorm-model-design` | `magicorm-entity-definition` |
| entity JSON、viewDeclare、constraints、readonly/default 定义核对 | `magicorm-entity-definition` | `magicorm-validation-write-safety` |
| Query、BatchQuery、Insert、Update、Delete 行为 | `magicorm-query-write-contract` | `magicorm-orm-query-update`, `magicorm-transaction-operations` |
| validation、readonly、default、req、enum、format、range | `magicorm-validation-write-safety` | `magicorm-validation` |
| schema 创建、删除、演进和关系表 | `magicorm-schema-lifecycle` | `magicorm-regression-testing` |
| 关系建模、relation-lite、response shape | `magicorm-provider-relation` | `magicorm-query-write-contract` |
| 数据库集成测试和环境排查 | `magicorm-testing-db` | `magicorm-regression-testing` |
| aging、性能漂移、错误观测 | `magicorm-aging-diagnosis` 或 `magicorm-error-observability` | `magicorm-regression-testing` |

## magicBase

| 任务 | 主 skill | supporting skill |
| --- | --- | --- |
| 应用端定义 Application、Entity、字段约束、Block、serviceExpose、数据存储 | `magicbase-data-capability-definition` | `magicorm-provider-object-usage`, `magicorm-entity-definition` |
| 普通路由、CAS 路由、RoleRouteRegistry、Privilege、session、401/403 | `magicbase-role-routing` | `magicbase-routing-auth` |
| 基于已定义能力做 DAO/helper/query/write 业务访问 | `magicbase-service-access` | `magicbase-data-capability-definition` |
| kernel/base、kernel/public 内部实体和值对象实现 | `magicbase-kernel-entity` | `magicbase-data-capability-definition` |
| magicBase 内部 kernel/block module 开发 | `magicbase-module-dev` | `go-module-initiator-lifecycle` |
| magicBase 启动链路、initiator、主入口排障 | `magicbase-app-bootstrap` | `magicbase-module-startup` |
| HTTP handler、请求解码、分页、错误包装 | `magicbase-http-handlers` | `magicbase-http-crud-toolkit` |
| 自举恢复、routeregistry、persistence 恢复 | `magicbase-service-recovery` | `magicbase-service-health` |

## magicRunner

| 任务 | 主 skill | supporting skill |
| --- | --- | --- |
| 服务治理主链：serviceExpose、Capability、Service、Publication、Subscription、Credential | `magicrunner-service-governance` | `magicrunner-service-gateway-auth`, `magicrunner-panel-service`, `magicrunner-portal-service` |
| 应用运行生命周期：Package/Release、install、schema、installer、compose、start/stop、uninstall | `magicrunner-application-runtime-lifecycle` | `magicrunner-installer-offline`, `magicrunner-vmi-install-recovery` |
| gateway 访问授权、Sig token、服务调试、public value 转发 | `magicrunner-service-gateway-auth` | `magicrunner-service-governance` |
| panel handler、管理台入口和鉴权上下文 | `magicrunner-panel-service` | `magicrunner-service-governance` |
| portal 服务目录、订阅入口、profile 边界 | `magicrunner-portal-service` | `magicrunner-service-governance` |
| runner 代理路由和 runtime-object fallback | `magicrunner-runtime-routing` | `magicrunner-runner-proxy` |
| MCP SSE 接入 | `magicrunner-mcp-service` | `magicengine-sse-streaming` |
| 新项目初始化 | `go-modular-project-bootstrap` | 不使用 `magicrunner-app-bootstrap` |
| 既有 magicRunner 应用入口维护 | `magicrunner-app-bootstrap` | `go-application-event-runtime` |

## magicCas、magicFile、magicModulesRepo

| 任务 | 主 skill | supporting skill |
| --- | --- | --- |
| magicCas 登录、刷新、JWT、endpoint session、role/namespace 授权链 | `magiccas-cas-auth` | `magiccas-http-handlers`, `magiccas-service-readiness` |
| magicCas 注册准入治理：RegistrationProfile、RegistrationPolicy、AccountRegistration、注册模板、审核、默认 role 绑定 | `magiccas-cas-auth` | `go-module-initiator-lifecycle`, `magiccas-block-module` |
| magicCas 启动和 ready、自举恢复、magicBase 强依赖 | `magiccas-service-readiness` | `magiccas-app-bootstrap`, `magiccas-base-integration` |
| magicCas 基础 block 模块：account、endpoint、namespace、role、totalizator | `magiccas-block-module` | `magiccas-base-integration` |
| magicFile 上传、下载、浏览、元数据、清理 | `magicfile-file-service` | `magicfile-static-install-paths`, `magicfile-client-integration` |
| magicFile 启动、模块装配、magicModulesRepo 依赖 | `magicfile-app-bootstrap` | `go-module-initiator-lifecycle` |
| magicModulesRepo 启动、initiator、listener 生命周期 | `magicmodulesrepo-app-bootstrap` | `magicmodulesrepo-routeregistry-health` |
| magicModulesRepo cas、metrics、totalizator block | 对应 `magicmodulesrepo-*` 专项 skill | `magicmodulesrepo-routeregistry-health` |

## 歧义处理

- “完善 skill”“刷新 skill”“同步 skill”“修改 `.agents/skills` 下的 `SKILL.md` / `agents/openai.yaml` / `references` / `scripts`” 优先用 `skillhub-skill-lifecycle`，不要直接走纯内容编辑路径。
- “项目初始化”优先判定是否新项目；新项目用 `go-modular-project-bootstrap`，不是 `magicrunner-app-bootstrap`。
- “module”先判断是业务插件生命周期还是业务模块落点；生命周期用 `go-module-initiator-lifecycle`，kernel/blocks 落点用 `go-multi-module-dev`，项目内部实现再用项目 skill。
- “block 还是 module / kernel 还是 blocks / 业务模型应该放哪里”优先用 `go-multi-module-dev`，不要直接进入项目专属 block skill。
- “符合 go-multi-module-dev”如果同时出现“基础框架 / magicCommon / magicEngine / EventHub / application framework”等目标，先做框架基线检查；如果缺依赖或入口仍为手写实现，不能只用 `go-multi-module-dev` 完成目录整理。
- “event_hub”或“后台任务”优先用 `go-application-event-runtime`；只有改底层 event/task 实现才用 `magiccommon-runtime-lifecycle`。
- “ORM provider/object/value”优先用 `magicorm-provider-object-usage`；只有修改 provider 内部才用 `magicorm-provider-remote`。
- “定义 Application/Entity/Block/serviceExpose”优先用 `magicbase-data-capability-definition`；只有 magicBase 内核实现才用 `magicbase-kernel-entity`。
- “服务能力、发布订阅、凭据”优先用 `magicrunner-service-governance`；只有请求已经落到 gateway 授权失败才用 `magicrunner-service-gateway-auth`。
- magicCas 中的“registration / 用户注册 / 注册模板 / 注册审核”默认指 `kernel/registration` 治理模块；不要选 `magiccas-block-module` 作为主 skill，也不要新增 `blocks/registration`。

## 使用步骤

1. 识别用户目标所属能力域。
2. 从矩阵选择一个主 skill。
3. 只在任务跨域或出现具体错误证据时追加 supporting skill。
4. 打开主 skill 的 `SKILL.md`，按其流程执行。
5. 如果发现矩阵与当前实现不一致，优先刷新具体业务 skill，再更新本索引。
