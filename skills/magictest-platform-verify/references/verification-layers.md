# 验证分层边界与报告规范

## 四层证据与依赖矩阵

| 层级 | 证明什么 | 不证明什么 | 典型入口 | 最小宿主机依赖 |
| --- | --- | --- | --- | --- |
| L1 静态/治理/Go-Vitest 单测 | 源码逻辑、接口路由、仓库目录与文档链接完整 | 不证明镜像、Docker Compose 或实库可用 | `go test`、`vitest`、`check_repository_layout.py` | 对应语言工具链（`go` `vendor` / `node`）+ `python3` |
| L2 打包与隔离夹具 | `release.sh` 允许清单、脚本容错与离线模型包校验 | 不证明目标主机证书、网络、CAS/Base 运行态正常 | `release-package_test.py`、`deployment-checks_test.sh`、`platform-manifests_test.sh` | `sh`、`bash`、`python3`（<3.11 需 `tomli`）、`jq`、`openssl`、`curl`；清单/运行校验需 `docker`/`go` + 同级源码 |
| L3 模拟应用冷启动与联调 | 端到端业务建模、Portal 订阅、Gateway 限流与 `CreateEffect` 派生 | 单运行不能替代全量 245 条平台回归 | `bootstrap_simulated_apps.py`、`run_dual_apps_e2e.py` | **Python 3.10+** 标准库（+ 系统 `tzdata`、OpenSSL `VERIFY_X509_PARTIAL_CHAIN`）+ 模型包 |
| L4 平台全量标准/异常/专项回归 | 多租户、权限撤回、并发/响应丢失与故障恢复（含 `remote-https` 跨机远端只读基线子集） | 定向 `--cases` 或 `remoteScopeComplete` 仅代表所选子集，不可推导含宿主机 `F059-001` 的整库 `complete` | `regression/run_standard.py`、`platform-standard`、`platform-abnormal` | `python3`、**Node 18+**、用户级 **Playwright `1.65.0`** + Chromium、`go`、短路径 `TMPDIR`；`local` 模式另需本机 `docker` |
| L5 跨机性能压测与 APM 关联 | 独立施压机 QPS/TPS、P50/P95/P99、长连接 vs 冷 TLS、老化劣化与平台 Prometheus APM（主机/容器/Traefik/Postgres/magicBase） | 短压或 `available=false` 指标项不推导容量承诺或应用层全链路归因 | `load/run_load.py`、`platform-load`、`load-tools-unit` | **Python 3.10+** 零第三方包（+ `0600` 凭据/ApiKey/最小权限 Token；被测端 `ENABLE_APM=true ./start.sh`） |

> 若需运行传统 `magicTest/{cas,file,panel,platform,session,ui,vmi,mock}` Python `pytest` / Python-UI 套件，需在独立 Python venv 中安装 `pytest`、`requests`、`urllib3`、`faker`（`ui/` 另需 Python 版 `playwright`，`vmi/` 另见 `vmi/requirements.txt`）。

## 报告与临时产物规则

1. `~/codespace/magicTest/reports/` 仅限本机保留，不提交 Git；执行全量 `platform-standard` 时会自动清理历史轮次目录，定向 `--cases` 与 `--dry-run` 不清旧记录。
2. 所有离线测试与预览脚本的临时输出必须使用 `mktemp -d` 放在源码仓库之外并及时清理。
3. 每次执行跨仓源码改动后，Go 服务依赖必须在消费者验证前通过 `~/codespace/upgrade_vendor.sh` 同步（纯文档/纯测试不重建 vendor）。
