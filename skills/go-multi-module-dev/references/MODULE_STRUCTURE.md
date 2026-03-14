# Module Structure

## 1. 常见目录

```text
project-root/
├── application/{app}/
├── internal/modules/kernel/{module}/
├── internal/modules/blocks/{module}/
├── internal/pkg/
├── pkg/
└── docs/
```

## 2. 什么时候放哪里

- `application/{app}`: 可执行程序入口、docker、bootstrap
- `internal/modules/kernel`: 核心业务模块
- `internal/modules/blocks`: 可复用业务模块
- `internal/pkg`: 仓库内部共享但不对外导出
- `pkg`: 对外可复用公共包

## 3. 模块最小结构

```text
{module}/
├── module.go
├── biz/
│   └── biz.go
├── service/
│   └── service.go
└── pkg/
    ├── common/
    │   └── const.go
    └── models/
```

## 4. 分层职责

- `module.go`: 模块注册、依赖获取、生命周期
- `biz/`: 业务逻辑、事件处理、后台任务、持久化编排
- `service/`: HTTP route、handler、session、请求响应
- `pkg/common`: 模块 ID、常量、错误、result/filter
- `pkg/models`: 模型、DTO、view

## 5. 经验规则

- 不要把 HTTP handler 和业务逻辑混在 `biz/`
- 不要把跨模块公共常量塞进单个业务模块
- 涉及 `magicOrm` 模型时，优先把模型和 filter 放进 `pkg/models` / `pkg/common`
- 涉及 `magicEngine` route 时，优先让 `service` 做注册和 handler 适配
- 涉及 event，先明确事件 ID、source、destination，再落到 `biz`
