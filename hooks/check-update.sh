#!/usr/bin/env bash
# UserPromptSubmit hook: checks once per session if a newer Agent Council
# version is available on GitHub and injects a systemMessage if so.
# All failures are silent.

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('session_id', 'unknown'))
except Exception:
    print('unknown')
" 2>/dev/null || echo "unknown")

SENTINEL="/tmp/agent-council-update-check-${SESSION_ID}"

if [ -f "$SENTINEL" ]; then
    exit 0
fi

touch "$SENTINEL" 2>/dev/null || true

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
INSTALLED_VERSION=$(python3 -c "
import json, os
root = os.environ.get('PLUGIN_ROOT', '')
path = os.path.join(root, '.claude-plugin', 'plugin.json')
try:
    with open(path) as f:
        print(json.load(f).get('version', ''))
except Exception:
    print('')
" 2>/dev/null)

if [ -z "$INSTALLED_VERSION" ]; then
    exit 0
fi

UPDATE_URL="${AGENT_COUNCIL_UPDATE_URL:-https://raw.githubusercontent.com/putchi/agent-council/main/.claude-plugin/marketplace.json}"

LATEST_JSON=$(curl -sf --max-time 5 "$UPDATE_URL" 2>/dev/null)

if [ -z "$LATEST_JSON" ]; then
    exit 0
fi

LATEST_VERSION=$(echo "$LATEST_JSON" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data['plugins'][0]['version'])
except Exception:
    print('')
" 2>/dev/null)

if [ -z "$LATEST_VERSION" ]; then
    exit 0
fi

HIGHER=$(printf '%s\n' "$INSTALLED_VERSION" "$LATEST_VERSION" | sort -V | tail -1)
if [ "$HIGHER" = "$LATEST_VERSION" ] && [ "$LATEST_VERSION" != "$INSTALLED_VERSION" ]; then
    python3 -c "
import json, sys
msg = (
    'agent-council v{latest} is available (installed: v{installed}). '
    'To update, run: /plugin update agent-council, then /reload-plugins. '
    'For manual installs, pull git@github.com-secondary:putchi/agent-council.git and rerun ./install.sh.'
).format(latest=sys.argv[1], installed=sys.argv[2])
print(json.dumps({'systemMessage': msg}))
" "$LATEST_VERSION" "$INSTALLED_VERSION"
fi

exit 0
