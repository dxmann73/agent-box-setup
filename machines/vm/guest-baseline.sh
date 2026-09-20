#!/usr/bin/env bash

# Credential-free, host-invoked baseline for the agent VM.  Run it as the
# normal guest user over SSH after the short console bootstrap in 01-bootstrap.

set -Eeuo pipefail
trap 'printf "ERROR: guest baseline failed at line %s\n" "$LINENO" >&2' ERR

expected_hostname="${AGENT_BOX_VM_HOSTNAME:-$(hostname)}"
readonly expected_hostname
readonly repository_url="https://github.com/dxmann73/agent-box-setup.git"
readonly repository_dir="$HOME/projects/agent-box-setup"

[[ $EUID -ne 0 ]] || {
    printf '%s\n' 'Run this as the normal guest user, not as root.' >&2
    exit 1
}
[[ "$(hostname)" = "$expected_hostname" ]] || {
    printf 'Expected guest hostname %q; got %q. Set AGENT_BOX_VM_HOSTNAME only when checking a specific guest.\n' \
        "$expected_hostname" "$(hostname)" >&2
    exit 1
}
systemd-detect-virt --quiet || {
    printf '%s\n' 'Refusing to configure a non-virtualized machine as the guest.' >&2
    exit 1
}
sudo -n true || {
    printf '%s\n' 'Guest passwordless sudo is required before running the baseline.' >&2
    exit 1
}

export DEBIAN_FRONTEND=noninteractive
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"

ensure_nodesource() {
    if node --version 2>/dev/null | grep -Eq '^v2[4-9]\.'; then
        return
    fi
    sudo install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key |
        sudo gpg --dearmor --yes -o /etc/apt/keyrings/nodesource.gpg
    printf 'deb [arch=%s signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main\n' \
        "$(dpkg --print-architecture)" |
        sudo tee /etc/apt/sources.list.d/nodesource.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y nodejs
}

ensure_wezterm() {
    sudo install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://apt.fury.io/wez/gpg.key |
        sudo gpg --dearmor --yes -o /etc/apt/keyrings/wezterm-fury.gpg
    printf '%s\n' \
        'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' |
        sudo tee /etc/apt/sources.list.d/wezterm.list >/dev/null
    sudo chmod 0644 /etc/apt/keyrings/wezterm-fury.gpg
    sudo apt-get update
    sudo apt-get install -y wezterm
}

ensure_vscode() {
    if command -v code >/dev/null 2>&1; then
        return
    fi
    sudo apt-get install -y wget gpg apt-transport-https
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc |
        gpg --dearmor --yes |
        sudo tee /usr/share/keyrings/microsoft.gpg >/dev/null
    printf '%s\n' \
        'deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main' |
        sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y code
}

sudo apt-get update
sudo apt-get install -y \
    ca-certificates curl git gh gnupg jq yq locales openssh-server \
    build-essential pkg-config python3 python3-pip python3-venv pipx \
    htop btop tmux ripgrep fd-find docker.io \
    qemu-guest-agent spice-vdagent xclip unattended-upgrades needrestart
ensure_nodesource
ensure_wezterm
ensure_vscode

sudo systemctl enable --now ssh qemu-guest-agent spice-vdagentd
sudo usermod -aG docker "$USER"
sudo loginctl enable-linger "$USER"
sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<'CONFIG'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
CONFIG
sudo systemctl enable --now apt-daily.timer apt-daily-upgrade.timer

mkdir -p "$HOME/projects" "$HOME/.npm-global" "$HOME/.local/bin" "$HOME/.config"
npm config set prefix "$HOME/.npm-global"

if [[ ! -d "$repository_dir/.git" ]]; then
    git clone "$repository_url" "$repository_dir"
fi

cd "$repository_dir"
[[ -d agents/skills && -f user-home/.bashrc ]] || {
    printf 'Repository at %s is not an agent-box-setup checkout.\n' "$repository_dir" >&2
    exit 1
}

mkdir -p "$HOME/.config/wezterm"
ln -sfn "$repository_dir/user-home/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"
mkdir -p "$HOME/.config/Code/User"
ln -sfn "$repository_dir/user-home/vscode/settings.json" "$HOME/.config/Code/User/settings.json"
ln -sfn "$repository_dir/user-home/vscode/keybindings.json" "$HOME/.config/Code/User/keybindings.json"
for dotfile in .bashrc .bash_aliases .profile; do
    [[ -e "$HOME/$dotfile" && ! -L "$HOME/$dotfile" ]] &&
        mv "$HOME/$dotfile" "$HOME/.agent-box-setup-${dotfile#.}" || true
    ln -sfn "$repository_dir/user-home/$dotfile" "$HOME/$dotfile"
done
ln -sfn "$repository_dir/user-home/ua.sh" "$HOME/ua.sh"
ln -sfn "$repository_dir/user-home/update-tools.sh" "$HOME/update-tools.sh"
ln -sfn "$repository_dir/.markdownlint.json" "$HOME/projects/.markdownlint.json"

