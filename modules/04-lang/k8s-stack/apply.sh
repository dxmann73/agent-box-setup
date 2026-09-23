#!/usr/bin/env bash
set -Eeuo pipefail
trap 'printf "ERROR: k8s-stack apply failed at line %s\n" "$LINENO" >&2' ERR
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

usage() { printf '%s\n' 'Usage: sudo ./apply.sh --target agent-vm'; }
if lang_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
lang_handle_parse_result "$status" usage || exit "$?"
lang_require_agent_vm || { usage >&2; exit 2; }
lang_require_sudo_user

kubernetes_minor='v1.37'
helm_key_id='DDF78C3E6EBB2D2CC223C95C62BA89D07698DBC6'
kubernetes_key="$(mktemp)"
helm_key="$(mktemp)"
minikube_package="$(mktemp --suffix=.deb)"
trap 'rm -f -- "$kubernetes_key" "$helm_key" "$minikube_package"' EXIT

lang_install_packages ca-certificates curl gnupg
install -d -m 0755 /etc/apt/keyrings /usr/share/keyrings /etc/apt/sources.list.d

curl -fsSL "https://pkgs.k8s.io/core:/stable:/${kubernetes_minor}/deb/Release.key" |
    gpg --dearmor --yes --output "$kubernetes_key"
install -m 0644 "$kubernetes_key" /etc/apt/keyrings/kubernetes-apt-keyring.gpg
printf 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/%s/deb/ /\n' \
    "$kubernetes_minor" >/etc/apt/sources.list.d/kubernetes.list
chmod 0644 /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey >"$helm_key"
actual_helm_key_id="$(gpg --show-keys --with-colons "$helm_key" | awk -F: '$1 == "fpr" { print $10; exit }')"
[[ "$actual_helm_key_id" == "$helm_key_id" ]] || {
    printf 'Unexpected Helm apt key fingerprint: %s\n' "$actual_helm_key_id" >&2
    exit 1
}
gpg --dearmor --yes --output /usr/share/keyrings/helm.gpg "$helm_key"
printf '%s\n' 'deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main' \
    >/etc/apt/sources.list.d/helm-stable-debian.list
chmod 0644 /etc/apt/sources.list.d/helm-stable-debian.list

apt-get update
apt-get install -y kubectl helm

architecture="$(dpkg --print-architecture)"
case "$architecture" in
    amd64 | arm64) ;;
    *)
        printf 'Minikube does not have a module recipe for Debian architecture %s.\n' "$architecture" >&2
        exit 1
        ;;
esac
curl -fsSL "https://storage.googleapis.com/minikube/releases/latest/minikube_latest_${architecture}.deb" \
    --output "$minikube_package"
apt-get install -y "$minikube_package"
printf '%s\n' 'k8s-stack applied for agent-vm. No Minikube cluster was started.'
