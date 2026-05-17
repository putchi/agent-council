# Overview

Four domain-specific councils, each defined as a standalone config file under `scripts/councils/`.
Each council has four role-based members and a Chairman for final synthesis. All calls run through the local `codex` CLI.

## Councils

| File | Members |
|------|---------|
| `councils/tech.sh` | Architect, Critic, Devil, Pragmatist |
| `councils/career.sh` | Hiring Manager, Career Coach, Critic, Devil |
| `councils/business.sh` | Strategist, Financial Analyst, Critic, Devil |
| `councils/personal.sh` | Mentor, Psychologist, Critic, Pragmatist |

## Workflow

1. `run-council.sh` loads the council definition via `source scripts/councils/<type>.sh`
2. Each member script invokes `scripts/call-codex.sh`, which embeds the role-specific prompt into a `codex exec` prompt
3. All responses are collected and passed to `chairman.sh`
4. Chairman synthesizes a final decision using the council's domain-specific prompt via `codex exec`

## Adding a new council

1. Create `scripts/councils/mycouncil.sh` defining `MEMBERS` and `CHAIRMAN_PROMPT`
2. Create `scripts/member-mycouncil-<role>.sh` for each member
3. Run with `--council mycouncil`

No changes to `run-council.sh` needed.

## Requirements

- `codex` CLI installed and authenticated
- `node` available
