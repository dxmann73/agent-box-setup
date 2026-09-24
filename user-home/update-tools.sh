#!/usr/bin/env bash
#
# Update the tooling that apt does not manage: global npm packages, Claude Code,
# Codex, Cursor CLI, Pi, and SDKMAN candidates.
#
# The host BB AppImage manages its own updates.
#
# Symlinked to ~/update-tools.sh; run weekly by a systemd user timer.

set -Eeuo pipefail

# Non-interactive shells (systemd timers) get none of ~/.bashrc, so put the
# usual tool locations on PATH explicitly.
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/snap/bin:/bin:$PATH"

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
    have agent || { echo "Cursor CLI not installed, skipping"; return 0; }
    agent update
}

codex_cli() {
    have codex || { echo "Codex not installed, skipping"; return 0; }
    have npm || return 1
    npm install -g @openai/codex@latest
}

pi_cli() {
    have pi || { echo "Pi not installed, skipping"; return 0; }
    pi update --self
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
step "Codex"               codex_cli
step "Cursor CLI"          cursor_cli
step "Pi"                  pi_cli
step "SDKMAN"              sdkman
step "Playwright browsers" playwright_browsers

if [ ${#failed[@]} -gt 0 ]; then
    log "FAILED: ${failed[*]}"
    exit 1
fi

log "all tooling updated"
