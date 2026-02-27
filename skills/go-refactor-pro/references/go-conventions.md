# Go 现代重构规范 (2025 更新)

## 1. 现代特性应用 (Go 1.18 - 1.24)
- **结构化日志**: 全面迁移至 `log/slog`。
- **错误聚合**: 使用 `errors.Join(err1, err2)` 替代自定义的错误拼接。
- **循环安全**: 充分利用 Go 1.22+ 循环变量独立作用域特性。
- **泛型应用**: 仅针对 Slice/Map 转换等纯工具逻辑应用泛型，业务逻辑保持具体。

## 2. 警惕过度工程化
- **YAGNI (You Ain't Gonna Need It)**: 不要为只有一个实现的结构体预定义接口。
- **优先组合**: 使用结构体嵌入而非模拟继承。
- **可读性权重**: 若抽象化重构显著降低了代码直观性，应回滚至简单版本。

## 3. 构造函数模版 (Functional Options)
```go
type Server struct { port int }
type Option func(*Server)
func WithPort(p int) Option { return func(s *Server) { s.port = p } }
func NewServer(opts ...Option) *Server {
    s := &Server{port: 8080} // 默认值
    for _, opt := range opts { opt(s) }
    return s
}
```