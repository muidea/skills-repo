---
name: code-cleanup-regression-guard
description: 用于执行失效代码、兼容代码、fallback、legacy 文档或结构清理前的回归防护流程，要求先识别业务边界、运行时闭环、真实外部系统行为和验收基线，避免误删仍支撑 MVP 或端到端流程的代码。
metadata:
  version: "1.0.0"
  author: "fedquery"
  created_at: "2026-04-27T23:06:05+08:00"
---
# Code Cleanup Regression Guard

本 skill 用于在清理代码或文档前建立“可删除性证明”和回归验证边界。清理目标可以是失效代码、过期文档、旧入口、无用测试、fallback、兼容逻辑或 legacy 适配，但只有在确认其不承担正式业务职责后才能删除。

## 适用场景

- 用户要求“清理失效代码”“去掉非必要兼容”“删除 fallback”“移除 legacy”“整理过期文档”“收口旧实现”。
- 大范围重构、目录迁移、模块边界调整后，需要判断旧代码是否还能删除。
- 真实 LLM、MCP、Shell、SSH、HTTP、事件运行时、后台任务、人工审批、配置热加载等外部或异步链路已接入，删除代码可能影响端到端流程。
- 回归测试突然大量失败，需要复盘是否误删了边界归一化、状态恢复、观测、验收或人工决策闭环代码。

## 工作流程

1. 先定义清理范围，不直接删除。列出候选文件、函数、配置、脚本或文档，并说明它们被判定为“失效”的依据。
2. 对每个候选项做业务归属判断。区分“真正无入口无语义”和“看起来像兼容但承担正式边界职责”的代码。
3. 检查运行时闭环影响。重点确认候选项是否参与 `input -> orchestration -> tool/runtime -> validation -> follow-up -> completion -> observability` 之类的业务闭环。
4. 检查外部系统边界。真实 LLM、MCP、Shell、SSH、HTTP provider、配置热加载、事件 hub 和后台任务的输出存在不稳定性，schema 归一化、重试入口、状态恢复、follow-up、人工补充信息处理通常不是无效代码。
5. 建立清理前验收基线。先运行或列出必须通过的测试和 e2e 验证；如果本地阶段要求真实外部系统，不能只依赖 mock 用例。
6. 小批量删除并即时验证。不要一次性删除跨多个业务闭环的代码；每批删除后运行对应单元、边界契约和端到端验证。
7. 记录清理结论。说明删除了什么、为什么可删、验证覆盖了什么、哪些候选项因仍有业务意义而保留。

## 可删除性判定

- 可以删除：无任何入口、无引用、无配置开关、无测试依赖、无文档承诺、无运行期数据读取、无用户交互路径、无观测价值的内容。
- 可以删除：已被正式业务模型完全替代，且新模型已覆盖读写、展示、验证、迁移或初始化路径的旧实现。
- 不应删除：LLM/MCP/外部 API 输出归一化、schema 容忍、状态恢复、补充信息后继续执行、approval/ticket 闭环、run snapshot、observability、validation evidence、配置加载、事件订阅关闭、后台任务生命周期等支撑执行稳定性的代码。
- 不应删除：当前阶段虽然看起来像 fallback，但实际用于真实环境 MVP 验收、人工决策流转、异步执行可观测或跨模块边界适配的代码。

## 验证要求

- 删除前必须确认项目的核心验收命令；Go 服务通常至少包含 `go test ./... -count 1`、边界契约验证、服务级 HTTP 验证和必要的 e2e 脚本。
- 对本地开发阶段要求真实外部系统的项目，真实 LLM 或真实 provider 用例应在本地执行；CI 中可按项目约定使用 mock，避免误报。
- 如果用户要求使用“当前部署实例”，e2e 测试不得自行启动服务，必须指向已部署服务并先检查 `/healthz`、`/readyz` 或等价 ready 接口。
- 清理影响 Web 管理界面时，必须验证对应业务模型仍可创建、查看、修改、推进、审批和观测，不能只验证接口返回成功。
- 若回归失败，不要继续扩大清理范围；先定位失败链路属于“误删业务边界”“测试基线缺失”“真实外部输出漂移”还是“原有缺陷被暴露”。

## Formatter

- `SKILL.md` / Markdown / YAML: 保持标题、列表和代码块格式稳定；归档前运行 `skill-hub validate code-cleanup-regression-guard --links`。
- `scripts/`: 当前模板未包含脚本；新增 Go/Python/JavaScript/TypeScript/Shell 等脚本时，必须在本段补充项目可运行的具体 formatter 命令。
- 常见 formatter 示例：Go 使用 `gofmt -w <files>`，Python 优先使用仓库已有的 `ruff format <files>` 或 `black <files>`，JavaScript/TypeScript 优先使用仓库已有的 `npm run format` 或 `prettier`，Shell 优先使用仓库已有 formatter 或语法检查。
- 不要声明当前项目无法执行的 formatter；如果对应文件类型没有 formatter，明确写出人工格式要求。

## 输出要求

- 给出清理候选清单和处理结果：已删除、保留、暂缓、需要用户确认。
- 对保留项必须说明业务意义，避免后续再次被误判为失效代码。
- 对删除项必须说明验证结果，并列出未执行的验证及原因。
- 如果本次经验适合复用，应运行 `skill-hub validate code-cleanup-regression-guard --links`，再用 `skill-hub feedback code-cleanup-regression-guard --dry-run` 预览归档；只有在确认后执行 `skill-hub feedback code-cleanup-regression-guard --force`。

## 注意事项

- 不要把“代码看起来像 fallback”作为删除依据；必须证明它不支撑正式业务边界。
- 不要把 mock 测试通过等同于真实端到端通过；真实外部系统和多轮人工决策通常会暴露 mock 覆盖不到的问题。
- 不要在调度器、框架层或通用运行时中加入具体业务目标识别逻辑来修复清理造成的问题；应回到模型边界、adapter、prompt contract、状态机或业务服务层修复。
- 不要删除用户未授权范围外的改动；发现工作树已有无关修改时，只记录并避开。
- 不要自动执行远程 `skill-hub push`；除非用户明确要求发布到远程仓库。
