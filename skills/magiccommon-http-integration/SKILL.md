---
name: magiccommon-http-integration
description: 用于基于 magicCommon foundation/net 处理业务 HTTP 集成，包括 JSON 请求、文件上传下载、URL 处理、DNS cache client 和邮件相关辅助能力。编写外部 HTTP/文件交互逻辑时使用。
version: 1.0.0
---

# magicCommon HTTP Integration

这个 skill 用于业务 HTTP 集成和网络 helper 使用。

## 1. 先读这些文件

- `foundation/net/README.md`
- `foundation/net/http.go`
- `foundation/net/httpClient.go`
- `foundation/net/form.go`
- `foundation/net/url.go`
- `foundation/net/mail.go`

## 2. 典型任务

- 发起 HTTP 请求
- 解析 JSON body
- 处理文件上传下载
- 使用 DNS cache client
- 处理 URL 和状态码

## 3. 处理规则

- 优先复用 `foundation/net` 的 helper，不要重复造 HTTP 小工具。
- 新建 DNS cache client 时，不要污染全局 `http.DefaultTransport`。
- 文件上传下载逻辑要先区分：
  - 只是 helper 层
  - 还是业务协议层

## 4. 风险点

- 网络超时、DNS、受限环境失败要和业务错误区分开。
- 邮件相关 helper 更偏工具，不要误当完整通知系统。

## 5. 推荐验证

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor \
go test ./foundation/net -count 1
```
