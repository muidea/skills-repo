---
name: workorch-core-template-boundary
description: "在 WorkOrch 开发、评审或排查中涉及 kernel/orchestrator/appservice、workspaceTemplate、Soul、DoD、evidence policy、prompt/context、ticket/approval、runtime block、memory 或 e2e 时使用；用于强制核对 WorkOrch 基础能力与 workspaceTemplate 业务策略边界，避免把具体场景、语言、工具或模板规则写入 core 通用流程。"
metadata:
  version: "1.0.7"
  author: "rangh"
  created_at: "2026-05-09T17:01:44+08:00"
---

# WorkOrch Core / Template Boundary

本技能用于在 WorkOrch 代码开发、代码评审、缺陷排查和需求收口时，先确认“基础能力”和“模板业务策略”的职责边界，再决定修改落点。

## 强制入口：合同审计先行

凡是准备修改 WorkOrch 代码、模板、Soul、TUI/Web 交互、EventHub 流转、LLM prompt/context、runtime 收敛、e2e 验证或 skill 规则时，必须先完成 `Contract Audit`。该审计是改代码前的准入门禁，不是修改后的总结。

执行顺序固定为：

1. 冻结事实：记录当前 workspace/run/step/ticket/approval、权威状态、最后事件、checkpoint、accepted/rejected evidence、实际 blocker 和复现证据。
2. 判定 owner：明确问题归属 `core`、`workspaceTemplate/Soul/policy`、`TUI/Web`、`LLM context/provider` 或 `runtime environment`，不能用单个 live workspace 现象直接反推通用代码应修改。
3. 拉通事件链路：写清 command/event -> owner state -> projection，或 LLM input -> contract validation -> evidence ledger -> next action 的完整路径。
4. 定义合同缺口：说明当前设计预期是什么、实际偏差是什么、缺失的是状态机规则、上下文字段、evidence、投影刷新、模板策略还是环境能力。
5. 选择最小落点：只修改直接命中 blocker 的 owner 模块；若缺少证据，先补审计、测试或观测，不补下游兜底。
6. 绑定验证：每个代码改动必须对应失败样本测试、边界搜索、e2e/live verification、投影验证或 cache/context 验证之一。

未完成 `Owner`、`Event path`、`Contract gap`、`Proposed change` 和 `Verification` 五项时，不得进入代码修改；如果连续两次修改后同一问题仍未改善，停止继续局部补丁，重新执行完整合同审计。

## 适用场景

- 修改 `internal/modules/kernel/**`、`internal/modules/blocks/**`、`internal/modules/application/workorchd/biz/appservice/**`、`internal/services/workorch/**`、`internal/pkg/workorchclient/**`、`internal/pkg/workorchport/**`、`internal/pkg/repository/**`、`application/workorch` 或 CLI/TUI/Web 入口时。
- 涉及 `workspaceTemplate`、Soul、Goal、DoD、Run、Ticket、Approval、Memory、Artifact、EvidenceQuality、runtime block、LLM prompt/context、e2e 验收时。
- 排查“某个模板或业务场景执行异常”时，特别是软件开发、天气查询、代码审查、文档生成等模板相关问题。
- 发现通用代码中出现具体业务名、模板名、编程语言、命令、外部服务、城市、服务器地址、测试输出 marker 等内容时。

## 核心原则

