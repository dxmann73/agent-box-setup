# Start here: fresh Kubuntu host

Use this page only on a new physical Kubuntu host. It starts one local agent, which clones this
repository and prepares the host from the modular catalog. An overlay may insert a browser guest
before remaining logins; host completion precedes agent-VM creation.

You need a Claude subscription that includes Claude Code. The deployment prompt, profile values,
locale, and project inventory live in the
[deployment overlay](https://github.com/dxmann73/dave.box-setup/tree/main/agent-box).

## 1. Install Claude Code

Kubuntu Desktop ships `curl` and `ca-certificates`. Open a terminal:

```bash
curl -fsSL https://claude.ai/install.sh | bash
claude
```

Complete sign-in in the browser, then return to the terminal.

## 2. Clone setup inputs

Install Git and GitHub CLI, then clone the public repository and selected private overlay under
`~/projects/`:

```bash
sudo apt-get update
sudo apt-get install -y git gh
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/dxmann73/agent-box-setup.git
gh auth login
gh repo clone dxmann73/dave.box-setup
```

Both checkouts are inputs to later recipes, not catalog modules.

## 3. Give the agent this task

Paste this into Claude Code:

> Set up this daily Kubuntu host with the modular catalog in
> `~/projects/agent-box-setup/modules/README.md`. Obtain the selected deployment overlay first.
> Determine the catalog box ID, follow its ticked module dependencies and operator schedule, and
> reuse existing working state. Run `host-sudo-session` before rootful work. If the overlay selects
> a browser guest, complete and verify it before remaining authentication. Ask before optional tools
> or unapproved data/security choices; diagnose failures before continuing. Verify with
> `./modules/verify-box.sh BOX --operational`; create an agent guest only after that gate passes.

The agent will request normal sudo confirmation where needed. Do not make host sudo passwordless.

## What happens next

Read the selected box column in the [module catalog](modules/README.md). Run each module's recipe
in dependency and schedule order. Use `./modules/verify-box.sh BOX --list` before the final
verification to see the exact catalog-derived checks. Guest provider, GitHub, Firecrawl, and model
credentials stay in their later login window.
