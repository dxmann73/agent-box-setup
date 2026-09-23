#!/usr/bin/env bash
set -Eeuo pipefail
trap 'printf "ERROR: wezterm apply failed at line %s\n" "$LINENO" >&2' ERR
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

usage() { printf '%s\n' 'Usage: sudo ./apply.sh --target daily-host|agent-vm'; }
if tool_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
tool_handle_parse_result "$status" usage || exit "$?"
tool_require_target || { usage >&2; exit 2; }
tool_require_sudo_user

setup_user="$SUDO_USER"
setup_home="$(getent passwd "$setup_user" | awk -F: 'NR == 1 { print $6 }')"
[[ -n "$setup_home" && -d "$setup_home" ]] || {
    printf 'Could not resolve a home directory for %s.\n' "$setup_user" >&2
    exit 1
}
setup_group="$(id -gn "$setup_user")"
module_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "$module_dir/../../.." && pwd)"
config_source="$repo_dir/user-home/wezterm/wezterm.lua"
config_target="$setup_home/.config/wezterm/wezterm.lua"
backup_dir="$setup_home/.agent-box-setup-backup"
[[ -f "$config_source" ]] || { printf 'Payload missing: %s\n' "$config_source" >&2; exit 1; }

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl gnupg
key_temp="$(mktemp)"
list_temp="$(mktemp)"
trap 'rm -f -- "$key_temp" "$list_temp"' EXIT
curl -fsSL https://apt.fury.io/wez/gpg.key | gpg --dearmor >"$key_temp"
printf '%s\n' 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' >"$list_temp"
install -d -m 0755 /etc/apt/keyrings /etc/apt/sources.list.d
install -m 0644 "$key_temp" /etc/apt/keyrings/wezterm-fury.gpg
install -m 0644 "$list_temp" /etc/apt/sources.list.d/wezterm.list
apt-get update
apt-get install -y wezterm
printf '%s\n' 'Unattended-Upgrade::Origins-Pattern {' '    "origin=wez_apt_fury_io";' '};' >"$list_temp"
install -m 0644 "$list_temp" /etc/apt/apt.conf.d/53unattended-upgrades-wezterm

install -d -o "$setup_user" -g "$setup_group" -m 0755 "$setup_home/.config/wezterm"
if [[ -L "$config_target" ]]; then
    ln -sfn "$config_source" "$config_target"
elif [[ -e "$config_target" ]]; then
    install -d -o "$setup_user" -g "$setup_group" -m 0700 "$backup_dir"
    backup_path="$backup_dir/wezterm.lua.$(date +%Y%m%d-%H%M%S)"
    mv "$config_target" "$backup_path"
    chown "$setup_user:$setup_group" "$backup_path"
    ln -s "$config_source" "$config_target"
else
    ln -s "$config_source" "$config_target"
fi
chown -h "$setup_user:$setup_group" "$config_target"
printf 'wezterm applied for %s.\n' "$tool_target"
