#!/usr/bin/env bash
# Run every locally verifiable catalog tick for one declared box.
set -Eeuo pipefail

readonly script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly repo_dir="$(cd -- "$script_dir/.." && pwd -P)"
readonly catalog="$script_dir/README.md"

box=""
phase="bootstrap"
list_only=false

usage() {
    cat <<'USAGE'
Usage: ./modules/verify-box.sh BOX [--bootstrap|--operational|--full] [--list]

BOX is one of: xhost, xagt, xchr, bhost. The tick set is read from modules/README.md.

bootstrap    Unattended and ISO-ready modules. Skips catalog login modules.
operational  Also checks login modules on daily hosts. This is the host-completion gate.
full         Also checks login modules on guests and authenticated app state.
--list       Print selected modules and commands without executing them.

Host-owned lifecycle checks are skipped on guests; run them on the daily host that owns the guest.
The catalog intentionally does not select a snapshot, backup set, overlay checkout, or remote BB
URL. Export non-secret context only when verifying the corresponding tick:

  BB_CLIENT_URL
  VIBE_TYPER_OVERLAY
  VM_SNAPSHOTS_DOMAIN VM_SNAPSHOTS_SNAPSHOT VM_SNAPSHOTS_MODE [VM_SNAPSHOTS_CURRENT=1]
  VM_DISK_BACKUP_DOMAIN VM_DISK_BACKUP_DIR VM_DISK_BACKUP_MODE

The runner never invokes an apply script and never supplies credentials.
USAGE
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 2
}

while (($#)); do
    case "$1" in
        xhost|xagt|xchr|bhost)
            [[ -z "$box" ]] || die 'pass exactly one box ID'
            box="$1"
            ;;
        --bootstrap) phase="bootstrap" ;;
        --operational) phase="operational" ;;
        --full) phase="full" ;;
        --list) list_only=true ;;
        -h|--help)
            usage
            exit 0
            ;;
        *) die "unknown argument: $1" ;;
    esac
    shift
done

[[ -n "$box" ]] || {
    usage >&2
    exit 2
}
[[ -r "$catalog" ]] || die "catalog not readable: $catalog"

case "$box" in
    xhost|bhost) target="daily-host" ;;
    xagt) target="agent-vm" ;;
    xchr) target="chrome-vm" ;;
esac

