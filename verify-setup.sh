#!/bin/bash

# Agent Box Setup Verification Script
# Run this to verify all components are properly installed

# Target profile: host (Ubuntu desktop) or vm (agent VM). See README.md.
PROFILE=""
while [ $# -gt 0 ]; do
    case "$1" in
        --host) PROFILE="host" ;;
        --vm)   PROFILE="vm" ;;
        -h|--help)
            echo "Usage: $0 [--host|--vm]"
            echo "  --host  verify the Ubuntu host (GPU, local model runtime)"
            echo "  --vm    verify the agent VM (Playwright, shared folders)"
            echo "  (omitted: detected via systemd-detect-virt)"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Usage: $0 [--host|--vm]" >&2
            exit 2
            ;;
    esac
    shift
done

if [ -z "$PROFILE" ]; then
    if systemd-detect-virt --quiet 2>/dev/null; then
        PROFILE="vm"
    else
        PROFILE="host"
    fi
    DETECTED=" (detected)"
else
    DETECTED=""
fi

echo "========================================="
echo "  Agent Box Setup Verification"
echo "  Profile: $PROFILE$DETECTED"
echo "========================================="
echo ""

# Load nvm and SDKMAN in this non-interactive script when present.
[ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh"
[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ] && . "$HOME/.sdkman/bin/sdkman-init.sh"

# Count top-level entries while excluding known metadata files.
count_entries() {
    find "$1" -mindepth 1 -maxdepth 1 ! -name 'AGENTS.md' 2>/dev/null | wc -l
}

# Agent Binaries
echo "=== Agent Binaries ==="
claude --version 2>/dev/null && echo "✓ Claude Code installed" || echo "✗ Claude Code missing"
agent --version 2>/dev/null && echo "✓ Cursor CLI Agent installed" || echo "✗ Cursor CLI Agent missing"
codex --version 2>/dev/null && echo "✓ Codex installed" || echo "✗ Codex missing"
if [ -L ~/.codex/config.toml ]; then
    echo "✓ ~/.codex/config.toml symlinked"
elif [ -f ~/.codex/config.toml ]; then
    echo "✗ ~/.codex/config.toml exists but is NOT a symlink"
else
    echo "✗ ~/.codex/config.toml missing"
fi
if [ -f ~/.codex/config.toml ]; then
    if rg -n '^[[:space:]]*codex_hooks[[:space:]]*=' ~/.codex/config.toml >/dev/null 2>&1; then
        echo "✗ ~/.codex/config.toml uses deprecated [features].codex_hooks"
    elif rg -n '^[[:space:]]*hooks[[:space:]]*=[[:space:]]*true$' ~/.codex/config.toml >/dev/null 2>&1; then
        echo "✓ ~/.codex/config.toml enables [features].hooks"
    else
        echo "✗ ~/.codex/config.toml missing [features].hooks = true"
    fi
fi
if [ -L ~/.codex/hooks.json ]; then
    echo "✓ ~/.codex/hooks.json symlinked"
elif [ -f ~/.codex/hooks.json ]; then
    echo "✗ ~/.codex/hooks.json exists but is NOT a symlink"
else
    echo "✗ ~/.codex/hooks.json missing"
fi
echo ""

# Home Directory Symlinks
echo "=== Home Directory Symlinks ==="
for dotfile in .bashrc .bash_aliases .profile .gitconfig .bash_secrets ua.sh; do
    if [ -L ~/"$dotfile" ]; then
        echo "✓ ~/$dotfile symlinked"
    elif [ -f ~/"$dotfile" ]; then
        echo "✗ ~/$dotfile exists but is NOT a symlink"
    else
        echo "✗ ~/$dotfile missing"
    fi
done
if [ -L ~/projects/.markdownlint.json ]; then
    echo "✓ ~/projects/.markdownlint.json symlinked"
elif [ -f ~/projects/.markdownlint.json ]; then
    echo "✗ ~/projects/.markdownlint.json exists but is NOT a symlink"
else
    echo "✗ ~/projects/.markdownlint.json missing"
fi
echo ""

# Agent Configuration
echo "=== Agent Configuration ==="
test -L ~/AGENTS.md && echo "✓ ~/AGENTS.md symlink exists" || echo "✗ ~/AGENTS.md missing"
test -L ~/CLAUDE.md && echo "✓ ~/CLAUDE.md symlink exists" || echo "✗ ~/CLAUDE.md missing"
test -L ~/.claude/settings.json && echo "✓ Claude settings linked" || echo "✗ Claude settings missing"
if [ -L ~/.agents ]; then
    echo "✓ ~/.agents symlinked"
elif [ -d ~/.agents ]; then
    echo "✗ ~/.agents exists but is NOT a symlink"
else
    echo "✗ ~/.agents missing"
fi
echo ""

# Caveman hooks
echo "=== Caveman Hooks ==="
if [ -L ~/.codex/hooks.json ]; then
    echo "✓ Codex hooks.json symlinked"
else
    echo "✗ Codex hooks.json missing or not a symlink"
fi
if [ -L ~/.cursor/hooks.json ] && [ -L ~/.cursor/hooks ]; then
    echo "✓ Cursor hooks.json + hooks/ symlinked"
else
    echo "✗ Cursor hooks.json / hooks/ missing or not symlinks"
fi
if [ -x ~/.cursor/hooks/caveman.sh ] &&
    echo '{"session_id":"verify","is_background_agent":false}' |
    ~/.cursor/hooks/caveman.sh 2>/dev/null | grep -q additional_context; then
    echo "✓ Cursor caveman sessionStart hook returns context"
else
    echo "✗ Cursor caveman sessionStart hook not working"
fi
echo ""

# Skills
echo "=== Skills ==="
skills_source_dir="$(dirname "$0")/agents/skills"
expected_skills=()
for skill_path in "$skills_source_dir"/*/; do
    [ -d "$skill_path" ] || continue
    expected_skills+=("$(basename "$skill_path")")
done
expected_skill_count=${#expected_skills[@]}
claude_skills=$(count_entries ~/.claude/skills)
cursor_skills=$(count_entries ~/.cursor/skills)
agent_skills=$(count_entries ~/.agents/skills)
echo "Expected skills from source: $expected_skill_count directories"
echo "Claude skills: $claude_skills directories"
echo "Cursor skills: $cursor_skills directories"
echo "Agent skills: $agent_skills directories"

skills_missing=0
for target_dir in ~/.claude/skills ~/.cursor/skills ~/.agents/skills; do
    for skill in "${expected_skills[@]}"; do
        if [ ! -e "$target_dir/$skill" ]; then
            echo "✗ Missing skill '$skill' in $target_dir"
            skills_missing=1
        fi
    done
    while IFS= read -r broken_link; do
        [ -n "$broken_link" ] || continue
        echo "✗ Broken skill link '$(basename "$broken_link")' in $target_dir"
        skills_missing=1
    done < <(find "$target_dir" -maxdepth 1 -xtype l 2>/dev/null)
done

if [ "$expected_skill_count" -eq 0 ]; then
    echo "✗ No source skills found in $skills_source_dir"
elif [ "$skills_missing" -eq 0 ]; then
    echo "✓ Skills configured and synced to source"
else
    echo "✗ Skills missing or incomplete vs source"
fi
echo ""

# Core Tools
echo "=== Core Tools ==="
gh --version >/dev/null 2>&1 && echo "✓ GitHub CLI installed" || echo "✗ GitHub CLI missing"
gh auth status >/dev/null 2>&1 && echo "✓ GitHub CLI authenticated" || echo "✗ GitHub CLI not authenticated"
jq --version >/dev/null 2>&1 && echo "✓ jq installed" || echo "✗ jq missing"
docker --version >/dev/null 2>&1 && echo "✓ Docker installed" || echo "✗ Docker missing"
echo ""

# Search Tools
echo "=== Search Tools ==="
rg --version >/dev/null 2>&1 && echo "✓ ripgrep installed" || echo "✗ ripgrep missing"
echo ""

# Development Environment
echo "=== Development Environment ==="
hash -r 2>/dev/null || true
if node --version >/dev/null 2>&1; then
    echo "✓ Node.js installed: $(node --version) ($(command -v node))"
    case "$(command -v node)" in
        "$HOME"/.nvm/*)
            echo "⊗ Node comes from nvm; systemd user services and non-interactive shells will not see it"
            echo "  (see machines/common/03-dev-environment.md — install Node from apt instead)"
            ;;
    esac
else
    echo "✗ Node.js missing"
fi
npm_prefix="$(npm config get prefix 2>/dev/null)"
if [ -n "$npm_prefix" ] && [ -w "$npm_prefix" ]; then
    echo "✓ npm global prefix writable without sudo: $npm_prefix"
else
    echo "✗ npm global prefix needs root: ${npm_prefix:-unknown} (npm config set prefix ~/.npm-global)"
fi
npm --version >/dev/null 2>&1 && echo "✓ npm installed" || echo "✗ npm missing"
tsc --version >/dev/null 2>&1 && echo "✓ TypeScript installed" || echo "✗ TypeScript missing"
if pnpm --version >/dev/null 2>&1; then
    echo "✓ pnpm installed: $(pnpm --version) ($(command -v pnpm))"
elif corepack pnpm --version >/dev/null 2>&1; then
    echo "⊗ pnpm shim missing (run: corepack enable)"
else
    echo "✗ pnpm missing"
fi
if markdownlint --version >/dev/null 2>&1; then
    echo "✓ markdownlint installed"
elif npx --yes markdownlint-cli --version >/dev/null 2>&1; then
    echo "⊗ markdownlint not installed globally; npx fallback works"
else
    echo "✗ markdownlint unavailable"
fi
if firecrawl --version >/dev/null 2>&1; then
    echo "✓ Firecrawl CLI installed"
    firecrawl_status="$(firecrawl --status 2>/dev/null || true)"
    if echo "$firecrawl_status" | grep -qi "not authenticated"; then
        echo "✗ Firecrawl CLI not authenticated (run: firecrawl login --browser)"
    elif echo "$firecrawl_status" | grep -qi "authenticated"; then
        echo "✓ Firecrawl CLI authenticated"
    else
        echo "✗ Firecrawl auth status unclear (run: firecrawl --status)"
    fi
else
    echo "✗ Firecrawl CLI missing"
fi
if [ "$PROFILE" = "vm" ]; then
    if npx --yes playwright --version >/dev/null 2>&1; then
        echo "✓ Playwright installed"
    else
        echo "✗ Playwright missing (run: npx --yes playwright@latest install chromium)"
    fi
fi
sdk version >/dev/null 2>&1 && echo "✓ SDKMAN installed" || echo "✗ SDKMAN missing"
if grep -q "sdkman_auto_env=true" ~/.sdkman/etc/config 2>/dev/null; then
    echo "✓ SDKMAN auto-env enabled"
else
    echo "✗ SDKMAN auto-env disabled (set sdkman_auto_env=true in ~/.sdkman/etc/config)"
fi
java --version >/dev/null 2>&1 && echo "✓ Java installed" || echo "✗ Java missing"
mvn --version >/dev/null 2>&1 && echo "✓ Maven installed" || echo "✗ Maven missing"
quarkus --version >/dev/null 2>&1 && echo "✓ Quarkus installed" || echo "✗ Quarkus missing"
if [ -f ~/.redhat/io.quarkus.analytics.localconfig ]; then
    if grep -q '"disabled":false' ~/.redhat/io.quarkus.analytics.localconfig 2>/dev/null; then
        echo "✓ Quarkus build analytics enabled"
    else
        echo "✗ Quarkus build analytics disabled (enable: echo '{\"disabled\":false}' > ~/.redhat/io.quarkus.analytics.localconfig)"
    fi
else
    echo "✗ Quarkus build analytics not configured (will prompt interactively)"
fi
echo ""

# Editor (see machines/common/04-ide+tooling.md)
echo "=== Editor (VS Code) ==="
if code --version >/dev/null 2>&1; then
    echo "✓ VS Code installed: $(code --version | head -1)"
else
    echo "✗ VS Code missing"
fi

# The live user config sits next to the UI: in $HOME natively, on the Windows side under WSL.
vscode_user_dir=""
if [ -d "$HOME/.config/Code/User" ]; then
    vscode_user_dir="$HOME/.config/Code/User"
else
    win_code_dirs=(/mnt/c/Users/*/AppData/Roaming/Code/User)
    if [ "${#win_code_dirs[@]}" -eq 1 ] && [ -d "${win_code_dirs[0]}" ]; then
        vscode_user_dir="${win_code_dirs[0]}"
    elif [ "${#win_code_dirs[@]}" -gt 1 ]; then
        echo "✗ several Windows profiles carry a VS Code config; refusing to guess:"
        printf '    %s\n' "${win_code_dirs[@]}"
    fi
