# Configure members

## Council definition files

Each council is a standalone shell file in `scripts/councils/` that defines two variables:

```bash
# scripts/councils/tech.sh
MEMBERS=("architect:🏗️" "critic:🔍" "devil:😈" "pragmatist:⚙️")
CHAIRMAN_PROMPT="You are the Chairman of a technical expert council..."
```

`MEMBERS` is an array of `role:emoji` pairs. Each role maps to a member script:
`scripts/member-<council>-<role>.sh`

## Adding a member

1. Add an entry to the council's `MEMBERS` array: `"newrole:🆕"`
2. Create `scripts/member-<council>-newrole.sh` with a role-specific system prompt

## Changing a member's behavior

Edit the `MEMBER_SYSTEM_PROMPT` inside the relevant `member-<council>-<role>.sh` script.

## Changing the Chairman's synthesis style

Edit the `CHAIRMAN_PROMPT` inside the relevant `councils/<type>.sh` file.

## Available councils

| Flag | File | Members |
|------|------|---------|
| `--council tech` | `councils/tech.sh` | architect, critic, devil, pragmatist |
| `--council career` | `councils/career.sh` | hiring-manager, coach, critic, devil |
| `--council business` | `councils/business.sh` | strategist, financial, critic, devil |
| `--council personal` | `councils/personal.sh` | mentor, psychologist, critic, pragmatist |

## council.config.yaml

Used only by the legacy `council.sh` job runner (async/polling mode).
Not required for `run-council.sh`.
