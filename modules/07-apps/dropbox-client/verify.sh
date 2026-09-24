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

app_check 'Dropbox package installed' app_package_installed dropbox
app_check 'dropbox on PATH' app_command_available dropbox
if ((authenticated == 1)); then
    app_check 'Dropbox directory exists' test -d "$HOME/Dropbox"
fi
app_finish_verify dropbox-client