# The catalog's fixed-width grids are the sole tick source. This extracts rows from a grid headed
# by the canonical box columns, then prints MODULE<TAB>SIT for Y ticks.
mapfile -t selected < <(
    awk -v wanted="$box" '
        /^module[[:space:]]+typ[[:space:]]+sit[[:space:]]+scp[[:space:]]+xhost[[:space:]]+xagt[[:space:]]+xchr[[:space:]]+bhost[[:space:]]+requires$/ {
            active = 1
            box_column = (wanted == "xhost" ? 5 : wanted == "xagt" ? 6 : wanted == "xchr" ? 7 : 8)
            next
        }
        active && /^```$/ { active = 0; next }
        active && /^[[:alnum:]][[:alnum:]_-]*[[:space:]]+/ && $box_column == "Y" { print $1 "\t" $3 }
    ' "$catalog"
)
(( ${#selected[@]} > 0 )) || die "no catalog ticks found for $box"

include_module() {
    local -r module="$1"
    local -r sit="$2"

    case "$target:$module" in
        daily-host:bb-enroll-execution-machine|\
        agent-vm:agent-vm|agent-vm:chrome-vm|agent-vm:vm-snapshots|agent-vm:vm-disk-backup|\
        chrome-vm:agent-vm|chrome-vm:chrome-vm|chrome-vm:vm-snapshots|chrome-vm:vm-disk-backup)
            return 1
            ;;
    esac
    case "$phase:$target:$sit" in
        bootstrap:*:login|bootstrap:*:gcred) return 1 ;;
        operational:agent-vm:login|operational:agent-vm:gcred|\
        operational:chrome-vm:login|operational:chrome-vm:gcred) return 1 ;;
        *) return 0 ;;
    esac
}

skip_reason() {
    local -r module="$1"
    case "$target:$module" in
        daily-host:bb-enroll-execution-machine)
            printf '%s' 'guest-local enrollment check'
            ;;
        agent-vm:agent-vm|agent-vm:chrome-vm|agent-vm:vm-snapshots|agent-vm:vm-disk-backup|\
        chrome-vm:agent-vm|chrome-vm:chrome-vm|chrome-vm:vm-snapshots|chrome-vm:vm-disk-backup)
            printf '%s' 'host-owned lifecycle check'
            ;;
        *) printf '%s' "catalog sit: $(printf '%s' "${2:-}"); phase: $phase" ;;
    esac
}

module_dir() {
    local -r module="$1"
    local -a matches=()

    mapfile -t matches < <(find "$script_dir" -type f -path "*/$module/verify.sh" -printf '%h\n' | sort -u)
    (( ${#matches[@]} == 1 )) || die "expected one verify.sh for $module; found ${#matches[@]}"
    printf '%s\n' "${matches[0]}"
}

require_env() {
    local -r variable="$1"
    if [[ -z "${!variable:-}" && "$list_only" != true ]]; then
        die "${variable} is required to verify this catalog tick"
    fi
    return 0
}

verify_args() {
    local -r module="$1"
    local -n args_ref="$2"
    args_ref=()

    case "$module" in
        kubuntu-baseline)
            if [[ "$target" == daily-host ]]; then args_ref+=(--target daily-host); else args_ref+=(--target guest); fi
            ;;
        build-essential|fd-find|github-cli|jq|ripgrep|wezterm|yq|firecrawl-cli|node-24|pnpm|typescript|\
        claude-code|codex-cli|cursor-cli|pi|agent-config|tailscale|claude-login|codex-login|cursor-login|\
        firecrawl-login|github-auth|pi-login|tailscale-login)
            args_ref+=(--target "$target")
            ;;
        docker|java-stack|k8s-stack|bb-enroll-execution-machine|playwright-chromium)
            args_ref+=(--target agent-vm)
            ;;
        imaging|cursor-agent-launcher|vscode|vscode-java-extensions|vscode-remote-ssh|setup-agent-login)
            args_ref+=(--target daily-host)
            ;;
        vscode-settings-sync)
            args_ref+=(--target daily-host --confirmed)
            ;;
        bitwarden-chrome|personal-browser-logins)
            args_ref+=(--target chrome-vm --confirmed)
            ;;
        virtiofs-desktop-share|virtiofs-user-data-shares)
            if [[ "$target" == daily-host ]]; then args_ref+=(--host); else args_ref+=(--guest); fi
            ;;
        bb-client)
            require_env BB_CLIENT_URL
            args_ref+=(--target daily-host --url "${BB_CLIENT_URL:-<BB_CLIENT_URL>}")
            ;;
        vibe-typer)
            require_env VIBE_TYPER_OVERLAY
            args_ref+=(--overlay "${VIBE_TYPER_OVERLAY:-<VIBE_TYPER_OVERLAY>}")
            ;;
        vm-snapshots)
            require_env VM_SNAPSHOTS_DOMAIN
            require_env VM_SNAPSHOTS_SNAPSHOT
            require_env VM_SNAPSHOTS_MODE
            args_ref=(--domain "${VM_SNAPSHOTS_DOMAIN:-<VM_SNAPSHOTS_DOMAIN>}" --snapshot "${VM_SNAPSHOTS_SNAPSHOT:-<VM_SNAPSHOTS_SNAPSHOT>}" --mode "${VM_SNAPSHOTS_MODE:-<VM_SNAPSHOTS_MODE>}")
            if [[ "${VM_SNAPSHOTS_CURRENT:-}" == 1 ]]; then args_ref+=(--current); fi
            ;;
        vm-disk-backup)
            require_env VM_DISK_BACKUP_DOMAIN
            require_env VM_DISK_BACKUP_DIR
            require_env VM_DISK_BACKUP_MODE
            args_ref=(--domain "${VM_DISK_BACKUP_DOMAIN:-<VM_DISK_BACKUP_DOMAIN>}" --backup-dir "${VM_DISK_BACKUP_DIR:-<VM_DISK_BACKUP_DIR>}" --mode "${VM_DISK_BACKUP_MODE:-<VM_DISK_BACKUP_MODE>}")
            ;;
        bitwarden-snap|dropbox-client)
            if [[ "$phase" == full ]]; then args_ref+=(--authenticated); fi
            ;;
    esac
}

failures=0
for entry in "${selected[@]}"; do
    IFS=$'\t' read -r module sit <<<"$entry"
    if ! include_module "$module" "$sit"; then
        printf 'SKIP %s (%s)\n' "$module" "$(skip_reason "$module" "$sit")"
        continue
    fi

    dir="$(module_dir "$module")"
    declare -a args=()
    verify_args "$module" args
    printf 'RUN  %s/verify.sh' "${dir#$repo_dir/}"
    if (( ${#args[@]} > 0 )); then printf ' %q' "${args[@]}"; fi
    printf '\n'
    if [[ "$list_only" == true ]]; then continue; fi
    if ! (cd "$dir" && ./verify.sh "${args[@]}"); then
        failures=$((failures + 1))
    fi
done

if ((failures > 0)); then
    printf 'verify-box failed: %d module verifier(s) failed\n' "$failures" >&2
    exit 1
fi
printf 'verify-box passed for %s / %s\n' "$box" "$phase"
