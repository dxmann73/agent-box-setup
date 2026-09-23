#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

readonly domain="${CHROME_VM_DOMAIN:-chrome-vm}"
readonly qga_wait_seconds="${CHROME_VM_QGA_WAIT_SECONDS:-120}"

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

usage() {
    printf 'Usage: %s\n' "$(basename -- "$0")" >&2
    printf '%s\n' 'Start chrome-vm if needed and show its viewer.' >&2
    printf '%s\n' 'This launcher is not a URL handler.' >&2
    exit 1
}

[[ $# -eq 0 ]] || usage

[[ "$qga_wait_seconds" =~ ^[1-9][0-9]*$ ]] ||
    die "CHROME_VM_QGA_WAIT_SECONDS must be a positive integer: ${qga_wait_seconds}"

export LIBVIRT_DEFAULT_URI="${LIBVIRT_DEFAULT_URI:-qemu:///system}"

command -v virsh >/dev/null 2>&1 || die 'virsh is required'

if ! virsh dominfo "$domain" >/dev/null 2>&1; then
    die "domain does not exist: ${domain}"
fi

if [[ "$(virsh domstate "$domain")" != running ]]; then
    virsh start "$domain" || die "could not start ${domain}"
fi

ready=false
for _ in $(seq 1 "$((qga_wait_seconds / 2))"); do
    if virsh qemu-agent-command "$domain" '{"execute":"guest-ping"}' >/dev/null 2>&1; then
        ready=true
        break
    fi
    sleep 2
done
[[ "$ready" == true ]] || die "qemu-guest-agent did not become ready in ${qga_wait_seconds}s"

if ! pgrep -f -- "[v]irt-viewer( |$).*${domain}" >/dev/null 2>&1; then
    command -v virt-viewer >/dev/null 2>&1 || die 'virt-viewer is required'
    setsid -f virt-viewer --attach "$domain" >/dev/null 2>&1 ||
        die 'could not attach virt-viewer'
fi
