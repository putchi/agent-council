#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_usage() {
  cat <<'EOF'
Usage:
  ./install.sh
  ./install.sh --platform claude
  ./install.sh --platform codex

Platforms:
  claude  Install to ~/.claude/skills/agent-council
  codex   Install to ~/.codex/skills/agent-council
EOF
}

PLATFORM=""

while [ $# -gt 0 ]; do
  case "$1" in
    --platform)
      if [ $# -lt 2 ]; then
        echo "Error: --platform requires claude or codex." >&2
        exit 1
      fi
      PLATFORM="$2"
      shift 2
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo "Error: unknown argument: $1" >&2
      print_usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$PLATFORM" ]; then
  echo "Install Agent Council for:"
  echo "  1) Claude Code (~/.claude/skills/agent-council)"
  echo "  2) Codex (~/.codex/skills/agent-council)"
  printf "Choose 1 or 2: "
  read -r CHOICE
  case "$CHOICE" in
    1) PLATFORM="claude" ;;
    2) PLATFORM="codex" ;;
    *)
      echo "Error: choose 1 or 2." >&2
      exit 1
      ;;
  esac
fi

case "$PLATFORM" in
  claude)
    SOURCE_DIR="$ROOT_DIR/skills/claude/agent-council"
    TARGET_DIR="$HOME/.claude/skills/agent-council"
    ;;
  codex)
    SOURCE_DIR="$ROOT_DIR/skills/codex/agent-council"
    TARGET_DIR="$HOME/.codex/skills/agent-council"
    ;;
  *)
    echo "Error: platform must be claude or codex." >&2
    exit 1
    ;;
esac

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: source skill not found: $SOURCE_DIR" >&2
  exit 1
fi

if [ -e "$TARGET_DIR" ]; then
  printf "Replace existing install at %s? [y/N] " "$TARGET_DIR"
  read -r CONFIRM
  case "$CONFIRM" in
    y|Y|yes|YES) ;;
    *)
      echo "Install cancelled."
      exit 0
      ;;
  esac
  rm -rf "$TARGET_DIR"
fi

mkdir -p "$(dirname "$TARGET_DIR")"
cp -R "$SOURCE_DIR" "$TARGET_DIR"

find "$TARGET_DIR/scripts" -type f \( -name '*.sh' -o -name '*.js' \) -exec chmod +x {} \; 2>/dev/null || true

echo "Installed Agent Council for $PLATFORM:"
echo "  $TARGET_DIR"
