---
name: skillhub-skill-lifecycle
description: 用于通过 skill-hub 创建、登记、补齐元数据、校验、归档和推送项目本地 skill。涉及批量收集 .agents/skills、去重保留最新版本、补齐 SKILL.md frontmatter、先 create 登记再 feedback 归档，以及 status/validate/push 等 skill-hub 工作流时使用。
compatibility: Compatible with open_code
metadata:
  version: "1.1.1"
  author: "rangh-codespace"
  created_at: "2026-04-24T20:05:43+08:00"
---

# skill-hub Skill Lifecycle

这个 skill 关注 `skill-hub` 的实际使用流程和仓库生命周期，也负责把“当前项目中对 skill 的编辑任务”纳入 `skill-hub` 流程。只要任务直接涉及当前项目 `.agents/skills/` 下的 skill 更新、刷新、批量同步、归档或发布，就应优先使用本 skill，再决定是否需要配合其他内容类 skill。

## 适用场景

- 项目里新增了一个不是通过 `skill-hub create` 创建的 skill，需要登记到本地仓库
- 当前任务直接修改 `.agents/skills/<id>/SKILL.md`、`agents/openai.yaml`、`references/`、`scripts/`
- 需要刷新、重写、批量更新当前项目里已有 skill，并确保更新能回到 skill-hub 本地仓库
- 从当前目录及子目录收集 `.agents/skills/*/SKILL.md`，统一整理到当前项目 `.agents/skills`
- 需要去除重复 skill，并按最新修改时间或明确来源保留最新版本
- `SKILL.md` 缺少 frontmatter，需要补齐 `name`、`description`、`compatibility`、`metadata.version`
- 需要把工作区 skill 归档到默认本地仓库
- 需要检查 skill 在项目工作区和本地仓库之间的状态
- 需要把已归档 skill 推送到远程仓库

## 核心规则

- 只要任务直接触达当前项目 `.agents/skills/`，优先先加载本 skill，再决定是否需要额外的内容设计 skill。
- 不要把“内容编辑”和“skill 生命周期管理”拆成互不相关的两步；只要修改了工作区 skill，就必须至少补 `status`、`validate`、`feedback` 这条链。
- 不要绕过 `skill-hub` 直接写 `~/.skill-hub/state.json` 来登记 skill。
- 对尚未在项目本地工作区登记的 skill，必须先运行 `skill-hub create <id>`。
- `feedback` 只用于把已登记的项目本地 skill 归档到默认本地仓库。
- 缺少 frontmatter 的旧格式 `SKILL.md`，先补齐必要元数据，再运行 `create`。
- 批量操作前先备份将要修改的 `.agents/skills` 目录或相关 skill 目录。
- 如果 `skill-hub` 不在 `PATH` 中，先从当前环境的本地 skill-hub checkout 或安装目录定位二进制，不要把用户 home 下的绝对路径写入 skill。

## 单个 Skill 流程

如果任务是“编辑已有 skill”，推荐顺序：

1. 先定位目标 skill 当前状态
2. 修改工作区 skill 内容
3. 执行 `validate`
4. 执行 `feedback --dry-run`
5. 确认后执行 `feedback --force`
6. 用 `status` 确认回到 `Synced`

### 1. 补齐 SKILL.md 元数据

`skill-hub validate` 和 `create` 依赖合规的 `SKILL.md` frontmatter。最小结构：

```markdown
---
name: <id>
description: <one sentence describing when to use this skill>
compatibility: Compatible with open_code
metadata:
  version: "1.0.0"
  author: "rangh-codespace"
---
```

优先从正文标题和第一段提取 `description`，不要用模板内容覆盖已有正文。

### 2. 先创建登记项

对不是通过 `skill-hub create` 生成的 skill，先执行：

```bash
skill-hub create <id> --target open_code
```

这一步的作用是：