fi

if [ -z "$vscode_user_dir" ]; then
    echo "✗ no VS Code user config directory found"
elif ! command -v jq >/dev/null 2>&1; then
    echo "✗ jq missing, cannot compare the live VS Code config against the repo copy"
else
    echo "✓ VS Code user config: $vscode_user_dir"
    vscode_ref_dir="$(dirname "$0")/user-home/vscode"
    # Strip // line comments so the JSONC reference files parse as JSON.
    strip_jsonc() { sed 's|^[[:space:]]*//.*$||' "$1"; }

    if [ ! -f "$vscode_user_dir/settings.json" ]; then
        echo "✗ settings.json absent from the live config (Settings Sync off and never copied?)"
    else
        settings_drift=$(jq -n \
            --argjson ref  "$(strip_jsonc "$vscode_ref_dir/settings.json")" \
            --argjson live "$(strip_jsonc "$vscode_user_dir/settings.json")" \
            '[$ref | to_entries[] | select($live[.key] != .value) | .key] | join(", ")' -r 2>/dev/null)
        if [ -z "$settings_drift" ]; then
            echo "✓ live settings.json carries every key from user-home/vscode/settings.json"
        else
            echo "✗ settings.json drift, live value missing or different: $settings_drift"
        fi
    fi

    if [ ! -f "$vscode_user_dir/keybindings.json" ]; then
        echo "✗ keybindings.json absent from the live config"
    else
        keys_drift=$(jq -n \
            --argjson ref  "$(strip_jsonc "$vscode_ref_dir/keybindings.json")" \
            --argjson live "$(strip_jsonc "$vscode_user_dir/keybindings.json")" \
            '[$ref[] | select(. as $b | ($live | index([$b])) == null) | .key] | join(", ")' -r 2>/dev/null)
        if [ -z "$keys_drift" ]; then
            echo "✓ live keybindings.json carries every binding from user-home/vscode/keybindings.json"
        else
            echo "✗ keybindings.json drift, binding missing or different: $keys_drift"
        fi
    fi
