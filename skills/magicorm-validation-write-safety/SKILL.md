---
name: magicorm-validation-write-safety
description: Use when implementing or reviewing magicOrm validation, readonly handling, defaults, and insert or update write safety. Covers req or ro or range or enum or format constraints and framework-level enforcement.
compatibility: Designed for agent clients working on magicOrm validation and persistence safety in repositories that rely on framework-enforced model constraints. Assumes local repository access; no network access is required.
metadata:
  author: rangh-codespace
  domain: magicorm
  scenario: validation-write-safety
  maturity: stable
---

# MagicOrm Validation And Write Safety

Use this skill when the task is about rejected writes, missing validation, readonly field drift, or update responses carrying wrong values.

## Core rules

- Validation belongs in `magicOrm`.
- Business services should not reimplement model constraints to compensate for framework gaps.
- Readonly fields must not be client-writable.
- Default values must follow the declared model contract.
- Insert and update responses must reflect persisted rule-compliant values.

## Constraint handling

- `req`
  The field must be present on the relevant write path.
- `ro`
  Client payload must not overwrite persisted values.
- range or enum or regex or format constraints
  Must be enforced by framework validation, not left to app-side best effort.

## Update safety rules

- Update execution must not write readonly fields.
- Update response must not echo dirty readonly input.
- If needed, response projection should use stored values after update.
- Optional fields set to null should be written as null when the model allows it.

## Review workflow

1. Identify the field declaration and active constraints.
2. Reproduce whether the bug is write-time validation, SQL write, or response projection.
3. Fix `magicOrm` if readonly or validation semantics are violated.
4. Keep `magicBase` and business services free of duplicate validation patches.
5. Add framework tests that cover insert, update, and write-after-read response consistency.

## Common bad patterns

- Reapplying readonly defaults in service code
- Accepting illegal payloads and fixing them in handlers
- Letting update responses reflect request payload instead of stored values
- Treating null updates as no-op when the model expects nullable persistence
