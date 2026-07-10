---
name: magicmodulesrepo-app-bootstrap
description: "用于处理 `magicModulesRepo` 的启动链路、initiator 装配和 listener 生命周期问题。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.3
  author: "rangh-codespace"
---
# magicmodulesrepo-app-bootstrap

用于处理 `magicModulesRepo` 的启动链路、initiator 装配和 listener 生命周期问题。

## 适用场景

- 排查 `persistence` / `routeregistry` / `pprof` / `cron` 启动失败
- 调整监听端口和中间件装配
- 补 initiator 生命周期测试

## 重点文件

- [design-startup.md](magicModulesRepo/docs/design-startup.md)
- [persistence.go](magicModulesRepo/initiators/persistence/persistence.go)
- [routeregistry.go](magicModulesRepo/initiators/routeregistry/routeregistry.go)
- [pprof.go](magicModulesRepo/initiators/pprof/pprof.go)
- [cron.go](magicModulesRepo/initiators/cron/cron.go)

## 工作方式

1. 先确认失败发生在 `Setup`、`Run` 还是 `Teardown`
2. listener 型 initiator 采用“先绑定、后启动、可关闭”
3. `cron` 是后台调度入口，排障时同时检查 background routine 和任务注册
4. 优先返回 `*cd.Error`，不用 `panic` 处理常规错误
5. 修改后至少运行 initiator 相关测试
6. `magicModulesRepo` 中的共享 initiator 只负责通用依赖装配，例如 base client、route registry、pprof、cron；不要在这里承接具体业务应用“已安装/未安装”的判定与恢复策略。
7. 如果共享 `persistence` 无法拿到业务应用所需的运行时绑定信息，应把错误显式返回给上层应用，由具体应用自行决定恢复或失败，而不是留下空 `baseClient` 继续启动后续模块。

## 验证

```bash
GOCACHE=/tmp/magicmodulesrepo-gocache go test ./initiators/... -count 1
```
