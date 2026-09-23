# k8s-stack

What: Kubernetes development stack.

Does: Installs Helm, kubectl, and Minikube on the agent VM without starting a cluster.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `sudo ./apply.sh --target agent-vm`

Verify: `./verify.sh --target agent-vm`
