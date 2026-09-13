# 02 - Core Tools

Essential tools that everything else depends on.

## Prerequisites

- Completed `00-home-environment.md` (install agents after Node.js)
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

## 2. jq and yq

```bash
sudo apt install -y jq yq
```

**Verify installation:**

```bash
jq --version
yq --version
```

Expected output: version numbers for both.

---

## 3. Docker

**VM only.** Membership in the `docker` group is equivalent to root on the machine — the daemon will
happily bind-mount `/` into a container for any group member. That is an acceptable trade inside the
agent VM, which is already the boundary and where agents have root anyway
([`../vm/01-bootstrap.md`](../vm/01-bootstrap.md) §2). It is not an acceptable trade on the host,
which carries personal data and the model runtime. Install it in the VM; on the host, skip this
section unless a specific host-scoped task needs it.

```bash
sudo apt install -y docker.io
sudo usermod -aG docker $USER
```

Docker Compose is a deployment overlay choice, not part of the generic baseline.

**Important:** Log out and back in (or restart) for group changes to take effect.

**Verify installation:**

```bash
docker --version
```

Expected output: Docker version.

**Verify Docker is working:**

```bash
docker run hello-world
```

Expected output: Should pull and run the hello-world image successfully

## 4. WezTerm

Install WezTerm on both host and VM.

```bash
curl -fsSL https://apt.fury.io/wez/gpg.key \
  | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' \
  | sudo tee /etc/apt/sources.list.d/wezterm.list >/dev/null
sudo chmod 0644 /usr/share/keyrings/wezterm-fury.gpg
sudo apt update
sudo apt install -y wezterm
```

Add `origin=wez_apt_fury_io` to the unattended-upgrades policy
([08-auto-updates.md](08-auto-updates.md)).

Verify:

```bash
wezterm --version
```

---

---

## Complete Verification

Run on both targets:

```bash
echo "=== GitHub CLI ===" && \
gh --version && \
gh auth status && \
echo -e "\n=== jq ===" && \
jq --version && \
echo -e "\n=== yq ===" && \
yq --version && \
echo -e "\n=== WezTerm ===" && \
wezterm --version
```

Run on the VM:

```bash
docker --version
docker run --rm hello-world | head -3
```

## Verification Checklist

- [ ] GitHub CLI installed; authenticate it during host completion or the VM credentials phase
- [ ] jq installed (`jq --version` shows version)
- [ ] yq installed (`yq --version` shows version)
- [ ] VM only: Docker installed (`docker --version` shows version)
- [ ] VM only: Docker working (`docker run hello-world` succeeds)
- [ ] WezTerm installed (`wezterm --version` succeeds)

**Next:** Continue to `03-dev-environment.md`
