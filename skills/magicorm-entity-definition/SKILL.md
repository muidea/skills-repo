---
name: magicorm-entity-definition
description: Use when defining, reviewing, or fixing magicOrm entity models in struct tags or entity JSON. Covers viewDeclare, constraints, readonly/default fields, and the rule that framework behavior must follow entity definitions rather than app-side patches.
compatibility: Designed for agent clients working in repositories that use magicOrm model definitions and magicBase-based services. Assumes local repository access; no network access is required.
metadata:
  author: rangh-codespace
  domain: magicorm
  scenario: entity-definition
  maturity: stable
version: 1.0.2
---

# MagicOrm Entity Definition

Use this skill when the task is about entity definitions, field visibility, validation rules, or why runtime behavior does not match the declared model.

## Scope

- Entity JSON under a project definition directory
- Struct-tag based entity definitions
- Field-level `viewDeclare`, `constraint`, `defaultValue`
- Runtime-object level `blockInfo` declarations
- Mismatches between declared definition and runtime/test behavior

Do not use this skill for generic business debugging if the issue is clearly outside model definition or ORM contract.

## Core rules

- Treat the entity definition as the source of truth.
- Use `boolean` as the canonical external boolean type name in entity JSON and type definitions.
- Treat runtime object identity as `pkgKey = path.Join(pkgPath, name)`. Review `name` and `pkgPath` together, not separately.
- Distinguish entity business fields from runtime-object top-level declarations such as `blockInfo`.
- If a field does not declare a public `viewDeclare`, do not require it to be returned.
- Public views are only `detail` and `lite`.
- `origin` and `meta` are internal runtime views, not public modeling inputs.
- Validation and readonly semantics belong in `magicOrm`, not in app-layer patches.
- `blockInfo` is not a normal business field when the active runtime-object definition declares it at the top level.
- For panel-style runtime objects, `blockInfo` is used to declare built-in platform block capabilities such as totalizator registration and refresh, not to expose business-management form fields.
- If runtime behavior conflicts with the definition, prefer fixing the framework path before changing business code.

## Definition review workflow

1. Find the active entity definition used by the target service.
2. Reconstruct the runtime `pkgKey` from `path.Join(pkgPath, name)` and confirm it matches what code expects.
3. Check whether the failing concern belongs to `fields[]` or to a top-level declaration such as `blockInfo`.
4. For field issues, check whether the failing field is actually declared.
5. Check whether its `viewDeclare` includes `detail` or `lite`.
6. Check whether `constraint` implies readonly, required, range, enum, or format validation.
7. Check whether `defaultValue` is meant for insert only or also affects update-time response.
8. For block/statistics issues, verify `blockInfo` is declared at the top level of the entity JSON rather than as a pseudo field inside `fields[]`.
9. If tests expect undeclared fields, tighten the tests to the definition.
10. If runtime ignores declared fields or constraints, fix `magicOrm` or `magicBase`.

## Field interpretation rules

- `viewDeclare: ["detail"]`
  The field is allowed in top-level detail responses.
- `viewDeclare: ["lite"]`
  The field is allowed in lite responses and therefore also relation-lite projections.
- No public `viewDeclare`
  Do not require the field in public query responses.
- `constraint: "ro"`
  The field must not be client-writable. Update paths must not let request payloads overwrite persisted values.
- `constraint: "req"`
  The field is required on the appropriate write path.

## Block declaration rules

- `blockInfo` belongs to the runtime-object root, parallel to `fields`, not inside `fields[]`, when the object is declaring built-in platform block capability.
- For panel runtime objects such as service, package, publication, release, schema, instance, and definition, built-in statistics registration should be modeled through top-level `blockInfo`.
- Do not model built-in statistics blocks as editable business fields just to make them visible in management pages.
- If a business object truly stores user-managed block configuration as data, that is a separate business-field design and must be justified explicitly. Do not infer it from other panel runtime objects.

## PkgKey rules

- Runtime object matching in panel/base startup depends on `pkgKey = path.Join(pkgPath, name)`.
- Do not encode the object name twice by putting it both in `pkgPath` and in `name`.
- If code expects `/panel/hub/serviceCapabilityBinding`, the correct declaration is:
  - `pkgPath = "/panel/hub"`
  - `name = "serviceCapabilityBinding"`
- A declaration such as:
  - `pkgPath = "/panel/hub/serviceCapabilityBinding"`
  - `name = "binding"`
  will produce `/panel/hub/serviceCapabilityBinding/binding`, which will break runtime entity lookup.

## Fix strategy

- Fix the declaration if the model is wrong.
- Fix `magicOrm` if the framework violates the declaration.
- Fix `magicBase` only when the issue is in service access plumbing.
- Only change business tests after confirming the declaration is the intended contract.

## Review checklist

- Is the field declared in the active model?
- Does `path.Join(pkgPath, name)` exactly match the pkg key expected by code and runtime initialization?
- Does the field have the expected public `viewDeclare`?
- Are readonly/default fields preserved correctly after update?
- Are relation fields modeled as relations rather than top-level payload expansions?
- Are tests asserting only what the definition actually promises?
- Is `blockInfo` declared at the correct layer: top-level runtime-object metadata vs. business field?
- If the object is reusing built-in platform statistics, is `blockInfo` kept out of business-management form semantics?
