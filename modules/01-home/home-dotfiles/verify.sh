#!/usr/bin/env bash
set -Eeuo pipefail

failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh

Checks that the managed shell dotfiles and helper scripts are symlinks pointing
at the agent-box-setup user-home payload.

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
src_dir="$repo_dir/user-home"

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

check_link '.bashrc linked'         "$HOME/.bashrc"         "$src_dir/.bashrc"
check_link '.bash_aliases linked'   "$HOME/.bash_aliases"   "$src_dir/.bash_aliases"
check_link '.profile linked'        "$HOME/.profile"        "$src_dir/.profile"
check_link 'ua.sh linked'           "$HOME/ua.sh"           "$src_dir/ua.sh"
check_link 'update-tools.sh linked' "$HOME/update-tools.sh" "$src_dir/update-tools.sh"

if ((failures > 0)); then
    printf 'home-dotfiles verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'home-dotfiles verify passed'
