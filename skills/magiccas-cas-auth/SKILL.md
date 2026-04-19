---
name: magiccas-cas-auth
description: "用于处理 `magicCas` 的登录、刷新、JWT / endpoint 会话、命名空间校验、账号/端点角色绑定演进，以及 `kernel/cas` 与 `account` / `role` / `namespace` / `endpoint` 授权链路的联动逻辑。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.2
  author: "rangh-codespace"
---
# magiccas-cas-auth

用于处理 `magicCas` 的登录、刷新、JWT / endpoint 会话、命名空间校验，以及 `kernel/cas` 与 `account` / `role` / `namespace` / `endpoint` 授权链路的联动逻辑。

## 适用场景

- 修改 `kernel/cas/biz` 或 `kernel/cas/service`
- 修改 `blocks/endpoint`、`blocks/account`、`blocks/role`、`blocks/namespace` 中与授权链路直接相关的逻辑
- 排查登录、登出、刷新、账号校验
- 调整 session 上下文、JWT、endpoint token 或 namespace 鉴权
- 核对 `Endpoint` / token / `AuthSecret` / `Scope` 的语义是否符合当前业务基线
- 为 CAS 入口补 direct test

## 重点文件

- `../docs/design-cas-auth.md`
- `docs/design-role-binding-evolution.md`
- `internal/modules/kernel/cas/module.go`
- `internal/modules/kernel/cas/service/cas.go`
- `internal/modules/kernel/cas/service/base.go`
- `internal/modules/blocks/endpoint/biz/endpoint.go`
- `internal/modules/blocks/account/biz/account.go`
- `internal/modules/kernel/cas/biz/role.go`
- `internal/modules/kernel/cas/biz/namespace.go`
- `internal/modules/kernel/cas/biz/scope.go`
- `internal/modules/kernel/cas/service/handler_test.go`

## 工作方式

1. 先确认问题在 HTTP handler、event bridge 还是 biz
2. 先以 `../docs/design-cas-auth.md` 和 `docs/design-role-binding-evolution.md` 的当前语义为准，不以历史实现习惯为准
3. 对明显参数错误返回 `IllegalParam`
4. 对缺少会话上下文或无效授权主体的路径，返回明确错误，不允许 panic
5. 保持 `refreshSession` 的 `401` 协议语义

## 必查语义

1. `Endpoint` 是显式访问授权对象，不是 token 的附属信息
2. token / `AuthSecret` 只是 `Endpoint` 的凭证表现形式，不能被当成独立授权主体
3. `Endpoint` 必须绑定有效 `Account`
4. `Endpoint` 必须绑定 `Role`
5. 运行态授权必须从 token 回溯到 `Endpoint`，再解析账号、role 与 `Endpoint.Scope`
6. `Namespace.Scope` 是 namespace 管理范围
7. `Endpoint.Scope` 是运行态数据访问范围
8. `Namespace.Scope` 与 `Endpoint.Scope` 不能混用
9. `magicCas` 不拥有 `Subscription` 这样的业务开通对象，只负责 `Endpoint/AuthSecret` 授权基础能力

## 核对重点

1. 登录链路写入 session 的 `AuthScope` 是否符合当前语义
2. endpoint token 生成、刷新、校验时写入和读取的 scope 是否一致
3. `VerifySessionEntity` / `VerifySessionEntityRole` 是否始终回溯到明确的 `Endpoint` 或 `Account`
4. `Account`、`Endpoint`、`Role` 缺失时是否返回明确错误，而不是隐式回填或 panic
5. namespace 管理权限是否按 `Namespace.Scope` 设计实现，而不是写死到单一默认 namespace
6. direct test 是否覆盖无效 JSON、缺少上下文、无效 role/account/endpoint、scope 混用等路径

## 验证

```bash
GOCACHE=/tmp/magiccas-gocache go test ./internal/modules/kernel/cas/... -count 1
GOCACHE=/tmp/magiccas-gocache go test ./internal/modules/blocks/endpoint/... -count 1
GOCACHE=/tmp/magiccas-gocache go test ./internal/modules/blocks/account/... -count 1
GOCACHE=/tmp/magiccas-gocache go test ./internal/modules/blocks/namespace/... -count 1
GOCACHE=/tmp/magiccas-gocache go test ./internal/modules/kernel/cas/service -count 1
```
