#!/usr/bin/env bash
set -Eeuo pipefail

failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh

Checks that apt prerequisites and the `claude` binary are present.

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

check() {
    local -r label="$1"
    shift

    if "$@"; then
        printf 'ok - %s\n' "$label"
    else
        printf 'not ok - %s\n' "$label" >&2
        failures=$((failures + 1))
    fi
}

package_installed() {
    dpkg-query -W -f='${Status}\n' "$1" 2>/dev/null | grep -q '^install ok installed$'
}

command_available() {
    command -v "$1" >/dev/null 2>&1
}

claude_prints_version() {
    claude --version >/dev/null 2>&1
}

check 'ca-certificates installed' package_installed ca-certificates
check 'curl installed' package_installed curl
check 'claude on PATH' command_available claude
check 'claude --version runs' claude_prints_version

if ((failures > 0)); then
    printf 'claude-code-bootstrap verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'claude-code-bootstrap verify passed'
