#!/bin/bash
set -uo pipefail

# Only run in remote (Claude Code on the web) sessions. Local installs of
# Claude Code already keep ~/.claude/ between sessions, so reinstalling
# every startup would be wasteful and would clobber user-level config.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

LOG_PREFIX="[session-start]"
GSD_MARKER="$HOME/.claude/get-shit-done/VERSION"

# Idempotency: if GSD is already present (cached container layer or a
# previous run in the same container), skip the install.
if [ -f "$GSD_MARKER" ]; then
  echo "$LOG_PREFIX GSD already installed ($(cat "$GSD_MARKER" 2>/dev/null || echo unknown)); skipping."
  exit 0
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "$LOG_PREFIX npx not available; skipping GSD install." >&2
  exit 0
fi

echo "$LOG_PREFIX installing get-shit-done-cc into ~/.claude/ ..."

# Never fail the session start because of a transient network/npm issue —
# the user can re-run the install manually if it didn't take.
if ! npx --yes get-shit-done-cc --claude --global >/tmp/gsd-install.log 2>&1; then
  echo "$LOG_PREFIX GSD install failed; see /tmp/gsd-install.log. Continuing." >&2
  exit 0
fi

echo "$LOG_PREFIX GSD install complete."
