#!/usr/bin/env bash
set -euo pipefail

pi_bin="$HOME/.npm-global/bin/pi"
if [[ ! -x "$pi_bin" ]]; then
    notify-send "Pi launcher" "Pi is not installed at $pi_bin"
    exit 1
fi

exec wezterm start --always-new-process --class pi-agent --cwd "$HOME/projects" -- "$pi_bin"
