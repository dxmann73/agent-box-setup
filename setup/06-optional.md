# 06 - Optional Tools

Tools that are useful but not required for every setup.

## Prerequisites

- Completed core setup (00-04)

---

## 1. Helm

Install Helm (Kubernetes package manager) via the [official install script](https://helm.sh/docs/intro/install/#from-script).

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash
```

**Verify installation:**

```bash
helm version
```

Expected output: Version number like `version.BuildInfo{Version:"v3.x.x", ...}`

---

## 2. Minikube and kubectl

For local Kubernetes development (needed for backend projects):

```bash
# Install kubectl
sudo apt install -y kubectl

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
```

**Verify installation:**

```bash
kubectl version --client
minikube version
```

Expected output: Version numbers for both tools

**Start cluster and verify:**

```bash
minikube start --memory=4096 --cpus=2
kubectl get nodes
```

Expected output: Node(s) in "Ready" status

---

---

## Complete Verification

Run verification commands for installed tools:

```bash
echo "=== Helm ===" && \
(helm version 2>/dev/null || echo "Not installed") && \
echo -e "\n=== kubectl ===" && \
(kubectl version --client 2>/dev/null || echo "Not installed") && \
echo -e "\n=== Minikube ===" && \
(minikube version 2>/dev/null || echo "Not installed") && \
echo -e "\n=== Minikube status ===" && \
(minikube status 2>/dev/null || echo "Not running or not installed")
```

## Verification Checklist

- [ ] Helm installed (if needed): `helm version` shows version
- [ ] kubectl installed (if needed): `kubectl version --client` shows version
- [ ] Minikube installed (if needed): `minikube version` shows version
- [ ] Minikube cluster running (if needed): `kubectl get nodes` shows Ready node
