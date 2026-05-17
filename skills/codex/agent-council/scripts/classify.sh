#!/bin/bash
# Classify a question into a council type
# Returns: tech | career | business | personal
# Requires: codex CLI
# Arg: $1 = question

set -euo pipefail

QUESTION="${1:-}"

SYSTEM="You are a classifier. Given a question, respond with exactly one word — the most appropriate council type:
- tech: software architecture, engineering decisions, tools, infrastructure, code
- career: job interviews, career moves, salary, hiring, job offers, professional development
- business: startups, products, strategy, market, fundraising, partnerships, operations
- personal: life decisions, relationships, relocation, family, personal dilemmas

Respond with only one of these four words: tech, career, business, personal. Nothing else."

if ! command -v codex >/dev/null 2>&1; then
  echo "tech"
  exit 0
fi

PROMPT=$(printf "%s\n\nQuestion:\n%s" "$SYSTEM" "$QUESTION")
if ! RESULT=$(codex exec --ephemeral --skip-git-repo-check "$PROMPT" 2>/dev/null | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]'); then
  echo "tech"
  exit 0
fi

case "$RESULT" in
  tech|career|business|personal) echo "$RESULT" ;;
  *) echo "tech" ;;
esac