fi
echo ""

# Automatic updates (see machines/common/08-auto-updates.md)
echo "=== Automatic Updates ==="
if dpkg -s unattended-upgrades >/dev/null 2>&1; then
    echo "✓ unattended-upgrades installed"
else
    echo "✗ unattended-upgrades missing (sudo apt install -y unattended-upgrades)"
fi
if [ -f /etc/apt/apt.conf.d/20auto-upgrades ] \
   && grep -q '^APT::Periodic::Unattended-Upgrade "1"' /etc/apt/apt.conf.d/20auto-upgrades; then
    echo "✓ unattended upgrades enabled"
else
    echo "✗ unattended upgrades not enabled (sudo dpkg-reconfigure -plow unattended-upgrades)"
fi
if [ -f /etc/apt/apt.conf.d/52unattended-upgrades-local ]; then
    echo "✓ local unattended-upgrades policy present"
else
    echo "✗ /etc/apt/apt.conf.d/52unattended-upgrades-local missing (see machines/common/08-auto-updates.md)"
fi
if systemctl is-enabled --quiet apt-daily-upgrade.timer 2>/dev/null; then
    echo "✓ apt-daily-upgrade.timer enabled"
else
    echo "✗ apt-daily-upgrade.timer not enabled"
fi
dpkg -s needrestart >/dev/null 2>&1 && echo "✓ needrestart installed" || echo "⊗ needrestart not installed (optional but recommended)"
if [ -L ~/update-tools.sh ] || [ -x ~/update-tools.sh ]; then
    echo "✓ update-tools.sh present"
