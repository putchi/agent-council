#!/usr/bin/env bash
set -euo pipefail

ORIGINAL_ARGS=("$@")

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
if [ -n "$SCRIPT_PATH" ] && [ -f "$SCRIPT_PATH" ]; then
  ROOT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
else
  ROOT_DIR="$(pwd)"
fi

read_prompt() {
  local var_name="$1"
  local prompt="$2"

  if [ -r /dev/tty ] && [ -w /dev/tty ]; then
    printf "%s" "$prompt" > /dev/tty
    IFS= read -r "$var_name" < /dev/tty
  else
    printf "%s" "$prompt" >&2
    IFS= read -r "$var_name"
  fi
}

bootstrap_from_remote() {
  if [ "${AGENT_COUNCIL_BOOTSTRAPPED:-}" = "1" ]; then
    echo "Error: source skill not found after downloading Agent Council." >&2
    exit 1
  fi

  if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required for remote installation." >&2
    exit 1
  fi

  if ! command -v tar >/dev/null 2>&1; then
    echo "Error: tar is required for remote installation." >&2
    exit 1
  fi

  local repo="${AGENT_COUNCIL_REPO:-putchi/agent-council}"
  local ref="${AGENT_COUNCIL_REF:-main}"
  local archive_url="${AGENT_COUNCIL_ARCHIVE_URL:-https://codeload.github.com/${repo}/tar.gz/refs/heads/${ref}}"
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  AGENT_COUNCIL_TMP_DIR="$tmp_dir"

  cleanup() {
    rm -rf "$AGENT_COUNCIL_TMP_DIR"
  }
  trap cleanup EXIT

  echo "Downloading Agent Council from ${repo}@${ref}..."
  curl -fsSL "$archive_url" | tar -xz -C "$tmp_dir" --strip-components=1

  AGENT_COUNCIL_BOOTSTRAPPED=1 bash "$tmp_dir/install.sh" "${ORIGINAL_ARGS[@]}"
  exit $?
}

print_usage() {
  cat <<'EOF'
Usage:
  ./install.sh
  ./install.sh --platform claude
  ./install.sh --platform codex
  curl -fsSL https://raw.githubusercontent.com/putchi/agent-council/main/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/putchi/agent-council/main/install.sh | bash -s -- --platform claude

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

if [ ! -d "$ROOT_DIR/skills" ]; then
  bootstrap_from_remote
fi

if [ -z "$PLATFORM" ]; then
  echo "Install Agent Council for:"
  echo "  1) Claude Code (~/.claude/skills/agent-council)"
  echo "  2) Codex (~/.codex/skills/agent-council)"
  if ! read_prompt CHOICE "Choose 1 or 2: "; then
    echo "Error: --platform claude or --platform codex is required when no terminal is available." >&2
    exit 1
  fi
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
  if ! read_prompt CONFIRM "Replace existing install at $TARGET_DIR? [y/N] "; then
    echo "Install cancelled."
    exit 0
  fi
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
