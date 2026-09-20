# Start here: fresh Kubuntu host

Use this page only on a new physical Kubuntu host. It starts one local agent; that agent clones this
repository and prepares the host. An overlay may insert a personal browser guest before the
remaining logins; full host completion precedes agent-VM creation.

You need a Claude subscription that includes Claude Code.

The dave.box overlay prompt, `box.env`, locale, and project inventory live in
[dave.box-setup/agent-box/README.md](https://github.com/dxmann73/dave.box-setup/blob/main/agent-box/README.md).

## 1. Install Claude Code

Kubuntu Desktop ships `curl` and `ca-certificates` already. Open a terminal and run:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Start Claude Code:

```bash
claude
```

Complete its sign-in prompts in the browser, then return to the terminal.

## 2. Clone the setup repositories

Kubuntu Desktop may not ship `git`. Install it and place both the public repository and the private
overlay under `~/projects/` before handing the task to the agent. The overlay is private, so it
needs a GitHub credential; the simplest bootstrap is `gh auth login` via HTTPS.

```bash
sudo apt-get update
sudo apt-get install -y git gh
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/dxmann73/agent-box-setup.git
gh auth login
gh repo clone dxmann73/dave.box-setup
```

Both checkouts are preconditions for the modules that follow; they are not modules themselves.
Downstream modules assume `~/projects/agent-box-setup` and `~/projects/dave.box-setup` are present
and treat them as inputs.

## 3. Give the agent this task

Paste the following into Claude Code:

> Set up this physical Kubuntu host using <https://github.com/dxmann73/agent-box-setup>. Obtain it
> under `~/projects/agent-box-setup` and obtain any selected deployment overlay before starting.
> Follow the phased host order in README.md. Check existing installations and reuse working logins.
> Complete the host baseline and virtualization prerequisites first. If the overlay selects a
> personal browser guest, set up and verify that browser before the remaining authentication,
> development tools and personal apps. Ask before optional tools or unapproved data/security
> choices; diagnose failures before continuing. Then complete all four agent CLIs, Firecrawl, VS
> Code and BB, and run host operational verification. That later checkpoint gates agent-VM creation;
> it does not block an overlay's earlier personal-browser phase.

The agent will ask for normal `sudo` confirmation where host setup requires it. Do not make host
sudo passwordless.

## What happens next

Follow the [host sequence](README.md#host), including the deployment's browser insertion if any. The
early [virtualization check](machines/host/verify-virtualization.sh) needs no provider logins. Once
the browser is ready, finish host tooling and authentication. Host operational verification then
gates the agent-VM creation section of [the hypervisor guide](machines/host/05-hypervisor.md). Guest
provider, GitHub, Firecrawl, and model credentials are deliberately a later phase.
