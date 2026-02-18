---
name: project-integrity-guardian
description: A consistency enforcement tool that audits a project against a "Source of Truth" (SoT). It supports using either a specific file or a raw text string as the anchor to verify and align Code, Docs, Scripts, Tests, and CI configurations.
version: 1.2.0
metadata:
  capabilities:
    [Cross-File Auditing, Textual Anchor Support, Multi-Domain Verification]
---

# Project Integrity Guardian

Use this skill when you need to ensure the entire project adheres to a specific requirement, version, or architectural decision.

## Operational Modes

### A. File-as-Anchor

When a user says "Use `config.json` as the anchor", run:
`python3 scripts/check_integrity.py --anchor_file ./config.json`

### B. Text-as-Anchor

When a user says "Check the project against this requirement: 'All APIs must use OAuth2 and port 443'", run:
`python3 scripts/check_integrity.py --anchor_text "All APIs must use OAuth2 and port 443"`

## Agent Instructions

1. **Pre-Audit**: When an anchor is provided, parse it to identify "Key Facts" (e.g., versions, protocols, constants, ports).
2. **Execution**: Call `check_integrity.py`. It will return a JSON report listing files that contain related but conflicting information.
3. **Reasoning**: Compare the script's output with the Anchor.
   - If a file mentions a relevant topic (e.g., "port") but has a different value, mark as a **Conflict**.
   - If a file is missing a required configuration defined in the anchor, mark as **Missing**.
4. **Reporting**: Present a grouped report (Code, Docs, Scripts, CI, Tests).
5. **Interactive Fix**:
   - For clear mismatches (e.g., version number), offer to `Apply Fix`.
   - For complex logic conflicts, **ask the user**: "The anchor requires X, but `core.py` implements Y. Should I refactor the code or update the anchor?"

## Example

"Check all project files against the text: 'The default timeout for all service calls is 5000ms'."
