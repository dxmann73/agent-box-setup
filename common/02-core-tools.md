# 02 - Core Tools

Essential tools that everything else depends on.

## Prerequisites

- Completed `00-home-environment.md` and `01-agent-setup.md`
- sudo access

---

## 1. GitHub CLI

GitHub CLI (`gh`) enables GitHub operations from the terminal.

```bash
sudo apt install gh -y
```

**Verify installation:**

```bash
gh --version
```

Expected output: `gh version 2.x.x` or similar

**Authenticate:**

```bash
gh auth login
```

Follow the prompts to authenticate via browser or token.

**Verify authentication:**

```bash
gh auth status
```

Expected output should show: `✓ Logged in to github.com account ...`

---

## 2. jq (JSON processor)

```bash
sudo apt install jq -y
```

**Verify installation:**

```bash
jq --version
```

Expected output: `jq-1.x` or similar

---

## 3. Docker

```bash
sudo apt install docker.io docker-compose -y
sudo usermod -aG docker $USER
```

**Important:** Log out and back in (or restart) for group changes to take effect.

**Verify installation:**

```bash
docker --version
docker compose version
```

Expected output: Version numbers for both commands

**Verify Docker is working:**

```bash
docker run hello-world
```

Expected output: Should pull and run the hello-world image successfully

---

---

## Complete Verification

Run all verification commands:

```bash
echo "=== GitHub CLI ===" && \
gh --version && \
gh auth status && \
echo -e "\n=== jq ===" && \
jq --version && \
echo -e "\n=== Docker ===" && \
docker --version && \
docker compose version && \
echo -e "\n=== Docker Test ===" && \
docker run --rm hello-world | head -3
```

All commands should complete successfully without errors.

## Verification Checklist

- [ ] GitHub CLI installed and authenticated (`gh auth status` shows ✓)
- [ ] jq installed (`jq --version` shows version)
- [ ] Docker installed (`docker --version` shows version)
- [ ] Docker working (`docker run hello-world` succeeds)

**Next:** Continue to `03-dev-environment.md`
