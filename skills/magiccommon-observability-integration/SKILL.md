---
name: magiccommon-observability-integration
description: 用于基于 magicCommon monitoring 为业务模块接入指标采集、Provider 注册、Exporter 导出和运行时配置。编写业务监控、性能指标或对接 Prometheus/JSON 导出时使用。
version: 1.0.0
---

# magicCommon Observability Integration

这个 skill 用于业务指标接入，不做监控框架底层重构。

## 1. 先读这些文件

- `monitoring/README.md`
- `monitoring/QUICK_START.md`
- `monitoring/API_REFERENCE.md`
- `monitoring/manager.go`
- `monitoring/types/provider.go`

## 2. 推荐接入顺序

优先使用实例级 `Manager`：

1. `NewManager(config)`
2. `Initialize()`
3. `RegisterProvider(...)`
4. `Start()`
5. 退出时 `Shutdown()`

## 3. 业务里怎么拆指标

- 一个业务域一个 provider
- 指标定义稳定，不随临时需求频繁改名
- label 控制基数，避免高基数用户 ID、订单号
- 慢变化状态用 Gauge
- 累积事件用 Counter
- 分布统计再考虑 Histogram / Summary

## 4. 推荐实践

- Provider 里只负责定义和收集，不要做重业务逻辑。
- Collector/exporter 的配置集中在应用启动阶段。
- 端口监听相关行为要考虑部署环境限制。
- 本地开发先验证 `./monitoring ./monitoring/core`，再验证 `./monitoring/test`

## 5. 推荐验证

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor \
go test ./monitoring ./monitoring/core -count 1
```

如果改到 HTTP exporter：

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor \
go test ./monitoring/test -count 1
```
