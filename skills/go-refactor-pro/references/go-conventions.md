# Go 语言重构与现代特性标准

## 1. 错误处理 (Modern Pattern)
- **显式处理**: 严禁忽略 `error`。
- **包装上下文**: 使用 `fmt.Errorf("...: %w", err)`。
- **多错误聚合**: 使用 Go 1.20+ 的 `errors.Join(errs...)`。

## 2. 现代特性应用 (Go 1.18+)
- **结构化日志**: 将 `log.Printf` 迁移至标准库 `slog`。
  - *示例*: `slog.Info("msg", "userID", id, "status", status)`
- **泛型 (Generics)**: 针对纯逻辑相关的重复代码（如 Slice 转换、Map 操作），使用泛型提升复用性。

## 3. 构造函数优化 (Functional Options)
重构包含多个配置参数的结构体初始化逻辑。

**模式示例：**
```go
type Server struct { timeout time.Duration }
type Option func(*Server)
func WithTimeout(t time.Duration) Option { return func(s *Server) { s.timeout = t } }
func NewServer(opts ...Option) *Server {
    s := &Server{}
    for _, opt := range opts { opt(s) }
    return s
}
```

## 4. 并发与上下文
- **Context 传递**: IO 和阻塞调用必须接受 `ctx context.Context`。
- **防死锁**: 检查 `defer mu.Unlock()` 的位置，确保锁范围最小化。
