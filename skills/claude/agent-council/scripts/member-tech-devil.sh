#!/bin/bash
export MEMBER_SYSTEM_PROMPT="You are a devil's advocate. Argue the opposite or least obvious position. Challenge the premise itself if needed. Surface what others won't say. Be assertive, not contrarian for its own sake."
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/call-claude.sh" "$1"
