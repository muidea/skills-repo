---
name: magiccommon-monitoring
description: 用于处理 magicCommon monitoring 的 Manager、Registry、Collector、Provider、Exporter 接入方式，以及相关测试和文档。修改监控初始化、指标提供者、导出配置或 monitoring 文档时使用。
version: 1.0.0
---

# magicCommon Monitoring

这个 skill 处理 `monitoring` 相关实现和接入。

## 1. 先读这些文件

- `monitoring/README.md`
- `monitoring/QUICK_START.md`
- `monitoring/API_REFERENCE.md`
- `monitoring/manager.go`
- `monitoring/core/collector.go`
- `monitoring/core/registry.go`
- `monitoring/core/exporter.go`
- `monitoring/test/*.go`

## 2. 当前推荐接入方式

优先使用实例级 `Manager`：

1. `NewManager(config)`
2. `Initialize()`
3. `RegisterProvider(...)`
4. `Start()`
5. `Shutdown()`

全局 manager 只用于历史兼容或简单程序。

## 3. 重点检查项

- `Manager` 是否误用全局 registry 或全局状态
- `UpdateConfig()` 是否在导出配置变化时真正重建 exporter
- provider 注册、collector 收集、exporter 导出链路是否一致
- HTTP exporter 测试在端口受限环境下是否会干净跳过
- 文档示例是否仍然匹配当前初始化顺序

## 4. 测试规则

- 不依赖 exporter 的逻辑优先测：
  - `./monitoring`
  - `./monitoring/core`
- 依赖端口监听的测试，要允许受限环境下 `Skip`
- 不要把监听失败、网络失败放大成 panic 或误导性的断言失败

## 5. 推荐验证

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor \
go test ./monitoring ./monitoring/core -count 1
```

如果改到 exporter 或 HTTP metadata，再加：

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor \
go test ./monitoring/test -count 1
```

最后收口：

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor go test ./... -count 1
```
