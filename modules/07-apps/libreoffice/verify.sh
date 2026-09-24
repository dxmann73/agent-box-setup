#!/usr/bin/env bash
set -Eeuo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
app_failures=0

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
    printf '%s\n' 'Usage: ./verify.sh'
    exit 0
fi
[[ $# -eq 0 ]] || app_die 'Usage: ./verify.sh'

app_check 'LibreOffice package installed' app_package_installed libreoffice
app_check 'libreoffice on PATH' app_command_available libreoffice
app_finish_verify libreoffice