else
    echo "✗ ~/update-tools.sh missing (see machines/common/00-home-environment.md)"
fi
if systemctl --user is-enabled --quiet update-tools.timer 2>/dev/null; then
    echo "✓ weekly tooling update timer enabled"
else
    echo "✗ update-tools.timer not enabled (see machines/common/08-auto-updates.md section 3)"
fi
if [ -f /var/run/reboot-required ]; then
    echo "⊗ reboot pending: $(tr '\n' ' ' < /var/run/reboot-required.pkgs 2>/dev/null)"
fi
echo ""

# Imaging Tools
echo "=== Imaging Tools ==="
if command -v magick >/dev/null 2>&1; then
    echo "✓ ImageMagick (magick)"
elif command -v convert >/dev/null 2>&1 && convert -version 2>/dev/null | grep -qi "ImageMagick"; then
    echo "✓ ImageMagick (convert)"
else
    echo "✗ ImageMagick missing"
fi
sharp --help >/dev/null 2>&1 && echo "✓ sharp CLI" || echo "✗ sharp CLI missing"
npm_root="$(npm root -g 2>/dev/null)"
if [ -n "$npm_root" ] && NODE_PATH="$npm_root" node -e "require('sharp')" >/dev/null 2>&1; then
    echo "✓ sharp module"
