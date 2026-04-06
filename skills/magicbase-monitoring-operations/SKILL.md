---
name: magicbase-monitoring-operations
description: Use when implementing or reviewing magicBase monitoring, operational dashboards, data-accuracy checks, or service health workflows. Covers monitoring semantics, metric correctness, and operational debugging patterns.
compatibility: Designed for agent clients working on repositories that use magicBase monitoring, health, or operational dashboards. Assumes local repository access and monitoring-related code or docs; no network access is required.
metadata:
  author: rangh-codespace
  domain: magicbase
  scenario: monitoring-operations
  maturity: stable
---

# MagicBase Monitoring And Operations

Use this skill when the task is about monitoring output, health checks, dashboard data correctness, or operational playbooks on `magicBase`.

## Scope

- Monitoring data generation
- Dashboard and health semantics
- Operational debugging and service recovery
- Monitoring data accuracy checks

## Core rules

- Monitoring should reflect actual service behavior, not guessed business interpretation.
- Metric correctness matters as much as metric presence.
- If health or monitoring output is wrong, fix the producing layer before patching dashboards.
- Operational playbooks should follow the platform contract instead of project-local ad hoc rules.

## Review workflow

1. Identify the source metric or health signal.
2. Verify whether the signal is computed correctly at the producer.
3. Check whether dashboard or alert semantics match the raw data.
4. Fix metric generation before adjusting visualizations.
5. Add monitoring regression checks where feasible.

## Common bad patterns

- Patching dashboards when the backend metric is wrong
- Treating missing observability as a business logic bug
- Mixing operational health semantics with endpoint contract semantics
- Leaving data-accuracy checks undocumented or untested
