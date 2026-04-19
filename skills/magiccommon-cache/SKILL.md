---
name: magiccommon-cache
description: 用于处理 magicCommon foundation/cache 的构造器、容量限制、过期清理、统计信息、并发访问和释放语义。修改 MemoryCache、KVCache、GenericKVCache 或其测试、文档时使用。
version: 1.0.0
---

# magicCommon Cache

这个 skill 只处理 `foundation/cache`。

## 1. 先读这些文件

- `foundation/cache/README.md`
- `foundation/cache/options.go`
- `foundation/cache/memorycache.go`
- `foundation/cache/kvcache.go`
- `foundation/cache/generickvcache.go`
- `foundation/cache/*_test.go`

## 2. 当前实现约定

- 旧构造器保留：
  - `NewCache`
  - `NewKVCache`
  - `NewGenericKVCache`
- 新能力走 options 构造器：
  - `NewCacheWithOptions`
  - `NewKVCacheWithOptions`
  - `NewGenericKVCacheWithOptions`
- 当前支持：
  - `Capacity`
  - `CleanupInterval`
  - `Stats()`
- 淘汰策略是轻量的 oldest-entry eviction，不是完整 LRU/LFU。

## 3. 改动原则

- 不要破坏旧构造器和旧接口。
- 新统计和新能力优先挂在具体实现上，除非要做统一接口升级。
- 关闭和过期清理必须避免：
  - 释放后再发命令
  - worker 退出后 channel send
  - 共享条目时间戳的并发写

## 4. 测试建议

- 新增容量/淘汰测试时，把 `CleanupInterval` 调小，避免慢测。
- 必测：
  - `Release()` 幂等
  - 过期清理不破坏释放
  - 容量淘汰
  - `Stats()` 命中/未命中/淘汰/过期计数

## 5. 推荐验证

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor \
go test ./foundation/cache -count 1
```

如果改动影响应用关闭路径，再加：

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor \
go test ./framework/application ./task ./execute -count 1
```
