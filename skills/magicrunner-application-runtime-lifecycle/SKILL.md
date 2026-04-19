---
name: magicrunner-application-runtime-lifecycle
description: 用于处理 magicRunner 的应用运行生命周期，覆盖 ApplicationDefinition/Package/Release 到 ApplicationRuntime 的安装、schema 创建回滚、installer 实体数据导入、compose 配置和 docker-compose 产物、Traefik 动态暴露、启动停止、卸载清理与操作记录；排查安装、启停、卸载、运行产物或数据库资源一致性时使用。
compatibility: Compatible with open_code
metadata:
  version: 1.0.1
  author: "rangh-codespace"
  created_at: "2026-04-18T22:48:00+08:00"
---

# magicRunner Application Runtime Lifecycle

Use this skill when troubleshooting or implementing the application lifecycle in `magicRunner`: package/release selection, install, schema preparation, installer execution, compose deployment, start/stop, and uninstall cleanup.

## Scope

- Use this for the end-to-end application runtime lifecycle.
- Use `magicrunner-installer-offline` for installer package parsing and offline install internals.
- Use `magicrunner-vmi-install-recovery` for VMI-specific recovery after installation failures.
- Use `magicrunner-runtime-routing` when the issue is runtime-object route ownership after an application is installed.
- Use `magicrunner-service-governance` when the issue is service capability generation or subscription governance.

## Read First

- [docs/design-modules.md](magicRunner/docs/design-modules.md)
- [docs/design-business-models.md](magicRunner/docs/design-business-models.md)
- [docs/design-application-service-governance.md](magicRunner/docs/design-application-service-governance.md)
- [docs/design-startup.md](magicRunner/docs/design-startup.md)
- [internal/modules/kernel/panel/biz/application/application.go](magicRunner/internal/modules/kernel/panel/biz/application/application.go)
- [internal/modules/kernel/panel/biz/application/online.go](magicRunner/internal/modules/kernel/panel/biz/application/online.go)
- [internal/modules/kernel/panel/biz/application/offline.go](magicRunner/internal/modules/kernel/panel/biz/application/offline.go)
- [internal/modules/blocks/installer/biz/offline.go](magicRunner/internal/modules/blocks/installer/biz/offline.go)
- [internal/modules/blocks/compose/biz/biz.go](magicRunner/internal/modules/blocks/compose/biz/biz.go)
- [internal/modules/blocks/compose/biz/manager.go](magicRunner/internal/modules/blocks/compose/biz/manager.go)
- [internal/modules/blocks/compose/biz/exposure.go](magicRunner/internal/modules/blocks/compose/biz/exposure.go)
- [internal/modules/blocks/database/biz/biz.go](magicRunner/internal/modules/blocks/database/biz/biz.go)

## Ownership Boundaries

- `kernel/panel` owns control-plane orchestration and metadata consistency.
- `blocks/installer` owns package extraction, `app.json`/`cas.json`/`entity`/`data` import, and application/entity/data registration.
- `blocks/database` owns database schema helper operations, but schema lifecycle orchestration belongs to panel.
- `blocks/compose` owns runtime artifacts and container lifecycle.
- `kernel/runner` only loads registered entities and creates public-value proxy routes; it must not perform install compensation or uninstall cleanup.

## Lifecycle Chain

Follow this chain for install and runtime troubleshooting:

- Select `ApplicationRelease` and `ApplicationPackage`, or accept an offline package input.
- Prepare runtime dependencies, especially `DatabaseSchema`.
- Call installer to register application, entity definitions, CAS data, and seed data.
- On install failure, roll back newly created schema and partially imported application/entity state.
- Generate runtime config under `apps/config/<app>/application.toml`.
- Generate compose artifact under `apps/compose/<app>/docker-compose.yaml`.
- Optionally generate Traefik dynamic config under `services/config/traefik/dynamic/app-<app>.toml`.
- Start or stop application containers through compose.
- On uninstall, remove runtime artifacts and reclaim schema when ownership matches the application UUID.

## Runtime Artifact Rules

- `application.toml` and `docker-compose.yaml` are runtime artifacts; keep them under compose ownership.
- Traefik dynamic config controls external exposure and should be created or removed with explicit exposure intent.
- Installer should not write `apps/config` or `apps/compose` directly.
- Schema create/delete should remain coordinated by panel because it depends on console metadata and ownership.
- Runtime application fields must stay aligned with magicBase `ApplicationDeclare/ApplicationView`; do not overload them with package or config-token metadata unless the runtime model is explicitly extended.

## Failure Diagnosis

1. Identify which stage failed: package, schema, installer, compose config, container start, gateway/exposure, or cleanup.
2. Check operation records and logs before retrying.
3. If schema was created in this attempt, verify rollback on failure.
4. If application metadata exists but ORM is missing, switch to magicBase recovery skills.
5. If config exists but container does not start, inspect compose artifact and runtime paths.
6. If container starts but routes are missing, switch to `magicrunner-runtime-routing` or runner proxy skills.
7. If service capabilities are missing after install, switch to `magicrunner-service-governance`.

## Validation

```bash
GOCACHE=/tmp/magicrunner-gocache go test ./internal/modules/kernel/panel/biz/application -count 1
GOCACHE=/tmp/magicrunner-gocache go test ./internal/modules/blocks/installer/... -count 1
GOCACHE=/tmp/magicrunner-gocache go test ./internal/modules/blocks/compose/... -count 1
GOCACHE=/tmp/magicrunner-gocache go test ./internal/modules/blocks/database/biz -count 1
```
