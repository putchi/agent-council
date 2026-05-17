#!/bin/bash
# Agent Council - multi-domain runner
# Usage: ./run-council.sh [--council tech|career|business|personal] "question"
#
# --council   : skip classification, use specified council type
# Requires: codex CLI installed and authenticated

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COUNCIL_TYPE=""
QUESTION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --council)
      if [ $# -lt 2 ]; then
        echo "Error: --council requires one of: tech, career, business, personal" >&2
        exit 1
      fi
      COUNCIL_TYPE="$2"
      shift 2
      ;;
    *)
      QUESTION="$1"
      shift
      ;;
  esac
done

if [ -z "$QUESTION" ]; then
  echo "Usage: run-council.sh [--council tech|career|business|personal] \"question\"" >&2
  exit 1
fi

# Validate codex CLI is available
if ! command -v codex >/dev/null 2>&1; then
  echo "Error: codex CLI not found. Install and authenticate the Codex CLI first." >&2
  exit 1
fi

# Auto-classify if no council specified
if [ -z "$COUNCIL_TYPE" ]; then
  echo "🔍 Classifying question..." >&2
  COUNCIL_TYPE=$(bash "$SCRIPT_DIR/classify.sh" "$QUESTION")
  echo "→ Council: $COUNCIL_TYPE" >&2
  echo "" >&2
fi

COUNCIL_FILE="$SCRIPT_DIR/councils/${COUNCIL_TYPE}.sh"

if [ ! -f "$COUNCIL_FILE" ]; then
  echo "Error: unknown council type '$COUNCIL_TYPE'" >&2
  echo "Available: $(ls "$SCRIPT_DIR/councils/"*.sh | xargs -n1 basename | sed 's/.sh//' | tr '\n' ' ')" >&2
  exit 1
fi

source "$COUNCIL_FILE"

echo "========================================"
echo "  COUNCIL : $COUNCIL_TYPE"
echo "  MODE    : Codex CLI"
echo "  Q: $QUESTION"
echo "========================================"
echo ""

COMBINED=""

for ENTRY in "${MEMBERS[@]}"; do
  ROLE="${ENTRY%%:*}"
  EMOJI="${ENTRY##*:}"
  SCRIPT="$SCRIPT_DIR/member-${COUNCIL_TYPE}-${ROLE}.sh"

  if [ ! -f "$SCRIPT" ]; then
    echo "Warning: $SCRIPT not found, skipping" >&2
    continue
  fi

  echo ">>> $EMOJI $ROLE is thinking..."
  if ! RESPONSE=$(bash "$SCRIPT" "$QUESTION" 2>&1); then
    RESPONSE=$(printf "Error while running %s:\n%s" "$ROLE" "$RESPONSE")
  fi
  echo ""
  echo "--- $EMOJI $ROLE ---"
  echo "$RESPONSE"
  echo ""
  COMBINED="${COMBINED}[$ROLE]\n${RESPONSE}\n\n"
done

echo "========================================"
echo "  👑 CHAIRMAN - Final Synthesis"
echo "========================================"
echo ""

export CHAIRMAN_SYSTEM="$CHAIRMAN_PROMPT"
bash "$SCRIPT_DIR/chairman.sh" "$QUESTION" "$(printf "%b" "$COMBINED")"

echo ""
echo "========================================"
