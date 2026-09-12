# 05 – Credentials

The VM gets its own credentials. The host's are never copied in (specification §12).

Working assumption: **anything an agent can reach inside the VM, an agent can read.** Every
credential placed here is one an agent may use, log, or send to a model provider. Scope each one so
that is acceptable.

## 1. Never share from the host

- `~/.ssh` as a whole
- browser profiles and their saved passwords
- cloud CLI configuration and long-lived cloud keys
- password manager vaults or exports
- the Dropbox account itself — only named subdirectories, see
  [06-shared-folders.md](06-shared-folders.md)

## 2. SSH

Generate a keypair that exists only in the VM:

```bash
ssh-keygen -t ed25519 -C "xmg-evo-agent-vm" -f ~/.ssh/id_ed25519 -N ""
```

**No passphrase**, deliberately. Agents run unattended and a passphrase-protected key needs an
interactive unlock that nobody is present to give; on an autologin guest, loading it into an agent at
session start would reduce the protection to a delay anyway. What limits the damage is that the key
is the VM's own, registered separately, and revocable on its own — not that it is encrypted at rest
on a disk the agent can read.

Register the public key with GitHub as a separate key so it can be revoked on its own. `gh auth
login` offers to upload it during §3; otherwise:

```bash
gh ssh-key add ~/.ssh/id_ed25519.pub --title xmg-evo-agent-vm
```

## 3. GitHub

```bash
gh auth login      # needs a TTY: ssh -t xmg-evo-agent-vm gh auth login
gh auth status
```

`gh` is installed in [01-bootstrap.md](01-bootstrap.md) §6, before this step, because this step
cannot run without it.

Prefer an account or fine-grained token limited to the repositories agents actually work on. A token
that can push to everything is a token an agent can push to everything with.

## 4. API tokens

Tokens live in `~/.bash_secrets`, symlinked from [`../../user-home/`](../../user-home/) per
[`../common/00-home-environment.md`](../common/00-home-environment.md). The template is
`.bash_secrets.CHANGE-ME`; the real file is never committed.

Typical contents: model provider keys, `FIRECRAWL_API_KEY`, `HF_TOKEN`, the local model base URL
from [03-networking.md](03-networking.md).

Hugging Face token: create at <https://huggingface.co/settings/tokens> with Read access, which is
enough for downloads.

## 5. Rotation and blast radius

- rotate VM credentials on their own schedule, independently of host credentials
- when a VM is discarded or rebuilt, revoke its keys rather than carrying them to the new one
- keep credentials out of the shared folders — a leaked file there syncs to the cloud

## 6. Checklist

- [ ] VM-only SSH keypair generated, public key registered separately
- [ ] GitHub auth scoped to the repositories agents need
- [ ] `~/.bash_secrets` populated from the template, not committed
- [ ] no host `~/.ssh`, browser profile or cloud config present in the VM
- [ ] revocation path known for every credential in the VM

Next: [06-shared-folders.md](06-shared-folders.md)
