# 05 – Credentials and provider enablement

The VM holds credentials separate from the host. Treat every credential in this VM as available to
the agents that run here. Run this only after the credential-free baseline and `clean-guest`
snapshot are complete.

## 1. GitHub

Authenticate the VM's full GitHub account over HTTPS:

```bash
gh auth login      # needs a TTY: ssh -t VM_NAME gh auth login
gh auth status
gh config get git_protocol     # https
git config --get credential.https://github.com.helper
```

Choose **HTTPS** and accept Git authentication during `gh auth login`. This configures Git to use
the GitHub CLI credential helper. Revoke the VM's authorization through GitHub's authorized-apps
settings and rotate it independently of the host.

`gh` is installed by [01-bootstrap.md](01-bootstrap.md)'s host-driven baseline.

## 2. Agent providers and Firecrawl

Authenticate each provider intentionally in a TTY on the guest. The CLI install and configuration
were completed by the baseline; these commands create the private state:

```bash
claude
codex
agent
pi                 # then /login
firecrawl login --browser
```

Keep `~/.pi/agent/auth.json` Pi-managed and untracked. Do not symlink it from the repository. Use
the corresponding provider account pages to revoke guest access independently from the host.

## 3. API tokens

Create the VM's secrets file after cloning this repository and running
[`../common/00-home-environment.md`](../common/00-home-environment.md):

```bash
cd ~/projects/agent-box-setup
cp user-home/.bash_secrets.CHANGE-ME user-home/.bash_secrets
nano user-home/.bash_secrets
ln -sf ~/projects/agent-box-setup/user-home/.bash_secrets ~/.bash_secrets
```

Add the VM's model-provider keys, `FIRECRAWL_API_KEY`, `HF_TOKEN`, and the local model base URL.
Create the Hugging Face token at <https://huggingface.co/settings/tokens> with Read access.

## 4. Checklist

- [ ] `gh auth status` reports the VM account and HTTPS Git operations
- [ ] Git uses the GitHub CLI credential helper
- [ ] required guest provider CLIs and Firecrawl are authenticated intentionally
- [ ] `~/.bash_secrets` is populated from the template and symlinked
- [ ] VM credentials have their own revocation path

Next: [06-shared-folders.md](06-shared-folders.md)
