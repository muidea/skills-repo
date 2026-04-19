---
name: magicbase-role-routing
description: "用于在 magicBase 中定义和管理普通路由、CAS 认证路由、RoleRouteRegistry 权限路由、Privilege 权限项、session 绑定和鉴权中间件；新增带权限 HTTP API、定义权限值、排查 401/403 或 register privilege failed 时使用。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.3
  author: "rangh-codespace"
---
# magicbase-role-routing

用于在 `magicBase` 中定义和管理普通路由、CAS 认证路由、RoleRouteRegistry 权限路由、Privilege 权限项、session 绑定和鉴权中间件。

## 适用场景

- 新增普通 HTTP 路由
- 新增只要求登录态的 CAS 路由
- 新增带权限的 HTTP 路由
- 定义路由对应的 `Privilege`
- 排查 `register privilege failed`
- 调整 `RoleRouteRegistry`
- 梳理权限、session、role 和 route 的绑定关系
- 排查 401/403、namespace、role、privilege 命中问题

## 重点文件

- [route.go](magicBase/pkg/toolkit/route.go)
- [cas.go](magicBase/pkg/toolkit/cas.go)
- [role.go](magicBase/pkg/toolkit/role.go)
- [util.go](magicBase/pkg/toolkit/util.go)
- [cas.go](magicBase/pkg/common/cas.go)
- [design-routing-auth.md](magicBase/docs/design-routing-auth.md)

## 路由类型选择

- 普通路由使用 `RouteRegistry.AddHandler` 或 `RouteRegistry.AddRoute`，只绑定 session 和 `extData`，不强制认证。
- 只需要认证身份的路由使用 `CasRouteRegistry.AddCasHandler` 或 `AddCasRoute`，中间件会绑定 session 并校验当前认证实体。
- 需要角色权限控制的路由使用 `RoleRouteRegistry.AddPrivilegeHandler` 或 `AddPrivilegeRoute`，中间件会绑定 session、解析请求 privilege、补全当前 role 并校验权限值。
- magicBase module 内部新增 service 路由时，先通过 initiator 获取 `RouteRegistryHelper`，再由 service 集中注册 route；模块生命周期和 route 装配问题同时参考 `magicbase-module-dev`。
- 底层 `:param`、`**`、API version 前缀和 middleware 顺序问题属于 magicEngine 路由层，参考 `magicengine-http-routing-middleware`。

## 权限项定义

- 权限项使用 `common.Privilege`：`Module` 表示所属模块，`UriPath` 表示实际参与匹配的 route pattern，`Value` 表示所需权限级别。
- 权限值使用 `common` 中的常量：`ReadPermission`、`WritePermission`、`DeletePermission`、`AllPermission`，不要在业务模块里硬编码裸数字。
- `RoleRouteRegistry` 会按当前 route pattern 和 privilege value 构造并同步 `Privilege`。
- `UriPath` 会受到 `NormalizeURI` 和 `routeRegistry.GetApiVersion()` 影响；排查不命中时同时检查原始 pattern、标准化 pattern 和 API version 后的实际 privilege URI。
- `verifyRole` 使用 role 中同 URI 的 privilege 或通配符 `*`，并要求 role 的 privilege value 大于等于当前 route 所需 value。
- `CurrentRequestPrivilege(ctx)` 可用于在下游逻辑读取当前请求命中的 privilege URI/value。

## 注册和失败语义

- 先注册 privilege，再注册 route
- 当前代码在 privilege 同步失败时会记录 `register privilege failed`，保留 route 和本地 privilege metadata；测试要求该 route 仍然存在。
- privilege 同步失败不能当成可忽略事件，因为上游权限数据可能缺失，后续鉴权可能无法按预期放行。
- 当前鉴权路径是 fail-closed：未认证返回 401，认证后 namespace、role 或 privilege 不满足返回 403。
- 当前实现不再用 panic 表达 routine 注册错误。
- 相关语义说明见 [design-routing-auth.md](magicBase/docs/design-routing-auth.md) 和 [design-http-entrypoints.md](magicBase/docs/design-http-entrypoints.md)

## 鉴权顺序

1. 解析或绑定当前 session。
2. 认证路由先校验当前 session 是否有有效 `AuthEntity`。
3. 权限路由先按请求路径匹配本地 privilege item。
4. 将命中的 privilege URI/value 写入 context。
5. 根据 namespace、session、当前 privilege 向上游 helper 补全当前 `AuthEntity` 和单个当前 `AuthRole`。
6. 短期 role 缓存必须同时命中 namespace、privilege URI 和 privilege value。
7. 使用 role 中的 privilege 列表校验当前路由所需权限。

## 401 和 403

- `401 Unauthorized` 表示无认证信息、认证信息失效，或认证实体校验失败。
- `403 Forbidden` 表示认证通过后 namespace、role 或 privilege 校验失败。
- 排查 401 时先看 session、CAS、token 和 `AuthEntity`。
- 排查 403 时先看 route pattern 是否命中、privilege URI/value 是否一致、role 是否包含该 privilege 或 `*`。

## 验证

优先跑受影响模块测试；如果改了公共权限基础设施，补一轮全量测试：

```bash
GOCACHE=/tmp/magicbase-gocache go test ./pkg/toolkit -count 1
GOCACHE=/tmp/magicbase-gocache go test ./... -count 1
```
