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

Verify:

```bash
node --version
npm --version
```

---

## 2. Global npm Packages

Install commonly used tools across all projects.

```bash
npm install -g typescript
npm install -g ts-node
npm install -g pnpm
```

Verify:

```bash
tsc --version
ts-node --version
pnpm --version
```

---

## 3. SDKMAN

[SDKMAN](https://sdkman.io/) manages different versions of Java, Maven, Quarkus, etc. It supports auto-switching SDKs when you `cd` into a directory with a `.sdkmanrc`.

```bash
cd ~
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
```

Enable auto-env so SDKMAN auto-loads SDK versions from `.sdkmanrc` on `cd`:

```bash
nano ~/.sdkman/etc/config
# Set: sdkman_auto_env=true
```

Verify:

```bash
sdk version
# cd into a dir with .sdkmanrc and confirm it prints e.g. "Using java version 21.0.8-oracle in this shell."
```

---

## 4. Java (via SDKMAN)

```bash
sdk install java 21.0.8-oracle
```

Verify:

```bash
java --version
```

---

## 5. Quarkus and Maven (via SDKMAN)

```bash
sdk install quarkus
sdk install maven
```

Verify:

```bash
quarkus --version
mvn --version
```

---

## Verification Checklist

Confirm all tools are working:

- [ ] Node.js installed: `node --version`
- [ ] npm available: `npm --version`
- [ ] nvm can switch versions: `nvm list`
- [ ] TypeScript compiler: `tsc --version`
- [ ] ts-node runtime: `ts-node --version`
- [ ] pnpm package manager: `pnpm --version`
- [ ] SDKMAN installed: `sdk version`
- [ ] SDKMAN auto-env enabled
- [ ] Java installed: `java --version`
- [ ] Quarkus installed: `quarkus --version`
- [ ] Maven installed: `mvn --version`

**Next:** Continue to `04-ide+tooling.md`
