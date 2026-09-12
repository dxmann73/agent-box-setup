#!/usr/bin/env bash

# VibeTyper publishes a portable AppImage without a documented signed or
# self-updating Linux update channel. Remind the user to download and review a
# replacement instead of silently replacing an executable.

set -Eeuo pipefail

readonly message='Check VibeTyper for an update at https://vibetyper.com/downloads. Review the download before replacing ~/Applications/VibeTyper.AppImage.'

printf '%s\n' "$message"
if command -v notify-send >/dev/null 2>&1; then
    notify-send --app-name='VibeTyper' 'VibeTyper update check' "$message" || true
fi
