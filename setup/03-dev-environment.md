# 03 - Development Environment

Programming languages and runtimes.

## Prerequisites

- Completed `02-core-tools.md`
- Package manager available

---

## 1. Node.js

Install Node.js using nvm for version management (recommended).

### Install nvm

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
source ~/.bashrc
nvm install --lts
nvm use --lts
nvm alias default lts/*
```

## 2. Global npm Packages

Install commonly used tools across all projects.

```bash
npm install -g typescript
npm install -g ts-node
npm install -g pnpm
```

### Verify

```bash
node --version
npm --version
tsc --version
ts-node --version
pnpm --version
```

## 3. Helm

Install Helm (Kubernetes package manager) via the [official install script](https://helm.sh/docs/intro/install/#from-script).

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash
```

### Verify

```bash
helm version
```

## Verification Checklist

Confirm all tools are working:

- [ ] Node.js installed: `node --version`
- [ ] npm available: `npm --version`
- [ ] nvm can switch versions: `nvm list`
- [ ] TypeScript compiler: `tsc --version`
- [ ] ts-node runtime: `ts-node --version`
- [ ] pnpm package manager: `pnpm --version`
- [ ] Helm installed: `helm version`

## Next Steps

Continue to `04-editor.md` to set up your code editor.
