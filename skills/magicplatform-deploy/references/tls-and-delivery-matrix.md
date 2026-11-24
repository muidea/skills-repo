# TLS 与交付模式矩阵

## TLS 模式选择

| `TLS_MODE` | 适用域名 | 必需输入/文件 | `deployment-preflight.sh` 校验要点 |
| --- | --- | --- | --- |
| `local-ca`（默认 `local.vpc`） | 仅 `local.vpc` | 自动生成到 `services/secret/tls/{ca.crt,tls.crt,tls.key}` | SAN 覆盖 `DOMAIN` 与 `*.DOMAIN`、链验证、公钥匹配、`-checkhost` 输出匹配及 24h 有效期 |
| `files` | 公网/受管域名 | `TLS_CERT_FILE`、`TLS_KEY_FILE`、`TLS_CA_FILE` | 同上（证书链 + SAN + 密钥匹配 + `-checkhost`） |
| `acme.sh`（默认非 `local.vpc`） | 公网域名 | `ACME_DNS_PROVIDER`、`acme.sh` 与 `reload-traefik-tls.sh` | 已物化 `tls.crt`/`tls.key`/`ca.crt` 后执行文件校验 |
| `traefik` | 公网域名 | `ACME_ACCOUNT_EMAIL`、`traefik-acme.toml`、`0600` `acme/acme.json` | 拒绝软链接、校验 `0600` 权限与合法 JSON 对象 |

## 不同模式主机依赖差异

- **开发初始化 / 更新（`MAGIC_DEPLOYMENT_MODE=development`）**：本机需要 `sh`、`python3 >= 3.9`（3.9/3.10 另需 `tomli==2.2.1`）、`jq`、`openssl`、`curl`、`docker` + `docker compose v2`（可选 `ss`）。
- **离线交付包导出与目标机导入（`release.sh` / `load.sh`）**：源机与目标机均需上述全部工具，并确保磁盘空间可容纳导出的镜像 tar 包及 `docker load`。
- **仅远端站点只读探活**：目标操作机只需 `sh`、`python3`、`curl`，使用 `deployment-health.sh --skip-docker --base-url https://panel.<domain>`。
- **源码级全清单校验（`platform-manifests_test.sh`）**：另需 `go`（`GOFLAGS=-mod=vendor`）及同级 `magicRunner`/`magicFile` checkout。

## 打包允许清单同步

新增进入运行发布包的脚本必须同时同步以下四处并运行包回归测试：

1. `~/dataspace/magicPlatform/scripts/stage-platform-delivery.py` 中的 `RUNTIME_SCRIPTS`
2. `~/dataspace/magicPlatform/release.sh` 中的 `copy_runtime_scripts()` 列表
3. `~/dataspace/magicPlatform/tests/deployment/release-package_test.py` 中的 `RUNTIME_SCRIPTS`
4. 运行回归：
   ```sh
   cd ~/dataspace/magicPlatform
   PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="$PWD/scripts" python3 -B tests/deployment/release-package_test.py
   PYTHONDONTWRITEBYTECODE=1 python3 -B tools/check_repository_layout.py
   ```
