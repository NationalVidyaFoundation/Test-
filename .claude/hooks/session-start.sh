#!/bin/bash
set -uo pipefail

# Only run in remote (Claude Code on the web) sessions. Local installs of
# Claude Code already keep ~/.claude/ between sessions, so reinstalling
# every startup would be wasteful and would clobber user-level config.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

LOG_PREFIX="[session-start]"

# ---------------------------------------------------------------------------
# 1. Runtime deps for the /watch skill: ffmpeg (+ ffprobe) and yt-dlp.
#    Skips work already done in this container. Never fails the session.
# ---------------------------------------------------------------------------

install_watch_deps() {
  local need_apt=0
  if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v ffprobe >/dev/null 2>&1; then
    need_apt=1
  fi

  if [ "$need_apt" = 1 ]; then
    if command -v apt-get >/dev/null 2>&1; then
      echo "$LOG_PREFIX installing ffmpeg via apt-get ..."
      # Skip `apt-get update` — the container ships with cached package
      # lists, and a full update fails when third-party PPAs (deadsnakes,
      # ondrej) return 403 in this environment.
      if ! DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ffmpeg >/tmp/apt-install.log 2>&1; then
        echo "$LOG_PREFIX ffmpeg install failed; see /tmp/apt-install.log. Continuing." >&2
      fi
    else
      echo "$LOG_PREFIX apt-get not available; skipping ffmpeg." >&2
    fi
  fi

  if ! command -v yt-dlp >/dev/null 2>&1; then
    if command -v pip3 >/dev/null 2>&1; then
      echo "$LOG_PREFIX installing yt-dlp via pip3 ..."
      # Ubuntu 24.04 marks the system Python as PEP-668 externally-managed,
      # so --break-system-packages is required for a global install.
      if ! pip3 install --quiet --break-system-packages --upgrade yt-dlp >/tmp/pip-install.log 2>&1; then
        echo "$LOG_PREFIX yt-dlp install failed; see /tmp/pip-install.log. Continuing." >&2
      fi
    else
      echo "$LOG_PREFIX pip3 not available; skipping yt-dlp." >&2
    fi
  fi
}

install_watch_deps

# ---------------------------------------------------------------------------
# 2. GSD (get-shit-done-cc): reinstall into ~/.claude/ if absent.
# ---------------------------------------------------------------------------

GSD_MARKER="$HOME/.claude/get-shit-done/VERSION"

if [ -f "$GSD_MARKER" ]; then
  echo "$LOG_PREFIX GSD already installed ($(cat "$GSD_MARKER" 2>/dev/null || echo unknown)); skipping."
  exit 0
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "$LOG_PREFIX npx not available; skipping GSD install." >&2
  exit 0
fi

echo "$LOG_PREFIX installing get-shit-done-cc into ~/.claude/ ..."

if ! npx --yes get-shit-done-cc --claude --global >/tmp/gsd-install.log 2>&1; then
  echo "$LOG_PREFIX GSD install failed; see /tmp/gsd-install.log. Continuing." >&2
  exit 0
fi

echo "$LOG_PREFIX GSD install complete."
