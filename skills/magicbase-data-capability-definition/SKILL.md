---
name: magicbase-data-capability-definition
description: 用于基于 magicBase 定义 Application、Entity、Entity fields/constraints、Block 与 serviceExpose 能力并接入数据存储，覆盖 ApplicationDeclare/数据库绑定、Entity remote.Object/schema 注册、字段类型/主键/生成策略/viewDeclare/constraint/defaultValue/relation、blockInfo 能力声明、EntityServiceExpose 能力项开放、pkg/helper DAO 使用、kernel/public 值读写、query/write 语义和恢复校验；在应用端用 magicBase 承载业务数据或开放实体服务能力时使用。
compatibility: Compatible with open_code
metadata:
  version: 1.0.3
  author: "rangh-codespace"
  created_at: "2026-04-18T22:45:00+08:00"
---

# magicBase Data Capability Definition

Use this skill when an application needs to define data capabilities on top of `magicBase`: register an `Application`, declare `Entity` metadata and fields, attach `Block` capabilities, expose service capabilities, and read or write business values through the public value APIs.

## Scope

- Use this for app-side capability definition and storage integration.
- Use `magicbase-kernel-entity` when changing `kernel/base` or `kernel/public` internals.
- Use `magicbase-service-access` when reviewing DAO/helper/query behavior after the capability is already defined.
- Use `magicbase-module-dev` when adding or changing a magicBase block module, its routes, or its lifecycle.
- Use `magicorm-entity-definition` for deep magicOrm model-definition questions, especially view/constraint behavior that is not magicBase-specific.
- Use `magicorm-provider-object-usage` when constructing `remote.Object`, `ObjectValue`, `SliceObjectValue`, or Local/Remote Provider inputs.

## Read First

- [docs/design-modules.md](magicBase/docs/design-modules.md)
- [docs/design-http-entrypoints.md](magicBase/docs/design-http-entrypoints.md)
- [pkg/common/application.go](magicBase/pkg/common/application.go)
- [pkg/common/entity.go](magicBase/pkg/common/entity.go)
- [pkg/common/block.go](magicBase/pkg/common/block.go)
- [pkg/common/public.go](magicBase/pkg/common/public.go)
- [pkg/helper/application.go](magicBase/pkg/helper/application.go)
- [pkg/helper/dao.go](magicBase/pkg/helper/dao.go)
- [magicOrm/provider/remote/object.go](magicOrm/provider/remote/object.go)
- [magicOrm/provider/remote/field.go](magicOrm/provider/remote/field.go)
- [magicOrm/provider/remote/spec.go](magicOrm/provider/remote/spec.go)
- [magicOrm/models/constraint.go](magicOrm/models/constraint.go)
- [internal/modules/kernel/base/biz/application.go](magicBase/internal/modules/kernel/base/biz/application.go)
- [internal/modules/kernel/base/biz/entity.go](magicBase/internal/modules/kernel/base/biz/entity.go)
- [internal/modules/kernel/public/biz/entity.go](magicBase/internal/modules/kernel/public/biz/entity.go)
- [internal/modules/kernel/public/biz/value.go](magicBase/internal/modules/kernel/public/biz/value.go)

## Application Definition

Define the application before defining entities or writing values.

- Use `common.ApplicationDeclare` as the capability boundary: `UUID`, `Name`, `PkgPrefix`, `Icon`, optional catalog/domain metadata, database declaration, hosting metadata, and exposure flags.
- Ensure the app exists and bind the client with `pkg/helper.EnsureApplicationBound`; this performs lookup by application identity and binds the resulting application UUID to the client.
- Do not hardcode a storage database in business code. `CreateApplication` fills the default database declaration when one is not provided, registers the database with magicOrm, and rolls back the application record if database registration fails.
- Treat application UUID as the storage namespace. Entity registration and value operations must operate under the correct bound application.

## Entity Definition

An entity is both metadata in `kernel/base` and a `magicOrm` model in the application namespace.

- Model the entity with `common.Entity`, which embeds `remote.Object` and adds `BlockInfo`, `ServiceExpose`, `Version`, and `Status`.
- Keep `Name` and `PkgPath` stable. The effective package key is `path.Join(PkgPath, Name)`, so avoid duplicating the name inside `PkgPath`.
- Put `viewDeclare`, field constraints, relation declarations, readonly/default behavior, and storage-facing object shape in the embedded `remote.Object`.
- Do not implement app-side patches for view or validation behavior. If the entity contract is wrong, fix the entity definition or the relevant magicOrm contract skill.
- `CreateEntity` persists entity metadata, registers the remote model for the application provider, and creates schema when the entity is enabled. Registration or schema failures must not leave a partially active entity.

## Field and Constraint Definition

Entity fields live in the embedded `remote.Object.Fields` list. Treat this list as the storage and API contract for business values.

