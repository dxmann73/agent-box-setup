#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

usage() { printf '%s\n' 'Usage: ./verify.sh --target agent-vm'; }
if lang_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
lang_handle_parse_result "$status" usage || exit "$?"
lang_require_agent_vm || { usage >&2; exit 2; }
lang_require_user

kubernetes_source_configured() {
    grep -Eq '^deb \[signed-by=/etc/apt/keyrings/kubernetes-apt-keyring\.gpg\] https://pkgs\.k8s\.io/core:/stable:/v1\.37/deb/ /$' \
        /etc/apt/sources.list.d/kubernetes.list
}
helm_source_configured() {
    grep -qxF 'deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main' \
        /etc/apt/sources.list.d/helm-stable-debian.list
}
lang_check 'kubectl package installed' lang_package_installed kubectl
lang_check 'helm package installed' lang_package_installed helm
lang_check 'minikube package installed' lang_package_installed minikube
lang_check 'Kubernetes apt source configured' kubernetes_source_configured
lang_check 'Helm signed apt source configured' helm_source_configured
lang_check 'kubectl reports its client version' kubectl version --client
lang_check 'helm reports its version' helm version
lang_check 'minikube reports its version' minikube version
lang_finish_verify k8s-stack
