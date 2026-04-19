---
name: magicbase-service-access
description: Use when building or reviewing business data access on top of magicBase and magicOrm after Application/Entity capability is already defined. Covers DAO/helper usage, query endpoint behavior, ignored query mask params, and the rule that business services must not bypass magicOrm contracts; use magicbase-data-capability-definition for Application, Entity, Block and storage capability definition.
compatibility: Designed for agent clients working in repositories that expose business CRUD through magicBase on top of magicOrm. Assumes local repository access; no network access is required.
metadata:
  author: rangh-codespace
  domain: magicbase
  scenario: service-access
  maturity: stable
  version: 1.0.1
---

# MagicBase Service Access

Use this skill when implementing or reviewing DAO, helper, toolkit, or HTTP entrypoint behavior built on `magicBase`.

If the task is to define `Application`, `Entity`, `BlockInfo`, schema capability, or app storage binding, use `magicbase-data-capability-definition` first. Return here after the capability exists and the question is about read/write access behavior.

## Service-layer contract

- `magicBase` must follow `magicOrm` query semantics, not redefine them.
- Single-object query paths must align with `magicOrm.Query(model)`.
- Filter and list paths must align with `magicOrm.BatchQuery(filter)`.
- Query endpoints must ignore unrecognized response-shaping parameters instead of letting them alter single-query semantics.

## Required behavior

- Single query:
  top-level response is `detail`
- Filter or list query:
  top-level response uses `ValueMask > view`
- Child objects:
  always `lite`

## DAO and helper rules

- Prefer `pkg/helper.QueryValue`, `FilterValue`, `InsertValue`, and `UpdateValue` for app-side data access.
- Do not simulate single query with filter-plus-mask logic.
- Do not pass non-empty response templates just to enlarge child payloads.
- Do not handcraft service-side relation expansion.
- Keep helper functions as thin wrappers over the framework contract.
- Do not bypass magicBase/magicOrm with direct SQL for business value reads or writes.

## HTTP entrypoint rules

- Query endpoints should not accept `_viewType` or `_valueMask` as semantic controls for single-object query responses.
- If such parameters arrive, ignore them unless the endpoint is explicitly defined as a filter or list endpoint.
- Do not add endpoint-specific exceptions to bypass ORM visibility rules.

## Fix priority

1. `magicOrm`
   If the core query or write contract is wrong.
2. `magicBase`
   If helper, toolkit, or HTTP plumbing distorts the ORM contract.
3. Business service
   Only for domain logic, not for response-shape compensation.

## Review workflow

1. Identify whether the path is single-query or filter or list.
2. Verify the helper or DAO calls the correct framework path.
3. Check that no response template or nested mask is being used to change child depth.
4. Verify query endpoints ignore stray response-shaping params.
5. Add guard tests so future code cannot regress into old patterns.

## Common bad patterns

- `FilterValue` plus `QueryValueByFilter` used to fake single query
- `BatchQuery` used for single-object detail reads
- Business code relying on child placeholders like `&Child{}`
- Endpoint-level `_viewType` or `_valueMask` changing query output
- Patching business handlers instead of fixing `magicOrm` or `magicBase`
