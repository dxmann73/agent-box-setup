# 07 - Optional Tools

Additional tools based on your needs. Install only what you'll use.

## Prerequisites

- Completed core setup (01-04, 06)

---

## 1. Docker

```bash
sudo apt install docker.io docker-compose -y
sudo usermod -aG docker $USER
# Log out and back in for group changes
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
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Configure:**
```bash
aws configure
```

### Google Cloud CLI

```bash
curl https://sdk.cloud.google.com | bash
```

**Configure:**
```bash
gcloud init
```

### Azure CLI

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Configure:**
```bash
az login
```

---

## 3. Database Tools

### PostgreSQL Client

```bash
sudo apt install postgresql-client -y
```

### DBeaver (GUI)

```bash
sudo snap install dbeaver-ce
```

---

## 4. API Testing

### Postman

```bash
sudo snap install postman
```

### HTTPie (CLI alternative)

```bash
pip3 install httpie
```

---

## 5. Additional Dev Tools

### jq (JSON processor)

```bash
sudo apt install jq -y
```

### ripgrep (fast search)

```bash
sudo apt install ripgrep -y
```

### fzf (fuzzy finder)

```bash
sudo apt install fzf -y
```

### bat (better cat)

```bash
sudo apt install bat -y
```

---

## 6. Fonts

### Programming Fonts

```bash
# Install JetBrains Mono Nerd Font
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip
unzip JetBrainsMono.zip
rm JetBrainsMono.zip
fc-cache -fv
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
