# Plan: key-only SSH over the tailnet

**Status:** superseded 2026-09-13. Do not apply from this file.

Live apply after `blade-14` joins:
[`infra/tailscale/ssh.md`](https://github.com/dxmann73/infra/blob/main/tailscale/ssh.md)
(Target). Windows client:
[`dave.box-setup/_incoming/2026-09-13-04-windows-vscode-remote-ssh-plan.md`](https://github.com/dxmann73/dave.box-setup/blob/main/_incoming/2026-09-13-04-windows-vscode-remote-ssh-plan.md).

Generic key-only sshd and the libvirt exception stay in abs host/VM guides. Tailscale join,
`from=`, `tailscale0` UFW, and ACL grants do not.

Phase 1 docs landed in abs, then Tailscale cookbooks left abs. See
[`2026-09-13-tailscale-docs-home-plan.md`](./2026-09-13-tailscale-docs-home-plan.md).