- WorkOrch core 只提供中立的编排、状态机、事件、治理、证据、上下文传递、运行时调度和质量门禁能力。
- `application/workorch` 是薄入口，`internal/services/workorch` 是 process service，`internal/modules/**` 只承载真实 framework initiator/module/block；process service 不应注册为 plugin module。
- CLI/TUI/agent 只能通过 `internal/pkg/workorchport` 访问 WorkOrch 能力；remote backend 只能通过 `internal/pkg/workorchclient` 访问 REST API；embedded backend 只能通过 EventHub command/result 访问正式 owner state。
- workspace/run/ticket/approval/result/artifact 等对象跨 workspace 可能同名，所有 command、REST、CLI/TUI backend 和派生持久化 ID 必须携带足够 scope；无 scope 的 resolve/get 入口只能选择唯一 open 对象，否则返回 conflict。
- `workspaceTemplate`、Soul、默认 DoD、template-bound policy、Skill、MCP 配置和 e2e 数据承载具体业务策略。
- 通用代码可以消费结构化字段，但不能根据模板名、Soul 名称、业务文本、命令输出文本或具体场景字符串推断行为。
- 如果需要支持某类场景规则，优先把规则做成数据配置，再由通用能力读取数据执行。
- 不为了快速修复在 core 中加入临时兼容、场景特判或 “contains xxx” 逻辑。
- LLM cache 是 core runtime 合同的一部分。任何 prompt/context/request rendering 修改都必须保持 provider-facing 稳定前缀稳定，不能为了当前阶段、repair、provider retry 或某个模板的执行效果污染 C0。
- Runtime 必须维持贯穿 planning、execution、follow-up、repair、validation、acceptance、resume 的强一致 Goal/DoD coverage contract；任何阶段不得丢失当前定义、未关闭缺口、已接受证据、被拒绝证据和下一步收敛约束。
- Memory 是当前决策的参考资产，不是事件日志搬运。无法作为后续决策参考、缺少 provenance、已过期、已被 superseded、纯诊断流水或低价值的 memory 不应进入 LLM 可见上下文。
- Contract violation 输出可以记录、投影和反馈给 LLM 重试，但未通过合同的输出只能作为 rejected diagnostic evidence；不能执行，不能作为 accepted result/artifact，也不能写成长期可召回 memory。

## 职责边界

WorkOrch core 可以包含：

- 通用状态：Goal、DoD、Run、Step、Ticket、Approval、Memory、Artifact、EvidenceQuality。
- 通用机制：事件发布订阅、异步回调、上下文预算、traceability、质量门禁、repository clone、read model 投影。
- 进程壳和适配器：`internal/services/workorch` 负责 mode selection、CLI/TUI/remote/server 编排和 backend 选择，但不拥有正式业务状态。
- 契约包：`internal/pkg/workorchport` 定义 CLI/TUI/agent port DTO，`internal/pkg/workorchclient` 定义 REST client DTO、path 构建和 error mapping。
- 通用 block 能力：shell/file/web/llm/mcp/approval 等能力的参数执行、结构化输出和错误处理。
- 通用策略解释器：例如读取 `evidencePolicies` 并按统一 schema 标记 `evidenceQuality`。
- 通用 LLM request 分区：C0 稳定语言/Schema 合同、C1 Goal/DoD 定义、C2 声明式能力合同、C3 阶段合同、C4 当前进展/失败/动作、C5 大对象引用。

WorkOrch core 不应包含：

- 具体模板 ID 或 Soul ID 的业务判断，例如 `software-dev`、`weather-query`、`code-review`。
- 具体语言、框架或命令策略，例如只针对 Go、Python、Node、`go test`、`npm test` 的判断。
- 具体业务实体，例如城市、服务器地址、SSH 账号、比赛、某个应用配置。
- 具体输出 marker 的硬编码，例如某测试框架的“未执行测试”文本。
- 只为某个 e2e 场景通过而加入的流程分支。

Template / Soul / policy 可以包含：

- 模板 ID、阶段 Soul、默认 Goal、默认 DoD、业务提示词和执行约束。
- template-bound policy，例如 `workspaceTemplate.evidencePolicies`。
- 特定模板的验收标准、e2e fixtures、示例仓库、场景化测试数据。

## LLM Context / Cache 约束

涉及 `prompt_messages.go`、`http_provider.go`、`sdk_provider.go`、`provider_context_budget.go`、`provider_cache_plan.go`、`runtime_adapter.go`、LLM usage/read model、memory recall、context budget 或 request log 的修改时，必须额外遵守本节。

