# 验证分层边界与报告规范

## 四层证据矩阵

| 层级 | 证明什么 | 不证明什么 | 典型入口 |
| --- | --- | --- | --- |
| L1 静态/治理/Go-Vitest 单测 | 源码逻辑、接口路由、仓库目录与文档链接完整 | 不证明镜像、Docker Compose 或实库可用 | `go test`、`vitest`、`check_repository_layout.py` |
| L2 打包与隔离夹具 | `release.sh` 允许清单、脚本容错与离线模型包校验 | 不证明目标主机证书、网络、CAS/Base 运行态正常 | `release-package_test.py`、`deployment-checks_test.sh` |
| L3 模拟应用冷启动与联调 | 端到端业务建模、Portal 订阅、Gateway 限流与 `CreateEffect` 派生 | 单运行不能替代全量 245 条平台回归 | `bootstrap_simulated_apps.py`、`run_dual_apps_e2e.py` |
| L4 平台全量标准/异常/专项回归 | 多租户、权限撤回、并发/响应丢失与故障恢复 | 定向 `--cases` 仅代表所选子集，不可推导整库通过 | `regression/run_standard.py` |

## 报告与临时产物规则

1. `~/codespace/magicTest/reports/` 仅限本机保留，不提交 Git；执行全量 `platform-standard` 时会自动清理历史轮次目录，定向 `--cases` 与 `--dry-run` 不清旧记录。
2. 所有离线测试与预览脚本的临时输出必须使用 `mktemp -d` 放在源码仓库之外并及时清理。
3. 每次执行跨仓源码改动后，Go 服务依赖必须在消费者验证前通过 `~/codespace/upgrade_vendor.sh` 同步（纯文档/纯测试不重建 vendor）。
