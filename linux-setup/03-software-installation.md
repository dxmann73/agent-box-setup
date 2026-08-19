# 03 – Installation of required software

Daily-use applications and system configuration, after the base system from
[02-kubuntu-installation.md](02-kubuntu-installation.md) is validated.

Developer tooling is a separate step: see
[04-development-setup.md](04-development-setup.md).

## 1. Chrome

Use Google's official Debian/Ubuntu package: <https://www.google.com/chrome/>

## 2. Bitwarden

Official downloads: <https://bitwarden.com/download/>

The browser extension is usually sufficient for daily browser use. Verify that your vault works
before becoming dependent on the Linux installation.

## 3. WhatsApp

The simplest Linux approach is WhatsApp Web: <https://web.whatsapp.com/>

Chrome can install it as a web application so it behaves more like a separate desktop application.
Be cautious with unofficial clients that request unusual permissions or credentials.

## 4. VLC

```bash
sudo apt install -y vlc
```

<https://www.videolan.org/vlc/>

## 5. Microsoft Office

There is no equivalent native current Microsoft Office desktop suite for Linux.

Practical options:

- Microsoft 365 web apps: <https://www.microsoft365.com/>
- LibreOffice: <https://www.libreoffice.org/>

Install LibreOffice:

```bash
sudo apt install -y libreoffice
```

Test your **actual** Word/Excel/PowerPoint files. Complex formatting, VBA/macros, Office add-ins and
specialized Excel functionality are reasons to retain Windows.

## 6. CapCut

A strong KDE-native alternative is Kdenlive: <https://kdenlive.org/>

```bash
sudo apt install -y kdenlive
```

## 7. Steam and Proton

Steam support: <https://help.steampowered.com/>

After installation, enable Steam Play/Proton as required.

Check individual games at <https://www.protondb.com/>

Game-by-game testing is important, especially for multiplayer titles with anti-cheat.

Prefer a Linux-native ext4 Steam library rather than making a shared Windows NTFS library your main
Linux configuration.

## 8. Voice dictation

Evaluate [vibetyper](https://vibetyper.com/docs). If that doesn't work, try to use
[repackaged WhisprFlow](https://github.com/wispr-flow-linux/wispr-flow-linux)

## 9. Filesystem organization

A simple structure is sufficient:

```text
/home/you/
├── Documents/
├── Downloads/
├── projects/
│   ├── project-a/
│   └── project-b/
├── models/
│   ├── 8b/
│   ├── 32b/
│   └── moe/
└── llm-bench/
```

Create the LLM directories later with:

```bash
mkdir -p ~/models ~/llm-bench
```

Large downloaded model files are replaceable, so decide whether they are worth including in backups.

## 10. Backups

Configure Linux backups before moving the only copy of important data to Kubuntu.

Prioritize:

```text
~/Documents
~/projects
~/.ssh
important application configuration
recovery material
```

Large GGUF model downloads can usually be excluded because they are reproducible downloads.

## 11. Flatpak and Snap

- Flatpak: <https://flatpak.org/>
- Flathub: <https://flathub.org/>

A useful packaging rule is:

```text
System/development components → apt
Desktop applications          → apt or Flatpak
GPU/ROCm compute stack        → AMD-supported instructions
```

Kubuntu/Ubuntu may also use Snap. There is no need to remove it preemptively.

Avoid mixing packaging systems for low-level GPU components without a reason.

## 12. SSH

Client:

```bash
sudo apt install -y openssh-client
```

Only install the server if the laptop needs to accept incoming SSH connections:

```bash
sudo apt install -y openssh-server
systemctl status ssh
```

If you migrate existing private SSH keys, preserve their permissions. Generating a machine-specific
new key is often preferable.

## 13. Firewall

Check UFW:

```bash
sudo ufw status
```

Enable it if desired:

```bash
sudo ufw enable
sudo ufw status verbose
```

Later, bind local LLM servers to `127.0.0.1` unless LAN access is intentional.

## 14. Do not install ROCm immediately

For the initial Linux setup, stop once these work:

```text
AMDGPU
Mesa
Vulkan
Steam
suspend/resume
daily applications
```

Only then follow the separate local-LLM guide and add ROCm: <https://rocm.docs.amd.com/>

This gives you a clean baseline: if something breaks after adding the compute stack, you know the
underlying desktop installation worked beforehand.

## 15. Application checklist

- [ ] Chrome installed
- [ ] Bitwarden works
- [ ] WhatsApp Web works
- [ ] VLC works
- [ ] Office workflow tested
- [ ] CapCut replacement/workflow tested
- [ ] voice dictation tested
- [ ] Steam installed
- [ ] important Steam games tested
- [ ] controllers/peripherals tested
- [ ] SSH keys/permissions verified
- [ ] firewall state decided
- [ ] backups configured
- [ ] local-LLM Vulkan baseline completed
- [ ] ROCm tested if required

**Next:** [04-development-setup.md](04-development-setup.md)
