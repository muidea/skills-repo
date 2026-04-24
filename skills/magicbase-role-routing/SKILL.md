---
name: magicbase-role-routing
description: "用于在 magicBase 中定义和管理普通路由、CAS 认证路由、RoleRouteRegistry 权限路由、Privilege 权限项、session 绑定和鉴权中间件；新增带权限 HTTP API、定义权限值、排查 401/403 或 register privilege failed 时使用。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.5
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

## 路由定义准确性

- `pkg/common` 里的常量如果会被 event hub、模块间命令或业务命令复用，应优先定义为稳定业务命令名，而不是只按前端最终 REST URL 命名。
- 标准 CRUD 命令常量使用 `filter/query/insert/update/delete`，例如 `/module/entity/filter/`、`/module/entity/query/:id`；这些值可同时作为 event hub command 和 route registration input。
- `AddHandler`、`AddCasHandler`、`AddPrivilegeHandler` 都会先调用 `NormalizeURI`，标准 CRUD 命令会在注册路由时转换成最终 REST 路径：
- `/module/entity/filter/` 实际注册为 `/module/entitys/`。
- `/module/entity/query/:id` 实际注册为 `/module/entitys/:id`。
- `/module/entity/insert/` 实际注册为 `/module/entitys/`。
- `/module/entity/update/:id` 实际注册为 `/module/entitys/:id`。
- `/module/entity/delete/:id` 实际注册为 `/module/entitys/:id`。
- 前端、API 文档和浏览器排查使用最终 REST 路径；后端 common、event hub、注册路由测试应保留并核对原始命令路径。
- 新增自定义 API 时，避免把路径命名成 `*/filter/`、`*/query/:id`、`*/insert/`、`*/update/:id`、`*/delete/:id`，除非明确就是标准 CRUD 命令并接受 `NormalizeURI` 转换。
- 如果业务期望路径是 `/portal/access-logs/` 且不是标准 CRUD/event command，常量就直接定义为 `/portal/access-logs/`，不要定义成 `/portal/access-log/filter/` 再依赖隐式改写。
- `bc.ApiVersion` 会在注册时作为版本前缀参与实际匹配；浏览器实际请求通常是 `/api/v1/...`。
- 注意 magicRunner 业务 module 存在额外约束：当 module 明确接管 runtime object 或 entity CRUD 时，代码内注册应使用 canonical action route，让 `NormalizeURI` 归一化为最终 REST 路径；这类场景优先同时使用 `magicrunner-runtime-routing`。
- 对动态 entity CRUD，不要直接设计多个动态 path 参数的自定义路径，例如 `/:app/entities/:entity/:id`。应先判断是否属于框架标准 CRUD；如果属于，使用稳定资源路径加显式 selector 参数，并避免 selector 参数进入业务 `ContentFilter`。

## 新增路由自检

- 先判断该接口是标准 CRUD 还是自定义 API。
- 标准 CRUD：common 注册常量使用 `filter/query/insert/update/delete` 命令路径；对外文档和前端使用归一化后的 REST 路径。
- 自定义 API：common 常量直接使用最终业务路径，避免误触发 `NormalizeURI` 的操作词。
- 写出 route contract：业务命令常量、是否用于 event hub、归一化路径、`bc.ApiVersion` 后路径、HTTP method、CAS/Role/Plain 类型、权限值、前端调用路径。
- 标准 CRUD 至少补一个 `NormalizeURI` 断言测试，防止把 common 命令常量误改成前端 REST 路径。
- 至少补一个 route dispatch test 通过 `/api/v1/...` 实际路径请求 registry；direct handler test 不足以证明路由注册正确。

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

## 404 排查

- 先看服务启动日志中的 `addRoute apiVersion=... pattern=... method=...`，确认实际注册路径，而不是只看代码里的原始常量。
- 对照浏览器请求完整路径：`/api/v1` 前缀、标准化后的 pattern、HTTP method 必须同时匹配。
- 如果代码常量包含 `filter/query/insert/update/delete`，优先检查是否被 `NormalizeURI` 改写为复数资源路径。
- 如果浏览器 404 但 common 常量是命令式路径，不要把 common 直接改成浏览器路径；先确认注册日志、`NormalizeURI` 输出和前端 REST 路径是否匹配。
- 如果浏览器路径包含多个动态业务段，先确认它不是误把标准 CRUD 做成了自定义路径；magicRunner 中这类问题按 `magicrunner-runtime-routing` 的 repair workflow 修复。
- 补一个真实 route dispatch 测试，用 `engine.NewResponseWriter(rec)` 包装 `httptest.ResponseRecorder`，通过 registry 请求 `/api/v1/...`，验证不会返回 404。
- handler direct test 只能验证 handler 逻辑，不能证明 API version、NormalizeURI 和路由注册后的真实路径可访问。

## 验证

优先跑受影响模块测试；如果改了公共权限基础设施，补一轮全量测试：

```bash
GOCACHE=/tmp/magicbase-gocache go test ./pkg/toolkit -count 1
GOCACHE=/tmp/magicbase-gocache go test ./... -count 1
```
