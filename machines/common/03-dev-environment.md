# 03 - Development Environment

Install Node.js 24, pnpm, TypeScript, Markdownlint, ripgrep, and Firecrawl CLI.

## Prerequisites

- Completed `02-core-tools.md`
- sudo access

## 1. Node.js 24

```bash
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" \
  | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt update
sudo apt install -y nodejs
```

Verify:

```bash
node --version
npm --version
command -v node
```

`node --version` must show `v24.x`; `command -v node` must show `/usr/bin/node`.

## 2. User-Owned Npm Prefix

```bash
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
```

Open a new shell, then verify:

```bash
npm config get prefix
npm root -g
```

Both paths must be under `~/.npm-global`.

## 3. pnpm and Global JS Tools

```bash
npm install -g corepack
corepack enable --install-directory ~/.local/bin
corepack prepare pnpm@latest --activate
hash -r
npm install -g typescript ts-node markdownlint-cli firecrawl-cli
```

Verify:

```bash
type -a pnpm
pnpm --version
tsc --version
ts-node --version
markdownlint --version
firecrawl --status
```

Authenticate Firecrawl during host completion or the VM credentials phase.

## 4. ripgrep

```bash
sudo apt install -y ripgrep
rg --version
```

## Dave Overlay

SDKMAN, Java, Quarkus, Maven, Docker Compose, and imaging tools belong to the Dave box setup.

## Checklist

- [ ] Node.js is `v24.x`
- [ ] npm global prefix is `~/.npm-global`
- [ ] pnpm, TypeScript, ts-node, Markdownlint, and Firecrawl CLI are installed
- [ ] Firecrawl is authenticated when the target requires credentials
- [ ] ripgrep is installed

Next: [04-ide+tooling.md](04-ide+tooling.md)
