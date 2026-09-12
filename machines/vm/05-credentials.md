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

**The VM has no git SSH key.** GitHub is reached over HTTPS with `gh`'s token (§3), so a keypair
would be a second credential on the agent's disk that nothing uses. The only key material here is
`~/.ssh/authorized_keys`, which is the host's public key for getting *into* the VM
([01-bootstrap.md](01-bootstrap.md) §1) — not the VM's identity towards anything.

If a genuine SSH need appears later — another host, a git remote that offers no HTTPS — generate it
then, and without a passphrase:

```bash
ssh-keygen -t ed25519 -C "xmg-evo-agent-vm" -f ~/.ssh/id_ed25519 -N ""
```

No passphrase, deliberately: agents run unattended, so a passphrase needs an interactive unlock that
nobody is present to give, and on an autologin guest loading it into an agent at session start turns
the protection into a delay. What limits the damage is that such a key is the VM's own, registered
separately, and revocable on its own — not that it is encrypted at rest on a disk the agent reads.

## 3. GitHub

```bash
gh auth login      # needs a TTY: ssh -t xmg-evo-agent-vm gh auth login
gh auth status
gh config get git_protocol     # https
git config --get credential.https://github.com.helper
```

Choose **HTTPS**, not SSH, and accept "Authenticate Git with your GitHub credentials?" — that runs
`gh auth setup-git`, which installs the credential helper the last command checks for. Clones then
use `https://github.com/...` and authenticate with the token, so the VM needs no SSH key at all
(§2).

`gh` is installed in [01-bootstrap.md](01-bootstrap.md) §6, before this step, because this step
cannot run without it.

Prefer an account or fine-grained token limited to the repositories agents actually work on. A token
that can push to everything is a token an agent can push to everything with.

## 4. API tokens

Tokens live in `~/.bash_secrets`, symlinked from [`../../user-home/`](../../user-home/) per
[`../common/00-home-environment.md`](../common/00-home-environment.md). The template is
`.bash_secrets.CHANGE-ME`; the real file is never committed.

Two consequences of that, in this order:

1. **This section runs after the repo is cloned**, i.e. after
   [01-bootstrap.md](01-bootstrap.md) §8 — the file lives inside the working tree and is symlinked
   out of it, so there is nowhere to put it before the clone exists. The symlink itself is part of
   [`../common/00-home-environment.md`](../common/00-home-environment.md), which runs inside
   [02-dev-and-agents.md](02-dev-and-agents.md) §2, so this section completes there while §2 and §3
   above are done earlier.
2. **The clone will not contain `.bash_secrets`.** It is gitignored, so a fresh clone in the VM has
   only `.bash_secrets.CHANGE-ME`. Create the VM's own from that template. Do not copy the host's
   file in — that is the one move this whole file exists to prevent (§1).

Typical contents: model provider keys, `FIRECRAWL_API_KEY`, `HF_TOKEN`, the local model base URL
from [03-networking.md](03-networking.md).

Hugging Face token: create at <https://huggingface.co/settings/tokens> with Read access, which is
enough for downloads.

## 5. Rotation and blast radius

- rotate VM credentials on their own schedule, independently of host credentials
- when a VM is discarded or rebuilt, revoke its keys rather than carrying them to the new one
- keep credentials out of the shared folders — a leaked file there syncs to the cloud

## 6. Checklist

- [ ] GitHub over HTTPS with `gh`'s token and credential helper; no unused SSH key on the disk
- [ ] GitHub auth scoped to the repositories agents need
- [ ] `~/.bash_secrets` populated from the template, not committed
- [ ] no host `~/.ssh`, browser profile or cloud config present in the VM
- [ ] revocation path known for every credential in the VM

Next: [06-shared-folders.md](06-shared-folders.md)