else
    echo "✗ sharp module missing"
fi
if [ -n "$npm_root" ] && NODE_PATH="$npm_root" node -e "require('@resvg/resvg-js')" >/dev/null 2>&1; then
    echo "✓ resvg module"
else
    echo "✗ resvg module missing"
fi
command -v pngquant >/dev/null 2>&1 && echo "✓ pngquant" || echo "⊗ pngquant (optional)"
command -v exiftool >/dev/null 2>&1 && echo "✓ exiftool" || echo "⊗ exiftool (optional)"
command -v optipng >/dev/null 2>&1 && echo "✓ optipng" || echo "⊗ optipng (optional)"
command -v ffmpeg >/dev/null 2>&1 && echo "✓ ffmpeg" || echo "✗ ffmpeg missing"
command -v inkscape >/dev/null 2>&1 && echo "✓ inkscape" || echo "✗ inkscape missing"
command -v gm >/dev/null 2>&1 && echo "✓ graphicsmagick (gm)" || echo "✗ graphicsmagick (gm) missing"
echo ""

# Host-only: GPU stack and local model runtime (see machines/host/01-hardware-validation.md, local-llm/)
if [ "$PROFILE" = "host" ]; then
    echo "=== Host: GPU and local model ==="
    if lspci -k 2>/dev/null | grep -A4 -E 'VGA|Display' | grep -q 'amdgpu'; then
        echo "✓ amdgpu kernel driver in use"
    else
        echo "✗ amdgpu kernel driver not reported by lspci"
    fi
    if command -v vulkaninfo >/dev/null 2>&1; then
        if vulkaninfo --summary >/dev/null 2>&1; then
            echo "✓ Vulkan works"
        else
            echo "✗ vulkaninfo present but fails"
        fi
    else
        echo "✗ vulkan-tools missing (sudo apt install -y vulkan-tools)"
    fi
    if [ "$LIBVIRT_DEFAULT_URI" = "qemu:///system" ]; then
        echo "✓ LIBVIRT_DEFAULT_URI=qemu:///system"
    else
        echo "✗ LIBVIRT_DEFAULT_URI is '${LIBVIRT_DEFAULT_URI:-unset}'; virsh will address the session daemon (see machines/host/05-hypervisor.md section 3)"
    fi
    if command -v virsh >/dev/null 2>&1 && virsh -c qemu:///system list >/dev/null 2>&1; then
        echo "✓ libvirt reachable without sudo"
        if virsh -c qemu:///system dominfo agent-vm >/dev/null 2>&1; then
            echo "✓ agent-vm defined: $(virsh -c qemu:///system domstate agent-vm 2>/dev/null)"
            if virsh -c qemu:///system dumpxml agent-vm 2>/dev/null | grep -q pflash; then
                echo "⊗ agent-vm boots UEFI; BIOS is assumed by the snapshot/backup steps (machines/host/05-hypervisor.md section 5)"
            else
                echo "✓ agent-vm boots BIOS, no NVRAM file to track"
            fi
            if virsh -c qemu:///system dumpxml agent-vm 2>/dev/null | grep -q "access mode='shared'"; then
                echo "✓ shared memory backing present (virtiofs shares can attach)"
            else
                echo "✗ no shared memory backing; virtiofs shares will not attach (machines/host/05-hypervisor.md section 5)"
            fi
        else
            echo "⊗ agent-vm not defined yet (see machines/host/05-hypervisor.md)"
        fi
    else
        echo "⊗ libvirt/KVM not usable (sudo apt install -y qemu-kvm libvirt-daemon-system virtinst; usermod -aG libvirt,kvm)"
    fi
    if command -v virtiofsd >/dev/null 2>&1 || [ -x /usr/libexec/virtiofsd ]; then
        echo "✓ virtiofsd present"
    else
        echo "⊗ virtiofsd missing (needed for shared folders: sudo apt install -y virtiofsd)"
    fi
    echo ""
