#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

trap 'printf "ERROR: kvm apply failed at line %s\n" "$LINENO" >&2' ERR

workdir=""
backup_dir=""

cleanup() {
    if [[ -n "$workdir" ]]; then
        rm -rf "$workdir"
    fi
}
trap cleanup EXIT

usage() {
    cat <<'USAGE'
Usage: ./apply.sh

Installs the daily-host KVM/libvirt stack, joins the current user to libvirt and kvm, and ensures
the stock default network, default storage pool, resolver modules, and libvirt-guests shutdown
policy.

Options:
  -h, --help   Show this help
USAGE
}

die() {
    printf '%s\n' "$@" >&2
    exit 1
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

[[ $EUID -ne 0 ]] || die 'Run as the normal user; the script uses sudo where needed.'

sudo -n true 2>/dev/null ||
    die \
        'sudo credentials are not cached.' \
        'Start the host-sudo-session babysit terminal or run sudo -v, then retry.'

[[ "$(uname -m)" == x86_64 ]] ||
    die "kvm installs qemu-system-x86. This machine is $(uname -m)."

if systemd-detect-virt --quiet; then
    die "kvm applies to daily hosts only. systemd-detect-virt reports $(systemd-detect-virt)."
fi

[[ -n "${HOME:-}" && -d "$HOME/vms" && -w "$HOME/vms" ]] ||
    die \
        "$HOME/vms is missing or not writable." \
        'Run kubuntu-baseline --target daily-host first; it owns ~/vms.'

readonly -a packages=(
    cpu-checker
    qemu-system-x86
    libvirt-daemon-system
    libvirt-clients
    virtinst
    virt-manager
    virt-viewer
    virtiofsd
    libnss-libvirt
)

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"

if ! kvm-ok; then
    die 'kvm-ok failed. Enable virtualization in firmware, then rerun.'
fi

sudo usermod -aG libvirt,kvm "$USER"
sudo systemctl enable --now libvirtd.service

workdir="$(mktemp -d)"

backup_file() {
    local -r file="$1"

    if [[ -z "$backup_dir" ]]; then
        backup_dir="/var/backups/agent-box-setup-kvm-$(date +%Y%m%d-%H%M%S)"
        sudo install -d -m 0700 "$backup_dir"
    fi
    sudo cp -a --parents "$file" "$backup_dir"
}

install_if_changed() {
    local -r destination="$1"
    local -r mode="$2"
    local -r source="$3"

    if sudo cmp -s "$source" "$destination"; then
        return 0
    fi
    backup_file "$destination"
    sudo install -o root -g root -m "$mode" "$source" "$destination"
}

ensure_nsswitch() {
    local line
    local field
    local new_line
    local -a fields
    local -a rebuilt
    local new_file="${workdir}/nsswitch.conf"
    local count

    count="$(awk '$1 == "hosts:" { n++ } END { print n + 0 }' /etc/nsswitch.conf)"
    [[ "$count" == 1 ]] || die "Expected one hosts: line in /etc/nsswitch.conf, found ${count}."

    line="$(awk '$1 == "hosts:" { print; exit }' /etc/nsswitch.conf)"
    read -r -a fields <<<"$line"
    [[ "${fields[0]}" == "hosts:" && "${fields[1]}" == "files" ]] ||
        die "hosts: line does not start with 'hosts: files': ${line}"

    rebuilt=("hosts:" "files" "libvirt" "libvirt_guest")
    for field in "${fields[@]:2}"; do
        [[ "$field" == "libvirt" || "$field" == "libvirt_guest" ]] && continue
        rebuilt+=("$field")
    done
    new_line="${rebuilt[*]}"
    [[ "$new_line" == "$line" ]] && return 0

    awk -v replacement="$new_line" '
        $1 == "hosts:" && !replaced {
            print replacement
            replaced = 1
            next
        }
        { print }
        END { if (!replaced) exit 1 }
    ' /etc/nsswitch.conf >"$new_file"

    install_if_changed /etc/nsswitch.conf 0644 "$new_file"
}

ensure_guest_shutdown() {
    local -r source_file="/etc/default/libvirt-guests"
    local -r new_file="${workdir}/libvirt-guests"
    local line
    local shutdown_count=0
    local boot_count=0

    [[ -f "$source_file" ]] || die "${source_file} is missing after the libvirt install."

    : >"$new_file"
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == ON_SHUTDOWN=* ]]; then
            shutdown_count=$((shutdown_count + 1))
            line="ON_SHUTDOWN=suspend"
        elif [[ "$line" == ON_BOOT=* ]]; then
            boot_count=$((boot_count + 1))
            if [[ "$line" != "ON_BOOT=ignore" ]]; then
                line="ON_BOOT=ignore"
            fi
        fi
        printf '%s\n' "$line" >>"$new_file"
    done <"$source_file"

    if ((shutdown_count > 1)); then
        die "${source_file} has more than one ON_SHUTDOWN= line."
    fi
    if ((boot_count > 1)); then
        die "${source_file} has more than one ON_BOOT= line."
    fi
    if ((shutdown_count == 0)); then
        printf '%s\n' 'ON_SHUTDOWN=suspend' >>"$new_file"
    fi

    install_if_changed "$source_file" 0644 "$new_file"
}

