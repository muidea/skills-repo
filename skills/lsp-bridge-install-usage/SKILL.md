---
name: lsp-bridge-install-usage
description: 用于在任意项目中安装、接入和验证 lsp-bridge MCP Server，覆盖在线安装路径选择、用户本地 bin 默认规则、LSP 依赖、MCP Client 配置、项目级 mcp-config.json 与故障排查。需要为项目启用 LSP 语义工具、配置 lsp-bridge、核对安装位置或复用统一安装流程时使用。
metadata:
  version: "1.0.0"
  author: "rangh"
  created_at: "2026-05-23T11:18:44+08:00"
---

# LSP Bridge Install Usage

这个 skill 用于把 `lsp-bridge` 作为 MCP Server 接入其它项目，让代理可以通过 LSP 执行定义跳转、hover、diagnostics、references 等语义查询。

## 适用场景

- 用户要求安装、升级、核对或复用 `lsp-bridge`。
- 用户要在某个项目中配置 MCP Client 的 `mcpServers.lsp-bridge`。
- 项目需要通过 `gopls`、`pyright-langserver`、`rust-analyzer`、`typescript-language-server`、`bash-language-server` 等 LSP server 提供代码语义能力。
- 需要确认 `LSP_BRIDGE_INSTALL_DIR`、`LSP_BRIDGE_HOME`、`LSP_BRIDGE_CONFIG`、`PATH` 的实际路径和保留位置。

## 工作流程

1. 先确认目标项目和运行环境
   - 记录目标项目根目录 `<project-root>`。
   - 检查系统类型和架构：`uname -s`、`uname -m`。
   - 检查是否已有安装：`command -v lsp-bridge`、`echo "$LSP_BRIDGE_HOME"`、`echo "$LSP_BRIDGE_CONFIG"`。
   - 如果用户询问“最新版”或准备发布/升级，核对 GitHub Release 最新 tag，不要凭记忆假设版本。

2. 选择安装根目录
   - 未指定安装目录时，在线安装器默认使用当前用户本地目录：`$HOME/.local`。
   - 默认二进制路径：`$HOME/.local/bin/lsp-bridge`。
   - 默认依赖路径：`$HOME/.local/.deps/node/`。
   - 需要固定到项目外的共享位置时，显式设置 `LSP_BRIDGE_INSTALL_DIR`，它表示安装根目录，不是 `bin` 目录。
   - 推荐用户级自定义目录：`$HOME/lsp-bridge-install` 或团队约定的用户可写目录；避免默认使用需要 root 权限的 `/usr/local`、`/opt`。

3. 执行在线安装

默认用户本地安装：

```bash
curl -fsSL https://raw.githubusercontent.com/muidea/lsp-bridge/master/scripts/install.sh | bash
```

指定安装根目录：

```bash
curl -fsSL https://raw.githubusercontent.com/muidea/lsp-bridge/master/scripts/install.sh | LSP_BRIDGE_INSTALL_DIR="$HOME/lsp-bridge-install" bash
```

固定版本或跳过默认 LSP 依赖：

```bash
curl -fsSL https://raw.githubusercontent.com/muidea/lsp-bridge/master/scripts/install.sh | LSP_BRIDGE_VERSION=v0.1.2 bash
curl -fsSL https://raw.githubusercontent.com/muidea/lsp-bridge/master/scripts/install.sh | INSTALL_PYRIGHT=0 INSTALL_GOPLS=0 bash
```

4. 确认 shell 环境
   - 安装器会把 `LSP_BRIDGE_HOME` 和 `PATH` 写入当前用户 shell 配置文件。
   - Bash 默认是 `$HOME/.bashrc`，Zsh 默认是 `$HOME/.zshrc`，Fish 默认是 `$HOME/.config/fish/config.fish`。
   - 当前 shell 未加载配置时，临时执行：

```bash
export LSP_BRIDGE_HOME="$HOME/.local"
export PATH="$LSP_BRIDGE_HOME/bin:$PATH"
```

如果使用自定义安装根目录，把 `$HOME/.local` 替换成实际 `LSP_BRIDGE_INSTALL_DIR`。

5. 准备项目级 LSP 配置
   - `lsp-bridge` 启动时读取 `LSP_BRIDGE_CONFIG` 指定的 JSON 文件。
   - 如果 `LSP_BRIDGE_CONFIG` 为空，只尝试读取当前进程工作目录的 `mcp-config.json`。
   - 推荐在目标项目保留 `<project-root>/mcp-config.json`，并在 MCP Client env 中显式指向它。

最小 `mcp-config.json` 示例：