npm install -g corepack typescript ts-node markdownlint-cli firecrawl-cli @openai/codex
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
corepack enable --install-directory "$HOME/.local/bin"
corepack prepare pnpm@latest --activate
command -v claude >/dev/null 2>&1 || curl -fsSL https://claude.ai/install.sh | bash
command -v agent >/dev/null 2>&1 || curl -fsS https://cursor.com/install | bash
hash -r

ln -sfn "$repository_dir/agents/AGENTS.md" "$HOME/AGENTS.md"
ln -sfn "$HOME/AGENTS.md" "$HOME/CLAUDE.md"
mkdir -p "$HOME/.codex" "$HOME/.cursor" "$HOME/.claude" "$HOME/.pi/agent"

# Claude Code reads only ~/.claude/skills; Codex, Cursor and Pi read the canonical ~/.agents/skills.
# Both must reach the index through one directory-level symlink, so that every skill root underneath
# stays a real directory. BB and Codex reject a skill whose own root path is a symlink, while claude
# and cursor-agent resolve it through the kernel, making the breakage silent and partial.
# See agents/README.md.
ln -sfn "$repository_dir/agents" "$HOME/.agents"
ln -sfn "$repository_dir/agents/skills" "$HOME/.claude/skills"

# Nothing may reintroduce a per-skill symlink inside the index.
symlinked_skills="$(find "$repository_dir/agents/skills" -mindepth 1 -maxdepth 1 -type l \
    -printf '%f ')"
if [ -n "$symlinked_skills" ]; then
    printf 'ERROR: skill root(s) in agents/skills are symlinks: %s\n' "$symlinked_skills" >&2
    printf 'Replace each with a real directory; BB and Codex skip symlinked roots.\n' >&2
    exit 1
fi

ln -sfn "$repository_dir/agents/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
ln -sfn "$repository_dir/agents/codex/config.toml" "$HOME/.codex/config.toml"
ln -sfn "$repository_dir/agents/codex/hooks.json" "$HOME/.codex/hooks.json"
ln -sfn "$repository_dir/agents/cursor/hooks.json" "$HOME/.cursor/hooks.json"
ln -sfn "$repository_dir/agents/cursor/hooks" "$HOME/.cursor/hooks"
ln -sfn "$repository_dir/agents/cursor/statusline.sh" "$HOME/.cursor/statusline.sh"
ln -sfn "$repository_dir/agents/claude/settings.json" "$HOME/.claude/settings.json"
ln -sfn "$repository_dir/agents/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
"$repository_dir/agents/cursor/apply-cli-config.sh" --permissions

sudo npx --yes playwright@latest install-deps chromium
npx --yes playwright@latest install chromium

kwriteconfig6 --file powerdevilrc --group AC --group Display --key DimDisplayWhenIdle false
kwriteconfig6 --file powerdevilrc --group AC --group Display --key DimDisplayIdleTimeoutSec -- -1
kwriteconfig6 --file powerdevilrc --group AC --group Display --key TurnOffDisplayWhenIdle false
kwriteconfig6 --file powerdevilrc --group AC --group Display --key TurnOffDisplayIdleTimeoutSec -- -1
kwriteconfig6 --file kscreenlockerrc --group Daemon --key Autolock false
kwriteconfig6 --file kscreenlockerrc --group Daemon --key LockOnResume false
kwriteconfig6 --file kscreenlockerrc --group Daemon --key Timeout 0
kwriteconfig6 --file kwinrc --group ElectricBorders --key TopLeft None
kwriteconfig6 --file kwinrc --group Effect-overview --key BorderActivate ''
kwriteconfig6 --file kwinrc --group Effect-PresentWindows --key BorderActivate ''
kwriteconfig6 --file kwinrc --group Effect-PresentWindows --key BorderActivateAll ''
kwriteconfig6 --file kwinrc --group Effect-PresentWindows --key BorderActivateClass ''
qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null 2>&1 || true
sudo install -d -m 0755 /etc/sddm.conf.d
printf '[Autologin]\nUser=%s\nSession=plasma\nRelogin=false\n' "$USER" |
    sudo tee /etc/sddm.conf.d/99-autologin.conf >/dev/null

mkdir -p "$HOME/.config/systemd/user"
ln -sfn "$repository_dir/user-home/klipper-clipboard-sync.sh" "$HOME/.local/bin/klipper-clipboard-sync"
ln -sfn "$repository_dir/user-home/systemd/klipper-clipboard-sync.service" \
    "$HOME/.config/systemd/user/klipper-clipboard-sync.service"
systemctl --user daemon-reload
# Starts with the next Plasma login when the baseline runs before a session exists.
systemctl --user enable klipper-clipboard-sync.service
if systemctl --user is-active --quiet graphical-session.target; then
    systemctl --user restart klipper-clipboard-sync.service
fi

printf '%s\n' 'Guest baseline complete. No provider, GitHub, Firecrawl, model, or share credentials were requested.'
printf '%s\n' "Run: cd $repository_dir && ./verify-setup.sh --vm --bootstrap"
