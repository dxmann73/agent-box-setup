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

Verify:

```bash
helm version
```

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

# Start cluster
minikube start --memory=4096 --cpus=2

# Verify
kubectl get nodes
```

---

## Verification Checklist

- [ ] Helm installed (if needed): `helm version`
- [ ] Minikube installed (if needed): `minikube version`
- [ ] kubectl installed (if needed): `kubectl version --client`
