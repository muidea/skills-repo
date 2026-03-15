---
name: skillhub-skill-lifecycle
description: 用于通过 skill-hub 创建、登记、校验、归档和推送项目本地 skill。涉及 skill-hub create、status、validate、feedback、push，以及把工作区已有 skill 同步到本地或远程仓库时使用。
version: 1.0.0
---

# skill-hub Skill Lifecycle

这个 skill 只关注 `skill-hub` 的实际使用流程，不处理 skill 内容设计本身。

## 适用场景

- 项目里新增了一个不是通过 `skill-hub create` 创建的 skill，需要登记到本地仓库
- 需要把工作区 skill 归档到默认本地仓库
- 需要检查 skill 在项目工作区和本地仓库之间的状态
- 需要把已归档 skill 推送到远程仓库

## 当前稳定流程

### 1. 先创建登记项

对不是通过 `skill-hub create` 生成的 skill，先执行：

```bash
skill-hub create <id>
```

这一步的作用是：

- 刷新项目状态
- 把 skill 登记到当前项目工作区
- 建立工作区 skill 和仓库 skill 的映射

如果目录和 `SKILL.md` 已存在，`create` 不会覆盖内容，只会完成登记。

### 2. 检查状态

```bash
skill-hub status <id>
```

关注状态：

- `Synced`
- `Modified`
- `Outdated`
- `Missing`

新增 skill 在归档前通常会显示为 `Modified`，并且仓库版本为 `N/A`。

### 3. 验证结构

```bash
skill-hub validate <id>
```

至少保证：

- `SKILL.md` YAML 合法
- 必需字段完整
- 目录结构合规

### 4. 先 dry-run 归档

```bash
skill-hub feedback <id> --dry-run
```

确认：

- 是新增 skill 还是已有 skill 更新
- 会写入哪些文件
- 版本号是否符合预期

### 5. 正式归档到本地仓库

```bash
skill-hub feedback <id>
```

交互确认后，skill 会写入默认归档仓库。

### 6. 推送到远程

```bash
skill-hub push
```

这一步会把默认本地仓库里的新 skill 提交并推送到远程仓库。

## 推荐顺序

对一批新增 skill，按这个顺序统一执行：

1. `create`
2. `status`
3. `validate`
4. `feedback --dry-run`
5. `feedback`
6. `push`

## 注意事项

- `feedback` 和 `push` 都可能有交互确认
- `status` 只是状态查看，不会归档
- 如果当前项目工作区还没注册，第一次执行 `create`/`status` 时会自动创建工作区状态
- 新增 skill 在本地仓库里通常会显示为“仓库中不存在，将作为新技能创建”
