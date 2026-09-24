#!/usr/bin/env bash
set -Eeuo pipefail

trap 'printf "ERROR: libreoffice apply failed at line %s\n" "$LINENO" >&2' ERR
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
    printf '%s\n' 'Usage: sudo ./apply.sh'
    exit 0
fi
[[ $# -eq 0 ]] || app_die 'Usage: sudo ./apply.sh'
app_require_root

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y libreoffice
printf '%s\n' 'libreoffice applied.'
