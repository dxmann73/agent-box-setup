# 02 – Host applications

Daily-use applications stay on the personal host and are deliberately **not** installed in the agent
VM: the host is the personal machine (specification §1), the VM is the agent sandbox (§2).

Do not treat this file as a required package list. Chrome, Dropbox, Steam, and similar names in the
architecture spec are examples of host-personal vs guest-automation, not packages every box must
install. The live install list for this laptop is the dave.box overlay:
[agent-box/machines/host/02-applications.md](https://github.com/dxmann73/dave.box-setup/blob/main/agent-box/machines/host/02-applications.md).

## Policy

- Keep the personal browser profile on the host. Agents never use it. Browser automation runs on a
  separate Chromium inside the VM, see [`../vm/02-dev-and-agents.md`](../vm/02-dev-and-agents.md)
  (specification §7).
- Sync daemons, account credentials, and full sync trees stay outside the VM. Share only a narrow
  subdirectory when an agent must work on it; see
  [`../vm/06-shared-folders.md`](../vm/06-shared-folders.md). Never share a sync root.
- Host-only desktop apps (password manager, editor, dictation, vendor desktop clients) stay here.

Ask before installing optional personal software. Prefer the application's documented Linux channel
(apt, Snap, Flatpak, or official package).

## Checklist

- [ ] personal apps stay on the host; agents do not use the personal browser profile
- [ ] the deployment overlay's install list, if any, is complete

Next: [03-system-config.md](03-system-config.md)
