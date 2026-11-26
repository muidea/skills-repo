---
name: magictest-remote-verification
description: End-to-end runbook for verifying a remote magicPlatform deployment from a separate clean test server over HTTPS only (without remote Docker socket or source mounts). Covers host readiness prechecks, remote health/APM checks, lightweight bundle or git setup, simulated-apps bootstrap/readback, cross-server load + Prometheus APM, and remote-https functional regression.
metadata:
  version: 1.0.1
  author: "rangh-codespace"
  tags: "magictest,remote-verification,cross-server,load,apm,e2e,regression"
compatibility: Compatible with open_code
---

# 独立新服务器对远端平台开展验证的操作指南

用于指导 AI Agent 或测试工程师在**一台独立的新测试机（服务器 B）**上，通过纯 HTTPS 对**远端已部署的 `magicPlatform`（服务器 A）**自动开展健康与 APM 巡检、双模拟应用冷启动与回读、跨机并发性能压测及 `remote-https` 功能回归。

## 何时使用

- **使用本 skill**：测试与平台分别部署在不同服务器，需要从一台全新/独立的测试机准备环境并串联执行“远端健康巡检 -> 模拟应用上线/造数 -> 性能压测/APM 采集 -> 跨机功能回归”全流程。
- **改用 `magicplatform-deploy`**：目标任务是在服务器 A 部署、升级、重置、打离线包或恢复 `magicPlatform` 容器。
- **改用 `magictest-simulated-apps-ops`**：只聚焦打包/运维/排查 `device-management` 与 `chess-room-booking` 两个模拟应用本身。
- **改用 `magictest-platform-verify`**：在开发本机执行离线单测、`run_tests.py` 发现或本机同宿主 `local` Docker 全量回归。

## 验证档位与前置自检

按需验证的范围从低到高准备新测试机依赖（不强行要求装齐全部重型依赖）：

| 档位 | 覆盖范围 | 新测试机最低依赖 | 资产获取 |
| --- | --- | --- | --- |
| **档位 1（零第三方包）** | 远端健康与 APM 巡检、双模拟应用冷启动/授权/造数/回读、跨机压测 + Prometheus APM | `Python 3.10+`（Linux 需 `tzdata`，OpenSSL 支持 `VERIFY_X509_PARTIAL_CHAIN`）、`sh`、`curl`、`jq`；无需 Docker/Node/Go/Playwright | 源机运行 `export_remote_sim_bundle.py` 解包即用 |
| **档位 2（跨机功能回归）** | 档位 1 + `remote-https` 功能/异常回归（自动排除宿主机强耦合与外部回调类用例） | 档位 1 依赖 + `Node.js 18+` + 用户级 Playwright `1.65.0`（`~/.local/share/playwright` + Chromium 或系统 Chrome） | 克隆/同步完整 `magicTest` 仓库 |
| **档位 3（含外部回调全远端回归）** | 档位 2 + 补跑 28 项标准 / 2 项异常外部上游回调类用例 | 档位 2 依赖 + 测试机开放回调端口使远端平台 `magicGateway` 可达测试机 `controlledUpstreamAdvertise` | 完整 `magicTest` + 私密配置回调监听/通告地址 |

在新测试机执行只读前置自检（无副作用）：

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -B - <<'PY'
import os, pathlib, shutil, ssl, sys
from zoneinfo import ZoneInfo

for cmd in ("sh", "curl", "jq"):
    assert shutil.which(cmd), f"missing required command: {cmd}"
assert sys.version_info >= (3, 10), f"need Python 3.10+, got {sys.version}"
ZoneInfo("Asia/Shanghai")
assert hasattr(ssl, "VERIFY_X509_PARTIAL_CHAIN"), "OpenSSL missing VERIFY_X509_PARTIAL_CHAIN"

# 检查 shell 代理变量是否可能拦截 panel/apm 域名（尤其 *.local.vpc）
no_proxy = os.environ.get("no_proxy") or os.environ.get("NO_PROXY") or ""
https_proxy = os.environ.get("https_proxy") or os.environ.get("HTTPS_PROXY") or ""