- C0 只能表达长期稳定的 system prompt、语言规则、输出 JSON schema、字段边界和中立 runtime 合同。
- C0 禁止包含 workspaceId、runId、stepId、Goal/DoD 正文、capability catalog、当前阶段、当前失败、当前进展、memory recall、provider retry、recovery mode、`assessmentOnly`、`stateChangingOutputRequired`、`repairObjective`、`repairActionPackage` 或 requested action。
- `stateChangingOutputRequired`、`repairObjective`、`stateChangingRecoveryMode`、provider timeout retry、assessment-only、requiredOutput / forbiddenActions 等运行期动态约束必须进入 C3 stage contract 或 C4 current-action。
- C1 只能承载当前 Goal/DoD 定义及 definition revision / definitionChangeImpact；Goal/DoD 变化应改变 `workspaceDefinitionHash`，不应改变 `stablePrefixHash`。
- C2 只能承载声明式 runtime capability、governance、Soul/policy 能力合同；当前阶段临时允许或禁止 executable output 不得改写 C2 能力目录。
- C3/C4/C5 承载运行期易变信息，包括 workspace/run identity、stage contract、repair action package、current failure/progress、process evidence timeline、memory recall、tool results、snapshots、trace refs 和 current requested action。
- 同一 run 内仅因 repair/follow-up/assessment/provider retry/state-changing 模式变化导致 `stablePrefixHash` 变化，必须视为 request rendering 缺陷。
- Provider 私有 cache-control 只能由 adapter 基于中立 `cachePlan.adapterHint` 转换；core runtime 不直接写入 provider 私有缓存字段，也不把 provider 私有缓存状态作为业务恢复状态。

## 强一致收敛合同约束

涉及 orchestrator、runtime repair、graph follow-up、completion gate、DoD gate、decision ticket、resume/replan、provider retry 或 LLM step input 的修改时，必须额外遵守本节。

- 每个 LLM step input 必须能重建当前有效 Goal/DoD、definition revision、coverage baseline、unresolved coverage、current progress、failure surface、process evidence timeline、accepted evidence、rejected evidence、requiredOutput / allowedOutputs 和 current requested action。
- Goal/DoD 通过 Web/TUI/API 补充或变更后，必须形成新的 definition revision，并触发后续 run/step 基于最新定义重新评估；不得把新增 Goal 追加成低显著性的历史文本，也不得继续按旧基线完成。
- 新 definition 是 cumulative latest。除非存在显式冲突，新的 Goal/DoD 只能补充或细化，不得弱化旧约束、删除仍有效证据或降低验收目标。
- Repair / follow-up / provider retry / resume 必须继承原失败 step 的阶段语义和收敛合同；decision resolution 只能补充恢复上下文，不能覆盖原 step 的 `runtimeStage`、`runtimeStageMode`、`repairObjective`、`stateChangingOutputRequired` 或 required output。
- `repairActionPackage` 是 primary actionable contract。governanceHistory、memory、旧 executionGraph、旧 rejected patch、旧 decision question 只能作为证据或 lineage，不得与当前 repairActionPackage 竞争。
- 当 runtime 已具备可自动继续的 evidence、capability 和 requiredOutput 时，LLM 返回 `blocked_on_decision` 应先经过中立的 decision ticket gate；不应在可机械修复、可继续验证或可 runtime repair 的场景直接阻塞。
- 上下文门禁失败属于 provider 前准入失败，不能被包装成普通 state-changing repair 交给 LLM 自修；应按 read_required / fail_fast 等结构化 gate action 处理。

## Context / Memory 质量约束

涉及 memory 写入、memory recall、selectedContext、processEvidenceTimeline、currentProgressDigest、request log、context budget 裁剪或摘要时，必须额外遵守本节。

- LLM 可见上下文必须按事件发生顺序、定义修订顺序、工具调用顺序和验证顺序保序；只有无语义顺序的集合才允许按 stable id 排序。
- 裁剪上下文时，禁止裁掉当前 Goal/DoD、requiredOutput、current failure、latest actionable diagnostics、target snapshot hash、accepted/rejected evidence、processEvidenceTimeline 中的关键 sourceRef。
- 脱敏和摘要不能改变语义。被 redacted/truncated 的内容不得被标记为可用于 complete file_write / exact patch 的安全快照。
- Memory 写入必须包含可追溯 sourceRef、类型、用途、confidence/importance 或等价质量字段；不能把 provider retry 流水、泛化失败摘要、无行动价值的日志片段写成可召回 memory。
- Memory recall 只能注入当前 retrieval 选中的高价值参考；excluded、stale、superseded、diagnostic-only、低置信或低重要度 memory 只能保留审计摘要，不能进入 LLM 正文。
- `contractViolationRecovery`、`contractViolationType`、`runtime_contract_violation`、违例 rule ID、rejected output 和 diagnostic-only 标签都属于当前恢复诊断；只能通过 C4 current-action 显式注入当前 retry，不能写成长期 memory。
- 如果 LLM 持续扩图、重复检查或只修测试/表象，优先核对上下文是否缺少当前真实进展、已存在内容、失败诊断、目标资源快照、未关闭 coverage 和已拒绝方案，而不是在 core 中加入场景特判。

