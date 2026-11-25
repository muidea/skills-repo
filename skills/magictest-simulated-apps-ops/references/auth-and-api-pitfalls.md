# 认证与接口排障清单

在通过 HTTP/HTTPS 对 `magicPlatform` 进行自动化接入时，必须遵守以下已实证的接口行为约束：

1. **Web BFF 代理校验 `Origin` 头**：
   - 所有发往 `/api/v1/web/proxy/...` 的请求必须携带与当前会话 `RedirectURI` 同源的 `Origin: https://panel.<domain>` 头，否则返回 `cd.InvalidAuthority`（`request origin does not match the application session`）。
2. **CAS 登录跳转、`GET /oauth/login` HTTP `401` JSON 与 `remember` 参数**：
   - `/api/v1/web/auth/login` 与 `/api/v1/cas/oauth/authorize` 可能先 302 跳转 WebPortal SPA `/login/cas?namespace=...&transaction=...`；客户端须提取 `transaction` 后以 `Accept: application/json` 请求 `GET /oauth/login?transaction=...` 获取 JSON `{"interaction":"login","transaction":...,"csrfToken":...}` 及 `Set-Cookie`（HTTP `401` 为正常交互状态，不可误判失败）。
   - `POST /oauth/login` 禁止传 `remember=false`（CAS 仅在记住登录时接受 `remember=true`，否则返回 HTTP `400 invalid_request: remember must be true when supplied`）。
   - 若管理员账号已完成交互改密，原引导文件 `services/secret/cas/bootstrap-admin-password` 已失效，继续提交会返回 `401 invalid account or password`；应向管理员核对当前密码。
3. **`POST /api/v1/cas/oauth/token` 禁止携带 Cookie**：
   - 用授权码或刷新令牌换取 Token 时若附带浏览器 SSO/BFF Cookie，CAS 会直接拒绝；必须使用独立无 Cookie 请求器。
4. **PKCE S256 与 `nonce` 必填**：
   - `/api/v1/cas/oauth/authorize` 必须包含 `code_challenge_method=S256`、`code_challenge`、`nonce`，且请求 `scope` 不可超出客户端 `allowedScopes`。
5. **`authority/preview` 必须传 `accountId`**：
   - `POST /cas/namespaces/:ns/endpoints/:id/authority/preview` 请求体必须显式传递关联账号的 `accountId`。
6. **16 KiB Action Token 体积上限与最小权限账号**：
   - `chess-room-booking` 的 `simulation_tool.py` 拒绝大于 `16384` 字节的 Bearer Token；`platform-admin` JWT 约 31.5 KiB，会触发体积超限，应为模拟操作创建专用最小权限账号（如 `crb-sim-operator`）。
7. **`simulator.py` 目录前置条件与公网/根 CA 参数**：
   - `simulator.py init` 强校验 `--run-dir` 目录尚不存在（否则报 `run directory already exists; use its config to resume` 并退出）；调用前只可预建父目录 `runs/`，应由 `simulator.py init` 自行创建目标 `0700` 目录。
   - `simulator.py init` 默认回退到本机 `tls.crt` 叶证书模式；对接公网证书或目标机导出的根 `ca.crt` 时，需传 `--ca-file <path> --ca-is-root`。
8. **新建动作操作员 PKCE 首次改密、Consent 与 `Origin` 头**：
   - 新建 `crb-sim-operator` 首次 PKCE 授权会进入 `interaction: "password_change"`，需携带 `Origin: https://panel.<domain>` 提交 `POST /oauth/password/change` 并将轮换后的新密码原子回写到 `0600` 密码文件，随后再经 `GET/POST /oauth/consent`（批准第三方 `public` PKCE 客户端）完成授权码换取。
9. **`crb-sim-pkce-client` 必需包含执行 Scope**：
   - `crb-sim-pkce-client` 的 `allowedScopes` 与 `/oauth/authorize` 的 `scope` 必须包含 `magicrunner.usage.apps.data.execute`（`audience: api://magicrunner`），仅持 `openid profile` 无法调用 `/api/v1/apps/entity/action/execute/`。
10. **模型包摘要字段名为 `artifactDigest`**：
    - `POST /panel/application/model-packages/imports/` 与 `GET /panel/application/model-packages/` 返回的主摘要字段为 `artifactDigest`（非 `digest` 或 `sourceDigest`）；调用 `GET /panel/application/installations/storage-options/?applicationUuid=...&sourceDigest=...` 与创建部署请求时 `expectedDigest` 均须传入 `artifactDigest`。
11. **应用就绪后的服务收敛、发布与 Portal 订阅匹配**：
    - 应用安装 `ready` 后仅注册源能力（`/panel/hub/capabilitys/`）；需调用 `POST /panel/hub/services/generated/converge/`（按 `runtimeApplicationUuid` 筛选 `providerType == "application"` 的已启用能力）收敛生成服务与草稿发布，再调 `PUT /panel/hub/publication/publish/:id` 发布，服务才会出现在 `GET /portal/services/`。
    - `PortalServiceView` 仅以 `id` 与 `leaseTerm.status` 识别订阅状态（不含 `key`/`hostedBy`）；创建 `POST /portal/service/subscriptions/` 需传正数租期 `leaseTerm: 1`（而非 `0`）。
12. **CAS Endpoint 与所属账号角色模板装配**：
    - 在 Portal 创建服务凭证获得 API Key 后，必须给生成的 CAS Endpoint 绑定安装自带的 `endpoint` 角色模板（如 `app-<deploymentId>-collector` / `app-<deploymentId>-channel-ingestor`），且在此之前需确保该 Endpoint 所属账号已具备所需角色上界（不足时保留原有 `templateRefs`/`applicationScopes` 追加对应 `account` 模板），否则 Gateway 调用被当前角色拒绝。
13. **跨服务器 `--target-address` 与 SNI 隔离**：
    - 在本机存在 `127.0.0.1 panel.local.vpc` 解析干扰时，不要修改本机 `/etc/hosts`；统一使用 `--target-address <目标IP>` / `MAGICTEST_TARGET_ADDRESS=<目标IP>`，保留 `Host` 与 TLS SNI 连接远端。
