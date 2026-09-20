#!/usr/bin/env bash
set -Eeuo pipefail

trap 'printf "ERROR: clone-agent-box-setup apply failed at line %s\n" "$LINENO" >&2' ERR

usage() {
    cat <<'USAGE'
Usage: ./apply.sh

Installs git via apt-get if it is missing. The first-ever clone of this repository is done by hand
per START-HERE.md; this script only runs from inside an existing checkout, so it does not clone.

Options:
  -h, --help   Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h | --help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown argument: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

[[ $EUID -ne 0 ]] || {
    printf '%s\n' 'Run as the normal user; the checkout lives under $HOME.' >&2
    exit 1
}

if command -v git >/dev/null 2>&1; then
    printf '%s\n' 'git already on PATH; skipping apt-get install.'
else
    sudo apt-get update
    sudo apt-get install -y git
fi

printf '%s\n' 'clone-agent-box-setup applied.'