## 工作流程

0. 先输出或更新合同审计记录。
   - 新需求、缺陷排查、线上 workspace 收口、测试失败、review 后修复都必须先写 `Contract Audit`。
   - 审计记录可以写在回复、任务文档或 `docs/70-roadmap/active/**` 对应文档中；必须在首次代码补丁前完成。
   - 审计必须明确“旧失败进入哪个函数/事件处理器、当前输出是什么、改动后应输出什么、如何验证不再偏”。

1. 再定位需求属于基础能力还是模板策略。
   - 如果多个模板都应复用，优先放在 core 通用能力。
   - 如果只对某类 workspaceTemplate 生效，优先放在 template/Soul/policy/e2e 数据。
   - 如果不确定，默认不要写入 kernel/orchestrator，先抽象成结构化数据和通用解释器。

2. 修改前执行边界搜索。
   - 使用 `rg` 检查目标通用目录是否已有或即将加入场景字符串。
   - 对涉及证据、prompt、DoD、ticket、approval 的修改，检查是否有按文本内容推断业务语义。
   - 对涉及 LLM request/context/cache 的修改，检查动态运行期字段是否进入 C0，检查 provider 私有 cache 字段是否进入 core。
   - 对涉及 repair/follow-up/resume/definition change 的修改，检查是否仍能继承最新 Goal/DoD、coverage、requiredOutput、accepted/rejected evidence 和 current requested action。
   - 对涉及 CLI/TUI/agent/backend/client 的修改，检查是否仍满足 process service、port、client、EventHub owner 边界，以及 REST query string 是否与 handler/脚本一致。

```bash
rg -n "software-dev|weather-query|code-review|go test|npm test|no tests to run|city|ssh|server" internal/modules/kernel internal/modules/application/workorchd/biz/appservice internal/pkg
rg -n "stateChangingOutputRequired|repairObjective|providerTimeoutStateChangingRetry|assessmentOnly|runtimeRepairFollowUp|currentProgressDigest|memoryRecall|Cache-Control|cache_control" internal/modules/blocks/llm internal/modules/kernel
rg -n "definitionChangeImpact|coverageTargetSet|repairActionPackage|processEvidenceTimeline|requiredOutput|blocked_on_decision|contextGate" internal/modules/kernel internal/modules/blocks/llm
rg -n "internal/modules/application/workorch(?!d)" application internal scripts Makefile README.md --pcre2
rg -n "workorchclient|biz/backends" internal/services/workorch/service internal/services/workorch/biz/agent internal/services/workorch/biz/session -g "*.go"
rg -n "internal/services/workorch|internal/pkg/workorchclient|biz/backends" internal/pkg/workorchport -g "*.go"
rg -n "workorchport|internal/services/workorch|framework/application|EventHub|event\\.Hub" internal/pkg/workorchclient -g "*.go"
rg -n "kernel/.*/(biz|service|repository)|repository\\." internal/services/workorch internal/pkg/workorchport internal/pkg/workorchclient -g "*.go"
```

3. 选择正确落点。
   - 通用字段和状态：放在 `internal/pkg/common`、kernel model、repository、read model。
   - 通用执行与门禁：放在 orchestrator 或 block 通用解释器。
   - 模板策略：放在 `internal/modules/application/workorchd/biz/bootstrap/defaults/templates.json`、`souls.json`、Skill/MCP 配置或 e2e fixture。
   - workspace 创建期绑定：模板数据需要随 workspace 固化时，创建 workspace 时从 template 拷贝到 workspace，运行期只读取 workspace 绑定数据。

