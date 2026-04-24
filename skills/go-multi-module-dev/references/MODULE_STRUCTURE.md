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

## 3. 共享能力分组与编排分组决策规则

先判断能力的职责边界，再创建目录。

放入共享能力分组：

- 围绕单一资源或单一技术能力建模
- 对外提供稳定 CRUD、状态切换、基础校验、资源事件或公共封装
- 被多个上层能力复用，但自身不负责完整业务流程
- 不主动组合多个其他运行单元来完成审核、准入、授权、发布、安装、治理等闭环

放入编排/治理分组：

- 组合多个共享能力或外部系统完成完整业务流程
- 承载策略、模板、审核、准入、授权编排、运行态治理、安装部署、服务治理等核心业务语义
- 需要保证跨资源一致性
- 对外暴露的是一个业务入口，而不是单一资源的基础管理入口

不要使用的判断方式：

- 不要因为有 CRUD 表或模型就直接放入共享能力分组
- 不要因为目录名字更短或历史相似就复用已有分组
- 不要把跨分组策略流程塞进某个基础能力单元
- 不要在分组根目录下新增孤立 helper 包。只有带 `<unit-entry-file>` 并参与生命周期的目录才属于运行单元；单元私有 helper 放 `{unit}/internal`，跨单元共享 helper 放 `internal/pkg`

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
- 涉及 event，先明确事件 ID、source、destination，再落到 `biz`