fi

# VM-only: sandbox plumbing (see machines/vm/01-bootstrap.md, machines/vm/06-shared-folders.md)
if [ "$PROFILE" = "vm" ]; then
    echo "=== VM: sandbox plumbing ==="
    if [ -f /etc/sudoers.d/agent-nopasswd ]; then
        echo "✓ passwordless sudo configured (agent user is root in the VM, by design)"
    else
        echo "✗ /etc/sudoers.d/agent-nopasswd missing (see machines/vm/01-bootstrap.md)"
    fi
    if systemctl is-active --quiet ssh; then
        echo "✓ sshd running (ssh agent-vm from the host)"
    else
        echo "✗ sshd not running (sudo apt install -y openssh-server)"
    fi
    if [ "$(hostname)" = "agent-vm" ]; then
        echo "✓ hostname is agent-vm, so libnss-libvirt resolves it from the host"
    else
        echo "⊗ hostname is '$(hostname)', not agent-vm; ssh agent-vm will not resolve"
    fi
    if systemctl is-active --quiet qemu-guest-agent; then
        echo "✓ qemu-guest-agent active"
    else
        echo "✗ qemu-guest-agent not active (sudo apt install -y qemu-guest-agent)"
    fi
    if systemctl is-active --quiet sddm; then
        echo "✓ Plasma display manager running"
    else
        echo "⊗ sddm not active (a desktop guest is expected, see machines/vm/01-bootstrap.md)"
    fi
    if systemctl is-active --quiet spice-vdagentd; then
        echo "✓ spice-vdagent active (SPICE console clipboard)"
    else
        echo "✗ spice-vdagentd not active (sudo apt install -y spice-vdagent)"
    fi
    if dpkg -s krdp >/dev/null 2>&1; then
        echo "⊗ krdp installed; this setup deliberately exposes no RDP listener (see machines/vm/01-bootstrap.md section 3)"
    fi
    virtiofs_mounts=$(findmnt -t virtiofs -no TARGET 2>/dev/null | tr '\n' ' ')
    if [ -n "$virtiofs_mounts" ]; then
        echo "✓ virtiofs shares mounted: $virtiofs_mounts"
    else
        echo "⊗ no virtiofs share mounted (no host directories shared)"
    fi
    if [ -d ~/.ssh ] && [ -n "$(ls -A ~/.ssh 2>/dev/null)" ]; then
        echo "✓ VM has its own ~/.ssh contents"
    else
        echo "✗ no SSH key in the VM (see machines/vm/05-credentials.md)"
    fi
    echo ""
fi

# Optional Tools
echo "=== Optional Tools ==="
helm version >/dev/null 2>&1 && echo "✓ Helm installed" || echo "⊗ Helm not installed (optional)"
kubectl version --client >/dev/null 2>&1 && echo "✓ kubectl installed" || echo "⊗ kubectl not installed (optional)"
minikube version >/dev/null 2>&1 && echo "✓ Minikube installed" || echo "⊗ Minikube not installed (optional)"
echo ""

echo "========================================="
echo "  Verification Complete"
echo "========================================="
echo ""
echo "Legend:"
echo "  ✓ = Installed and configured"
echo "  ✗ = Missing (required)"
echo "  ⊗ = Not installed (optional)"
echo ""
echo "To fix missing components, see SETUP.md, agents/README.md, machines/common/*.md and machines/$PROFILE/*.md"