4. 修改中保持数据化。
   - 使用结构化字段，例如 `evidenceQuality`、`zeroWork`、`evidenceTags`、`policyId`。
   - 避免在通用代码里解析自然语言业务结论。
   - 避免通过 Soul ID、template ID、workspace title 推断功能分支。

5. 修改后做反向核对。
   - 搜索通用目录中的业务词、模板词、语言词和命令词。
   - 确认 template 专项内容只出现在 `templates.json`、`souls.json`、template/e2e 测试或专用 fixture。
   - 确认新增单测至少覆盖：通用解释器、template 数据绑定、非目标模板不被影响。
   - 如果修改了 LLM request rendering，新增或更新 cache 相关回归测试，至少证明动态阶段字段不会改变 C0 `stablePrefixHash`。
   - 如果修改了 Goal/DoD、repair、follow-up、resume、memory 或 context budget，新增或更新回归测试证明最新定义、未关闭 coverage、requiredOutput 和关键 evidence 未丢失且顺序正确。

## 合同审计防偏流程

当任务涉及 workspace 执行不收敛、LLM 合同违例、TUI/Web 状态不一致、EventHub 流转异常、CPU/IO 异常、replan/resume 不推进或多轮 repair 循环时，必须先完成合同审计，再决定是否改代码。

### 修改前冻结证据

每次改动前必须记录可复核的当前事实：

- `workspaceId`、`runId`、`stepId`、`ticketId` 或 `approvalId`。
- 当前状态、最后事件时间、最新 checkpoint、最新 accepted/rejected evidence refs。
- 当前真实 blocker：运行中无目标产出、等待 decision/approval、合同违例、provider transient failure、projection 展示滞后、端侧命令未提交成功、EventHub 未投递或未消费。
- 预期状态和实际状态的差异。
- 涉及 owner：coverage ledger、convergence contract、repair action package、execution contract、evidence recorder、projection、TUI/Web port、workspaceTemplate/Soul/policy。

如果无法说明“旧失败会进入哪个函数或事件处理器、当前实现会输出什么、改动后应输出什么”，不得开始改代码。

### 修改前判定落点

必须先把问题归入一个主落点：

- `workorch core`：中立状态机、EventHub、coverage ledger、convergence、contract validation、evidence、projection、port DTO、runtime 调度。
- `workspaceTemplate/Soul/policy`：具体业务目标、业务验证习惯、工具选择偏好、DoD 默认项、template-bound evidence policy。
- `TUI/Web`：只负责命令提交、投影展示、输入提示和订阅刷新，不拥有业务状态机。
- `LLM context/provider`：request 分区、上下文裁剪、cache 稳定性、provider transient retry。
- `运行环境`：凭证、网络、外部服务、provider 配额、文件系统或进程生命周期。

不能因为 live workspace 的单点现象，把具体业务、语言、工具、模板、文件名或命令输出 marker 写入 `kernel/orchestrator`、通用 `appservice` 或 repository。

### 修改前建立合同链路

对 runtime 收敛类问题，必须按顺序核对完整链路：

1. 命令来源：TUI/Web/REST/agent 是否只产生 scoped command/event。
2. EventHub：command/event 是否投递到 owner，是否同步等待同 lane 或发生丢失。
3. Owner state：workspace/run/ticket/approval/coverage 的权威状态是否只由 owner 更新。
4. Coverage ledger：当前 Goal/DoD、definition revision、required evidence、accepted/rejected evidence、missing evidence 是否一致。
5. Convergence contract：ledger 状态是否映射为唯一下一步 action。
6. Repair action package：是否只渲染当前 action 的 requiredOutput。
7. LLM input：是否包含最新 Goal/DoD、当前 gap、requiredOutput、process evidence timeline、target snapshot 和 rejected diagnostics。
8. Execution contract：LLM 输出是否通过合同验证，违例是否只作为 rejected diagnostic evidence。
9. Evidence recorder：accepted evidence 是否回写 ledger 并触发下一轮状态重算。
10. Projection：workorchd 是否刷新 ViewModel，TUI/Web 是否只展示投影。

任何环节缺少证据，都先补审计或测试，不直接改下游兜底。

### 合同审计输出模板

