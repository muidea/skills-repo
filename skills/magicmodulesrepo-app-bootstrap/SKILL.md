---
name: magicmodulesrepo-app-bootstrap
description: "用于处理 `magicModulesRepo` 的启动链路、initiator 装配和 listener 生命周期问题。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.2
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

## 验证

```bash
GOCACHE=/tmp/magicmodulesrepo-gocache go test ./initiators/... -count 1
```
