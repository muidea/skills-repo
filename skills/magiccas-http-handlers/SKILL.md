---
name: magiccas-http-handlers
description: "用于处理 `magicCas` 的 HTTP handler、请求体解析、REST ID 解析和返回语义；登录、刷新、JWT、endpoint token 或角色授权链路优先使用 magiccas-cas-auth。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.2
  author: "rangh-codespace"
---
# magiccas-http-handlers

用于处理 `magicCas` 的 HTTP handler、请求体解析、REST ID 解析和返回语义。

## 适用场景

- 修 handler 的参数校验
- 统一 `IllegalParam` / `InvalidAuthority` / `401`
- 补 `httptest` 级 direct test
- 排查 handler panic 或错误码不一致

## 重点文件

- `../docs/design-cas-auth.md`
- `docs/design-modules.md`
- `docs/testing-guide.md`
- `internal/modules/**/service/*.go`

## 工作方式

1. 对无效 JSON、无效 REST ID 这类输入优先返回 `IllegalParam`
2. 会话或权限缺失按鉴权失败处理，不允许 panic
3. 优先补 direct test，而不是只依赖集成验证
4. 保持当前已存在的特殊协议语义，例如 `refreshSession` 的 `401`

## 验证

```bash
GOCACHE=/tmp/magiccas-gocache go test ./internal/modules/.../service -count 1
```
