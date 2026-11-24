---
name: magictest-platform-verify
description: Selects, executes, checks host dependencies for, and reports layered magicTest and magicPlatform verification suites from offline governance checks up to live regression runs. Use when pre-checking toolchain dependencies, discovering test targets, running unit/packaging/E2E dry-runs or live verification, and distinguishing offline proofs from real live acceptance.
metadata:
  version: "1.1.0"
  author: "rangh-codespace"
  tags: "magictest,verification,e2e,regression,governance"
compatibility: Compatible with open_code
---

# 平台与模拟应用分层验证指南

用于规范核对宿主机工具链依赖、选择与执行 `magicPlatform` 和 `magicTest` 的各层测试与回归入口，严防“源码单测替代打包/Live 验收”“mock 成功掩盖真实边界”以及报告产物误污染仓库。

## 何时使用

- 准备在新环境运行测试前，需按目标层级确认最小依赖是否齐全。
- 代码修改后需要确认最小影响回归范围与配套仓（如 `magicRunner`、`magicPlatform`、`magicTest`）联动检查。
- 需要查询 `run_tests.py` 或 `regression_inventory.py` 规划标准/异常/专项验收。
- 需要撰写精确区分“源码单测 / 隔离打包 / 双应用冷启动预检 / 真实 Live”的验证结论。

## 前置依赖与分层自检

按待跑目标层级先执行只读自检（缺项即停或按规则记为 skipped/blocked，不盲跑；详细清单见 [验证分层边界与报告规范](references/verification-layers.md)）：

```sh
# 1. Layer 1/2 基础依赖自检（magicPlatform 离线测试 + magicTest 模拟/库存单测）
for c in sh bash python3 jq openssl; do
  command -v "$c" >/dev/null 2>&1 || echo "MISSING:$c"
done
PYTHONDONTWRITEBYTECODE=1 python3 -B -c "import zoneinfo, ssl; assert hasattr(ssl, 'VERIFY_X509_PARTIAL_CHAIN')"
PYTHONDONTWRITEBYTECODE=1 python3 -B ~/dataspace/magicPlatform/scripts/deployment_toml.py

# 2. Layer 3/4 浏览器全量回归额外自检（platform-standard / platform-abnormal）
node -v
node -e "const p = require(require('node:os').homedir() + '/.local/share/playwright/node_modules/playwright/package.json'); if (p.version !== '1.65.0') throw new Error(p.version); console.log('playwright-node=' + p.version);"
for c in docker go; do
  command -v "$c" >/dev/null 2>&1 || echo "MISSING_FOR_FULL_REGRESSION:$c"
done

# 3. 传统 Python pytest / VMI / UI 套件额外自检（仅触发相关 goal 时检查）
PYTHONDONTWRITEBYTECODE=1 python3 -B -c "
for m in ('pytest', 'requests', 'urllib3', 'faker'):
    __import__(m)
print('legacy-pytest-deps-ok')
"
```

- 浏览器回归建议在启动前设置较短宿主临时目录 `export TMPDIR=~/.local/state/magicTest/t`（`mkdir -p` 并 `chmod 700`），避免 Chromium Unix socket 超长。
- `node` 需 `18+`（内置 `node:test`、`node:assert/strict` 等核心模块）；用户级浏览器可通过 `~/.local/bin/playwright install chromium` 安装，或显式传 `--chrome`。

## 核心规则与断言原则

1. **严禁跨层夸大通过范围**：
   - 离线夹具、Go 单测、Vite 构建、`--dry-run`、隔离 Docker 打包与真实 Live 必须分别记录。
   - 跳过（SKIP）、部分完成（partial）或被阻塞项不得表述为“全部通过”。
2. **严禁修改历史产物或清理失败现场制造通过**：
   - 未知结果的原操作按 owner 正式查询/恢复路径处理；不删除原状态或伪造新成功样本代替。
   - 严格避免在源码目录生成 `__pycache__`（统一使用 `python3 -B` 或 `PYTHONDONTWRITEBYTECODE=1`）。
3. **仅引用实跑观测结果**：只报告最后一次编辑完成后亲眼观测到的命令退出码与实际数字。

## 分层执行清单

### Layer 1：文档、目录治理与部署离线回归（`magicPlatform`）

```sh
cd ~/dataspace/magicPlatform
PYTHONDONTWRITEBYTECODE=1 python3 -B tools/check_repository_layout.py
PYTHONDONTWRITEBYTECODE=1 python3 -B tools/check_documentation_layout.py
PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover -s tests/governance -p 'test_*.py' -v
sh tests/deployment/deployment-checks_test.sh
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="$PWD/scripts" python3 -B tests/deployment/release-package_test.py
```

### Layer 2：`magicTest` 目标发现、模拟应用单测与离线预检

```sh
cd ~/codespace/magicTest
python3 -B run_tests.py --list-goals
python3 -B run_tests.py --list
python3 -B regression_inventory.py --check

python3 -B -m unittest discover -s applications/live_e2e -p 'test_*.py' -v
python3 -B -m unittest discover -s tools -p 'test_export_remote_sim_bundle.py' -v
python3 -B applications/live_e2e/run_dual_apps_e2e.py --dry-run --output-dir /tmp/magic-e2e-dryrun
```

### Layer 3：Live 健康、双应用联调与平台标准回归

先运行 `sh ~/dataspace/magicPlatform/scripts/deployment-health.sh --json` 验证环境基线，再按目标执行：

```sh
cd ~/codespace/magicTest
# 平台常规回归预览 / 执行（使用仓外私密配置）
python3 -B run_tests.py --target platform-standard --dry-run
# 双应用 Live E2E（独立 state-dir 与 0600 密钥文件）
python3 -B run_tests.py --target app-dual-live-e2e --help
```

执行完整 `platform-standard` / `platform-abnormal` 前确认已通过上方 Layer 3/4 浏览器依赖自检（Node 18+、用户级 Playwright 1.65.0 与 Chromium、Docker、Go）。

各测试层级的边界、报告留存位置与异常/专项隔离原则见 [验证分层边界与报告规范](references/verification-layers.md)。

## Formatter

- 测试结论与验收记录严格按“已验证项 / 未执行或受阻条件 / 新增缺口”分段书写，保持 GitHub 风格 Markdown，文件引用在平台维护文档内统一使用以 `~/` 开头的路径。
