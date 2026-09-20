#!/usr/bin/env bash
set -Eeuo pipefail

failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh

Checks that markdownlint is on PATH, ~/projects/.markdownlint.json is a symlink
into the repo, and markdownlint --version runs.

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
src_file="$repo_dir/.markdownlint.json"
dst_file="$HOME/projects/.markdownlint.json"

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

check_command() {
    local -r label="$1"
    local -r bin="$2"

    if ! command -v "$bin" >/dev/null 2>&1; then
        printf 'not ok - %s (%s not on PATH)\n' "$label" "$bin" >&2
        failures=$((failures + 1))
        return
    fi

    printf 'ok - %s\n' "$label"
}

check_runs() {
    local -r label="$1"
    shift

    if ! "$@" >/dev/null 2>&1; then
        printf 'not ok - %s (%s failed)\n' "$label" "$*" >&2
        failures=$((failures + 1))
        return
    fi

    printf 'ok - %s\n' "$label"
}

check_command 'markdownlint on PATH' markdownlint
check_link    '.markdownlint.json linked' "$dst_file" "$src_file"
check_runs    'markdownlint --version runs' markdownlint --version

if ((failures > 0)); then
    printf 'markdownlint verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'markdownlint verify passed'