optional = {cmd: bool(shutil.which(cmd)) for cmd in ("node", "docker", "google-chrome")}
pw_pkg = pathlib.Path.home() / ".local/share/playwright/node_modules/playwright/package.json"
print({
    "tier1Ready": True,
    "python": sys.version.split()[0],
    "optionalTools": optional,
    "playwrightInstalled": pw_pkg.is_file(),
    "httpsProxyConfigured": bool(https_proxy),
    "noProxy": no_proxy,
})
PY
```

## 核心边界与防呆规则

1. **纯 HTTPS 跨机边界**：测试机不挂载、也不探测远端平台机 Docker Socket 或运行数据目录；巡检与回归一律走公开 `https://panel.<domain>` 与 `https://apm.<domain>`。
2. **私有状态目录严格 `0700`/`0600`**：所有导出包外秘密（`ca.crt`、`admin-password`、`*.api-key`、`crb-operator.token`、`credentials.json`、`regression-config.json`）统一放仓库外（如 `~/.local/state/magic-verify/`），目录 `0700`、文件 `0600`，绝不写入仓内或回显至日志/报告。
3. **根 CA 与叶证书区分**：自签 `local.vpc` 环境推荐从目标机拉取 `services/secret/tls/ca.crt` 至 `0600` 私有文件，传 `--ca-file .../ca.crt`（不加 `--trust-leaf`）；仅直接使用叶证书 `tls.crt` 时才附加 `--trust-leaf`。公网域名省略 `--ca-file` 走系统信任库。
4. **SNI 直连不改本机 `/etc/hosts`**：测试机无 `local.vpc` 解析或本地 `/etc/hosts` 存在 `127.0.0.1 panel.local.vpc` 干扰时，各工具均传 `--target-address <平台IP>`（或设 `MAGICTEST_TARGET_ADDRESS`），保留原始 `Host` 与 TLS SNI 连接远端。
5. **警惕 Shell 代理拦截 `panel.<domain>` / `apm.<domain>`**：若测试机存在 `https_proxy` / `http_proxy`，而 `no_proxy` 未包含 `panel.<domain>`、`apm.<domain>`（或只写了 `panel.local.vpc` 漏写 `apm.local.vpc`），`curl`、Playwright/Node 或 Python `urllib` 会走本地代理导致 `SSL_ERROR_SYSCALL` 或误访问。`deployment-health.sh --target-address` 会对解析主机自动加 `--noproxy`；运行压测前（或使用 Playwright 时）亦应确保目标域名在 `no_proxy` 中（或显式 `unset https_proxy http_proxy`）。
6. **区分 `bootstrap-admin-password` 失效**：目标机若已完成首次登录改密（`POST /oauth/password/change`），旧引导密码返回 `401 invalid account or password`；应向管理员获取最新密码，严禁私自重置平台数据库。
7. **禁止跨级宣称通过**：跨机功能回归结果以 `remoteScopeComplete` 统计，绝不覆盖或冒充包含 `F059-001` 等宿主机耦合项的全量 `complete`；模拟应用 `verify` 仅证明 Gateway 双轮扫描与派生回读，不替代浏览器端到端页面验收。
8. **字节码清理规范**：所有 Python 调用必须加 `python3 -B` 或 `PYTHONDONTWRITEBYTECODE=1`，严禁在源码仓留下 `__pycache__`。

## 标准执行工作流

以下示例假设在本机创建私有工作目录 `STATE=~/.local/state/magic-verify`（目标平台域名为 `<domain>`、IP 为 `<target-ip>`）：

### Step 1：在新测试机准备验证工具与模型资产

- **仅跑档位 1（轻量免源码）**：在开发/源机执行打包并将压缩包传输到新测试机解包：
  ```sh
  # 源机打包（自动包含 live_e2e、双模拟器、load/ 与 apps/models/，不含秘密）
  python3 -B ~/codespace/magicTest/tools/export_remote_sim_bundle.py \
    --output /tmp/magic-sim-bundle.tar.gz

  # 新测试机解包后设环境变量：
  tar -xzf magic-sim-bundle.tar.gz && cd magic-sim-bundle
  export MAGICPLATFORM_ROOT="$PWD/magicPlatform"
  ```
- **需要跑档位 2 / 3**：直接克隆完整 `magicTest`（以及 `magicPlatform`，供只读脚本与模型读取），按需安装用户级 Node.js 18+ 与 Playwright `1.65.0`（详见 [远端验证清单与配置模板](references/remote-runner-checklist.md)）。

### Step 2：准备私密工作目录、CA 与管理员凭据

```sh
umask 077
mkdir -p ~/.local/state/magic-verify/secrets ~/.local/state/magic-verify/runs ~/.local/state/magic-verify/t
chmod 700 ~/.local/state/magic-verify ~/.local/state/magic-verify/secrets ~/.local/state/magic-verify/t

# 1. 自签环境从平台机拷入 ca.crt（chmod 600）；公网域名可跳过
# 2. 写入有效管理员密码（无尾随换行或保持干净文本，chmod 600）：
# printf '%s' '<admin-password>' > ~/.local/state/magic-verify/secrets/admin-password
# chmod 600 ~/.local/state/magic-verify/secrets/admin-password
```

### Step 3：只读远端健康与 APM 基线巡检

开始任何写操作或压测前先确认目标机可用（若平台以 `ENABLE_APM=true ./start.sh` 开启 APM，一并传 `--include-apm`）：

```sh
sh "$MAGICPLATFORM_ROOT/scripts/deployment-health.sh" \
  --skip-docker \
  --base-url "https://panel.<domain>" \
  --target-address "<target-ip>" \
  --ca-file ~/.local/state/magic-verify/secrets/ca.crt \
  --include-apm --json
```

核对返回 `"passed": true` 且 `"failCount": 0`；再继续下一步。

