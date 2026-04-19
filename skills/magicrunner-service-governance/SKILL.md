---
name: magicrunner-service-governance
description: 用于处理 magicRunner 的服务治理主链，覆盖 EntityDefinition.serviceExpose、CapabilityDefinition 自动生成、ServiceDefinition 服务项、ServiceCapabilityBinding 聚合、ServicePublication 发布治理、ServiceSubscription 订阅、SubscriptionCredential 凭据、portal/panel 进入服务语义和 gateway 访问边界；排查能力项、服务项、发布、订阅、凭据或服务调试链路时使用。
compatibility: Compatible with open_code
metadata:
  version: 1.0.1
  author: "rangh-codespace"
  created_at: "2026-04-18T22:48:00+08:00"
---

# magicRunner Service Governance

Use this skill when working on the service governance chain in `magicRunner`: from application entity exposure to capability generation, service aggregation, publication, subscription, credentials, and gateway access.

## Scope

- Use this for service governance object semantics and cross-module troubleshooting.
- Use `magicrunner-service-gateway-auth` when the problem is specifically gateway authorization or downstream forwarding.
- Use `magicrunner-panel-service` or `magicrunner-portal-service` for handler-level parameter and session behavior.
- Use `magicrunner-native-crud-toolkit` when deciding whether a native model CRUD route belongs to panel/portal or runner fallback.
- Use `magicbase-data-capability-definition` when the source issue is magicBase `Entity.serviceExpose` or entity field definitions.

## Read First

- [docs/design-application-service-governance.md](magicRunner/docs/design-application-service-governance.md)
- [docs/design-entity-service-exposure.md](magicRunner/docs/design-entity-service-exposure.md)
- [docs/design-business-models.md](magicRunner/docs/design-business-models.md)
- [docs/design-http-entrypoints.md](magicRunner/docs/design-http-entrypoints.md)
- [internal/modules/kernel/panel/biz/capability/capability.go](magicRunner/internal/modules/kernel/panel/biz/capability/capability.go)
- [internal/modules/kernel/panel/biz/service/service.go](magicRunner/internal/modules/kernel/panel/biz/service/service.go)
- [internal/modules/kernel/panel/biz/binding/binding.go](magicRunner/internal/modules/kernel/panel/biz/binding/binding.go)
- [internal/modules/kernel/panel/biz/publication/publication.go](magicRunner/internal/modules/kernel/panel/biz/publication/publication.go)
- [internal/modules/kernel/panel/biz/subscription/subscribe.go](magicRunner/internal/modules/kernel/panel/biz/subscription/subscribe.go)
- [internal/modules/kernel/portal/biz/service.go](magicRunner/internal/modules/kernel/portal/biz/service.go)
- [internal/modules/kernel/gateway/biz/biz.go](magicRunner/internal/modules/kernel/gateway/biz/biz.go)

## Governance Chain

Keep the subject chain explicit:

- `ApplicationDefinition` expresses what the application is.
- `EntityDefinition` expresses application internal entities and `serviceExpose`.
- `CapabilityDefinition` is the generated minimal executable capability.
- `ServiceDefinition` is the business service item that users can understand and subscribe to.
- `ServiceCapabilityBinding` aggregates capabilities into a service item.
- `ServicePublication` controls visibility, subscription policy, and publication state.
- `ServiceSubscription` records the consumer relationship.
- `SubscriptionCredential` represents endpoint/auth credentials derived from an approved subscription.
- Gateway access executes the published and subscribed service through the correct credential boundary.

## Entity Exposure Rules

- `EntityDefinition.serviceExpose` is the design-time source of service capabilities.
- First-stage capabilities are fixed to `query`, `get`, `create`, `update`, and `delete`.
- Field visibility and write constraints come from the entity definition: `viewDeclare`, `constraint`, and `defaultValue`.
- Do not add field-level service exposure rules unless the model explicitly evolves to support them.
- Uninstalled applications may keep service declarations, but they should not directly enter the service governance runtime chain.

## Capability and Service Rules

- A generated `CapabilityDefinition` is not the final business service.
- A `ServiceDefinition` should aggregate one or more capabilities through `ServiceCapabilityBinding`.
- A capability must not be bound to multiple service items at the same time. Move it by unbinding first.
- Keep service publication and subscription centered on `ServiceDefinition`, not raw capability items.
- Service management pages should distinguish generated capability items from service items.

## Publication, Subscription, and Credential Rules

- `ServicePublication` decides whether a service is published, visible, subscribable, and subject to approval or policy.
- `ServiceSubscription` is the lease between a consumer and a service.
- `SubscriptionCredential` is derived from an effective subscription; it is not a field inside the subscription body.
- `approve`, `enable`, `disable`, and endpoint management are business actions and must not be downgraded to plain runtime-object field updates.
- Backend approval logic should write audit fields such as approver and approval time.

## Panel, Portal, and Gateway Boundaries

- `portal` represents the consumer side. Service debugging must use the current user's effective subscription and endpoint credential.
- `panel` represents the governance side. Service debugging uses the current login authority and must not require that the admin has subscribed to the service.
- `/api/v1/gateway/services/*` should not be registered as a role-privilege business menu route.
- Gateway business logic owns publication, subscription, endpoint credential, scope, quota, and rate-limit checks.
- Entity capabilities should be executed through magicBase public value endpoints after gateway authorization, not through application runtime CRUD routes.

## Diagnosis Workflow

1. Identify the failing subject: capability, service item, binding, publication, subscription, credential, or gateway access.
2. Trace the object chain from `EntityDefinition.serviceExpose` to gateway target.
3. Confirm the application is installed before expecting generated runtime capabilities.
4. Check whether the caller is `panel` or `portal`; do not mix their credential rules.
5. If the failure is access-time authorization, switch to `magicrunner-service-gateway-auth`.
6. If the failure is handler parsing or session binding, switch to `magicrunner-panel-service` or `magicrunner-portal-service`.
7. Add tests at the layer that owns the broken semantic rather than patching downstream symptoms.

## Validation

```bash
GOCACHE=/tmp/magicrunner-gocache go test ./internal/modules/kernel/panel/biz/... -count 1
GOCACHE=/tmp/magicrunner-gocache go test ./internal/modules/kernel/portal/... -count 1
GOCACHE=/tmp/magicrunner-gocache go test ./internal/modules/kernel/gateway/... -count 1
```
