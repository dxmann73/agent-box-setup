#!/usr/bin/env bash

# Verification profiles deliberately distinguish credential-free baseline state
# from host readiness and explicitly enabled integrations.
set -u -o pipefail

target=""
profile="bootstrap"
while (($#)); do
    case "$1" in
        --host) target=host ;;
        --vm) target=vm ;;
        --bootstrap) profile=bootstrap ;;
        --operational) profile=operational ;;
        --full) profile=full ;;
        -h|--help)
            cat <<'USAGE'
Usage: ./verify-setup.sh [--host|--vm] [--bootstrap|--operational|--full]

bootstrap    Credential-free deterministic readiness (default).
operational  Required host completion gate; guest credentials remain deferred.
full         Explicitly enabled credentials and optional capabilities.
USAGE
            exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
    esac
    shift
done

if [[ -z "$target" ]]; then
    if systemd-detect-virt --quiet 2>/dev/null; then target=vm; else target=host; fi
    detected=' (detected)'
else
    detected=''
fi

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/snap/bin:/bin:$PATH"
failures=0

pass() { printf '✓ %s\n' "$1"; }
fail() { printf '✗ %s\n' "$1"; failures=$((failures + 1)); }
skip() { printf '⊗ %s\n' "$1"; }
check() {
    local label="$1"; shift
    if "$@" >/dev/null 2>&1; then pass "$label"; else fail "$label"; fi
}
command_check() { check "$1" command -v "$2"; }
symlink_check() { check "$1" test -L "$2"; }
profile_at_least() {
    case "$profile:$1" in
        operational:bootstrap|operational:operational|full:bootstrap|full:operational|full:full) return 0 ;;
        bootstrap:bootstrap) return 0 ;;
        *) return 1 ;;
    esac
}

printf 'Agent Box Setup Verification — %s / %s%s\n\n' "$target" "$profile" "$detected"

printf '=== Bootstrap: system ===\n'
check 'en_US.UTF-8 generated' bash -c "locale -a | grep -Eiq '^en_US\\.(utf-?8)$'"
check 'git user.name is set' git config --includes --global --get user.name
check 'git user.email is set' git config --includes --global --get user.email
symlink_check 'WezTerm configuration linked' "$HOME/.config/wezterm/wezterm.lua"
check 'WezTerm configuration is repository source' cmp -s "$repo_dir/user-home/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"
check 'unattended upgrades enabled' grep -q '^APT::Periodic::Unattended-Upgrade "1"' /etc/apt/apt.conf.d/20auto-upgrades

printf '\n=== Bootstrap: toolchain and agents ===\n'
for binary in git curl jq yq rg node npm pnpm tsc wezterm claude codex agent pi; do
    command_check "$binary available" "$binary"
done
check 'Node.js 24 active' bash -c "node --version | grep -Eq '^v24[.]'"
check 'npm prefix is user writable' test -w "$(npm config get prefix 2>/dev/null || printf /nonexistent)"
for path in "$HOME/AGENTS.md" "$HOME/CLAUDE.md" "$HOME/.agents" \
    "$HOME/.codex/config.toml" "$HOME/.codex/hooks.json" \
    "$HOME/.cursor/hooks.json" "$HOME/.cursor/hooks" \
    "$HOME/.pi/agent/AGENTS.md"; do
    symlink_check "$(basename "$path") linked" "$path"
done
check '.agents skills resolves to repository index' \
    test "$(readlink -f "$HOME/.agents/skills" 2>/dev/null)" = "$repo_dir/agents/skills"

expected_skills=0
missing_skills=0
missing_skill_md=0
while IFS= read -r -d '' skill_dir; do
    [[ -d "$skill_dir" ]] || continue
    skill_name="$(basename "$skill_dir")"
    expected_skills=$((expected_skills + 1))
    [[ -e "$skill_dir/SKILL.md" ]] || missing_skill_md=$((missing_skill_md + 1))
    for destination in "$HOME/.claude/skills/$skill_name"; do
        [[ -e "$destination" ]] || missing_skills=$((missing_skills + 1))
    done
done < <(find -L "$repo_dir/agents/skills" -mindepth 1 -maxdepth 1 -type d -print0)
if ((expected_skills > 0 && missing_skills == 0)); then
    pass "all $expected_skills indexed skills linked for Claude Code compatibility"
else
    fail "skill links incomplete ($missing_skills missing; index has $expected_skills)"
fi
if ((expected_skills > 0 && missing_skill_md == 0)); then
    pass "all $expected_skills indexed skills have reachable SKILL.md"
else
    fail "indexed skill SKILL.md files incomplete ($missing_skill_md missing; index has $expected_skills)"
