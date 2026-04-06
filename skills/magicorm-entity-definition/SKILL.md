---
name: magicorm-entity-definition
description: Use when defining, reviewing, or fixing magicOrm entity models in struct tags or entity JSON. Covers viewDeclare, constraints, readonly/default fields, and the rule that framework behavior must follow entity definitions rather than app-side patches.
compatibility: Designed for agent clients working in repositories that use magicOrm model definitions and magicBase-based services. Assumes local repository access; no network access is required.
metadata:
  author: rangh-codespace
  domain: magicorm
  scenario: entity-definition
  maturity: stable
---

# MagicOrm Entity Definition

Use this skill when the task is about entity definitions, field visibility, validation rules, or why runtime behavior does not match the declared model.

## Scope

- Entity JSON under a project definition directory
- Struct-tag based entity definitions
- Field-level `viewDeclare`, `constraint`, `defaultValue`
- Mismatches between declared definition and runtime/test behavior

Do not use this skill for generic business debugging if the issue is clearly outside model definition or ORM contract.

## Core rules

- Treat the entity definition as the source of truth.
- If a field does not declare a public `viewDeclare`, do not require it to be returned.
- Public views are only `detail` and `lite`.
- `origin` and `meta` are internal runtime views, not public modeling inputs.
- Validation and readonly semantics belong in `magicOrm`, not in app-layer patches.
- If runtime behavior conflicts with the definition, prefer fixing the framework path before changing business code.

## Definition review workflow

1. Find the active entity definition used by the target service.
2. Check whether the failing field is actually declared.
3. Check whether its `viewDeclare` includes `detail` or `lite`.
4. Check whether `constraint` implies readonly, required, range, enum, or format validation.
5. Check whether `defaultValue` is meant for insert only or also affects update-time response.
6. If tests expect undeclared fields, tighten the tests to the definition.
7. If runtime ignores declared fields or constraints, fix `magicOrm` or `magicBase`.

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

## Fix strategy

- Fix the declaration if the model is wrong.
- Fix `magicOrm` if the framework violates the declaration.
- Fix `magicBase` only when the issue is in service access plumbing.
- Only change business tests after confirming the declaration is the intended contract.

## Review checklist

- Is the field declared in the active model?
- Does the field have the expected public `viewDeclare`?
- Are readonly/default fields preserved correctly after update?
- Are relation fields modeled as relations rather than top-level payload expansions?
- Are tests asserting only what the definition actually promises?
