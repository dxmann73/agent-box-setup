# k8s-stack recipe

Run after `kubuntu-baseline` and `docker` on the catalog-ticked agent VM only. Docker is required as
the intended Minikube driver, but apply does not start a cluster or write a kubeconfig.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/04-lang/k8s-stack
sudo ./apply.sh --target agent-vm
```

Apply installs kubectl from the official Kubernetes v1.37 apt channel, Helm from its signed apt
repository after checking the published fingerprint, and the official Minikube Debian package for
the system architecture.

## Verify

```bash
./verify.sh --target agent-vm
```

The verifier checks package and source state plus each CLI version. To create a local cluster later,
run `minikube start --driver=docker` as the desktop user after reviewing its resource use.
