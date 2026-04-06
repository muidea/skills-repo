---
name: magicorm-query-write-contract
description: Use when implementing or reviewing magicOrm query and write behavior. Covers Query vs BatchQuery semantics, ValueMask and view precedence, relation-lite rules, and insert/update response projection.
compatibility: Designed for agent clients working in repositories that use magicOrm query and write paths directly or through magicBase. Assumes local repository access; no network access is required.
metadata:
  author: rangh-codespace
  domain: magicorm
  scenario: query-write-contract
  maturity: stable
---

# MagicOrm Query And Write Contract

Use this skill when the task involves query response shape, relation expansion, insert/update response projection, or framework-level CRUD consistency.

## Stable contract

- `Query(model)` is the formal single-object query entry.
- `BatchQuery(filter)` is the formal multi-object query entry.
- `Query(model)` does not process `ValueMask`.
- Top-level `Query(model)` responses use `DetailView`.
- `BatchQuery(filter)` uses `ValueMask > view`.
- Primary key fields must remain available.
- Child include/reference objects must always collapse to `lite`.

## Relation rules

- Parent `detail` does not upgrade child objects to `detail`.
- Nested masks must not upgrade child objects to `detail`.
- If a child object needs detail, fetch it again by its own primary key.

## Write response rules

- Insert and update responses must follow the same public projection rules as query responses.
- Undeclared public fields must not leak through write responses.
- Readonly fields must not be overwritten by request payloads.
- If a readonly persisted field is needed in the response, the framework should project the stored value, not echo dirty input.

## Implementation guidance

- Fix response shape in `magicOrm` first.
- Keep app and service code thin; do not add endpoint-specific response masks to compensate for ORM defects.
- Avoid reintroducing public `relationView`.
- Keep `QueryByFilter` out of the public ORM contract.

## Review workflow

1. Decide whether the path is single-query or filter-query.
2. Check the top-level response rule:
   `Query -> DetailView`
   `BatchQuery -> ValueMask > view`
3. Check every relation field and verify it is returned only as `lite`.
4. Check insert and update responses against the same visibility rules.
5. Add or update framework tests before touching business tests.

## Common bad patterns

- Using non-empty child templates to influence query depth
- Hand-building nested `ValueMask` to force child detail
- Treating undeclared fields as implicitly public
- Echoing update payloads directly instead of projecting stored values
- Fixing ORM response defects in business handlers
