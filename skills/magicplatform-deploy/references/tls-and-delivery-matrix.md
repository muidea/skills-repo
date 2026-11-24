# TLS 与交付模式矩阵

## TLS 模式选择

| `TLS_MODE` | 适用域名 | 必需输入/文件 | `deployment-preflight.sh` 校验要点 |
| --- | --- | --- | --- |
| `local-ca`（默认 `local.vpc`） | 仅 `local.vpc` | 自动生成到 `services/secret/tls/{ca.crt,tls.crt,tls.key}` | SAN 覆盖 `DOMAIN` 与 `*.DOMAIN`、链验证、公钥匹配及 24h 有效期 |
| `files` | 公网/受管域名 | `TLS_CERT_FILE`、`TLS_KEY_FILE`、`TLS_CA_FILE` | 同上（证书链 + SAN + 密钥匹配） |
| `acme.sh`（默认非 `local.vpc`） | 公网域名 | `ACME_DNS_PROVIDER`、`acme.sh` 与 `reload-traefik-tls.sh` | 已物化 `tls.crt`/`tls.key`/`ca.crt` 后执行文件校验 |
| `traefik` | 公网域名 | `ACME_ACCOUNT_EMAIL`、`traefik-acme.toml`、`0600` `acme/acme.json` | 拒绝软链接、校验 `0600` 权限与合法 JSON 对象 |

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