fi
check 'skill frontmatter valid' "$repo_dir/audit-skills.sh"

if [[ "$target" == vm ]]; then
    printf '\n=== Bootstrap: VM boundary ===\n'
    check 'passwordless guest sudo works' sudo -n true
    check 'sshd active' systemctl is-active --quiet ssh
    check 'sshd configuration valid' sudo sshd -t
    check 'sshd requires public-key authentication' bash -c \
        "sudo sshd -T | grep -qx 'authenticationmethods publickey'"
    check 'sshd password authentication disabled' bash -c \
        "sudo sshd -T | grep -qx 'passwordauthentication no'"
    check 'sshd keyboard-interactive authentication disabled' bash -c \
        "sudo sshd -T | grep -qx 'kbdinteractiveauthentication no'"
    check 'sshd root login disabled' bash -c "sudo sshd -T | grep -qx 'permitrootlogin no'"
    check 'sshd empty passwords disabled' bash -c \
        "sudo sshd -T | grep -qx 'permitemptypasswords no'"
    check 'QEMU guest agent active' systemctl is-active --quiet qemu-guest-agent
    check 'SPICE guest agent active' systemctl is-active --quiet spice-vdagentd
    check 'Klipper clipboard sync enabled' systemctl --user is-enabled --quiet klipper-clipboard-sync.service
    check 'BB service active' systemctl --user is-active --quiet bb.service
    command_check 'BB launcher available' bb-app
    check 'BB listens only locally' curl --fail --silent --max-time 5 http://127.0.0.1:38886/
    check 'Playwright Chromium can capture a page' npx --yes playwright@latest screenshot https://example.com /tmp/agent-box-playwright-check.png
    check 'VS Code installed' code --version
    check 'VS Code settings present' test -L "$HOME/.config/Code/User/settings.json"
    check 'VS Code keybindings present' test -L "$HOME/.config/Code/User/keybindings.json"
else
    check 'host does not have agent NOPASSWD policy' test ! -e /etc/sudoers.d/agent-nopasswd
    check 'libvirt system URI usable' virsh -c qemu:///system list
fi

if profile_at_least operational; then
    printf '\n=== Operational: required host readiness ===\n'
    if [[ "$target" == host ]]; then
        check 'GitHub CLI authenticated on host' gh auth status
        check 'Claude host credential state exists' test -f "$HOME/.claude.json"
        check 'Codex host credential state exists' test -f "$HOME/.codex/auth.json"
        check 'Cursor CLI configuration exists after login' test -f "$HOME/.cursor/cli-config.json"
        check 'Pi host credential state exists' test -f "$HOME/.pi/agent/auth.json"
        check 'Firecrawl authenticated on host' bash -c 'firecrawl --status 2>/dev/null | grep -qi authenticated'
        check 'VS Code installed' code --version
        check 'VS Code settings present' test -f "$HOME/.config/Code/User/settings.json"
        check 'VS Code keybindings present' test -f "$HOME/.config/Code/User/keybindings.json"
        check 'BB desktop AppImage executable' test -x "$HOME/Applications/bb.AppImage"
    else
        skip 'host-only completion gate; run --host --operational on the personal host'
    fi
else
    skip 'operational checks deferred; run with --operational after host completion'
fi

if profile_at_least full; then
    printf '\n=== Full: enabled credentials and optional capabilities ===\n'
    check 'GitHub CLI authenticated' gh auth status
    if [[ "$target" == vm ]]; then
        check 'Claude guest credential state exists' test -f "$HOME/.claude.json"
        check 'Codex guest credential state exists' test -f "$HOME/.codex/auth.json"
        check 'Cursor CLI configuration exists after login' test -f "$HOME/.cursor/cli-config.json"
        check 'Pi credential state exists' test -f "$HOME/.pi/agent/auth.json"
        check 'Firecrawl authentication configured' bash -c 'firecrawl --status 2>/dev/null | grep -qi authenticated'
        check 'UFW active with default inbound deny' bash -c \
            "sudo ufw status verbose | grep -q '^Default: deny (incoming)'"
        check 'guest UFW limits libvirt SSH to the hypervisor' bash -c \
            "sudo ufw status | grep -Eq '^22/tcp on [^[:space:]]+[[:space:]]+ALLOW[[:space:]]+192[.]168[.]122[.]1'"
        check 'guest secrets file linked' test -L "$HOME/.bash_secrets"
    else
        check 'host Pi credential state exists' test -f "$HOME/.pi/agent/auth.json"
    fi
else
    skip 'credential and optional-capability checks deferred; run with --full after enabling them'
fi

printf '\nResult: %d required check(s) failed.\n' "$failures"
((failures == 0))
