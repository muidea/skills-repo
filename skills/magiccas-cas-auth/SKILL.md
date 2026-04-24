---
name: magiccas-cas-auth
description: "用于处理 `magicCas` 的登录、刷新、JWT / endpoint 会话、命名空间校验、账号/端点角色绑定演进、注册准入治理，以及 `kernel/cas` / `kernel/registration` 与 `account` / `role` / `namespace` / `endpoint` 授权链路的联动逻辑。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.6
  author: "rangh-codespace"
---
# magiccas-cas-auth

用于处理 `magicCas` 的登录、刷新、JWT / endpoint 会话、命名空间校验、注册准入治理，以及 `kernel/cas` / `kernel/registration` 与 `account` / `role` / `namespace` / `endpoint` 授权链路的联动逻辑。

## 适用场景

- 修改 `kernel/cas/biz` 或 `kernel/cas/service`
- 修改 `kernel/registration`、用户注册、注册策略、注册模板、注册申请审核或默认 role 绑定
- 修改 `blocks/endpoint`、`blocks/account`、`blocks/role`、`blocks/namespace` 中与授权链路直接相关的逻辑
- 排查登录、登出、刷新、账号校验
- 调整 session 上下文、JWT、endpoint token 或 namespace 鉴权
- 调整 registration 与 account / role / namespace 之间的 event、DAO 或服务边界
- 核对 `Endpoint` / token / `AuthSecret` / `Scope` 的语义是否符合当前业务基线
- 为 CAS 入口补 direct test

## 重点文件

- `../docs/design-cas-auth.md`
- `../docs/design-user-registration-role-template.md`
- `docs/design-role-binding-evolution.md`
- `internal/modules/kernel/cas/module.go`
- `internal/modules/kernel/cas/service/cas.go`
- `internal/modules/kernel/cas/service/base.go`
- `internal/modules/kernel/registration/module.go`
- `internal/modules/kernel/registration/biz/registration.go`
- `internal/modules/kernel/registration/service/registration.go`
- `internal/modules/kernel/registration/dao/dao.go`
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

## Registration 归属规则

1. 注册准入是 CAS 治理流程，归属 `internal/modules/kernel/registration`，与 `kernel/cas` 同层
2. `RegistrationProfile`、`RegistrationPolicy`、`AccountRegistration` 是注册策略、模板和申请记录，不属于 `blocks/account`
3. 不新增 `blocks/registration` 来承载注册流程；block 只承载 `account`、`role`、`namespace`、`endpoint` 等基础资源能力
4. `account` 模块只负责账号创建、密码 hash、角色绑定、实体同步和账号生命周期，不直接承载注册策略或审核流程
5. `registration` 创建或启用账号时必须通过 `account` 模块暴露的事件或服务接口，不直接写 `account` DAO
6. 注册过程不保存明文密码、可逆密码或外部生成的 password hash；password hash 只能由 `account` 模块在创建或修改账号时生成
7. 注册 namespace、profile、role、privilege 必须从后端策略和请求上下文解析，不允许客户端指定
8. 如果默认模板中的 role 被停用，应跳过该 role；模板最终没有任何启用 role 时注册应失败，避免创建无法完成有效授权的账号
9. 内置模板全局共享，namespace 可定制覆盖，最终执行以 namespace 定制策略为准
10. 审核开关由后端策略控制，不允许前端绕过
11. 需要审核的注册提交时应创建禁用账号，审核通过时启用账号，审核拒绝时清理禁用账号，避免为了延迟创建账号而持久化密码或 hash

## Registration 路由与命令契约

1. `pkg/common/registration.go` 里的管理类 CRUD 常量首先是业务命令定义，可被 event hub 和模块间命令复用，不能只按浏览器最终 REST URL 命名。
2. `RegistrationProfile`、`RegistrationPolicy`、`AccountRegistration` 的管理类 common 常量应保持 `filter/query/insert/update/delete` 命令式路径，例如 `/registration/profile/filter/`、`/registration/profile/query/:id`。
3. `RoleRouteRegistry.AddPrivilegeHandler` 在注册时会调用 `magicBase/pkg/toolkit.NormalizeURI`，把命令式路径转换成前端实际访问的 REST 路径，例如 `/registration/profile/filter/` 转为 `/registration/profiles/`。
4. 前端 service、浏览器 Network、API 验收使用转换后的 REST 路径；后端 common、event hub、权限注册、route registration test 使用原始命令路径。
5. 排查 registration 404 时，不要直接把 common 常量改成前端 REST 路径；应先核对 `NormalizeURI` 输出、服务 `addRoute` 日志、前端请求路径和 HTTP method。
6. `policy` 转换后的默认 REST 路径当前由框架生成 `/registration/policys/`，不要单独在业务侧绕过生成规则改成另一套路径，除非同步调整框架转换规则和全部调用方。
7. `public`、`submit`、`approve`、`reject` 是领域动作，不属于标准 CRUD，可保留动作路径，不要求经过 CRUD 归一化。
8. 修改 registration 路由时，必须补充或更新测试覆盖：原始 common 命令注册、`NormalizeURI` 后的 REST 路径、前端调用路径三者一致。

## 核对重点

1. 登录链路写入 session 的 `AuthScope` 是否符合当前语义
2. endpoint token 生成、刷新、校验时写入和读取的 scope 是否一致
3. `VerifySessionEntity` / `VerifySessionEntityRole` 是否始终回溯到明确的 `Endpoint` 或 `Account`
4. `Account`、`Endpoint`、`Role` 缺失时是否返回明确错误，而不是隐式回填或 panic
5. namespace 管理权限是否按 `Namespace.Scope` 设计实现，而不是写死到单一默认 namespace
6. direct test 是否覆盖无效 JSON、缺少上下文、无效 role/account/endpoint、scope 混用等路径
7. registration 路由是否只由 `kernel/registration` 注册，没有残留在 `blocks/account`
8. account DAO / service 中是否没有残留 registration profile、policy、申请审核等治理逻辑
9. registration 与 account 之间是否通过事件或服务接口协作，避免绕过 account 账号创建规则
10. registration common 常量是否保持命令式路径，且路由注册层是否通过 `NormalizeURI` 映射到前端 REST 路径

## 验证

```bash
GOCACHE=/tmp/magiccas-gocache go test ./internal/modules/kernel/cas/... -count 1
GOCACHE=/tmp/magiccas-gocache go test ./internal/modules/kernel/registration/... -count 1
GOCACHE=/tmp/magiccas-gocache go test ./internal/modules/blocks/endpoint/... -count 1
GOCACHE=/tmp/magiccas-gocache go test ./internal/modules/blocks/account/... -count 1
GOCACHE=/tmp/magiccas-gocache go test ./internal/modules/blocks/namespace/... -count 1
GOCACHE=/tmp/magiccas-gocache go test ./internal/modules/kernel/cas/service -count 1
```
