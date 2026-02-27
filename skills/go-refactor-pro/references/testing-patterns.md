# Go 重构测试模式

## 1. 表格驱动测试 (Table-Driven Tests)
重构后的代码必须通过表格驱动测试验证其稳健性。

```go
func TestExample(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    int
        wantErr bool
    }{
        {"success", "valid-data", 200, false},
        {"empty-input", "", 0, true},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := MyFunc(tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("error = %v, wantErr %v", err, tt.wantErr)
                return
            }
            if got != tt.want {
                t.Errorf("got = %v, want %v", got, tt.want)
            }
        })
    }
}
```