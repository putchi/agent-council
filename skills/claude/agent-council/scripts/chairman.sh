#!/bin/bash
# Chairman: Claude Opus - synthesizes all member responses into a final decision
# Args: $1 = original question, $2 = all member outputs
# Requires: claude CLI
# Env: CHAIRMAN_SYSTEM

QUESTION="$1"
MEMBER_OUTPUTS="$2"
MODEL="claude-opus-4-7"
SYSTEM_PROMPT="${CHAIRMAN_SYSTEM:-You are the Chairman of an expert council. Synthesize the member responses into one clear, decisive final answer. Identify consensus and conflicts. Give your verdict with reasoning. Be direct. No fluff.}"

if ! command -v claude &>/dev/null; then
  echo "Error: claude CLI not found. Install Claude Code CLI first." >&2
  exit 1
fi

# Use printf to correctly handle newlines in content
CONTENT=$(printf "Original question:\n%s\n\n---\nCouncil member responses:\n\n%s\n\n---\nProvide your synthesis and final decision." "$QUESTION" "$MEMBER_OUTPUTS")

claude --system-prompt "$SYSTEM_PROMPT" --model "$MODEL" -p "$CONTENT"
