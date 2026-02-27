# Go 性能基准测试规范 (Go 1.24+)

## 1. 编写模式
使用 Go 1.24 引入的 `b.Loop()` 以获得更精准的测量。

```go
func BenchmarkRefactoredLogic(b *testing.B) {
    // 耗时初始化逻辑...
    b.ResetTimer()
    for b.Loop() { // Go 1.24+ 推荐写法
        TargetLogic()
    }
}
```

## 2. 核心验证指标
- **`ns/op`**: 每次操作的纳秒耗时。
- **`B/op`**: 每次操作分配的内存字节数。
- **`allocs/op`**: 每次操作的内存分配次数（重构重点目标是降低此指标）。