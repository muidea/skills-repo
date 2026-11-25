---
name: modorch-fedengine-integration
description: "在 Modorch 0.0.3 宿主中接入 modorch-fedengine Facade，处理 Bundle/Profile、宿主预算、路径和检查式退出时使用；含受控 Query/Management Client，不用于修改框架 Runtime 或使用未开放的 EmbeddedCore。"
metadata:
  compatibility: "Rust/Cargo 1.94、Python 3.11+；modorch-fedengine 0.1.0 开发源码与 Modorch 0.0.3 的匹配指纹"
  version: "1.1.6"
  framework-version: "0.0.3"
  library-contracts-revision: "1.1.2"
---

# modorch-fedengine 宿主接入

## 预检与资料

目标为已有宿主或当前源码的独立消费者。先取得目标 manifest、FedEngine 源码位置、入口选择和资源/状态约束；不把工作区外的设计稿当成可调用 API。接口与边界摘要见[当前接入规则](references/integration.md)。

从本 Skill 实际所在目录执行脚本，传入目标宿主 manifest：

```sh
python3 scripts/preflight.py --manifest-path /absolute/host/Cargo.toml
```

预检使用 locked/offline Cargo metadata，检查唯一 Modorch 0.0.3 Git Source/revision、实际 Feature 子集/逐文件框架指纹、Facade 0.1.0 的源码指纹。快照位于[兼容身份](references/compatibility.json)。缺缓存、源码/版本不匹配时报告 Blocked/NotRun，不改写快照绕过。匹配新实现须先验证接口和契约，再更新 Skill 版本及受控快照。

## 接入流程

- 只通过 `modorch_fedengine` Facade 接入；与宿主的 `modorch` 必须是相同 Package ID/Source。当前版本未发布 crates.io，Git 消费需要实际包含本接口的提交。
- 后续所有正式服务统一由 magicDataHub 项目编排与部署。modorch-fedengine 只作为库交付，无可发布服务二进制/镜像；开发测试宿主仅为 dev-dependency，不作为宿主依赖。
- 宿主选择配置、路径、SecretRef、端口、Runtime、日志和信号。`Config::load` 不相对 TOML 重定位；准备绝对文件路径，保留原管理文件/WAL及引用，各实例独立分配可写目录/文件/端口。源 file 引用按各自凭据目录解析，PGWire 用户口令仍引用环境变量。
- 自动组织对 PostgreSQL/MySQL 统一按产品、规范化实例身份和原生数据库精确名称分组：每个原生库独立成虚拟库，同库来源合并，同一连接登记可发现多个虚拟库。保留原 Schema；不要把实例内多个 MySQL database 合成一个自动库，也不要把所有来源放进测试汇总库作为默认交付。
- `FedEngineBundle::new(config).profile(profile).register(&mut builder)` 仅注册 Factory。合并返回实际 IDs 与其他库的显式选择，归并资源建议后由宿主只 build/start 一个 Application。register 失败丢弃 Builder，不启动部分注册结果。
- start 返回后 `registered.observe(&app)`，检查完整应用 Ready。启动失败保留 StartupError source/cleanup/handle；早于 Bundle setup 的失败可能无法见证身份，不强行关联或伪报 Ready。
- 进程内调用仅在 Ready 后绑定 query_client/management_client。Principal 是可信宿主已认证身份断言，不是口令验证；管理 grant 默认拒绝，必须显式授予精确源/虚拟库与写权限，不从不可信输入铸造授权。参数化 SQL、opaque Prepared、预算和未知写入规则见[当前接入规则](references/integration.md)。
- 宿主可开启 Hub 字节预算；库的入口及下游请求声明逻辑输入成本，超额拒绝不放宽。该成本不代表 RSS 或结果流内存。
- 运行结束始终 checked shutdown。StopIncomplete 时保留 Application/Runtime/资源并按宿主策略重试；Forced 保留异常语义。取消不等于同步扩展 I/O 已退出，不自动重放未知写入。
- 模块化扩展与按需插件目录优先读取 `duckdb.plugin_extension_directory` / 环境变量 `FEDENGINE_PLUGIN_EXTENSION_DIRECTORY`（`plugin` 优先于内置 `extension_directory`），支持 `manifest.d/*.json` 插件清单位点及 SHA-256 校验；宿主管理端提供 `GET /api/v1/plugins` 返回 11 类数据源（内置 PG/MySQL 族与按需 OCI 插件 SQL Server/Oracle/DB2/HANA/Dameng）的扩展与 ODBC 驱动就绪状态。

## 当前边界与验证

每 App 一套固定 ID，支持 PgServer/ManagedServer；EmbeddedCore 明确拒绝。Handle 保持只读；Query/Management 能力从注册结果显式绑定，DDL 通过 QueryClient。不直接把内部 Hub、Principal 或执行服务暴露给不可信调用者。生产默认 FailFast，测试注入 Restart 不表示开放热重启 API。

在 FedEngine 源码根目录查阅 `contracts/README.md`、`docs/integration/modorch-host.md` 和 `examples/embedded-in-modorch/`。运行 `python3 scripts/check-library-contracts.py` 做静态检查；用 `--run local` 或 `--run external` 取得对应实际测试证据，实际命令非零不能报告通过。远端测试只用 `scripts/test-federation.sh` 的一次性 PG/MySQL，不指向业务 DSN。联合 MQTT、magicDataHub、规模与长时未执行时单列未验收，不沿用单库结论。

结果说明目标 manifest/版本/指纹、改动、实际命令与范围、契约对应、未执行项和发布状态。临时日志/报告/截图不归档，长期边界留在正式文档。提交/远程发布依用户授权，Skill 不扩展授权。

## Formatter

Markdown/YAML 保持稳定标题、标量 frontmatter 和清晰列表。Python 使用四空格、无尾随空格，运行语法检查并实际执行 preflight；JSON 使用两空格和末尾换行。源码 Rust 使用 cargo fmt。反馈前运行 `skill-hub validate --pattern modorch-fedengine-integration --links` 与 `scripts/quick_validate.py`（若本机 Skill Creator 提供）；先预览 feedback，再仅归档本 Skill 的已验证改动。
