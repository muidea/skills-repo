---
name: magiccommon-session-auth
description: 用于基于 magicCommon session 处理业务认证与会话，包括 JWT、Endpoint 签名、Cookie Token、Session Registry、上下文读写和会话超时。编写登录态、鉴权中间件或会话透传逻辑时使用。
version: 1.0.0
---

# magicCommon Session Auth

这个 skill 用于业务认证和会话接入。

## 1. 先读这些文件

- `session/registry.go`
- `session/session.go`
- `session/jwt.go`
- `session/endpoint.go`
- `session/helper.go`

## 2. 能力选择

- 浏览器 Cookie 会话：用 `ReadSessionTokenFromCookie` / `WriteSessionTokenToCookie`
- JWT 场景：用 `SignatureJWT`
- 内部 endpoint 签名透传：用 `EncryptEndpoint` + `SignatureEndpoint`

## 3. 业务接入建议

- 外部用户登录态优先用 JWT 或 Cookie Token
- 内部服务透传上下文优先用 Endpoint 签名
- 会话上下文里只放必要字段，不要塞业务大对象
- 超时策略统一走环境变量 `SESSION_TIMEOUT_VALUE`

## 4. 风险点

- `session` 更像轻量会话容器，不是完整 IAM 框架。
- 自定义 context 字段要避免和内置 key 冲突。
- endpoint context 里要保证可 JSON 序列化。
- 安全敏感字段不要直接裸放进 header/query。

## 5. 推荐验证

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor \
go test ./session -count 1
```
