# 06 - Optional Tools

Additional tools based on your needs. Install only what you'll use.

## Prerequisites

- Completed core setup (01-05)

---

## 1. Docker

### Windows

```powershell
winget install Docker.DockerDesktop
```

Requires WSL2. If not already enabled:
```powershell
wsl --install
```

### Linux

```bash
# Debian/Ubuntu
sudo apt install docker.io docker-compose -y
sudo usermod -aG docker $USER
# Log out and back in for group changes
```

### macOS

```bash
brew install --cask docker
```

**Verify:**
```bash
docker --version
docker run hello-world
```

---

## 2. Cloud CLIs

### AWS CLI

```bash
# Windows
winget install Amazon.AWSCLI

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# macOS
brew install awscli
```

**Configure:**
```bash
aws configure
```

### Google Cloud CLI

```bash
# Windows
winget install Google.CloudSDK

# Linux
curl https://sdk.cloud.google.com | bash

# macOS
brew install --cask google-cloud-sdk
```

**Configure:**
```bash
gcloud init
```

### Azure CLI

```bash
# Windows
winget install Microsoft.AzureCLI

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# macOS
brew install azure-cli
```

**Configure:**
```bash
az login
```

---

## 3. Database Tools

### PostgreSQL Client

```bash
# Windows
winget install PostgreSQL.psql

# Linux
sudo apt install postgresql-client -y

# macOS
brew install postgresql
```

### DBeaver (GUI)

```bash
# Windows
winget install dbeaver.dbeaver

# Linux
sudo snap install dbeaver-ce

# macOS
brew install --cask dbeaver-community
```

---

## 4. API Testing

### Postman

```bash
# Windows
winget install Postman.Postman

# macOS
brew install --cask postman
```

### HTTPie (CLI alternative)

```bash
pip3 install httpie
```

---

## 5. Additional Dev Tools

### jq (JSON processor)

```bash
# Windows
winget install jqlang.jq

# Linux
sudo apt install jq -y

# macOS
brew install jq
```

### ripgrep (fast search)

```bash
# Windows
winget install BurntSushi.ripgrep.MSVC

# Linux
sudo apt install ripgrep -y

# macOS
brew install ripgrep
```

### fzf (fuzzy finder)

```bash
# Windows
scoop install fzf

# Linux
sudo apt install fzf -y

# macOS
brew install fzf
```

### bat (better cat)

```bash
# Windows
winget install sharkdp.bat

# Linux
sudo apt install bat -y

# macOS
brew install bat
```

---

## 6. Fonts

### Programming Fonts

```bash
# Windows - via Scoop
scoop bucket add nerd-fonts
scoop install JetBrainsMono-NF

# macOS
brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono-nerd-font
```

---

## Verification Checklist

Mark what you installed:

- [ ] Docker (`docker --version`)
- [ ] AWS CLI (`aws --version`)
- [ ] GCloud CLI (`gcloud --version`)
- [ ] Azure CLI (`az --version`)
- [ ] Database tools
- [ ] API testing tools
- [ ] Additional CLI tools

**Setup Complete!** Return to `setup-checklist.md` for final verification.