virsh_names_contain() {
    local -r name="$1"
    shift
    local line

    while IFS= read -r line; do
        [[ "$line" == "$name" ]] && return 0
    done < <(sudo virsh -c qemu:///system "$@")
    return 1
}

xml_matches() {
    local -r pattern="$1"
    shift
    local xml

    xml="$(sudo virsh -c qemu:///system "$@")"
    grep -Eq "$pattern" <<<"$xml"
}

ensure_default_pool() {
    local target

    if ! sudo virsh -c qemu:///system pool-info default >/dev/null 2>&1; then
        if [[ ! -d /var/lib/libvirt/images ]]; then
            sudo install -d -o root -g root -m 0755 /var/lib/libvirt/images
        fi
        sudo virsh -c qemu:///system pool-define-as default dir --target /var/lib/libvirt/images
    fi

    target="$(
        sudo virsh -c qemu:///system pool-dumpxml default | awk '
            /<target>/ { in_target = 1 }
            in_target && match($0, /<path>[^<]+<\/path>/) {
                text = substr($0, RSTART + 6, RLENGTH - 13)
                print text
                exit
            }
        '
    )"
    [[ "$target" == /var/lib/libvirt/images ]] ||
        die \
            "default pool target is '${target:-<missing>}', expected /var/lib/libvirt/images." \
            'Refusing to redefine it.'

    if ! virsh_names_contain default pool-list --name; then
        sudo virsh -c qemu:///system pool-start default
    fi
    sudo virsh -c qemu:///system pool-autostart default
}

ensure_default_network() {
    local -r stock_xml="/usr/share/libvirt/networks/default.xml"

    if ! sudo virsh -c qemu:///system net-info default >/dev/null 2>&1; then
        [[ -f "$stock_xml" ]] || die "Stock network XML is missing: ${stock_xml}"
        sudo virsh -c qemu:///system net-define "$stock_xml"
    fi

    xml_matches "name=['\"]virbr0['\"]" net-dumpxml default ||
        die \
            'default network bridge is not virbr0.' \
            'Refusing to redefine it. A guest may still be attached.'
    xml_matches "address=['\"]192\\.168\\.122\\.1['\"]" net-dumpxml default ||
        die \
            'default network address is not 192.168.122.1.' \
            'Refusing to redefine it. A guest may still be attached.'
    xml_matches "<forward[[:space:]]*/>|<forward[[:space:]][^>]*mode=['\"]nat['\"]" \
        net-dumpxml default ||
        die \
            'default network is not NAT.' \
            'Refusing to redefine it. A guest may still be attached.'

    if ! virsh_names_contain default net-list --name; then
        sudo virsh -c qemu:///system net-start default
    fi
    sudo virsh -c qemu:///system net-autostart default
}

session_has_group() {
    local -r group="$1"
    local current

    while IFS= read -r current; do
        [[ "$current" == "$group" ]] && return 0
    done < <(id -nG | tr ' ' '\n')
    return 1
}

ensure_nsswitch
ensure_guest_shutdown
ensure_default_pool
ensure_default_network

# enable --now starts the unit only when it is inactive. Do not restart
# libvirt-guests: its stop action managed-saves every running guest.
sudo systemctl enable --now libvirt-guests.service

if session_has_group libvirt && session_has_group kvm; then
    printf '%s\n' 'kvm applied.'
else
    printf '%s\n' \
        'kvm applied. Group membership is recorded, but this session does not have it yet.' \
        'Log out and back in, then run ./verify.sh.'
fi

if [[ -n "$backup_dir" ]]; then
    printf 'Backups: %s\n' "$backup_dir"
fi
