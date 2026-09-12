# 02 – Host applications

Daily-use applications. These stay on the host and are deliberately **not** installed in the agent
VM: the host is the personal machine (specification §1), the VM is the agent sandbox (§2).

## 1. Chrome

Use Google's official Debian/Ubuntu package: <https://www.google.com/chrome/>

This is the personal browser profile. Agents never use it — browser automation runs on a separate
Chromium inside the VM, see [`../vm/02-dev-and-agents.md`](../vm/02-dev-and-agents.md)
(specification §7).

## 2. Bitwarden

Use the official Bitwarden Snap on the host. It receives updates through
Snap's refresh service; do not substitute the `.deb`, which Bitwarden does not
auto-update.

```bash
sudo snap install bitwarden
```

Install the Bitwarden browser extension in the personal Chrome profile too.
Verify that the desktop vault, browser extension, and unlock flow work before
becoming dependent on them.

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

Decision (September 11, 2026): Kdenlive on the host as the CapCut replacement. Channel: Snap from
the `kde` publisher, `latest/stable`. Installed: 26.04.3 (rev 144). snapd refreshes it automatically
([`../common/08-auto-updates.md`](../common/08-auto-updates.md) §2). Do not install it in the agent
VM.

On a new host:

```bash
sudo snap install kdenlive
```

<https://kdenlive.org/>

KDE's Linux downloads are AppImage and Flatpak. Snap is the chosen channel here because it updates
with no extra timer. Ubuntu apt on this machine offers 25.12.3; skip it. Do not install DaVinci
Resolve.

Intended use: cut clips, speed a section for a timelapse, and re-encode only when a different format
is needed. Clips under `$HOME` (including Dropbox) are visible to the Snap. For USB or other
removable volumes:

```bash
sudo snap connect kdenlive:removable-media
```

## 8. Steam and Proton

Steam support: <https://help.steampowered.com/>

After installation, enable Steam Play/Proton as required.

Check individual games at <https://www.protondb.com/>

Game-by-game testing is important, especially for multiplayer titles with anti-cheat.

Prefer a Linux-native ext4 Steam library.

## 9. Voice dictation reference

[Vibe Typer](https://vibetyper.com/downloads) is a host-only, portable AppImage
that supports both Plasma Wayland and X11. Download it to
`~/Applications/VibeTyper.AppImage`, make it executable, and link the
repository-managed launcher and desktop entry:

```bash
mkdir -p ~/Applications ~/.local/bin ~/.local/share/applications
chmod +x ~/Applications/VibeTyper.AppImage
ln -sfn ~/projects/agent-box-setup/user-home/vibe-typer-launch.sh \
  ~/.local/bin/vibe-typer-launch.sh
ln -sfn ~/projects/agent-box-setup/user-home/applications/vibe-typer.desktop \
  ~/.local/share/applications/vibe-typer.desktop
```

The launcher waits for KDE Wallet after login, avoiding the known wallet race.
It deliberately passes `--no-sandbox`, matching the working host installation.

Enable the weekly update reminder. It only notifies: VibeTyper has no
documented signed/self-updating Linux channel, so replacing the AppImage stays
a reviewed user action.

```bash
ln -sfn ~/projects/agent-box-setup/user-home/vibe-typer-update-reminder.sh \
  ~/.local/bin/vibe-typer-update-reminder.sh
mkdir -p ~/.config/systemd/user
ln -sfn ~/projects/agent-box-setup/user-home/systemd/vibe-typer-update-reminder.service \
  ~/.config/systemd/user/vibe-typer-update-reminder.service
ln -sfn ~/projects/agent-box-setup/user-home/systemd/vibe-typer-update-reminder.timer \
  ~/.config/systemd/user/vibe-typer-update-reminder.timer
systemctl --user daemon-reload
systemctl --user enable --now vibe-typer-update-reminder.timer
```

## 10. Claude Desktop and ChatGPT desktop

Install the official Linux desktop packages on the host only. Their account
sessions and desktop state remain outside the VM.

- [Claude Desktop](https://claude.ai/download) ships its own APT source and
  unattended-upgrades rule.
- [ChatGPT desktop](https://chatgpt.com/download) installs an APT source; add
  its verified `site=persistent.oaistatic.com,codename=stable` pattern to the
  unattended-upgrades policy in [08-auto-updates.md](../common/08-auto-updates.md).

Verify:

```bash
claude-desktop --version
chatgpt --version
```

## 10. Application checklist

- [ ] Chrome installed
- [ ] Bitwarden works
- [ ] Dropbox installed and synced
- [ ] Bitwarden desktop app and Chrome extension work
- [ ] WhatsApp Web works
- [ ] VLC works
- [ ] Office workflow tested
- [x] Kdenlive installed (Snap 26.04.3, KDE)
- [ ] video editing workflow tested
- [ ] Steam installed
- [ ] important Steam games tested
- [ ] controllers/peripherals tested
- [ ] Vibe Typer installed and working
- [ ] VibeTyper weekly update reminder enabled
- [ ] Claude Desktop and ChatGPT desktop installed and working

Next: [03-system-config.md](03-system-config.md)
