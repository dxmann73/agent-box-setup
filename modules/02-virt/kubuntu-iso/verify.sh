#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh

Checks the catalog Kubuntu desktop ISO: signed checksum metadata in ~/vms and the installed ISO
under /var/lib/libvirt/boot.

Environment overrides:
  KUBUNTU_ISO_VERSION   Default: 26.04.1
  KUBUNTU_ISO_WORK_DIR  Default: ~/vms
  KUBUNTU_ISO_DEST_DIR  Default: /var/lib/libvirt/boot

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

readonly iso_version="${KUBUNTU_ISO_VERSION:-26.04.1}"
readonly iso_name="kubuntu-${iso_version}-desktop-amd64.iso"
readonly work_dir="${KUBUNTU_ISO_WORK_DIR:-$HOME/vms}"
readonly dest_dir="${KUBUNTU_ISO_DEST_DIR:-/var/lib/libvirt/boot}"
readonly keyring="/usr/share/keyrings/ubuntu-archive-keyring.gpg"
readonly sums_file="${work_dir}/SHA256SUMS"
readonly sums_sig="${work_dir}/SHA256SUMS.gpg"
readonly cached_iso="${work_dir}/${iso_name}"
readonly installed_iso="${dest_dir}/${iso_name}"

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

command_available() {
    command -v "$1" >/dev/null 2>&1
}

daily_host_x86_64() {
    [[ "$(uname -m)" == x86_64 ]] || return 1
    ! systemd-detect-virt --quiet
}

signed_sums_valid() {
    gpgv --keyring "$keyring" "$sums_sig" "$sums_file" >/dev/null 2>&1
}

expected_sha() {
    awk -v file="$iso_name" '
        {
            name = $2
            sub(/^\*/, "", name)
            if (name == file) {
                print $1
                found = 1
                exit
            }
        }
        END { if (!found) exit 1 }
    ' "$sums_file"
}

sha_matches() {
    local -r file="$1"
    local expected
    local actual

    expected="$(expected_sha)" || return 1
    actual="$(sha256sum "$file" | awk '{ print $1 }')"
    [[ "$actual" == "$expected" ]]
}

dest_dir_ready() {
    [[ -d "$dest_dir" && -r "$dest_dir" && -x "$dest_dir" ]]
}

check 'daily-host x86_64' daily_host_x86_64
check 'curl available' command_available curl
check 'gpgv available' command_available gpgv
check 'sha256sum available' command_available sha256sum
check 'Ubuntu archive keyring readable' test -r "$keyring"
check '~/vms exists and is writable' test -w "$work_dir"
check 'SHA256SUMS present' test -r "$sums_file"
check 'SHA256SUMS.gpg present' test -r "$sums_sig"
check 'SHA256SUMS signature valid' signed_sums_valid
check "SHA256SUMS contains ${iso_name}" expected_sha
check 'cached ISO present' test -r "$cached_iso"
check 'cached ISO checksum valid' sha_matches "$cached_iso"
check 'libvirt boot directory readable' dest_dir_ready
check 'installed ISO present' test -r "$installed_iso"
check 'installed ISO checksum valid' sha_matches "$installed_iso"

if ((failures > 0)); then
    printf 'kubuntu-iso verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'kubuntu-iso verify passed'
