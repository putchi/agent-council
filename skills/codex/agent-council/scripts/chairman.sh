#!/bin/bash
# Chairman: synthesizes all member responses into a final decision with Codex.
# Args: $1 = original question, $2 = all member outputs
# Requires: codex CLI
# Env: CHAIRMAN_SYSTEM

set -euo pipefail

QUESTION="${1:-}"
MEMBER_OUTPUTS="${2:-}"
SYSTEM_PROMPT="${CHAIRMAN_SYSTEM:-You are the Chairman of an expert council. Synthesize the member responses into one clear, decisive final answer. Identify consensus and conflicts. Give your verdict with reasoning. Be direct. No fluff.}"

if ! command -v codex >/dev/null 2>&1; then
  echo "Error: codex CLI not found. Install and authenticate the Codex CLI first." >&2
  exit 1
fi

# Use printf to correctly handle newlines in content
CONTENT=$(printf "You are the Chairman of an Agent Council.\n\nChairman instructions:\n%s\n\n---\nOriginal question:\n%s\n\n---\nCouncil member responses:\n\n%s\n\n---\nProvide the final synthesis and verdict. Identify consensus, disagreements, material risks, and the recommended path forward." "$SYSTEM_PROMPT" "$QUESTION" "$MEMBER_OUTPUTS")

codex exec --ephemeral --skip-git-repo-check "$CONTENT"
