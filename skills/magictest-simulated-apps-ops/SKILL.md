---
name: magictest-simulated-apps-ops
description: Operates simulated application packaging, cold-start import/install/approval, Portal subscriptions, least-privilege CAS OAuth provisioning, data seeding, and readback verification via magicTest. Use when exporting remote simulation bundles or populating and verifying device-management and chess-room-booking on a deployed magicPlatform.
metadata:
  version: "1.0.0"
  author: "rangh-codespace"
  tags: "magictest,simulated-apps,device-management,chess-room-booking,oauth"
compatibility: Compatible with open_code
---

# 模拟应用打包、冷启动与数据验证操作

用于跨机器导出最小模拟应用工具包，并在已就绪的 `magicPlatform` 上安全完成 `device-management` 与 `chess-room-booking` 的导入安装、门户订阅、最小权限 CAS OAuth 授权、造数与双轮回读核验。

## 何时使用

- 需要把权威模型与模拟器工具打包到无完整源码的目标机。
- 需要在新部署或已重置环境快速上线两大模拟应用并注入逼真演示/测试数据。
- 需要排查 Portal 订阅、API Key、PKCE Action Token（16 KiB 上限）或双应用模拟器回读失败。

## 核心规则与安全边界

1. **绝不覆盖未确认环境**：默认若 `device-management` 或 `chess-room-booking` 已有 `ready` 实例，`bootstrap_simulated_apps.py` 直接拒绝操作；只有在确认复用既有实例时才传 `--reuse-existing`。
2. **严格遵守单一订阅入口**：所有订阅必须经 Portal `POST /api/v1/web/proxy/portal/service/subscriptions/` 创建，严禁调用 `/panel/hub/subscriptions/`。
3. **凭据文件化、脱敏保存**：管理员密码文件、`*.api-key`、`crb-operator.token` 均以 `0600` 写入 `--state-dir/secrets/`（`0700` 目录），绝不传入 CLI 命令行或写入摘要报告。
4. **最小权限 Action 账号**：棋牌室业务动作不得使用角色过多的 `platform-admin` JWT（超过 `simulation_tool.py` 16 KiB 限制）；必须通过专用账号（如 `crb-sim-operator`）配合最小角色模板及 PKCE S256 签发。
5. **未知写结果绝不自动重发**：模拟器发生传输中断且无可靠回执 ID 时，保留原 `state-dir` 日志与 journal，交由 owner 核对，不得删目录重试。

## 标准工作流

### 1. 导出跨机器轻量化包（无完整源码环境使用）

```sh
python3 -B ~/codespace/magicTest/tools/export_remote_sim_bundle.py \
  --output /tmp/magic-sim-bundle.tar.gz
```

解包后在目标机设置 `export MAGICPLATFORM_ROOT="$PWD/magicPlatform"` 即可运行工具。

### 2. 离线计划预览（`--dry-run`）

```sh
python3 -B ~/codespace/magicTest/applications/live_e2e/bootstrap_simulated_apps.py \
  all --base-url https://panel.example.com --state-dir ~/.local/state/magic-sim --dry-run
```

### 3. 一键冷启动或分阶段执行

```sh
# 阶段可选：all | import-install | provision-access | seed-data | verify
python3 -B ~/codespace/magicTest/applications/live_e2e/bootstrap_simulated_apps.py \
  all \
  --base-url https://panel.example.com \
  --admin-password-file ~/.config/magic-sim/admin-password \
  --state-dir ~/.local/state/magic-sim \
  --reuse-existing
```

- 自签 `local.vpc` 环境额外附加：`--ca-file ~/dataspace/magicPlatform/services/secret/tls/tls.crt --trust-leaf`。
- 公网 CA 环境直接省略 `--ca-file` 即可（脚本会自动为 `simulator.py` 匹配系统 CA 束与 `--ca-is-root`）。

认证与 API 常见坑点详见 [认证与接口排障清单](references/auth-and-api-pitfalls.md)。

## Formatter

- 保持操作摘要仅包含非机密身份、状态、字节计数与脱敏文件路径；所有命令加 `python3 -B` 或 `PYTHONDONTWRITEBYTECODE=1`，防止在源码树留下 `__pycache__`。
