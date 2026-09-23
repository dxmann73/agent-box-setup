#!/usr/bin/env bash
set -Eeuo pipefail
trap 'printf "ERROR: node-24 apply failed at line %s\n" "$LINENO" >&2' ERR
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

usage() { printf '%s\n' 'Usage: sudo ./apply.sh --target daily-host|agent-vm'; }
if lang_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
lang_handle_parse_result "$status" usage || exit "$?"
lang_require_target || { usage >&2; exit 2; }
lang_require_sudo_user

setup_user="$SUDO_USER"
setup_home="$(getent passwd "$setup_user" | awk -F: 'NR == 1 { print $6 }')"
setup_group="$(id -gn "$setup_user")"
[[ -n "$setup_home" && -d "$setup_home" ]] || {
    printf 'Could not resolve a home directory for %s.\n' "$setup_user" >&2
    exit 1
}

key_file="$(mktemp)"
source_file="$(mktemp)"
trap 'rm -f -- "$key_file" "$source_file"' EXIT
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key |
    gpg --dearmor --yes --output "$key_file"
printf 'deb [arch=%s signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main\n' \
    "$(dpkg --print-architecture)" >"$source_file"

install -d -m 0755 /etc/apt/keyrings /etc/apt/sources.list.d
install -m 0644 "$key_file" /etc/apt/keyrings/nodesource.gpg
install -m 0644 "$source_file" /etc/apt/sources.list.d/nodesource.list
lang_install_packages ca-certificates curl gnupg nodejs

install -d -o "$setup_user" -g "$setup_group" -m 0755 "$setup_home/.npm-global"
sudo -u "$setup_user" env HOME="$setup_home" npm config set prefix "$setup_home/.npm-global"
printf 'node-24 applied for %s.\n' "$lang_target"
