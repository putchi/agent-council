#!/bin/bash
# Claude Code CLI caller (no API fallback)
# Requires: claude CLI installed and authenticated
# Env: MEMBER_SYSTEM_PROMPT
# Args: $1 = prompt, $2 = model override (optional)

PROMPT="$1"
MODEL="${2:-claude-sonnet-4-6}"

if ! command -v claude &>/dev/null; then
  echo "Error: claude CLI not found. Install Claude Code CLI first." >&2
  exit 1
fi

claude --system-prompt "$MEMBER_SYSTEM_PROMPT" --model "$MODEL" -p "$PROMPT"
