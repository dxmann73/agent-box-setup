#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
dev_parse_target 'Usage: ./apply.sh --target daily-host' "$@"
dev_require_target daily-host
dev_require_user
dev_require_commands cursor-agent curl
converter=$(command -v magick || command -v convert) || { echo 'Apply imaging first.' >&2; exit 1; }
repo=$(dev_repo_root)
icon_dir="$HOME/.local/share/icons/hicolor"
install -d "$icon_dir/scalable/apps" "$HOME/.local/share/applications"
curl -fsSL https://cursor.com/favicon.svg -o "$icon_dir/scalable/apps/cursor-agent.svg"
for size in 16 24 32 48 64 128 256 512; do install -d "$icon_dir/${size}x${size}/apps"; "$converter" -background none "$icon_dir/scalable/apps/cursor-agent.svg" -resize "${size}x${size}" "$icon_dir/${size}x${size}/apps/cursor-agent.png"; done
ln -sfn "$repo/user-home/applications/cursor-agent.desktop" "$HOME/.local/share/applications/cursor-agent.desktop"
command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -f -t "$icon_dir"
command -v update-desktop-database >/dev/null && update-desktop-database "$HOME/.local/share/applications"