每次准备修改 WorkOrch 代码前，先在响应、任务文档或对应 active roadmap 文档中输出以下审计记录。记录不要求冗长，但必须能让下一次接手的人复核“为什么改、改哪里、如何证明没有偏”。

```markdown
## Contract Audit

- Scope: <workspaceId/runId/stepId/ticketId/approvalId 或代码路径>
- Observed state: <当前状态、最后事件、checkpoint、accepted/rejected evidence refs>
- Expected state: <按设计合同应发生的状态变化或输出>
- Deviation: <实际偏差，避免泛化成“执行失败”>
- Owner: <core | template/Soul/policy | TUI/Web | LLM context/provider | runtime environment>
- Event path: <command/event -> owner -> state -> projection 或 LLM step -> contract -> evidence>
- Contract gap: <缺失的状态机规则、上下文字段、evidence、投影刷新或模板策略>
- Proposed change: <待改函数/模块/配置，说明为什么直接命中 blocker>
- Boundary check: <说明是否保持 core 业务中立，是否有模板/语言/命令特判>
- Verification: <失败样本测试、边界搜索、e2e/live verification、缓存或投影验证>
```

没有完成 `Owner`、`Event path`、`Contract gap` 和 `Verification` 四项时，不得直接进入代码修改。

### 反打圈门禁

每次修改前后必须做反打圈审核：

- 改动必须直接命中当前 blocker 路径；未命中时不能声明修复 live blocker。
- 若连续两次修改后同一 workspace 仍未正向推进，停止追加局部补丁，回到完整链路审计。
- 修改 prompt、Soul 或 template 时，必须说明它如何绑定到 workspace、如何进入 run executionContext、如何进入 LLM input；只改文档但没有绑定路径不算收口。
- 修改 core 合同时，必须新增失败样本单测，证明原错误会被提前拒绝、正确分类或转入唯一下一步 action。
- 修改 projection/TUI 时，必须证明 workorchd 是 ViewModel owner，TUI/Web 不保留另一套业务推断状态。
- 修改 contract violation recovery 时，必须证明 rejected output 没有 state-changing side effect、没有进入 accepted evidence/result/artifact，也没有写成高价值 memory。

### LLM 违例收敛规则

LLM 输出一定可能不稳定，runtime 不能依赖 LLM 自己选择正确状态转移。

- Runtime 负责 deterministic state transition：coverage 分类、missing evidence 计算、assessment-ready 检测、focus binding、requiredOutput 渲染、accepted/rejected evidence 记录、decision/approval gate eligibility、completion gate。
- LLM 只负责 candidate content generation：state-changing output、validation evidence graph、assessment with evidence refs、structured blocker。
- 违例输出只能记录为 rejected diagnostic evidence；不能执行、不能接受、不能写 artifact/result，也不能成为长期 memory。
- 只有当下一步仍需要 LLM 生成内容时才允许 bounded retry；如果 ledger 已经能确定下一步 action，runtime 必须确定性推进。

### 必要验收证据

代码收口完成前至少需要以下证据之一覆盖每个显式需求：

- 失败样本单测或集成测试证明旧错误路径被正确收敛。
- 边界搜索证明 core 没有新增业务/模板/语言/工具特判。
- EventHub/owner/projection 测试证明状态由 owner 管理，端侧只消费投影。
- LLM request/cache 测试证明动态运行期字段没有污染 C0，且关键 Goal/DoD/requiredOutput/evidence 没有被裁剪。
- live verification 记录二进制版本、进程启动时间、run id、decision/replan/resume 时间和最终状态。

## 收口修改规范

当任务来自线上 workspace 执行异常、TUI/Web 状态异常、CPU/IO 异常或多轮 repair 不推进时，必须先完成下列核对，再改代码：

1. 记录真实 blocker。
   - 写明 workspaceId、runId、currentStep、ticket/approval id、failureClass、failureSignature、最后事件时间、最新 evidence refs、实际变更文件和缺失 Goal/DoD。
   - 区分“还在运行但无目标产出”、“等待 decision/approval”、“validation 合同失败”、“provider transient failure”、“projection 展示滞后”和“端侧输入未提交成功”。

