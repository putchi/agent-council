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
  ./install.sh --platform both
  curl -fsSL https://raw.githubusercontent.com/putchi/agent-council/main/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/putchi/agent-council/main/install.sh | bash -s -- --platform claude
  curl -fsSL https://raw.githubusercontent.com/putchi/agent-council/main/install.sh | bash -s -- --platform both

Platforms:
  claude  Install as a Claude Code plugin with hooks enabled
  codex   Install to ~/.codex/skills/agent-council
  both    Install the Claude Code plugin and the Codex skill
EOF
}

PLATFORM=""

while [ $# -gt 0 ]; do
  case "$1" in
    --platform)
      if [ $# -lt 2 ]; then
        echo "Error: --platform requires claude, codex, or both." >&2
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
  echo "  1) Claude Code plugin (hooks enabled)"
  echo "  2) Codex (~/.codex/skills/agent-council)"
  echo "  3) Both"
  if ! read_prompt CHOICE "Choose 1, 2, or 3: "; then
    echo "Error: --platform claude, --platform codex, or --platform both is required when no terminal is available." >&2
    exit 1
  fi
  case "$CHOICE" in
    1) PLATFORM="claude" ;;
    2) PLATFORM="codex" ;;
    3) PLATFORM="both" ;;
    *)
      echo "Error: choose 1, 2, or 3." >&2
      exit 1
      ;;
  esac
fi

json_value() {
  local file="$1"
  local key="$2"
  python3 - "$file" "$key" <<'PY'
import json
import sys

path, key = sys.argv[1], sys.argv[2]
try:
    with open(path, encoding="utf-8") as f:
        value = json.load(f).get(key, "")
except Exception:
    value = ""
print(value)
PY
}

copy_repo_tree() {
  local target_dir="$1"
  local source_real
  local target_real=""

  source_real="$(cd "$ROOT_DIR" && pwd -P)"
  if [ -d "$target_dir" ]; then
    target_real="$(cd "$target_dir" && pwd -P)"
  fi

  if [ "$source_real" = "$target_real" ]; then
    return 0
  fi

  rm -rf "$target_dir"
  mkdir -p "$target_dir"
  (
    cd "$ROOT_DIR"
    tar -cf - --exclude .git --exclude .DS_Store .
  ) | (
    cd "$target_dir"
    tar -xf -
  )
}

chmod_skill_scripts() {
  local skill_dir="$1"
  find "$skill_dir/scripts" -type f \( -name '*.sh' -o -name '*.js' \) -exec chmod +x {} \; 2>/dev/null || true
}

install_codex_skill() {
  local on_decline="${1:-cancel}"
  local source_dir="$ROOT_DIR/skills/codex/agent-council"
  local target_dir="$HOME/.codex/skills/agent-council"

  if [ ! -d "$source_dir" ]; then
    echo "Error: source skill not found: $source_dir" >&2
    exit 1
  fi

  if [ -e "$target_dir" ]; then
    if ! read_prompt CONFIRM "Replace existing install at $target_dir? [y/N] "; then
      echo "Install cancelled."
      exit 0
    fi
    case "$CONFIRM" in
      y|Y|yes|YES) ;;
      *)
        if [ "$on_decline" = "skip" ]; then
          echo "Skipped Agent Council for codex:"
          echo "  $target_dir"
          return 0
        fi
        echo "Install cancelled."
        exit 0
        ;;
    esac
    rm -rf "$target_dir"
  fi

  mkdir -p "$(dirname "$target_dir")"
  cp -R "$source_dir" "$target_dir"

  chmod_skill_scripts "$target_dir"

  echo "Installed Agent Council for codex:"
  echo "  $target_dir"
}

update_claude_plugin_settings() {
  local settings_file="$1"
  local known_marketplaces_file="$2"
  local marketplace_dir="$3"
  local repo="${AGENT_COUNCIL_REPO:-putchi/agent-council}"

  python3 - "$settings_file" "$known_marketplaces_file" "$marketplace_dir" "$repo" <<'PY'
import datetime
import json
import os
import sys

settings_file, known_file, marketplace_dir, repo = sys.argv[1:5]

def load_json(path):
    if not os.path.exists(path):
        return {}
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}

def write_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = f"{path}.{os.getpid()}.tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    os.replace(tmp, path)

