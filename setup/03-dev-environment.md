# 03 - Development Environment

Programming languages and runtimes.

## Prerequisites

- Completed `02-core-tools.md`
- Package manager available

---

## 1. Node.js

**Using nvm (Recommended)**

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
# Restart terminal or source profile
source ~/.bashrc
nvm install --lts
nvm use --lts
```

**Verify:**

```bash
node --version
npm --version
```

## 3. Common Global npm Packages

These are useful across projects:

```bash
npm install -g typescript
npm install -g ts-node
npm install -g pnpm
```

**Verify:**

```bash
tsc --version
pnpm --version
```

## Verification Checklist

- [ ] Node.js installed (`node --version`)
- [ ] npm working (`npm --version`)
- [ ] pnpm working (`pnpm --version`)

**Next:** Continue to `04-editor.md`