2. 对齐改动落点。
   - 状态机、coverage ledger、repair budget、projection、EventHub、BackgroundRoutine、REST/TUI port 属于 core 通用能力，必须保持业务中立。
   - 代码生成偏差、服务验证习惯、测试 harness、提交快照、LSP 使用顺序等属于 `software-dev` template / Soul / profile / skill，不能硬编码进 kernel/orchestrator。
   - 某个 live workspace 的交付代码缺口只能作为现象和测试样本，不能把目标项目的文件名、语言、端口、协议或工具名写入 core 判定。

3. 优先修正直接阻塞路径。
   - 若 live blocker 是 validation graph 被 shell policy 拒绝，优先修正 concrete validation contract / Soul 验证策略；不要继续泛化改 context、cache 或 TUI。
   - 若 live blocker 是处于 decision 但 TUI prompt 不刷新，优先核对 workorchd projection、port DTO、TUI Presenter/ViewModel 订阅链；不要让 TUI 自行推断业务状态。
   - 若 live blocker 是 CPU/IO 持续过高，优先核对 request-time scan、projection rebuild 去重、watchdog 周期、事件订阅泄漏；不要靠扩大超时或压低日志绕过。

4. Concrete validation graph 规范。
   - `repairActionPackage.requiredOutput.mustProduceConcreteValidationEvidence=true` 时，LLM 输出必须是 bounded validation evidence graph 或 satisfied assessment with concrete evidenceRefs。
   - `shell/command` 验证节点必须声明 `validationEvidence.mode` 与 `validationEvidence.observationType`。
   - 禁止用 `nohup`、`setsid`、后台 `&` 常驻、`kill` / `pkill` / `killall` / `fuser -k` 或进程终止 approval 作为验证策略。
   - 服务、代理、流式、长运行入口的验证应由 template/Soul 指导为前台 timeout harness、项目测试、临时端口、fake/stub、fixture 或等价 MCP/tool 证据。

5. 反打圈审核。
   - 每次修改前后比较当前 blocker 是否直接命中新代码路径；若没有命中，不能把改动描述为“已解决 live blocker”。
   - 修改 prompt/Soul 时必须说明它如何进入 workspace activation / run executionContext / LLM input；只改 markdown 但没有绑定路径的变更不算收口。
   - 修改 core 合同时必须补充至少一个失败样本单测，证明原错误会被提前拒绝或正确转入下一阶段。
   - 修改 projection/TUI 时必须证明 workorchd 是 ViewModel owner，TUI 只消费 projection/port DTO，不保留另一套业务状态机。
   - 修改 contract violation recovery 时必须证明 rejected output 没有 state-changing side effect、没有进入 accepted evidence/result/artifact，也没有被持久化为高价值 memory。

## 排查流程

1. 先复盘异常来自哪个层级：template 数据、workspace 绑定数据、run executionContext、block 输出、orchestrator 门禁、read model 展示。
2. 如果通用层误判业务语义，优先删除通用层判断，并改为结构化 metadata 或 template-bound policy。
3. 如果 template 数据未生效，检查创建 workspace 时是否已绑定到 workspace；不要在激活 run 时按模板名临时补策略。
4. 如果 e2e 依赖某个具体场景，测试名和 fixture 可以具体，但断言应证明通用能力消费的是结构化字段或模板数据。

## 验证清单

- `go test ./... -count=1` 通过，或至少先跑受影响包再跑全量。
- 通用目录搜索没有新增不该出现的具体业务/模板/语言/命令特判。
- 新增模板策略能从 template 创建期绑定到 workspace，并能在 run executionContext 中追溯。
- Web/TUI/CLI 只展示业务模型字段，不复制后端的业务推断逻辑。
- CLI/TUI/agent 只依赖 `workorchport`；REST client 不依赖 port/service/framework/EventHub；embedded backend 对同步 command/result 缺失或错误返回失败。
- REST URL 的 path/query 与前端、client、handler、e2e 脚本一致；新增状态等待或列表分页参数时必须确认使用 `?` 开始 query string。
- 跨 workspace 可能重复的 run/ticket/approval/result/artifact 操作已绑定 workspace scope；无 scope API 对重复 open 对象返回 conflict。
- 文档同步说明策略归属：core 通用能力、template 数据、Soul 约束或 e2e fixture。
- 涉及 LLM context/cache 时，必须补充或更新 `docs/workorch-llm-request-cache-aware-context-design.md` / `docs/workorch-runtime-stage-contract-neutrality-design.md` 中的对应约束。
- 涉及 Goal/DoD 变更、repair/follow-up/resume、memory/context 裁剪时，必须证明 LLM request 中仍包含完整收敛合同和可追溯 evidence。
- 涉及 live workspace 阻塞收口时，必须补充“修改命中 blocker 路径”的说明：旧失败进入哪个函数、现在会得到什么分类/合同/投影输出、下一步自动恢复路径是什么。
- 涉及服务/代理/长运行验证时，必须搜索 `nohup|setsid|kill|pkill|killall|fuser -k| &`，确认 core 只做中立 shell 形态限制，profile/Soul 承载具体验证策略。

