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

**Alternative: Using apt (simpler but less flexible)**
```bash
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install nodejs -y
```

**Verify:**
```bash
node --version
npm --version
```

---

## 2. Python

```bash
# Usually pre-installed, but ensure latest
sudo apt install python3 python3-pip python3-venv -y
```

**Verify:**
```bash
python3 --version
pip3 --version
```

---

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

---

## 4. Common Python Tools

```bash
pip3 install --user pipx
pipx ensurepath
# Restart terminal
pipx install poetry
pipx install black
pipx install ruff
```

**Verify:**
```bash
poetry --version
```

---

## 5. Build Tools (if needed)

Some packages require native compilation.

```bash
sudo apt install build-essential -y
```

---

## Verification Checklist

- [ ] Node.js installed (`node --version`)
- [ ] npm working (`npm --version`)
- [ ] Python installed (`python3 --version`)
- [ ] pip working (`pip3 --version`)
- [ ] Build tools available (if needed)

**Next:** Continue to `04-editor.md`
