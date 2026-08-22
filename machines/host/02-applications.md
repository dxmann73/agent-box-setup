# 02 – Host applications

Daily-use applications. These stay on the host and are deliberately **not** installed in the agent
VM: the host is the personal machine (specification §1), the VM is the agent sandbox (§2).

## 1. Chrome

Use Google's official Debian/Ubuntu package: <https://www.google.com/chrome/>

This is the personal browser profile. Agents never use it — browser automation runs on a separate
Chromium inside the VM, see [`../vm/02-dev-and-agents.md`](../vm/02-dev-and-agents.md)
(specification §7).

## 2. Bitwarden

Official downloads: <https://bitwarden.com/download/>

The browser extension is usually sufficient for daily browser use. Verify that your vault works
before becoming dependent on the Linux installation.

## 3. Dropbox

Official Linux client: <https://www.dropbox.com/install-linux>

Dropbox is host-only. The sync daemon, the account credentials and the full tree stay outside the
VM.

Selected subdirectories are shared into the VM read/write when an agent has to work on their
contents — the tax-advisor folder, for example. That sharing is explicit and per-directory; see
[`../vm/06-shared-folders.md`](../vm/06-shared-folders.md). Never share the Dropbox root.

## 4. WhatsApp

The simplest Linux approach is WhatsApp Web: <https://web.whatsapp.com/>

Chrome can install it as a web application so it behaves more like a separate desktop application.
Be cautious with unofficial clients that request unusual permissions or credentials.

## 5. VLC

```bash
sudo apt install -y vlc
```

<https://www.videolan.org/vlc/>

## 6. Microsoft Office

There is no equivalent native current Microsoft Office desktop suite for Linux.

Practical options:

- Microsoft 365 web apps: <https://www.microsoft365.com/>
- LibreOffice: <https://www.libreoffice.org/>

Install LibreOffice:

```bash
sudo apt install -y libreoffice
```

Test your **actual** Word/Excel/PowerPoint files. Complex formatting, VBA/macros, Office add-ins and
specialized Excel functionality are where the web apps and LibreOffice fall short.

## 7. Video editing

A strong KDE-native alternative to CapCut is Kdenlive: <https://kdenlive.org/>

```bash
sudo apt install -y kdenlive
```

## 8. Steam and Proton

Steam support: <https://help.steampowered.com/>

After installation, enable Steam Play/Proton as required.

Check individual games at <https://www.protondb.com/>

Game-by-game testing is important, especially for multiplayer titles with anti-cheat.

Prefer a Linux-native ext4 Steam library.

## 9. Voice dictation

Host-only: dictation needs the microphone and types into host applications.

Evaluate [VibeTyper](https://vibetyper.com/docs). If that doesn't work, try
[repackaged WhisprFlow](https://github.com/wispr-flow-linux/wispr-flow-linux).

The earlier self-hosted attempt (faster-whisper, nerd-dictation) is retired but kept for reference
in [voice-setup.old/](voice-setup.old/).

## 10. Application checklist

- [ ] Chrome installed
- [ ] Bitwarden works
- [ ] Dropbox installed and synced
- [ ] WhatsApp Web works
- [ ] VLC works
- [ ] Office workflow tested
- [ ] video editing workflow tested
- [ ] Steam installed
- [ ] important Steam games tested
- [ ] controllers/peripherals tested
- [ ] voice dictation tested

Next: [03-system-config.md](03-system-config.md)
