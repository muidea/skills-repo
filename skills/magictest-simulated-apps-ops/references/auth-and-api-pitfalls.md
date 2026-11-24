# 认证与接口排障清单

在通过 HTTP/HTTPS 对 `magicPlatform` 进行自动化接入时，必须遵守以下已实证的接口行为约束：

1. **Web BFF 代理校验 `Origin` 头**：
   - 所有发往 `/api/v1/web/proxy/...` 的请求必须携带与当前会话 `RedirectURI` 同源的 `Origin: https://panel.<domain>` 头，否则返回 `cd.InvalidAuthority`（`request origin does not match the application session`）。
2. **`GET /oauth/login?transaction=...` 正常返回 HTTP `401` JSON**：
   - 带 `Accept: application/json` 访问时，HTTP 状态码 `401` 但响应体包含合法 JSON `{"interaction":"login","transaction":...,"csrfToken":...}` 且伴随 `Set-Cookie`；不可将 `401` 视作失败，需提取 `csrfToken` 后以 `application/x-www-form-urlencoded` 提交 `POST /oauth/login`。
3. **`POST /api/v1/cas/oauth/token` 禁止携带 Cookie**：
   - 用授权码或刷新令牌换取 Token 时若附带浏览器 SSO/BFF Cookie，CAS 会直接拒绝；必须使用独立无 Cookie 请求器。
4. **PKCE S256 与 `nonce` 必填**：
   - `/api/v1/cas/oauth/authorize` 必须包含 `code_challenge_method=S256`、`code_challenge`、`nonce`，且请求 `scope` 不可超出客户端 `allowedScopes`。
5. **`authority/preview` 必须传 `accountId`**：
   - `POST /cas/namespaces/:ns/endpoints/:id/authority/preview` 请求体必须显式传递关联账号的 `accountId`。
6. **16 KiB Action Token 体积上限与最小权限账号**：
   - `chess-room-booking` 的 `simulation_tool.py` 拒绝大于 `16384` 字节的 Bearer Token；`platform-admin` JWT 约 31.5 KiB，会触发体积超限，应为模拟操作创建专用最小权限账号（如 `crb-sim-operator`）。
7. **`simulator.py` 与公网 CA**：
   - `simulator.py init` 默认回退到本机 `tls.crt` 叶证书模式；对接公网证书时需显式指定系统 CA 路径（如 `/etc/ssl/certs/ca-certificates.crt` 或 `/etc/pki/tls/certs/ca-bundle.crt`）并附加 `--ca-is-root`。
