---
name: magicbase-module-startup
description: Use when wiring modules, startup order, dependency registration, or runtime initialization in services built on magicBase. Covers module boundaries, bootstrap flow, and startup-safe extension patterns.
compatibility: Designed for agent clients working on repositories that build services on magicBase module and startup conventions. Assumes local repository access and application bootstrap code; no network access is required.
metadata:
  author: rangh-codespace
  domain: magicbase
  scenario: module-startup
  maturity: stable
---

# MagicBase Module Startup

Use this skill when the task is about module assembly, startup sequence, dependency registration, or service bootstrapping on `magicBase`.

## Scope

- Module boundaries and ownership
- Startup initialization order
- Dependency wiring and bootstrap paths
- Runtime extension points

## Core rules

- Startup should compose modules cleanly; avoid side-effect-heavy hidden registration.
- Module boundaries should stay explicit.
- Shared boot logic belongs in `magicBase` patterns, not repeated project glue.
- Initialization order must respect configuration, provider, ORM, and service wiring dependencies.

## Review workflow

1. Identify the startup entry and module graph.
2. Check which dependencies must exist before service exposure.
3. Verify module registration order.
4. Fix startup flow in shared bootstrap or module wiring rather than scattered business patches.
5. Add startup or smoke tests for the affected path.

## Common bad patterns

- Implicit side effects during import-time module loading
- Duplicated bootstrap logic across services
- Starting HTTP exposure before dependencies are ready
- Fixing startup bugs only in deployment scripts