## LLM Cache 验证清单

- `go test ./internal/modules/blocks/llm/biz -count=1` 通过。
- 若修改 request log / usage / read model，补跑相关 appservice 或脚本验证。
- 对历史或新 workspace request log 使用 `./scripts/verify-llm-cache-aware-request-log.sh <workspaceId>`；历史旧日志可作为问题样本，新日志必须满足同一 run 内 `stablePrefixHash` 不随动态阶段变化。
- 单测应覆盖至少一种动态输入变化，例如 `assessmentOnly`、`stateChangingOutputRequired`、provider retry、repair objective 或 Goal/DoD definition revision；其中动态阶段变化不得改变 `stablePrefixHash`，Goal/DoD revision 变化只能改变 `workspaceDefinitionHash`。
- Review diff 时明确确认 C0/C1/C2/C3/C4/C5 归属，没有把当前 failure/progress/memory/repair guidance 拼进稳定前缀。

## Formatter

- `SKILL.md` / Markdown / YAML: 保持标题、列表和代码块格式稳定；归档前运行 `skill-hub validate --pattern workorch-core-template-boundary --links`。
- `scripts/`: 当前技能未包含脚本；新增脚本时，必须在本段补充项目可运行的具体 formatter 命令。
- Go 代码示例或辅助脚本使用 `gofmt -w <files>`；Shell 脚本至少保持 Bash 语法一致并运行可用的语法检查。
- 不要声明当前项目无法执行的 formatter；如果对应文件类型没有 formatter，明确写出人工格式要求。

## 输出要求

- 开发或排查完成时，明确说明修改落点为什么属于 core 或 template。
- 列出发现并清理的边界偏差。
- 给出执行过的边界搜索命令和测试命令。
- 如果新增或调整 template/Soul/policy，必须说明该策略如何绑定到 workspace、如何进入 run context、如何被通用能力消费。

## 禁止事项

- 禁止在 `kernel/orchestrator`、通用 `appservice` 或 repository 中写入具体模板、业务、语言、命令输出 marker 的特判。
- 禁止用“先兼容一下”的方式绕过 template/Soul/policy 归属。
- 禁止让 TUI/Web/CLI 形成另一套业务决策逻辑。
- 禁止让 CLI/TUI/agent 直接 import REST client、backend implementation、kernel owner service 或 repository。
- 禁止用无 scope 的 run/ticket/approval ID 直接 resolve/get 跨 workspace 对象；不能确定唯一对象时必须 conflict。
- 禁止把 e2e fixture 中的业务文本复制到 core 作为判断依据。
- 禁止把运行期动态字段、repair guidance、provider retry guidance、当前失败/进展、memory recall 或 requested action 拼入 C0 stable prompt。
- 禁止为了缓存命中删除 Goal/DoD、requiredOutput、failure evidence、target snapshot、process evidence timeline 等 LLM 必需上下文；缓存优化必须通过分区稳定性和有序裁剪实现。
- 禁止把旧 Goal/DoD、旧 graph、旧 memory 或旧 decision resolution 当作当前权威合同，覆盖最新 definition revision。
- 禁止把可自动继续的 validation/repair gap 直接转成人工 ticket，除非结构化 blocker 表明缺少 runtime 无法获得的外部信息、权限、凭证、审批或配置。