settings = load_json(settings_file)
enabled = settings.setdefault("enabledPlugins", {})
enabled["agent-council@agent-council"] = True
extra = settings.setdefault("extraKnownMarketplaces", {})
extra["agent-council"] = {
    "source": {
        "source": "github",
        "repo": repo,
    }
}
write_json(settings_file, settings)

known = load_json(known_file)
known["agent-council"] = {
    "source": {
        "source": "github",
        "repo": repo,
    },
    "installLocation": marketplace_dir,
    "lastUpdated": datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z"),
}
write_json(known_file, known)
PY
}

remove_legacy_claude_skill() {
  local legacy_dir="$HOME/.claude/skills/agent-council"

  if [ ! -e "$legacy_dir" ]; then
    return 0
  fi

  if ! read_prompt CONFIRM "Remove legacy manual Claude skill install at $legacy_dir? [y/N] "; then
    echo "Legacy manual Claude skill left in place:"
    echo "  $legacy_dir"
    return 0
  fi

  case "$CONFIRM" in
    y|Y|yes|YES)
      rm -rf "$legacy_dir"
      echo "Removed legacy manual Claude skill:"
      echo "  $legacy_dir"
      ;;
    *)
      echo "Legacy manual Claude skill left in place:"
      echo "  $legacy_dir"
      ;;
  esac
}

install_claude_plugin() {
  local on_decline="${1:-cancel}"
  local plugin_json="$ROOT_DIR/.claude-plugin/plugin.json"
  local source_skill_dir="$ROOT_DIR/skills/agent-council"
  local hooks_file="$ROOT_DIR/hooks/hooks.json"

  if [ ! -f "$plugin_json" ]; then
    echo "Error: Claude plugin manifest not found: $plugin_json" >&2
    exit 1
  fi
  if [ ! -d "$source_skill_dir" ]; then
    echo "Error: Claude plugin skill not found: $source_skill_dir" >&2
    exit 1
  fi
  if [ ! -f "$hooks_file" ]; then
    echo "Error: Claude plugin hooks not found: $hooks_file" >&2
    exit 1
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 is required to install the Claude plugin metadata." >&2
    exit 1
  fi

  local plugin_version
  plugin_version="$(json_value "$plugin_json" version)"
  if [ -z "$plugin_version" ]; then
    echo "Error: could not read version from $plugin_json" >&2
    exit 1
  fi

  local claude_dir="$HOME/.claude"
  local plugin_root="$claude_dir/plugins"
  local marketplace_dir="$plugin_root/marketplaces/agent-council"
  local cache_dir="$plugin_root/cache/agent-council/agent-council/$plugin_version"
  local settings_file="$claude_dir/settings.json"
  local known_marketplaces_file="$plugin_root/known_marketplaces.json"

  if [ -e "$marketplace_dir" ] || [ -e "$cache_dir" ]; then
    if ! read_prompt CONFIRM "Replace existing Claude plugin install for Agent Council? [y/N] "; then
      echo "Install cancelled."
      exit 0
    fi
    case "$CONFIRM" in
      y|Y|yes|YES) ;;
      *)
        if [ "$on_decline" = "skip" ]; then
          echo "Skipped Agent Council for claude:"
          echo "  $marketplace_dir"
          return 0
        fi
        echo "Install cancelled."
        exit 0
        ;;
    esac
  fi

  copy_repo_tree "$marketplace_dir"
  copy_repo_tree "$cache_dir"

  chmod_skill_scripts "$marketplace_dir/skills/agent-council"
  chmod_skill_scripts "$cache_dir/skills/agent-council"
  chmod +x "$marketplace_dir/hooks/check-update.sh" "$cache_dir/hooks/check-update.sh" 2>/dev/null || true

  update_claude_plugin_settings "$settings_file" "$known_marketplaces_file" "$marketplace_dir"
  remove_legacy_claude_skill

  echo "Installed Agent Council for claude as a Claude Code plugin:"
  echo "  $cache_dir"
  echo "Run /reload-plugins in active Claude Code sessions."
}

case "$PLATFORM" in
  claude)
    install_claude_plugin
    ;;
  codex)
    install_codex_skill
    ;;
  both)
    install_claude_plugin skip
    install_codex_skill skip
    ;;
  *)
    echo "Error: platform must be claude, codex, or both." >&2
    exit 1
    ;;
esac
