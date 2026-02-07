# 02 - Core Tools

Essential tools that everything else depends on.

## Prerequisites

- Fresh Ubuntu installation or clean environment
- sudo access

---

## 1. GitHub CLI

GitHub CLI (`gh`) enables GitHub operations from the terminal.

```bash
sudo apt install gh -y
```

**Authenticate:**

```bash
gh auth login
```

Follow the prompts to authenticate via browser or token.

Verify:

```bash
gh --version
gh auth status
```

---

## 2. jq (JSON processor)

```bash
sudo apt install jq -y
```

Verify:

```bash
jq --version
```

---

## Verification Checklist

- [ ] GitHub CLI installed and authenticated (`gh auth status`)
- [ ] jq installed (`jq --version`)

**Next:** Continue to `03-dev-environment.md`