- Define each field with `remote.Field`: `Name`, `ShowName`, `Description`, `Type`, and `Spec`.
- Keep field `Name` stable; it is the payload field name used by `ObjectValue` and helper conversion.
- Use `SpecImpl.FieldName` for the storage column name when it differs from `Name`; avoid accidental drift between API field name and storage field name.
- Mark exactly the intended primary key with `SpecImpl.PrimaryKey`. Do not declare multiple primary keys unless the underlying ORM/schema path explicitly supports it.
- Use `SpecImpl.ValueDeclare` for framework-generated values: customer-provided default, `auto`, `uuid`, `snowflake`, or `datetime`.
- Use `SpecImpl.ViewDeclare` to define public visibility. Only `detail` and `lite` are stable public views; `origin` and `meta` are internal framework views.
- Use `SpecImpl.Constraint` for validation and write-safety rules: `req`, `ro`, `wo`, `min`, `max`, `range`, `in`, and `re`.
- Use `SpecImpl.DefaultValue` only for basic literal defaults. Do not encode expressions, slices, maps, structs, or runtime references as defaults.
- Model relation fields with the field `Type`/relation declaration expected by magicOrm, not by embedding expanded child payloads into ordinary fields.
- Keep top-level runtime declarations such as `blockInfo` and `serviceExpose` out of `Fields`; they are entity metadata, not business value fields.

## Field Semantics Checklist

- `req` means the value is required for the applicable write scenario. Do not add app-layer fallback values just to hide a missing required field.
- `ro` means client writes must not overwrite the persisted value. For update flows, verify the framework preserves the stored value.
- `wo` means the field is write-only and must not leak through query/list response projection.
- `min` and `max` apply to numeric values or length-bearing values according to magicOrm validation.
- `range` uses a closed numeric interval.
- `in` is an enum list. Keep enum spellings stable because they become data contracts.
- `re` is a regular expression constraint; ensure escaping is valid for JSON or Go struct tags.
- If a field lacks `detail` or `lite`, do not expect it in public query responses.
- If a field appears in relation-lite output, it must be allowed by the relation/lite projection contract, not forced by app-side response templates.
- If validation or projection behavior is wrong, fix magicOrm or magicBase plumbing rather than compensating in business handlers.

## Block Capability Definition

Blocks are entity capabilities, not normal business fields.

- Declare block capability through top-level `blockInfo`, matching `common.BlockInfo`.
- Keep block capability metadata separate from persisted business fields in the `remote.Object` field list.
- Use `common.StageView`, block params, and function metadata for block-specific execution semantics.
- Entity create/update paths run block prechecks and postchecks. Do not bypass these checks by writing entity metadata directly.
- Block HTTP services that require application context must fail closed when the context is missing.
- Event-only blocks, such as masking-style blocks, may intentionally have no HTTP route.

## Service Capability Exposure

Service exposure is entity metadata, not a replacement for entity schema or block definition.

- Define service exposure through top-level `serviceExpose`, matching `common.EntityServiceExpose`.
- Use `EntityServiceExpose.Enabled` as the overall exposure switch for the entity service capability.
- Define each exposed operation with `EntityServiceCapability`: `Key` is the capability identifier, `Enabled` controls that capability, and `Scope` declares the intended exposure boundary.
- Keep service capability definitions separate from `remote.Object` fields. Do not persist `serviceExpose` as a normal business field.
- Use the dedicated update routes when changing service exposure metadata: base `UpdateEntityServiceExpose` or public `UpdatePublicEntityServiceExpose`.
- Public service exposure update must resolve application context first and send the update through the base event path with `ServiceExposeTag`; do not write entity rows directly from public handlers.
- Application-level `ApplicationDeclare.Exposed` is not the same as entity-level `serviceExpose`; check both when debugging why a capability is not externally visible.

## Data Storage Path

Separate platform metadata from application business data.

- Application and entity metadata are managed by `kernel/base` and stored through the platform-side provider.
- Business values are stored through the application-bound remote provider and the schema generated from the entity's `remote.Object`.
- Use `pkg/helper` data helpers for app-side access: `QueryValue`, `FilterValue`, `InsertValue`, `UpdateValue`.
- Build values with the application provider's `GetObject`, `GetObjectValue`, and `GetSliceObjectValue`; then let helper conversion update typed structs from returned `ObjectValue`.
- Do not bypass `magicBase` and `magicOrm` with direct SQL or custom DAO writes unless the task is explicitly framework internals.

## Query and Write Semantics

Keep endpoint behavior aligned with `magicOrm`.

- Single query returns `detail` shape and should ignore `_viewType` or `_valueMask` response-shaping parameters.
- Filter/list query applies `ValueMask > view` for top-level projection.
- Child relation objects stay lite unless the underlying ORM contract explicitly supports a deeper shape.
- `kernel/public` may accept primary-key shorthand for relation fields; reject illegal complex values early.
- Bad JSON, invalid REST IDs, invalid object values, or missing application context should map to client-side parameter errors rather than silent fallback.

## Validation

- Validate application create/bind paths include rollback on database registration failure.
- Validate entity create/update registers the model under the correct application UUID and handles schema errors.
- Validate every field has the intended name, storage field name, type, primary key, value declaration, public view declaration, constraints, and default value.
- Validate readonly, write-only, required, enum, range, regex, and relation fields through insert, update, query, and filter paths.
- Validate block capability updates trigger the expected precheck/postcheck path.
- Validate service exposure updates round-trip through `EntityServiceExpose` JSON and use the correct base or public route.
- Validate exposed service capabilities are not accidentally added to `remote.Object` storage fields.
- Validate business value CRUD through `pkg/helper` rather than direct provider or SQL shortcuts.
- Run targeted magicBase tests for the touched path, then run the relevant magicOrm tests if query/write, validation, view, or schema semantics changed.
