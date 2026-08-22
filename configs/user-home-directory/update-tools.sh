#!/usr/bin/env bash
#
# Update the tooling that apt does not manage: global npm packages, the coding
# agent CLIs, and SDKMAN candidates.
#
# Deliberately excluded: T3 Code. Its client and server must stay on the same
# version, so it is updated by hand on both ends together. See
# common/08-auto-updates.md and vm/04-t3code.md.
#
# Symlinked to ~/update-tools.sh; run weekly by a systemd user timer.

set -Eeuo pipefail

# Non-interactive shells (systemd timers) get none of ~/.bashrc, so put the
# usual tool locations on PATH explicitly.
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

failed=()

log()  { printf '\n=== %s\n' "$*"; }
warn() { printf '!!! %s\n' "$*" >&2; }

# Run a step, record the failure, and keep going: one dead upstream must not
# stop the rest of the updates.
step() {
    local name="$1"; shift
    log "$name"
    if "$@"; then
        return 0
    fi
    warn "$name failed"
    failed+=("$name")
    return 0
}

have() { command -v "$1" >/dev/null 2>&1; }

npm_globals() {
    have npm || { warn "npm not on PATH"; return 1; }

    # The global prefix is user-owned (~/.npm-global, see
    # common/03-dev-environment.md) precisely so this needs no root and can run
    # from an unattended timer.
    local npm_root
    npm_root="$(npm root -g)"
    if [ ! -w "$npm_root" ]; then
        warn "global npm dir $npm_root is not writable; set a user-owned prefix (npm config set prefix ~/.npm-global)"
        return 1
    fi

    npm update -g
    npm outdated -g --depth=0 || true
}

claude_code() {
    have claude || { echo "claude not installed, skipping"; return 0; }
    claude update
}

cursor_cli() {
    have cursor-agent || { echo "cursor-agent not installed, skipping"; return 0; }
    cursor-agent update
}

codex_cli() {
    have codex || { echo "codex not installed, skipping"; return 0; }
    have npm || return 1
    npm install -g @openai/codex@latest
}

sdkman() {
    [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ] || { echo "SDKMAN not installed, skipping"; return 0; }
    # SDKMAN's own functions read unset variables throughout, so -u and -e stay
    # off for the whole block, not just for the sourcing.
    set +ue
    # shellcheck disable=SC1091
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    sdk selfupdate
    sdk update
    local rc=$?
    set -ue
    return "$rc"
}

playwright_browsers() {
    have npx || return 0
    [ -d "$HOME/.cache/ms-playwright" ] || { echo "Playwright not installed, skipping"; return 0; }
    npx --yes playwright@latest install chromium
}

log "$(date '+%Y-%m-%d %H:%M') updating tooling on $(hostname)"

step "global npm packages" npm_globals
step "Claude Code"         claude_code
step "Cursor CLI"          cursor_cli
step "Codex"               codex_cli
step "SDKMAN"              sdkman
step "Playwright browsers" playwright_browsers

log "T3 Code: skipped on purpose — update the desktop app and the VM server together"

if [ ${#failed[@]} -gt 0 ]; then
    log "FAILED: ${failed[*]}"
    exit 1
fi

log "all tooling updated"
