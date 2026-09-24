#!/usr/bin/env bash
set -Eeuo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
app_failures=0

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
    printf '%s\n' 'Usage: ./verify.sh'
    exit 0
fi
[[ $# -eq 0 ]] || app_die 'Usage: ./verify.sh'

removable_media_connected() {
    snap connections kdenlive 2>/dev/null |
        grep -Eq '^removable-media[[:space:]]+kdenlive:removable-media[[:space:]]+:removable-media'
}

app_check 'Kdenlive snap installed' app_snap_installed kdenlive
app_check 'kdenlive on PATH' app_command_available kdenlive
app_check 'Kdenlive has removable-media access' removable_media_connected
app_finish_verify kdenlive
