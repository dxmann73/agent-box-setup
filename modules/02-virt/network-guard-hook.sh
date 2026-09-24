#!/usr/bin/env bash
# Install as /etc/libvirt/hooks/network.d/NETWORK.guard (a root-owned copy).
# Apply its root-owned nft policy before network start and guest attachment.
# Never call virsh/libvirt from a synchronous libvirt hook.
set -Eeuo pipefail

network="$(basename -- "${BASH_SOURCE[0]}" .guard)"
[[ "$network" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]] || {
    printf 'ERROR: unexpected network guard filename.\n' >&2
    exit 1
}
[[ ${1:-} == "$network" ]] || exit 0
case "${2:-}:${3:-}" in
    start:begin|port-created:begin) ;;
    *) exit 0 ;;
esac

rules="/etc/libvirt/network-guards/$network.nft"
[[ -r "$rules" ]] || {
    printf 'ERROR: required network guard rules missing: %s\n' "$rules" >&2
    exit 1
}
exec /usr/sbin/nft -f "$rules"