### Step 4：双模拟应用冷启动、授权、造数与回读（档位 1）

先执行零网络 `--dry-run` 确认本地包摘要完整，再联机执行（若目标平台已有 `ready` 实例，补充 `--reuse-existing`；若远端已存在默认 `crb-sim-operator` 且本机无其密码文件，应传 `--operator-password-file` 或指定独立 `--operator-account <name>`；在 `--reuse-existing` 下若 `chess-room-booking` 远端实例非空，工具会执行只读 `inspect` 而不覆写既有数据）：

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -B magicTest/applications/live_e2e/bootstrap_simulated_apps.py \
  all \
  --base-url "https://panel.<domain>" \
  --target-address "<target-ip>" \
  --ca-file ~/.local/state/magic-verify/secrets/ca.crt \
  --admin-account platform-admin \
  --admin-password-file ~/.local/state/magic-verify/secrets/admin-password \
  --state-dir ~/.local/state/magic-verify \
  --reuse-existing
```

完成后确认 `~/.local/state/magic-verify/bootstrap-summary.json`、`runs/device-management/verification.json` 均通过（或 `chess-room-booking` 在复用非空实例时为 `reused_non_empty_readonly_inspected`），且 `crbOperator.tokenBytes <= 16384`。

### Step 5：跨机性能压测与 Prometheus APM 采集（档位 1）

压测前按 [远端验证清单与配置模板](references/remote-runner-checklist.md) 核对平台机 `[oauth.loginRate]` 与服务 `maxQPS`/`dailyQuota` 配置。直接复用 Step 4 产物施压并关联 APM 指标：

```sh
OUT=$(mktemp -d /tmp/magic-load-XXXXXX)
PYTHONDONTWRITEBYTECODE=1 python3 -B magicTest/load/run_load.py \
  --from-sim-state ~/.local/state/magic-verify \
  --sim-app device-management --sim-scenario gateway-read \
  --mode step --concurrency 2,8,16 --duration 30 \
  --ca-file ~/.local/state/magic-verify/secrets/ca.crt \
  --apm-url "https://apm.<domain>/prometheus/" \
  --apm-idle-seconds 30 --require-apm \
  --output "$OUT"
```

查看 `$OUT/summary.md` 与 `$OUT/report.json` 中的各阶段 QPS、P95/P99、Host CPU、Traefik QPS/延迟及 PostgreSQL 指标。

### Step 6：跨机 `remote-https` 功能回归（档位 2 / 档位 3）

在仓外准备 `0600` 权限的扁平 `credentials.json` 与分套件 `regression-config-standard.json` / `regression-config-abnormal.json`（先跑 `standard` 再跑 `abnormal`，模板见 [远端验证清单与配置模板](references/remote-runner-checklist.md)），并设置短 `TMPDIR` 与 `no_proxy`：

```sh
export TMPDIR=~/.local/state/magic-verify/t
# 1. 离线预览本次远端执行用例清单（确认 excludeHostCoupled 分流生效）：
PYTHONDONTWRITEBYTECODE=1 python3 -B magicTest/regression/run_standard.py \
  --config ~/.local/state/magic-verify/regression-config-standard.json \
  --suite standard --dry-run

# 2. 执行远端标准（以及独立的 --suite abnormal）功能回归：
PYTHONDONTWRITEBYTECODE=1 python3 -B magicTest/regression/run_standard.py \
  --config ~/.local/state/magic-verify/regression-config-standard.json \
  --suite standard
```

### Step 7：分层收口报告

输出最终验证结论时，按实测分层分别列出且互不混用：
1. **远端健康与 APM**：`deployment-health.sh` 返回的 HTTP / OIDC / Prometheus targets 结果。
2. **双模拟应用**：安装 ID / Deployment ID、Service Key、Token 字节数、`verification.json` 与 `simulation_tool verify`/`inspect` 结果（标注仅 Gateway 回读，不含浏览器页面验收）。
3. **跨机压测与 APM**：目标端点、并发阶梯、`keep-alive`/`cold-tls` 模式、失败率及各采集器（`host`/`traefik`/`postgres`/`cadvisor`/`magicbase`）可用状态。
4. **跨机功能回归**：明确列出 `remoteScopeComplete`、`excludedCases` 与 `excludedCaseReasons`（宿主机耦合 / 本地交付夹具 / 无反连回调通道），禁止写成全目录 `complete`。

详细信息与配置模板见 [远端验证清单与配置模板](references/remote-runner-checklist.md)。

## Formatter

- Markdown/YAML：更新本 skill 后执行 `skill-hub repo rebuild-index`、`skill-hub apply --global` 与 `skill-hub status --global --pattern magictest-remote-verification`（在 `.agents/skills/` 开发时使用 `skill-hub validate --pattern magictest-remote-verification --links`）。
- 本 skill 涉及的 Shell / Python / JSON 示例保持 LF、零硬编码密钥；所有 Python 命令带 `python3 -B` 或 `PYTHONDONTWRITEBYTECODE=1`。