- 刷新项目状态
- 把 skill 登记到当前项目工作区
- 建立工作区 skill 和仓库 skill 的映射

如果目录和 `SKILL.md` 已存在，`create` 不会覆盖内容，只会完成登记。

### 3. 检查状态

```bash
skill-hub status <id>
```

关注状态：

- `Synced`
- `Modified`
- `Outdated`
- `Missing`

新增 skill 在归档前通常会显示为 `Modified`，并且仓库版本为 `N/A`。

已登记 skill 在工作区被编辑后，通常会显示为 `Modified`；这不是异常，而是提示你后续必须执行 `feedback`。

### 4. 验证结构

```bash
skill-hub validate <id>
```

至少保证：

- `SKILL.md` YAML 合法
- 必需字段完整
- 目录结构合规

### 5. 先 dry-run 归档

```bash
skill-hub feedback <id> --dry-run
```

确认：

- 是新增 skill 还是已有 skill 更新
- 会写入哪些文件
- 版本号是否符合预期

### 6. 正式归档到本地仓库

```bash
skill-hub feedback <id> --force
```

`--force` 适合批处理或已完成人工确认的场景。归档后，skill 会写入默认归档仓库，并刷新 registry。

### 7. 推送到远程

```bash
skill-hub push
```

这一步会把默认本地仓库里的新 skill 提交并推送到远程仓库。

## 批量收集和归档流程

### 1. 扫描来源

```bash
find . -name SKILL.md -type f
```

只把形如 `.agents/skills/<id>/SKILL.md` 的目录视为 skill。按目录名 `<id>` 去重。

### 2. 去重保留最新版本

默认判定：

- 同名且内容 hash 相同：任意保留一份，优先最新修改时间。
- 同名但内容不同：比较目录内所有文件的最新修改时间，保留最新版本。
- 如果用户指定来源优先级，以用户指定为准。

整理到当前项目：

```text
<project>/.agents/skills/<id>/SKILL.md
```

不要删除子项目里的原始副本，除非用户明确要求清理源目录。

### 3. 补齐缺失 frontmatter

对所有不以 `---` 开头的 `SKILL.md`，先备份再补齐最小 frontmatter。补齐时只添加元数据，不重写正文。

### 4. 登记未登记 skill

先查看当前项目状态：

```bash
skill-hub status
```

对未登记 skill：

```bash
skill-hub create <id> --target open_code
```

如果 `SKILL.md` 已存在且合规，`create` 会刷新项目状态并保留现有内容。

### 5. 归档全部目标 skill

```bash
skill-hub feedback <id> --force
```

批量归档完成后检查：

```bash
skill-hub status
skill-hub repo list
git -C ~/.skill-hub/repositories/<default-repo> status --short
```

成功标准：

- 当前项目目标 skill 全部已登记
- `skill-hub status` 显示目标 skill 为 `Synced`
- 默认本地仓库 `skills/<id>` 包含目标 skill
- 默认本地仓库 `registry.json` 包含目标 skill

## 与内容类 skill 的协同

- 如果任务是“改 skill 内容”，本 skill 负责生命周期主链：`status`、`validate`、`feedback`、`push`
- 如果任务还需要重写 `SKILL.md` 业务内容、references 或脚本，可以配合内容类 skill
- 但无论是否配合其他 skill，只要改了 `.agents/skills/`，最后都要回到本 skill 完成归档和状态确认

## 注意事项

- `feedback` 和 `push` 都可能有交互确认
- `status` 会检查并可能刷新本地状态，但不会归档
- 如果当前项目工作区还没注册，第一次执行 `create`/`status` 时会自动创建工作区状态
- 新增 skill 在本地仓库里通常会显示为“仓库中不存在，将作为新技能创建”
- `feedback` 可能自动提升 patch 版本号；归档后再用 `status` 确认最终版本
- 本地归档完成不等于远程同步；只有 `skill-hub push` 才会提交并推送默认仓库
