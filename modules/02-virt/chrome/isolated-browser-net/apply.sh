#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

trap 'printf "ERROR: isolated-browser-net apply failed at line %s\n" "$LINENO" >&2' ERR

workdir=""

cleanup() {
    if [[ -n "$workdir" ]]; then
        rm -rf "$workdir"
    fi
}
trap cleanup EXIT

usage() {
    cat <<'USAGE'
Usage: ./apply.sh

Defines and starts the isolated libvirt NAT network for the browser VM, and installs the host
nftables guard for that network.

Required environment:
  BROWSER_NET_NAME        libvirt network name
  BROWSER_NET_BRIDGE      libvirt bridge interface name
  BROWSER_NET_ADDRESS     gateway IPv4 address
  BROWSER_NET_NETMASK     gateway IPv4 netmask
  BROWSER_NET_DHCP_START  DHCP range start
  BROWSER_NET_DHCP_END    DHCP range end

Optional environment:
  BROWSER_NET_NFT_TABLE   nftables table name; default: agent_box_${BROWSER_NET_NAME//-/_}

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

if systemd-detect-virt --quiet; then
    die "isolated-browser-net applies to daily hosts only. systemd-detect-virt reports $(systemd-detect-virt)."
fi

for variable in \
    BROWSER_NET_NAME \
    BROWSER_NET_BRIDGE \
    BROWSER_NET_ADDRESS \
    BROWSER_NET_NETMASK \
    BROWSER_NET_DHCP_START \
    BROWSER_NET_DHCP_END
do
    [[ -n "${!variable:-}" ]] || die "Missing required environment variable: ${variable}"
done

[[ "$BROWSER_NET_NAME" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]] ||
    die "Invalid BROWSER_NET_NAME: ${BROWSER_NET_NAME}"
[[ "$BROWSER_NET_BRIDGE" =~ ^[A-Za-z0-9][A-Za-z0-9_.:-]*$ ]] ||
    die "Invalid BROWSER_NET_BRIDGE: ${BROWSER_NET_BRIDGE}"

readonly net_name="$BROWSER_NET_NAME"
readonly bridge="$BROWSER_NET_BRIDGE"
readonly address="$BROWSER_NET_ADDRESS"
readonly netmask="$BROWSER_NET_NETMASK"
readonly dhcp_start="$BROWSER_NET_DHCP_START"
readonly dhcp_end="$BROWSER_NET_DHCP_END"
readonly nft_table="${BROWSER_NET_NFT_TABLE:-agent_box_${BROWSER_NET_NAME//-/_}}"

[[ "$nft_table" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] ||
    die "Invalid BROWSER_NET_NFT_TABLE: ${nft_table}"

for binary in python3 virsh nft systemctl; do
    command -v "$binary" >/dev/null 2>&1 || die "Missing required command: ${binary}"
done

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "$script_dir/../../../.." && pwd)"
hook_source="${repo_dir}/machines/host/network-guard-hook.sh"
[[ -r "$hook_source" ]] || die "Missing network guard hook source: ${hook_source}"

workdir="$(mktemp -d)"
network_xml="${workdir}/${net_name}.xml"
rules_file="${workdir}/${net_name}.nft"
render_env="${workdir}/render.env"

cat >"$render_env" <<EOF
name=${net_name}
bridge=${bridge}
address=${address}
netmask=${netmask}
dhcp_start=${dhcp_start}
dhcp_end=${dhcp_end}
nft_table=${nft_table}
EOF

python3 - "$render_env" "$network_xml" "$rules_file" <<'PY'
import html
import ipaddress
import sys
from pathlib import Path

values = {}
for line in Path(sys.argv[1]).read_text().splitlines():
    key, value = line.split('=', 1)
    values[key] = value

network = ipaddress.IPv4Network(f"{values['address']}/{values['netmask']}", strict=False)
gateway = ipaddress.IPv4Address(values['address'])
dhcp_start = ipaddress.IPv4Address(values['dhcp_start'])
dhcp_end = ipaddress.IPv4Address(values['dhcp_end'])

if gateway not in network:
    raise SystemExit('BROWSER_NET_ADDRESS is not inside its netmask-derived network')
if dhcp_start not in network or dhcp_end not in network:
    raise SystemExit('DHCP range is not inside the browser network')
if int(dhcp_start) > int(dhcp_end):
    raise SystemExit('BROWSER_NET_DHCP_START is after BROWSER_NET_DHCP_END')

xml = f'''<network ipv6="no">
  <name>{html.escape(values["name"])}</name>
  <bridge name="{html.escape(values["bridge"])}"/>
  <forward mode="nat"/>
  <ip address="{gateway}" netmask="{values["netmask"]}">
    <dhcp>
      <range start="{dhcp_start}" end="{dhcp_end}"/>
    </dhcp>
  </ip>
</network>
'''
Path(sys.argv[2]).write_text(xml)

rules = f'''destroy table inet {values["nft_table"]}

table inet {values["nft_table"]} {{
  set nonpublic_v4 {{
    type ipv4_addr
    flags interval
    elements = {{
      0.0.0.0/8,
      10.0.0.0/8,
      100.64.0.0/10,
      127.0.0.0/8,
      169.254.0.0/16,
      172.16.0.0/12,
      192.0.0.0/24,
      192.0.2.0/24,
      192.168.0.0/16,
      198.18.0.0/15,
      198.51.100.0/24,
      203.0.113.0/24,
      224.0.0.0/4,
      240.0.0.0/4
    }}
  }}

  chain from_browser_input {{
    type filter hook input priority -10; policy accept;
    iifname "{values["bridge"]}" meta nfproto ipv6 counter drop comment "drop browser IPv6 host input"
    iifname "{values["bridge"]}" ct state invalid counter drop
    iifname "{values["bridge"]}" ip saddr {{ 0.0.0.0, {network.with_prefixlen} }} ip daddr {{ {gateway}, 255.255.255.255 }} udp sport 68 udp dport 67 counter accept
    iifname "{values["bridge"]}" ip saddr != {network.with_prefixlen} counter drop comment "drop spoofed browser source"
    iifname "{values["bridge"]}" ct direction reply ct state established,related counter accept
    iifname "{values["bridge"]}" ip daddr {gateway} udp dport 53 counter accept
    iifname "{values["bridge"]}" ip daddr {gateway} tcp dport 53 counter accept
    iifname "{values["bridge"]}" counter drop comment "drop browser guest to host bridge input"
  }}

  chain from_browser_forward {{
    type filter hook forward priority -10; policy accept;
    iifname "{values["bridge"]}" meta nfproto ipv6 counter drop comment "drop browser IPv6 forwarding"
    iifname "{values["bridge"]}" ct state invalid counter drop
    iifname "{values["bridge"]}" ip saddr != {network.with_prefixlen} counter drop comment "drop spoofed browser source"
    iifname "{values["bridge"]}" ip daddr @nonpublic_v4 counter drop comment "drop browser private network egress"
    iifname "{values["bridge"]}" ct state established,related counter accept
    iifname "{values["bridge"]}" meta l4proto {{ tcp, udp }} counter accept
    oifname "{values["bridge"]}" ct state established,related counter accept
    oifname "{values["bridge"]}" counter drop comment "drop unsolicited forwarded browser ingress"
  }}
}}
'''
Path(sys.argv[3]).write_text(rules)
PY

sudo nft --check -f "$rules_file"
sudo install -d -m 0755 /etc/libvirt/network-guards /etc/libvirt/hooks/network.d
sudo install -o root -g root -m 0644 "$rules_file" "/etc/libvirt/network-guards/${net_name}.nft"
sudo install -o root -g root -m 0755 "$hook_source" "/etc/libvirt/hooks/network.d/${net_name}.guard"
sudo nft -f "/etc/libvirt/network-guards/${net_name}.nft"

if systemctl is-active --quiet virtnetworkd.service; then
    sudo systemctl restart virtnetworkd.service
elif systemctl is-active --quiet libvirtd.service; then
    sudo systemctl restart libvirtd.service
else
    die 'Neither virtnetworkd.service nor libvirtd.service is active.'
fi

if sudo virsh -c qemu:///system net-info "$net_name" >/dev/null 2>&1; then
    existing_xml="${workdir}/${net_name}.existing.xml"
    sudo virsh -c qemu:///system net-dumpxml --inactive "$net_name" >"$existing_xml"
    python3 - "$network_xml" "$existing_xml" <<'PY'
import sys
import xml.etree.ElementTree as ET

desired = ET.parse(sys.argv[1]).getroot()
existing = ET.parse(sys.argv[2]).getroot()

def text(path):
    found = existing.find(path)
    return found.text if found is not None else None

bridge = existing.find('bridge')
forward = existing.find('forward')
ip = existing.find('ip')
dhcp_range = existing.find('ip/dhcp/range')

checks = [
    existing.get('ipv6') == desired.get('ipv6'),
    text('name') == desired.findtext('name'),
    bridge is not None and bridge.get('name') == desired.find('bridge').get('name'),
    forward is not None and forward.get('mode') == desired.find('forward').get('mode'),
    ip is not None and ip.get('address') == desired.find('ip').get('address'),
    ip is not None and ip.get('netmask') == desired.find('ip').get('netmask'),
    dhcp_range is not None and dhcp_range.get('start') == desired.find('ip/dhcp/range').get('start'),
    dhcp_range is not None and dhcp_range.get('end') == desired.find('ip/dhcp/range').get('end'),
]
sys.exit(0 if all(checks) else 1)
PY
else
    sudo virsh -c qemu:///system net-define "$network_xml"
fi

if ! sudo virsh -c qemu:///system net-list --name | grep -Fxq "$net_name"; then
    sudo virsh -c qemu:///system net-start "$net_name"
fi
sudo virsh -c qemu:///system net-autostart "$net_name"

printf 'isolated-browser-net applied: %s on %s\n' "$net_name" "$bridge"
