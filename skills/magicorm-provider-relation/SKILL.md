---
name: magicorm-provider-relation
description: Use when defining or reviewing magicOrm local or remote provider behavior, relation modeling, relation response shape, and spec generation. Covers relation-lite rules and the rule that relationView is not a public capability.
compatibility: Designed for agent clients working with magicOrm local or remote providers and relation-heavy entity models. Assumes local repository access; no network access is required.
metadata:
  author: rangh-codespace
  domain: magicorm
  scenario: provider-relation
  maturity: stable
---

# MagicOrm Provider And Relation

Use this skill when the task touches provider modeling, remote spec generation, relation tags, include or reference fields, or why relation payloads do not match expectation.

## Scope

- Local provider struct tags
- Remote provider spec generation
- Relation fields and relation metadata
- Relation query projection and relation-lite behavior

## Stable rules

- Public field visibility is controlled by public views only.
- Public views are `detail` and `lite`.
- `relationView` is not a public capability.
- Relation objects in query or write responses must collapse to `lite`.
- Parent projection must not enlarge child projection.

## Modeling rules

- Model relation fields as relations, not as manually expanded nested payload contracts.
- If a child object must expose more data, fetch it as a top-level object.
- Remote specs should expose the effective public contract, not internal tuning knobs.
- If a spec contains stale public fields that no longer affect behavior, remove them from the public surface.

## Review workflow

1. Check whether the issue is in local tags, remote spec generation, or runtime projection.
2. Verify the relation field exists in the entity definition and carries the expected public view.
3. Verify the provider does not expose `relationView` or similar expansion controls as a public promise.
4. Verify runtime projection still collapses children to `lite`.
5. Add a provider or ORM regression test if the issue is framework-level.

## Common bad patterns

- Exposing `relationView` in public definitions
- Expecting parent `detail` to imply child `detail`
- Using nested masks to force relation expansion
- Treating remote spec output as a place to expose internal runtime knobs
