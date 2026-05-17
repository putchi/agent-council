#!/bin/bash
# Classify a question into a council type
# Returns: tech | career | business | personal
# Requires: claude CLI
# Arg: $1 = question

QUESTION="$1"
MODEL="claude-haiku-4-5-20251001"

SYSTEM="You are a classifier. Given a question, respond with exactly one word — the most appropriate council type:
- tech: software architecture, engineering decisions, tools, infrastructure, code
- career: job interviews, career moves, salary, hiring, job offers, professional development
- business: startups, products, strategy, market, fundraising, partnerships, operations
- personal: life decisions, relationships, relocation, family, personal dilemmas

Respond with only one of these four words: tech, career, business, personal. Nothing else."

if ! command -v claude &>/dev/null; then
  echo "tech"
  exit 0
fi

RESULT=$(claude --system-prompt "$SYSTEM" --model "$MODEL" -p "$QUESTION" 2>/dev/null | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')

case "$RESULT" in
  tech|career|business|personal) echo "$RESULT" ;;
  *) echo "tech" ;;
esac
