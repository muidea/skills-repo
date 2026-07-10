---
name: magiccas-app-bootstrap
description: "用于处理 `magicCas` 的启动链路、initiator 装配、主入口调整和应用级排障。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.2
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
5. `magicCas` 是否已完成自身运行时绑定、缺失时是否需要初始化或直接失败，属于 `magicCas` 自己的启动治理逻辑，不能继续依赖共享 initiator 或 `magicBase` 替它做业务判断。
6. `persistence` 未就绪时必须在 initiator 或 module 边界直接返回明确错误，禁止让 `role` / `namespace` DAO 在 `baseClient == nil` 的状态下继续运行。

## 验证

```bash
GOCACHE=/tmp/magiccas-gocache go test ./internal/initiators/... -count 1
```
