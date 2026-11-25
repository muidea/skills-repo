# 当前 Facade 接入规则

适用 0.1.0 开发树，业务契约 1.1.2。正式服务统一由 magicDataHub 编排与部署，FedEngine 只交付库。`tests/support/host` 和开发 example 不得作为服务依赖；没有库级服务二进制或 Docker 镜像。完整签名从预检匹配的 Facade 源码/Rustdoc查询；下表不是未来 API 清单。

| 接口 | 已实现行为 |
|---|---|
| `FedEngineConfig` | 当前 Config 别名，load/validate；路径仍按进程 CWD |
| `FedEngineBundle` | new、profile、register；纯 Factory 注册，返回 FedEngineRegisteredComponents |
| `FedEngineProfile` | PgServer { management_api }、ManagedServer { pgwire }；EmbeddedCore 为明确拒绝的保留变体 |
| 注册结果 | components、initiator_ids、module_ids、profile、resource_requirements、handle、observe |
| `FedEngineResourceDemand` | blocking_io_threads、blocking_io_capacity、max_tasks_per_owner，建议值不自动配置宿主 |
| `FedEngineHandle` | status、pgwire_address、management_address、metrics；无消息/查询/停止能力 |
| `FedEngineStatus` | 实际 Application ID/state、选择覆盖、Ready、组件健康/代际、failure、可用地址 |
| `FedEngineQueryClient` | 注册结果 query_client 绑定可信宿主身份；prepare 固定数据库 OID/版本，execute 仅同 Client/Clone，流式 next/取消 |
| `FedEngineManagementClient` | management_client 绑定显式 grant；source/submit/operation/database/mutate_database，CAS/幂等与异步状态 |
| `FedEngineClientBudget` | Clone 共享准入，无界排队拒绝；SQL/参数/描述/管理控制与累计行数/估算字节、deadline 有界 |
| `FedEngineError` | UnsupportedProfile、Framework；保留实际框架错误 |

默认 Profile 保持 PGWire 开启、HTTP 跟随 management.enabled。Profile 不改变内部 managed storage；HTTP-only 不读 PGWire 口令/TLS，但业务 principal、虚拟库、源配置与共享 query_timeout_ms 仍有效。Config::load 走默认入口校验；接受禁用入口专属无效字段时宿主可反序列化当前 DTO，交 Bundle 作 Profile 校验，不新增旧格式。

关键装配顺序为：加载和准备纯配置 → 同一 Builder 注册 → 显式选择实际 ID → 合并宿主预算 → build/start → observe → 检查 Ready → 接流量 → 等待信号/失败 → checked drain。启动错误后的 cleanup 不完整则保留清理 handle 和 Runtime。关联 Handle 前没有全应用 Ready 证据，不把组件钩子当作全局屏障。

组件 ID：核心 Initiator `duckdb-instance`、`datasource-registry`、`duckdb-runtime`；Module `catalog-manager`、`policy-manager`、`query-coordinator`、`source-manager`；可选入口 `pgwire-listener`、`management-api`。重复 Bundle 拒绝；晚期重复可能留下部分注册，丢弃 Builder。实际 ID 应取返回迭代器，不在宿主复制清单。

配置规则：保留 `data/fedengine.duckdb` 的部署路径、WAL、SecretRef 和凭据格式。不同 App 独立文件/临时目录/端口；同进程共享环境变量不是自动命名空间。缺凭据明确失败/降级，不用默认值。源配置仅首次导入，之后管理状态优先。当前版本不匹配明确拒绝，无历史迁移/回退/自动修复。

自动组织规则：PG/MySQL 均逐原生数据库独立成库，同产品/规范化实例/原生库精确名称相同的登记合并贡献。不同端口或原生库不得按同名合并；同一连接登记可对应多个虚拟库。PG 保留来源 Schema，MySQL 在独立虚拟库内保留原生 database 同名 Schema。来源范围、账号或凭据别名不代替原生目标身份；失败激活不等于已发布目录。

资源规则：受管任务、ServiceLease、实际连接、源/实例屏障和文件占用持续到真实退出。同步扩展可能在客户端取消后继续，StopIncomplete 保留资源，Forced 不是 GracefullyStopped，未知写入不重放。默认 FailFast；监督闭包测试显式注入 Restart，不能据此使用不存在的策略 API。

进程内调用规则：

- FedEnginePrincipal::authenticated(name, origin) 是宿主完成认证后的断言，名称须为配置用户，来源/名称非空、最多128字节且无控制字符。不能直接信任网络请求字段。
- 管理 grant 默认全拒绝；source/database 精确匹配，allow_writes 单独授予。SQL 用户不自动成为管理员，operation 回执也核对来源范围；策略变更丢弃并重新绑定。
- query_client/management_client 只绑定同 Bundle 已见证且完整 Ready 应用；每次调用/流读取检查 Ready 与代际。状态快照不是原子代际租约，应用级 Hub 不随代际失效，仍保持 FailFast，不开放热重启。
- prepare(database, sql, parameter_types, cancel) 检查 CONNECT/Policy/能力；opaque Prepared 保存数据库 OID/版本和源版本，不允许改写。execute(prepared, values, cancel) 仅同 Client/Clone 使用；无多语句或可变会话，DDL 通过同一路径。
- 默认预算10s/4并发/SQL64KiB/参数128/结果10000行及估算8MiB/控制256KiB；绑定有硬上限，timeout不超过配置查询/管理较小值。参数嵌套深度限制64。Clone共享准入，超额53300；执行和消费共享deadline。字节是估算，内部目录/已生成批次仍须依赖全局预算。
- ResultStream 持 permit，next 返回 Rows/Complete；检查 Completion.outcome 与 SQLSTATE/outcome_unknown，缺终态报错。取消、future/stream drop 不证明原生退出或写回滚；permit归还不代表worker退出，仍须checked shutdown。管理提交超时/drop后操作可能继续，宿主持有原幂等key并查询回执，未知写入不自动重放。

当前不提供独立 DDLClient、EmbeddedCore、可配置组件 namespace 或 MQTT 联合容量保证。独立样例是完整可编译 main，不另维护片段模板。Git revision 在源码真正提交后固定；publish=false 不应被接入任务自动改开。

宿主可开启 Hub 消息/全局/目标字节预算；库的 PGWire、管理 HTTP、Query Client 及下游目录/权限/管理请求均声明逻辑输入成本。超额明确拒绝，不自动放宽。成本含可变输入，不是 RSS/结果流上限；结果与元数据仍需独立预算。