```json
{
  "languages": {
    "go": {
      "command": ["gopls", "serve"]
    },
    "python": {
      "command": ["pyright-langserver", "--stdio"]
    },
    "typescript": {
      "command": ["typescript-language-server", "--stdio"]
    },
    "rust": {
      "command": ["rust-analyzer"]
    },
    "shell": {
      "command": ["bash-language-server", "start"]
    }
  }
}
```

6. 配置 MCP Client
   - 如果 `lsp-bridge` 已在 `PATH` 中，可以用短命令。
   - 如果 PATH 不稳定，优先使用绝对路径。
   - `LSP_BRIDGE_CONFIG` 使用目标项目内的绝对路径，避免 MCP Client 工作目录变化导致配置丢失。

推荐配置：

```json
{
  "mcpServers": {
    "lsp-bridge": {
      "command": "/home/<user>/.local/bin/lsp-bridge",
      "args": [],
      "env": {
        "LSP_BRIDGE_CONFIG": "/absolute/path/to/project/mcp-config.json"
      }
    }
  }
}
```

7. 初始化和使用
   - 使用前先对目标项目调用 `lsp_initialize`。
   - `root_path` 必须是目标项目根目录或语言服务器期望的 workspace 根。
   - 多语言仓库需要分别初始化不同 `lang_id`。

调用参数示例：

```json
{
  "root_path": "/absolute/path/to/project",
  "lang_id": "go"
}
```

常用工具：

- `lsp_initialize`
- `lsp_sync`
- `lsp_definition`
- `lsp_hover`
- `lsp_diagnostics`
- `lsp_references`

## 验证

- 安装验证：`command -v lsp-bridge` 或 `"$LSP_BRIDGE_HOME/bin/lsp-bridge"` 可启动。
- PATH 验证：新开 shell 后 `lsp-bridge` 可解析到预期路径。
- 配置验证：确认 `LSP_BRIDGE_CONFIG` 指向存在且 JSON 合法的文件。
- LSP 依赖验证：
  - Go: `command -v gopls`
  - Python: `command -v pyright-langserver`
  - Rust: `command -v rust-analyzer`
  - TypeScript/JavaScript: `command -v typescript-language-server`
  - Shell: `command -v bash-language-server`
- 功能验证：对目标项目执行 `lsp_initialize`，再调用 `lsp_hover` 或 `lsp_diagnostics`。

## 故障处理

- `lsp-bridge: command not found`: 检查 shell rc 是否加载，或在 MCP Client 中使用绝对路径。
- `read config` 失败或配置未生效：把 `LSP_BRIDGE_CONFIG` 改成绝对路径，并确认 MCP Client 传入了 env。
- 初始化失败且提示 LSP server 不存在：安装对应语言的 LSP server，或在 `mcp-config.json` 中写入正确命令。
- Go 项目语义不完整：确认在正确的 module/workspace 根目录调用 `lsp_initialize`，并检查 `go env`、`go.mod`、`go.work`。
- Node 类 LSP 不可用：确认 `node`、`npm`、`$LSP_BRIDGE_HOME/.deps/node/node_modules/.bin` 或项目 `node_modules/.bin` 可用。
- 多项目同时使用：每个项目保留自己的 `mcp-config.json`，MCP Client 通过不同 server 配置或 env 指向对应配置。

## Formatter

- `SKILL.md` / Markdown / YAML: 保持标题、列表和代码块格式稳定；归档前运行 `skill-hub validate lsp-bridge-install-usage --links`。
- 当前 skill 不包含脚本；新增脚本时必须补充对应语言的 formatter 或语法检查命令。
- 归档前运行 `skill-hub feedback lsp-bridge-install-usage --dry-run`。

## 输出要求

- 向用户报告最终安装根目录、二进制路径、配置文件路径和 MCP Client 配置片段。
- 明确哪些 LSP 依赖已安装，哪些需要项目自行补充。
- 如果修改了项目配置文件，列出具体文件和验证命令。
- 如果创建或更新了 reusable skill，先 validate，再通过 `skill-hub feedback <skill-id> --force` 归档到本地默认 skill 仓库；不要自动远程 push。

## 注意事项

- 不要把 `LSP_BRIDGE_INSTALL_DIR` 当成 `bin` 目录；它是安装根目录。
- 不要把项目专属 `mcp-config.json` 放在临时目录。
- 不要在未确认用户意图时修改全局 shell rc 以外的系统级配置。
- 需要联网下载 release、npm 包或 Go module 时，如果命令因网络或沙箱失败，按当前环境规则请求授权后重试。
- 远程发布 skill 或推送 skill 仓库必须等待用户明确要求。
