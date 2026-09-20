#!/usr/bin/env bash
set -Eeuo pipefail

failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh

Checks that the update-tools user service and timer are symlinked into
~/.config/systemd/user/ from the repo payload, and that the timer is enabled
and active.

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

module_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "$module_dir/../../.." && pwd)"
src_dir="$repo_dir/user-home/systemd"
dst_dir="$HOME/.config/systemd/user"

check_link() {
    local -r label="$1"
    local -r target="$2"
    local -r expected="$3"

    if [[ ! -L "$target" ]]; then
        printf 'not ok - %s (%s is not a symlink)\n' "$label" "$target" >&2
        failures=$((failures + 1))
        return
    fi

    local resolved
    resolved="$(readlink -f -- "$target" 2>/dev/null || true)"
    if [[ "$resolved" != "$expected" ]]; then
        printf 'not ok - %s (points to %s, expected %s)\n' \
            "$label" "$resolved" "$expected" >&2
        failures=$((failures + 1))
        return
    fi

    printf 'ok - %s\n' "$label"
}

check_systemctl_state() {
    local -r label="$1"
    local -r verb="$2"
    local -r unit="$3"
    local -r expected="$4"

    local actual
    actual="$(systemctl --user "$verb" "$unit" 2>/dev/null || true)"
    if [[ "$actual" != "$expected" ]]; then
        printf 'not ok - %s (%s %s = %s, expected %s)\n' \
            "$label" "$verb" "$unit" "$actual" "$expected" >&2
        failures=$((failures + 1))
        return
    fi

    printf 'ok - %s\n' "$label"
}

check_link 'update-tools.service linked' \
    "$dst_dir/update-tools.service" "$src_dir/update-tools.service"
check_link 'update-tools.timer linked' \
    "$dst_dir/update-tools.timer"   "$src_dir/update-tools.timer"
check_systemctl_state 'timer enabled' is-enabled update-tools.timer enabled
check_systemctl_state 'timer active'  is-active  update-tools.timer active

if ((failures > 0)); then
    printf 'update-tools-timer verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'update-tools-timer verify passed'
