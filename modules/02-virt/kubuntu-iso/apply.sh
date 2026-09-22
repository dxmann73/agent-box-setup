#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

trap 'printf "ERROR: kubuntu-iso apply failed at line %s\n" "$LINENO" >&2' ERR

usage() {
    cat <<'USAGE'
Usage: ./apply.sh

Downloads the catalog Kubuntu desktop ISO, verifies Ubuntu-signed SHA256SUMS, verifies the ISO
checksum, and installs the ISO to /var/lib/libvirt/boot.

Environment overrides:
  KUBUNTU_ISO_VERSION   Default: 26.04.1
  KUBUNTU_ISO_BASE      Default: https://cdimage.ubuntu.com/kubuntu/releases/26.04/release
  KUBUNTU_ISO_WORK_DIR  Default: ~/vms
  KUBUNTU_ISO_DEST_DIR  Default: /var/lib/libvirt/boot

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
    die "kubuntu-iso downloads the amd64 desktop ISO. This machine is $(uname -m)."

if systemd-detect-virt --quiet; then
    die "kubuntu-iso applies to daily hosts only. systemd-detect-virt reports $(systemd-detect-virt)."
fi

readonly iso_version="${KUBUNTU_ISO_VERSION:-26.04.1}"
iso_series="$iso_version"
if [[ "$iso_series" =~ ^[0-9]+[.][0-9]+[.][0-9]+$ ]]; then
    iso_series="${iso_series%.*}"
fi
readonly iso_series
readonly iso_name="kubuntu-${iso_version}-desktop-amd64.iso"
readonly iso_base="${KUBUNTU_ISO_BASE:-https://cdimage.ubuntu.com/kubuntu/releases/${iso_series}/release}"
readonly work_dir="${KUBUNTU_ISO_WORK_DIR:-$HOME/vms}"
readonly dest_dir="${KUBUNTU_ISO_DEST_DIR:-/var/lib/libvirt/boot}"
readonly keyring="/usr/share/keyrings/ubuntu-archive-keyring.gpg"

[[ -d "$work_dir" && -w "$work_dir" ]] ||
    die \
        "${work_dir} is missing or not writable." \
        'Run kubuntu-baseline --target daily-host first; it owns ~/vms.'

for binary in curl gpgv sha256sum awk; do
    command -v "$binary" >/dev/null 2>&1 || die "Missing required command: ${binary}"
done

[[ -r "$keyring" ]] || die "Ubuntu archive keyring is missing or unreadable: ${keyring}"

cd "$work_dir"

curl -fLO -C - "${iso_base}/${iso_name}"
curl -fLO "${iso_base}/SHA256SUMS"
curl -fLO "${iso_base}/SHA256SUMS.gpg"

gpgv --keyring "$keyring" SHA256SUMS.gpg SHA256SUMS

expected_sha="$(
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
    ' SHA256SUMS
)" || die "SHA256SUMS does not contain ${iso_name}."

actual_sha="$(sha256sum "$iso_name" | awk '{ print $1 }')"
[[ "$actual_sha" == "$expected_sha" ]] ||
    die \
        "${iso_name} checksum mismatch." \
        "Expected: ${expected_sha}" \
        "Actual:   ${actual_sha}"

sudo install -d -o root -g root -m 0755 "$dest_dir"
sudo install -o root -g root -m 0644 "$iso_name" "${dest_dir}/${iso_name}"

printf 'kubuntu-iso applied: %s\n' "${dest_dir}/${iso_name}"
