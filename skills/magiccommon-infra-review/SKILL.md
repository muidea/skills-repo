---
name: magiccommon-infra-review
description: 用于评审和修复 magicCommon 基础设施模块中的并发、生命周期、关闭幂等、环境敏感测试和文档一致性问题。处理 event、execute、task、session、framework、foundation、monitoring 相关问题时使用。
version: 1.0.0
---

# magicCommon Infra Review

处理 `magicCommon` 基础设施问题时，优先按这套流程执行。

## 1. 先看哪些文件

- 总览先读：
  - `README.md`
  - `technical-note-infra-hardening-2026-03.md`
- 再按模块读对应文档：
  - `event/README.md`
  - `execute/README.md`
  - `task/README.md`
  - `foundation/cache/README.md`
  - `foundation/net/README.md`
  - `foundation/path/README.md`
  - `foundation/pool/README.md`
  - `foundation/signal/README.md`
  - `framework/configuration/README.md`
  - `monitoring/README.md`

## 2. 重点检查项

- 并发问题：
  - `RLock` 下写状态
  - 遍历共享 slice/map 时并发修改
  - 原子状态缺失
- 生命周期问题：
  - `Stop` / `Close` / `Release` / `Terminate` 是否幂等
  - 关闭后是否还会向 channel 发送消息
  - worker/goroutine 是否会泄漏
- 兼容性问题：
  - 旧接口是否仍可用
  - 新能力优先走新增 API，不轻易破坏老调用面
- 环境敏感测试：
  - 数据库不可用时应 `Skip` 或显式报错，不要 panic
  - 端口监听受限时 exporter 类测试应 `Skip`
- 文档一致性：
  - 行为变化后同步更新对应 README 和根索引

## 3. 默认工作流

1. 先跑 `git status`，确认工作区状态。
2. 用 `rg` 找相关 API、测试、README。
3. 先补或更新回归测试，再修代码。
4. 改完后至少跑目标包测试。
5. 如果行为变了，刷新模块 README 和 `technical-note-infra-hardening-2026-03.md`。

## 4. 推荐测试命令

优先使用：

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor go test ./目标包... -count 1
```

收口阶段再跑：

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor go test ./... -count 1
```

## 5. 固定约束

- 对环境依赖测试，优先修成“干净失败或跳过”，不要让环境问题放大成 panic。
- 对基础设施接口，优先新增能力，不直接重写老语义。
- 所有关闭路径默认都要追问三件事：
  - 是否幂等
  - 是否排空
  - 是否允许继续提交新任务
