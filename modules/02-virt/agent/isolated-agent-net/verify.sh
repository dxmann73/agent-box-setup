#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh

Checks the isolated libvirt NAT network for the agent VM and its host nftables guard.

Required environment:
  AGENT_NET_NAME        libvirt network name
  AGENT_NET_BRIDGE      libvirt bridge interface name
  AGENT_NET_ADDRESS     gateway IPv4 address
  AGENT_NET_NETMASK     gateway IPv4 netmask
  AGENT_NET_DHCP_START  DHCP range start
  AGENT_NET_DHCP_END    DHCP range end

Optional environment:
  AGENT_NET_NFT_TABLE   nftables table name; default: agent_box_${AGENT_NET_NAME//-/_}

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

die() {
    printf '%s\n' "$@" >&2
    exit 2
}

command_available() {
    command -v "$1" >/dev/null 2>&1
}

bare_metal_host() {
    ! systemd-detect-virt --quiet
}

required_environment_present() {
    local variable

    for variable in \
        AGENT_NET_NAME \
        AGENT_NET_BRIDGE \
        AGENT_NET_ADDRESS \
        AGENT_NET_NETMASK \
        AGENT_NET_DHCP_START \
        AGENT_NET_DHCP_END
    do
        [[ -n "${!variable:-}" ]] || return 1
    done
}

valid_identifiers() {
    [[ "${AGENT_NET_NAME:-}" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]] || return 1
    [[ "${AGENT_NET_BRIDGE:-}" =~ ^[A-Za-z0-9][A-Za-z0-9_.:-]*$ ]] || return 1
    [[ "$nft_table" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]
}

info_field() {
    local -r field="$1"

    virsh -c qemu:///system net-info "$AGENT_NET_NAME" | awk -F: -v field="$field" '
        $1 == field {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
            print $2
            exit
        }
    '
}

network_ready() {
    [[ "$(info_field Active)" == yes ]] || return 1
    [[ "$(info_field Persistent)" == yes ]] || return 1
    [[ "$(info_field Autostart)" == yes ]] || return 1
    [[ "$(info_field Bridge)" == "$AGENT_NET_BRIDGE" ]]
}

network_xml_matches() {
    local xml

    xml="$(virsh -c qemu:///system net-dumpxml "$AGENT_NET_NAME")" || return 1
    python3 -c '
import ipaddress
import os
import sys
import xml.etree.ElementTree as ET

root = ET.fromstring(sys.stdin.read())
network = ipaddress.IPv4Network(
    f"{os.environ["AGENT_NET_ADDRESS"]}/{os.environ["AGENT_NET_NETMASK"]}",
    strict=False,
)
gateway = ipaddress.IPv4Address(os.environ["AGENT_NET_ADDRESS"])
dhcp_start = ipaddress.IPv4Address(os.environ["AGENT_NET_DHCP_START"])
dhcp_end = ipaddress.IPv4Address(os.environ["AGENT_NET_DHCP_END"])
bridge = root.find("bridge")
forward = root.find("forward")
ip = root.find("ip")
dhcp_range = root.find("ip/dhcp/range")

checks = [
    gateway in network,
    dhcp_start in network,
    dhcp_end in network,
    int(dhcp_start) <= int(dhcp_end),
    not any(ip.get("family") == "ipv6" for ip in root.findall("./ip")),
    root.findtext("name") == os.environ["AGENT_NET_NAME"],
    bridge is not None and bridge.get("name") == os.environ["AGENT_NET_BRIDGE"],
    forward is not None and forward.get("mode") == "nat",
    ip is not None and ip.get("address") == str(gateway),
    ip is not None and ip.get("netmask") == os.environ["AGENT_NET_NETMASK"],
    dhcp_range is not None and dhcp_range.get("start") == str(dhcp_start),
    dhcp_range is not None and dhcp_range.get("end") == str(dhcp_end),
]
sys.exit(0 if all(checks) else 1)
' <<<"$xml"
}

guard_installed() {
    [[ -r "/etc/libvirt/network-guards/${AGENT_NET_NAME}.nft" ]] || return 1
    [[ -x "/etc/libvirt/hooks/network.d/${AGENT_NET_NAME}.guard" ]]
}

nft_policy_loaded() {
    sudo -n nft list table inet "$nft_table" >/dev/null
}

nft_policy_mentions_bridge() {
    local rules

    rules="$(sudo -n nft list table inet "$nft_table")" || return 1
    grep -Fq "iifname \"${AGENT_NET_BRIDGE}\"" <<<"$rules"
}

bridge_has_gateway() {
    ip -4 address show dev "$AGENT_NET_BRIDGE" | grep -Eq "[[:space:]]${AGENT_NET_ADDRESS}/"
}

nft_table="${AGENT_NET_NFT_TABLE:-agent_box_${AGENT_NET_NAME:-agent_net}}"
readonly nft_table="${nft_table//-/_}"

required_environment_present ||
    die \
        'Missing isolated-agent-net environment.' \
        'Export AGENT_NET_NAME, AGENT_NET_BRIDGE, AGENT_NET_ADDRESS, AGENT_NET_NETMASK,' \
        'AGENT_NET_DHCP_START and AGENT_NET_DHCP_END before running verify.sh.'

check 'daily host, not guest' bare_metal_host
check 'identifiers valid' valid_identifiers
check 'virsh available' command_available virsh
check 'nft available' command_available nft
check 'ip available' command_available ip
check 'python3 available' command_available python3
check 'system libvirt connection' virsh -c qemu:///system list --all
check 'agent network active, persistent and autostarted' network_ready
check 'agent network XML matches environment' network_xml_matches
check 'agent bridge has gateway address' bridge_has_gateway
check 'network guard files installed' guard_installed
check 'nft policy table loaded' nft_policy_loaded
check 'nft policy scoped to bridge' nft_policy_mentions_bridge

if ((failures > 0)); then
    printf 'isolated-agent-net verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'isolated-agent-net verify passed'
