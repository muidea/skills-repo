# 测试驱动重构模式

## 1. 表格驱动测试 (Table-Driven Tests)
重构散乱的测试用例，统一使用表格驱动模式，确保覆盖边界情况。

**标准模板：**
```go
func TestExample(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        wantErr bool
    }{
        {"valid input", "ok", false},
        {"empty input", "", true},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := Process(tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("Process() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}