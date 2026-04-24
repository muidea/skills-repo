---
name: magicrunner-service-gateway-auth
description: Use when implementing, reviewing, or diagnosing magicRunner service gateway access, portal or panel service debugging, endpoint Sig token authorization, ServicePublication or ServiceSubscription access checks, and entity capability forwarding through gateway. Covers the boundary between gateway authorization, CAS sessions, subscription credentials, and magicBase public-value execution; use magicrunner-service-governance for the broader service definition, capability, publication, subscription, and credential governance chain.
compatibility: Designed for agents working on magicRunner, magicCas, magicBase, and magicWebPortal service-access flows. Assumes local repository access and, when debugging runtime issues, access to docker logs or database access logs.
metadata:
  author: rangh-codespace
  domain: magicrunner
  scenario: service-gateway-auth
  maturity: stable
version: 1.0.4
---

# MagicRunner Service Gateway Auth

Use this skill when the task involves `/api/v1/gateway/services/*`, portal or panel "进入服务" debugging, endpoint `Authorization: Sig <token>`, service subscriptions, or entity capabilities exposed as services.

If the task is about how `EntityDefinition.serviceExpose` becomes `CapabilityDefinition`, how capabilities are aggregated into `ServiceDefinition`, or how publication/subscription/credentials are managed before gateway access, use `magicrunner-service-governance` first.

## Key Files

- [main.go](magicRunner/application/magicGateway/cmd/main.go)
- [module.go](magicRunner/internal/modules/kernel/gateway/module.go)
- [biz.go](magicRunner/internal/modules/kernel/gateway/biz/biz.go)
- [service.go](magicRunner/internal/modules/kernel/gateway/service/service.go)
- [common.go](magicRunner/internal/modules/kernel/gateway/pkg/common/common.go)
- [metadata.go](magicRunner/internal/pkg/servicedebug/metadata.go)
- [design-http-entrypoints.md](magicRunner/docs/design-http-entrypoints.md)

## Core Boundary

- `kernel/gateway` is the external service access authorization boundary.
- Gateway routes should bind a valid login session or endpoint session subject through CAS session handlers, but should not be registered as privilege-gated business menu routes.
- Real service access authorization belongs in gateway business logic: publication state, subscription state, endpoint credential scope, allowed role scope, quota, and rate limit.
- Panel service debugging uses the current login user's management authority and must not depend on the service being subscribed by that user.
- Portal service debugging uses the current user's approved subscription and its bound endpoint/auth token.
- Entity capabilities must not be forwarded to application runtime CRUD routes after gateway authorization, because application runtime CRUD routes can re-run CAS role checks and reject valid endpoint calls.

## Entity Capability Execution Rule

For `CapabilityDefinition.SourceType == "entity"`:

- Resolve the target to `magicBase /api/v1/public/value/{pkgPath}/{entity}/{operation}`.
- Do not use the generated application runtime CRUD URL as the gateway target.
- Forward context headers needed by magicBase:
  - `Application`: capability application UUID
  - `Namespace`: request/auth namespace
  - `EntityExtData`: encoded caller context from the gateway request context
- Use the fixed operation mapping:
  - `query -> filter`
  - `get -> query`
  - `create -> insert`
  - `update -> update`
  - `delete -> delete`
- For external or non-entity capabilities, keep using `CapabilityDefinition.address`.

Important implementation detail: do not use `toolkit.NormalizeURI()` to build `/public/value/.../{operation}` targets. `NormalizeURI()` is for runtime CRUD route normalization and can rewrite or strip operation segments unexpectedly. Build the public-value path directly.

## Diagnosis Workflow

1. Confirm which layer returns the error.
2. Check `magicgateway` logs for request receipt, route registration, and gateway error body.
3. Check gateway access logs, especially `serviceKey`, `serviceID`, `subscriberID`, `publicationID`, `target`, `status`, and result/detail fields.
4. If gateway access log shows a resolved `target` and `result=ok` but the HTTP status is `403`, inspect the downstream service logs.
5. If downstream logs show role verification failures for an endpoint subject, treat it as a boundary leak: gateway likely forwarded to an application runtime CRUD route instead of `magicBase /public/value`.
6. Fix target resolution and context forwarding before changing role definitions or subscription data.

## Common Failure Patterns

- `Authorization: Sig <token>` reaches gateway but downstream application returns `403` with `verify role failed`.
- Gateway target points to `http://{app}:8080/api/v1/{pkgPath}/{entities}/...` for an entity capability.
- Frontend reports "当前未查询到访问凭证" on panel debug even though panel debug should use login-session authority.
- Portal debug uses a raw user JWT or manually regenerated token instead of the subscription-bound auth token.
- Route is added through a role-privilege registrar, causing portal-only users to fail before service authorization runs.

## Implementation Checklist

- Gateway route registration uses session/auth binding only for `/gateway/services/*`; avoid role privilege route registration for this path family.
- Route parsing resolves service access by `ServiceDefinition.key`; numeric internal IDs are only used after key lookup and for access logs or data joins.
- Single-bound services route directly to the resolved capability target.
- Multi-bound services dispatch by path first segment matching `CapabilityDefinition.key`.
- Entity capability target resolution covers all CRUD operations, not just `query` and `get`.
- External capability target resolution remains provider-address based.
- Gateway forwarding preserves method, body, and query string while adding only required internal context headers for entity capabilities.
- Tests cover both target URL resolution and forwarded headers.

## Validation

Use targeted gateway tests first:

```bash
# Run from the magicRunner project root.
GOCACHE=/tmp/go-build GOMODCACHE=/tmp/go-mod-cache go test ./internal/modules/kernel/gateway/... --count=1
```

Then run the full runner suite when the change can affect shared models or docs:

```bash
# Run from the magicRunner project root.
GOCACHE=/tmp/go-build GOMODCACHE=/tmp/go-mod-cache go test ./... --count=1
```

For runtime verification, retry the portal subscription debug request and confirm downstream application logs no longer show role verification failures for `/api/v1/{pkgPath}/{entities}/...`.
