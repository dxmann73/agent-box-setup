# Start here: fresh Kubuntu host

Use this page only on a new physical Kubuntu host. It starts one supervised local agent; that agent
then clones this repository and completes the host before it creates an agent VM.

You need a Claude subscription that includes Claude Code. Do not enable Claude's bypass-permissions
mode during this bootstrap: keep its normal prompts and enter your password only when you have
reviewed the command.

The dave.box overlay prompt, `box.env`, locale, and project inventory live in
[dave.box-setup/agent-box/README.md](https://github.com/dxmann73/dave.box-setup/blob/main/agent-box/README.md).

## 1. Install Claude Code

Open a terminal and run:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Start Claude Code:

```bash
claude
```

Complete its sign-in prompts in the browser, then return to the terminal.

## 2. Give the agent this task

Paste the following into Claude Code:

> Set up this physical Kubuntu host using <https://github.com/dxmann73/agent-box-setup>. First clone
> it into `~/projects/agent-box-setup`. Work on the **host** path only and keep all permissions
> supervised. Follow numbered host and shared guides in order; ask me before optional tools,
> personal applications, or choices that affect my data or security; diagnose failures before
> continuing. Complete the host baseline, desktop/session settings, all four agent CLIs, VS Code,
> and the BB desktop application. Run the host operational verification. Do **not** create or change
> a VM until that host completion checkpoint succeeds.

The agent will ask for normal `sudo` confirmation where host setup requires it. Do not make host
sudo passwordless and do not grant unrestricted host-agent permissions.

## What happens next

Once host operational verification succeeds, continue with
[the hypervisor guide](machines/host/05-hypervisor.md). The host agent creates the guest and
configures it over SSH. Guest provider, GitHub, Firecrawl, Tailscale, and model credentials are
deliberately a later phase.
