---
name: magiccommon-config-hotreload
description: 用于基于 magicCommon framework/configuration 设计业务配置、模块配置、环境变量覆盖和热加载监听。处理 application.toml、config.d、Watch/WatchModule/Reload 等场景时使用。
version: 1.0.0
---

# magicCommon Config Hotreload

这个 skill 用于业务配置接入和热加载，不处理配置框架底层实现。

## 1. 先读这些文件

- `framework/configuration/README.md`
- `framework/configuration/manager.go`
- `framework/configuration/config.go`

## 2. 目录约定

默认结构：

```text
config/
  application.toml
  config.d/
    payment.toml
    auth.toml
```

推荐做法：

- 全局公共配置放 `application.toml`
- 模块隔离配置放 `config.d/*.toml`
- 敏感信息优先走环境变量覆盖

## 3. 常用业务用法

- 全局读取：
  - `GetString / GetInt / GetBool`
- 模块读取：
  - `GetModuleConfig`
  - `GetModule...WithDefault`
- 热加载监听：
  - `Watch`
  - `WatchModule`
  - `WatchSection`

## 4. 写业务配置时的规则

- 配置 key 尽量稳定，不要频繁改层级。
- 可选项必须提供默认值。
- 热更新回调里只做轻量刷新，不做重 IO 或阻塞逻辑。
- 如果配置变化会影响连接池、client、后台任务，回调里要明确做重建或切换。

## 5. 推荐验证

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor \
go test ./framework/configuration -count 1
```
