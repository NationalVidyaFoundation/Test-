#!/bin/bash
# SessionStart hook: install the notebooklm-py CLI so the `notebooklm` skill works.
# Runs only in Claude Code on the web (remote) sessions. Idempotent & non-interactive.
# Note: this installs the CLI only. Authentication (`notebooklm login`) is interactive
# and must be run once by you in a session with a browser/display.
set -euo pipefail

# Only run in the remote (web) environment.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Run in the background so session startup isn't blocked by the install.
# The CLI is only needed when the notebooklm skill is invoked, which is never
# in the first seconds of a session, so the async race window is not a concern.
echo '{"async": true, "asyncTimeout": 300000}'

# Already installed? Nothing to do (keeps resumes fast).
if command -v notebooklm >/dev/null 2>&1; then
  echo "notebooklm CLI already installed: $(notebooklm --version 2>/dev/null || echo present)"
  exit 0
fi

echo "Installing notebooklm-py[browser]..."
python -m pip install --quiet --disable-pip-version-check "notebooklm-py[browser]"

# rookiepy ([cookies] extra) fails to build on Python 3.13+; install it only where it builds.
if python -c "import sys; sys.exit(0 if sys.version_info < (3, 13) else 1)"; then
  python -m pip install --quiet --disable-pip-version-check "notebooklm-py[cookies]" || \
    echo "warn: [cookies] extra failed to install; use 'notebooklm login' interactively."
else
  echo "Skipping [cookies] extra on Python 3.13+ (rookiepy unavailable)."
fi

echo "notebooklm CLI installed. Run 'notebooklm login' once to authenticate."
