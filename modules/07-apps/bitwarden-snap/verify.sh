#!/usr/bin/env bash
set -Eeuo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
app_failures=0
authenticated=0

usage() {
    printf '%s\n' 'Usage: ./verify.sh [--authenticated]'
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --authenticated) authenticated=1 ;;
        -h | --help) usage; exit 0 ;;
        *) app_die "Unknown argument: $1" ;;
    esac
    shift
done

bitwarden_config_exists() {
    [[ -d $HOME/snap/bitwarden/current ]] || [[ -d $HOME/.config/Bitwarden ]]
}

app_check 'Bitwarden snap installed' app_snap_installed bitwarden
app_check 'bitwarden on PATH' app_command_available bitwarden
if ((authenticated == 1)); then
    app_check 'Bitwarden local configuration exists' bitwarden_config_exists
fi
app_finish_verify bitwarden-snap
