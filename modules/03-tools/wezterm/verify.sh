#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

usage() { printf '%s\n' 'Usage: ./verify.sh --target daily-host|agent-vm'; }
if tool_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
tool_handle_parse_result "$status" usage || exit "$?"
tool_require_target || { usage >&2; exit 2; }
[[ $EUID -ne 0 ]] || { printf '%s\n' 'Run as the normal desktop user, not with sudo.' >&2; exit 1; }
module_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "$module_dir/../../.." && pwd)"
config_source="$repo_dir/user-home/wezterm/wezterm.lua"
config_target="$HOME/.config/wezterm/wezterm.lua"
source_configured() {
    grep -qxF 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' \
        /etc/apt/sources.list.d/wezterm.list
}
config_linked() {
    [[ -L "$config_target" ]] && [[ "$(readlink -f -- "$config_target" 2>/dev/null || true)" == "$config_source" ]]
}
unattended_upgrade_allowed() {
    grep -qx 'Unattended-Upgrade::Origins-Pattern {' /etc/apt/apt.conf.d/53unattended-upgrades-wezterm &&
        grep -qx '    "origin=wez_apt_fury_io";' /etc/apt/apt.conf.d/53unattended-upgrades-wezterm
}
tool_check 'wezterm package installed' tool_package_installed wezterm
tool_check 'wezterm is on PATH' command -v wezterm
tool_check 'wezterm reports its version' wezterm --version
tool_check 'WezTerm signed apt source configured' source_configured
tool_check 'WezTerm unattended upgrades allowed' unattended_upgrade_allowed
tool_check 'managed wezterm.lua linked' config_linked
tool_finish_verify wezterm
