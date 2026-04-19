---
name: magicbase-app-bootstrap
description: "用于处理 `magicBase` 的启动链路、initiator 装配、主入口调整和应用级排障。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.2
  author: "rangh-codespace"
---
# magicbase-app-bootstrap

用于处理 `magicBase` 的启动链路、initiator 装配、主入口调整和应用级排障。

## 适用场景

- 调整 `application/magicBase/cmd/main.go`
- 排查 initiator 启动失败
- 处理 `monitoring` / `persistence` / `routeregistry` / `pprof` / `timer` 生命周期问题
- 补启动链路测试和文档

## 重点文件

- [main.go](magicBase/application/magicBase/cmd/main.go)
- [design-startup.md](magicBase/docs/design-startup.md)
- [design-http-entrypoints.md](magicBase/docs/design-http-entrypoints.md)
- [monitoring.go](magicBase/internal/initiators/monitoring/monitoring.go)
- [persistence.go](magicBase/internal/initiators/persistence/persistence.go)
- [routeregistry.go](magicBase/internal/initiators/routeregistry/routeregistry.go)
- [pprof.go](magicBase/internal/initiators/pprof/pprof.go)
- [timer.go](magicBase/internal/initiators/timer/timer.go)

## 工作方式

1. 先确认失败发生在 `Setup`、`Run` 还是 `Teardown`
2. 优先返回 `*cd.Error`，避免把常规错误做成 `panic`
3. 对监听器类 initiator，要求“先绑定、后启动、可关闭”
4. `timer` 通过后台任务发事件，排障时同时检查 task/event 依赖是否已就绪
5. 保持应用创建原子失败，避免数据库注册失败后留下半成功状态
6. 变更后至少运行相关 initiator 包测试

## 验证

```bash
GOCACHE=/tmp/magicbase-gocache go test ./internal/initiators/... -count 1
```
