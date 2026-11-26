# 远端测试机配置清单与操作模板

## 1. 档位 2/3 所需 Playwright `1.65.0` 安装（用户级）

当新测试机需要运行 `regression/run_standard.py` 时，安装与 `magicTest` 锁定的用户级 Playwright 版本（不污染系统或业务仓）：

```sh
mkdir -p ~/.local/share/playwright ~/.local/bin
npm --prefix ~/.local/share/playwright install --no-save playwright@1.65.0
ln -sf ~/.local/share/playwright/node_modules/.bin/playwright ~/.local/bin/playwright
~/.local/bin/playwright install chromium
```

若宿主机已安装 `/usr/bin/google-chrome` 且离线无法下载 Chromium，可在私有 `regression-config.json` 中显式指定 `"chrome": "/usr/bin/google-chrome"`。运行回归前务必导出较短临时目录：

```sh
export TMPDIR=~/.local/state/magic-verify/t
```

## 2. 私密 `credentials.json` 模板（仓外 `0600` 文件）

> 切勿将此文件放进任意 Git 仓库。`regression/standard.cjs` 使用扁平管理员结构（`origin`、`account`、`password`、`namespace`），运行时会自动创建并清理 `tenantA`、`tenantB`、`user`、`tenantAdmin`、`otherTenantAdmin` 等回归夹具，无需预置租户或普通用户凭据。

```json
{
  "origin": "https://panel.<domain>",
  "account": "platform-admin",
  "password": "<current-admin-password>",
  "namespace": "panel"
}
```

## 3. 私密 `regression-config.json` 模板（`remote-https` 模式，仓外 `0600` 文件）

### 档位 2（仅测试机 -> 平台单向 HTTPS，自动分流宿主机强耦合、本地夹具与回调类用例）

为使 `standard` 与 `abnormal` 两套报告并列留存（`run_standard.py` 运行全量 `standard` 时会清理历史轮次目录），建议为两套配置独立的 `output` 子目录：

`regression-config-standard.json`：
```json
{
  "executionMode": "remote-https",
  "credentials": "/home/<user>/.local/state/magic-verify/secrets/credentials.json",
  "output": "/home/<user>/testspace/magicTest/reports/remote-verify/standard",
  "targetAddress": "<target-ip>",
  "caFile": "/home/<user>/.local/state/magic-verify/secrets/ca.crt",
  "excludeHostCoupled": true
}
```

`regression-config-abnormal.json`：将 `output` 改为 `.../reports/remote-verify/abnormal`；`F049-003` 会默认通过 `GET /files/self/files/limits/` 自动读取部署上限，如需覆盖或强制校对，可补充可选字段 `"fileUploadMaxBytes": <uploads.maxBytes>`。

### 档位 3（额外开放平台 -> 测试机外部回调，补跑回调用例）

在档位 2 基础上追加（需确认测试机防火墙允许来自平台机 `magicGateway` 的对应端口访问）：

```json
{
  "controlledUpstreamBind": "0.0.0.0:19000",
  "controlledUpstreamAdvertise": "<tester-reachable-ip>:19000"
}
```

- 注意：`remote-https` 模式下**禁止**配置 `deliveryFixtureConfig` 或 `runtimeSnapshotConfig`。
- `caFile` 对公网 CA 域名可省略；对自签 `local.vpc` 域名指向目标机拷出的 `ca.crt`（或叶证书 `tls.crt`）。

## 4. `remote-https` 用例自动分流边界

[remote_profile.py](~/codespace/magicTest/regression/remote_profile.py) 在 `excludeHostCoupled: true`（默认）下按以下规则自动分流，并在 `inputs.json` 与 `report.json` 的 `executionGates.excludedCaseReasons` 中按类别留证：

- **宿主机强耦合（`hostCoupled`，始终排除）**：标准套件 34 项（含 `F059-001` 容器指纹及 `postgres_fixture`/Docker/本地交付夹具用例）、异常套件 6 项。
- **本地交付夹具依赖（`deliveryFixture`，需 `deliveryFixtureConfig`）**：标准套件 58 项、异常套件 9 项。
- **外部上游回调（`upstreamCallback`，未配 `controlledUpstreamBind`/`Advertise` 时排除）**：标准套件 28 项、异常套件 2 项。
- 报告 JSON 中使用 `remoteScopeComplete` 判定远端已覆盖范围是否全通，`catalogCoverage.complete` 仍保持严格全目录口径。

## 5. 跨机压测前的平台侧检查清单

在平台机（服务器 A）与测试机（服务器 B）正式跑长时压测前确认：

1. **开启 APM 栈**：平台机需以 `ENABLE_APM=true ./start.sh` 启动（含 `node-exporter`、`cadvisor`、`postgres-exporter`、`prometheus`、`grafana`；Traefik `:8082` 仅内部 Docker 网络抓取，不暴露宿主机端口）。
2. **保护 APM 域名访问**：建议对 `apm.<domain>` 配置内网 IP 白名单或 BasicAuth（若启用 BasicAuth，压测端通过 `--apm-auth-file` 传入 `0600` 凭据）。
3. **核对限流配置**：
   - 如测试机从单一源 IP 高频登录/并发，检查平台运行配置 `services/runtime/foundation/config/cas/application.toml` 中的 `[oauth.loginRate]`（默认同租户同 IP 60s 限 30 次）与 `[http.source]` 可信代理。
   - 若直接复用意图压测的服务（如 `device_management_service`），确认 Portal 发布配额（如默认收敛 `maxQPS=50`、`dailyQuota=100000`）是否符合本次预期压力梯度，避免误把预期 429 限流计入失败。
4. **验证 Shell `no_proxy`**：若测试机配置了 `https_proxy`，运行前将 `panel.<domain>,apm.<domain>` 加入 `no_proxy` 与 `NO_PROXY`（或使用 `deployment-health.sh --target-address`，以及 `load/run_load.py` / `bootstrap_simulated_apps.py` 的 `--target-address`）。
