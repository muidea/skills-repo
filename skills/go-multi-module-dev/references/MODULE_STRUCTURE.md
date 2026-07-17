# Runtime Unit Structure

## 1. 常见目录

```text
project-root/
├── <entry-root>/<entry-name>/
├── internal/<unit-root>/<group-path>/<unit>/
├── internal/pkg/
├── pkg/
└── docs/
```

这是常见形态，不是固定标准。

## 2. 什么时候放哪里

- `<entry-root>/<entry-name>`: 可执行程序入口、启动参数、docker、bootstrap
- `internal/<unit-root>/<shared-group>/<unit>`: 可复用基础能力或单一资源能力
- `internal/<unit-root>/<orchestration-group>/<unit>`: 编排、治理、策略、准入、授权、安装、运行态控制
- `internal/<unit-root>/<group-path>/<unit>/internal`: 单个运行单元私有 helper
- `internal/pkg`: 仓库内部共享但不对外导出
- `pkg`: 对外可复用公共包

如果当前仓库已经把 `<shared-group>` 和 `<orchestration-group>` 命名成 `blocks/kernel` 或其他名字，直接沿用，不要重命名。

## 3. Module / Block / Initiator 决策规则

先判断能力的职责边界，再创建目录。

定义为 module：

- 功能闭环必须组合、聚合、治理或编排多个独立组件合同
- 可以管理自身协调状态，但不能持有其他组件的 service、repository、adapter 或 callback
- 与其他 module/block 的运行期交互只能通过 EventHub
- 不能因为存在 repository、正式状态、route 或较多调用方就自动定义为 module

定义为 block：

- 围绕单一资源或单一技术能力建模
- 可以管理自己的正式状态或运行时状态，并提供稳定 CRUD、状态切换、基础校验、资源事件或公共封装
- 被多个上层能力复用，但自身不负责完整业务流程
- 不主动组合多个其他运行单元来完成审核、准入、授权、发布、安装、治理等闭环

定义为 initiator：

- 只提供一种无业务状态基础设施能力
- 可以持有该能力所需的单一进程级句柄，但不管理业务状态、业务策略或多能力状态
- 不得同时聚合 repository set、EventHub wrapper、runtime policy、route registry 等多种职责
- “无业务状态”不等于零字段；RouteRegistry Initiator 可以持有 router/server/listener，但只服务 HTTP 路由基础设施

不要使用的判断方式：

- 不要用“有状态就是 module、无状态就是 block”判断；block 允许拥有自己的状态
- 不要因为目录名字更短或历史相似就复用已有分组
- 不要把跨分组策略流程塞进某个基础能力单元
- 不要让 module/block 通过直接接口注入互调；它们只能通过 EventHub 的具体事件合同协作
- 不要把只有一个消费者、没有独立资源生命周期的内存索引或纯 helper 强行拆成 block
- 不要在分组根目录下新增孤立 helper 包。只有带 `<unit-entry-file>` 并参与生命周期的目录才属于运行单元；单元私有 helper 放 `{unit}/internal`，跨单元共享 helper 放 `internal/pkg`

组件必要性检查：

- 是否有独立资源生命周期或正式状态 owner？
- 是否需要独立启停、恢复、巡检或限流？
- 是否有多个真正独立的消费者？
- 如果删除该运行单元并改为 focused package，是否会破坏 owner 或 lifecycle 边界？

以上均为否时，通常不需要独立 Block。

## 4. 运行单元最小结构

```text
{unit}/
├── <unit-entry-file>
├── biz/
│   └── biz.go
├── service/
│   └── service.go
└── pkg/
    ├── common/
    │   └── const.go
    └── models/
```

## 5. 分层职责

- `<unit-entry-file>`: 运行单元注册、依赖获取、生命周期
- `biz/`: 业务逻辑、事件处理、后台任务、持久化编排
- `service/`: HTTP route、handler、session、请求响应
- `pkg/common`: 单元 ID、常量、错误、result/filter
- `pkg/models`: 模型、DTO、view

## 6. 经验规则

- 不要把 HTTP handler 和业务逻辑混在 `biz/`
- 不要把跨运行单元公共常量塞进单个业务单元
- 涉及 `magicOrm` 模型时，优先把模型和 filter 放进 `pkg/models` / `pkg/common`
- 涉及 `magicEngine` route 时，优先让 `service` 做注册和 handler 适配
- 涉及 event，先由投递组件在自己的 `pkg/events` 明确事件 ID、具体 command/data/result、source、destination，再由消费组件导入并订阅
- module/block 不得通过 EventHub 返回内部 `*Store`、`*Registry`、`*Recorder` 等实现对象；这会让后续调用绕过 owner
- process service 只驱动 application lifecycle 和进程信号，不承担业务 owner 或路由声明
