# Overview

Four domain-specific councils, each defined as a standalone config file under `scripts/councils/`.
Each council has four role-based members (Sonnet) and a Chairman (Opus) for final synthesis.

## Councils

| File | Members |
|------|---------|
| `councils/tech.sh` | Architect, Critic, Devil, Pragmatist |
| `councils/career.sh` | Hiring Manager, Career Coach, Critic, Devil |
| `councils/business.sh` | Strategist, Financial Analyst, Critic, Devil |
| `councils/personal.sh` | Mentor, Psychologist, Critic, Pragmatist |

## Workflow

1. `run-council.sh` loads the council definition via `source scripts/councils/<type>.sh`
2. Each member script invokes the `claude` CLI (`-p`) with a role-specific system prompt (Sonnet)
3. All responses are collected and passed to `chairman.sh`
4. Chairman (Opus) synthesizes a final decision using the council's domain-specific prompt

## Adding a new council

1. Create `scripts/councils/mycouncil.sh` defining `MEMBERS` and `CHAIRMAN_PROMPT`
2. Create `scripts/member-mycouncil-<role>.sh` for each member
3. Run with `--council mycouncil`

No changes to `run-council.sh` needed.

## Requirements

- `claude` CLI installed and authenticated
- `node` available
