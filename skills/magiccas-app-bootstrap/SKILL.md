---
name: magiccas-app-bootstrap
description: "用于处理 `magicCas` 的启动链路、initiator 装配、主入口调整和应用级排障。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.1
  author: "rangh-codespace"
---
# magiccas-app-bootstrap

用于处理 `magicCas` 的启动链路、initiator 装配、主入口调整和应用级排障。

## 适用场景

- 调整 `cmd/magicCas/main.go`
- 排查 `persistence` / `routeregistry` / `pprof` 启动失败
- 处理 listener 生命周期和关闭逻辑
- 补 initiator 相关测试和文档

## 重点文件

- `cmd/magicCas/main.go`
- `docs/design-startup.md`
- `internal/initiators/persistence/persistence.go`
- `internal/initiators/routeregistry/routeregistry.go`
- `internal/initiators/pprof/pprof.go`

## 工作方式

1. 先确认失败发生在 `Setup`、`Run` 还是 `Teardown`
2. 优先返回 `*cd.Error`，避免把常规错误做成 `panic`
3. 对监听器类 initiator，要求“先绑定、后启动、可关闭”
4. 变更后至少运行 initiator 相关测试

## 验证

```bash
GOCACHE=/tmp/magiccas-gocache go test ./internal/initiators/... -count 1
```
