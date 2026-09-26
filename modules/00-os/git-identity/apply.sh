#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

trap 'printf "ERROR: git-identity apply failed at line %s\n" "$LINENO" >&2' ERR

target=""
source_file=""
vm_host=""

usage() {
    cat <<'USAGE'
Usage: ./apply.sh --target daily-host --source PATH
       ./apply.sh --target agent-vm --source PATH --vm-host HOST

Installs one real ~/.gitconfig file from the deployment overlay payload.

  --target daily-host   Write $HOME/.gitconfig on this box.
  --target agent-vm     Run on the daily host; stream the same file to the agent
                        VM over the libvirt-bridge SSH path.
  --source PATH         Overlay .gitconfig to install; no default. In this
                        deployment: ~/projects/dave.box-setup/agent-box/user-home/.gitconfig
  --vm-host HOST        SSH destination of the agent VM; required for --target agent-vm.
  -h, --help            Show this help

The installed path is a regular file, never a symlink, so that `gh auth setup-git`
and other tools can write to it without touching a repository working tree. An
existing symlink is removed; an existing regular file with different content is
moved into ~/.agent-box-setup-backup/ first.

This module does not write credential helpers. Run `gh auth setup-git` on each box
after apply.
USAGE
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target | --source | --vm-host)
            [[ $# -ge 2 ]] || die "$1 requires a value"
            case "$1" in
                --target) target="$2" ;;
                --source) source_file="$2" ;;
                --vm-host) vm_host="$2" ;;
            esac
            shift 2
            ;;
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

case "$target" in
    daily-host | agent-vm) ;;
    *)
        printf '%s\n' 'Use --target daily-host or agent-vm.' >&2
        usage >&2
        exit 2
        ;;
esac

[[ -n "$source_file" ]] || die '--source is required'
[[ -f "$source_file" ]] || die "source .gitconfig not found: $source_file"
grep -q '^\[user\]' "$source_file" || die "source has no [user] section: $source_file"
git config --file "$source_file" --get user.name >/dev/null || die "source has no user.name: $source_file"
git config --file "$source_file" --get user.email >/dev/null || die "source has no user.email: $source_file"

[[ $EUID -ne 0 ]] || die 'Run as the normal user; this module writes only under $HOME.'

if [[ "$target" == agent-vm ]]; then
    [[ -n "$vm_host" ]] || die '--vm-host is required for --target agent-vm'
    command -v ssh >/dev/null 2>&1 || die 'Missing required command: ssh'

    ssh -o BatchMode=yes -o ConnectTimeout=10 "$vm_host" 'true' \
        || die "cannot reach $vm_host over SSH without a prompt; check ssh-add -l on this host"

    remote_script='
set -eu
umask 022
backup_dir="$HOME/.agent-box-setup-backup"
tmp="$(mktemp "$HOME/.gitconfig.XXXXXX")"
cat >"$tmp"
if [ -L "$HOME/.gitconfig" ]; then
    rm -f "$HOME/.gitconfig"
elif [ -f "$HOME/.gitconfig" ] && ! cmp -s "$tmp" "$HOME/.gitconfig"; then
    mkdir -p "$backup_dir"
    mv "$HOME/.gitconfig" "$backup_dir/.gitconfig"
fi
mv "$tmp" "$HOME/.gitconfig"
chmod 0644 "$HOME/.gitconfig"
command -v git >/dev/null 2>&1 || { printf "ERROR: git is missing on the guest\n" >&2; exit 1; }
git config --file "$HOME/.gitconfig" --get user.email >/dev/null
printf "git-identity: wrote %s on %s\n" "$HOME/.gitconfig" "$(hostname)"
'

    ssh -o BatchMode=yes "$vm_host" "$remote_script" < "$source_file" \
        || die "failed to install ~/.gitconfig on $vm_host"

    printf 'git-identity applied for agent-vm (%s). Run `gh auth setup-git` on the guest.\n' "$vm_host"
    exit 0
fi

dst="$HOME/.gitconfig"
backup_dir="$HOME/.agent-box-setup-backup"

if [[ -L "$dst" ]]; then
    rm -f "$dst"
elif [[ -f "$dst" ]] && ! cmp -s "$source_file" "$dst"; then
    mkdir -p "$backup_dir"
    mv "$dst" "$backup_dir/.gitconfig"
fi

install -m 0644 "$source_file" "$dst"

printf 'git-identity applied for daily-host (%s). Run `gh auth setup-git` on this box.\n' "$dst"
