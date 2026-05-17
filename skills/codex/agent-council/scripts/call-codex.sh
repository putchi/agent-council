#!/bin/bash
# Codex CLI caller for council members.
# Requires: codex CLI installed and authenticated.
# Env: MEMBER_SYSTEM_PROMPT
# Args: $1 = prompt

set -euo pipefail

PROMPT="${1:-}"
SYSTEM_PROMPT="${MEMBER_SYSTEM_PROMPT:-You are an expert council member. Answer from your assigned role. Be direct, specific, and useful.}"

if [ -z "$PROMPT" ]; then
  echo "Error: missing prompt." >&2
  exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
  echo "Error: codex CLI not found. Install and authenticate the Codex CLI first." >&2
  exit 1
fi

COMPOSED_PROMPT=$(cat <<EOF
You are participating as one role in an Agent Council.

Role instructions:
$SYSTEM_PROMPT

Question:
$PROMPT

Respond only as this council member. Use the role instructions above as your operating instructions. Be direct, specific, and do not include meta-commentary about running Codex.
EOF
)

codex exec --ephemeral --skip-git-repo-check "$COMPOSED_PROMPT"
