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

**Verify installation:**

```bash
nvm --version
node --version
command npm --version
```

Expected output: Version numbers for nvm, node (v22.x or similar), and npm

---

## 2. Package Managers and Global JS Tools

Bootstrap `pnpm` using Corepack first, then install global JS tools with the real `npm` binary.

```bash
corepack enable
corepack prepare pnpm@latest --activate
pnpm --version
command npm install -g typescript ts-node
```

**Verify installation:**

```bash
tsc --version
ts-node --version
pnpm --version
```

Expected output: Version numbers for all three tools

---

## 3. Playwright Browser Runtime (for frontend browser tests)

Some frontend test suites run in a real browser through Playwright. Install Chromium once so those tests do not fail at startup.

From a project that includes Playwright in dependencies (for example `apps/frontend` in `nomap`):

```bash
pnpm exec playwright install chromium
```

On Linux/WSL, also install required system packages:

```bash
pnpm exec playwright install-deps chromium
```

If system packages are already installed, `install-deps` is effectively a no-op.

---

## 4. SDKMAN

[SDKMAN](https://sdkman.io/) manages different versions of Java, Maven, Quarkus, etc. It supports auto-switching SDKs when you `cd` into a directory with a `.sdkmanrc`.

```bash
cd ~
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
```

Enable auto-env so SDKMAN auto-loads SDK versions from `.sdkmanrc` on `cd`:

```bash
sed -i 's/sdkman_auto_env=false/sdkman_auto_env=true/' ~/.sdkman/etc/config
```

**Verify SDKMAN installation:**

```bash
sdk version
```

Expected output: `SDKMAN x.x.x` or similar

**Verify auto-env is enabled:**

```bash
grep sdkman_auto_env ~/.sdkman/etc/config
```

Expected output: `sdkman_auto_env=true`

### Manually trigger an SDKMAN environment reload (if needed)

If you don't see the environment updating on `cd`, you can force a reload with:

```bash
sdk env
```

This should activate the SDKs as defined in `.sdkmanrc` and print the versions being used.

---

## 5. Java (via SDKMAN)

```bash
sdk install java 21.0.8-oracle
```

**Verify installation:**

```bash
java --version
```

Expected output: `java 21.0.8` or similar

---

## 6. Quarkus and Maven (via SDKMAN)

```bash
sdk install quarkus
sdk install maven
```

**Verify installation:**

```bash
quarkus --version
mvn --version
```

Expected output: Version numbers for both Quarkus CLI and Maven

---

---

## Complete Verification

Run all verification commands:

```bash
echo "=== Node.js & npm ===" && \
nvm --version && \
node --version && \
command npm --version && \
echo -e "\n=== Global npm packages ===" && \
tsc --version && \
ts-node --version && \
pnpm --version && \
echo -e "\n=== SDKMAN ===" && \
sdk version && \
echo "Auto-env: $(grep sdkman_auto_env ~/.sdkman/etc/config)" && \
echo -e "\n=== Playwright (frontend browser tests) ===" && \
ls ~/.cache/ms-playwright || echo "No Playwright browser cache found yet" && \
echo -e "\n=== Java Development ===" && \
java --version && \
quarkus --version && \
mvn --version | head -1
```

All commands should complete successfully and show version numbers.

## Verification Checklist

Confirm all tools are working:

- [ ] Node.js installed: `node --version` shows v22.x or similar
- [ ] npm available: `command npm --version` shows version
- [ ] nvm can switch versions: `nvm list` shows installed versions
- [ ] TypeScript compiler: `tsc --version` shows version
- [ ] ts-node runtime: `ts-node --version` shows version
- [ ] pnpm package manager: `pnpm --version` shows version
- [ ] Playwright Chromium installed for frontend browser tests
- [ ] SDKMAN installed: `sdk version` shows version
- [ ] SDKMAN auto-env enabled: config shows `sdkman_auto_env=true`
- [ ] Java installed: `java --version` shows 21.x
- [ ] Quarkus installed: `quarkus --version` shows version
- [ ] Maven installed: `mvn --version` shows version

**Next:** Continue to `04-ide+tooling.md`
