# virtiofs-user-data-shares recipe

Run the host side on a daily host after `agent-vm` exists. Run the guest side inside the agent VM
after `guest-ssh-sudo-bootstrap` has passwordless sudo working.

This module owns only explicitly listed user-data virtiofs shares:

- host side: create one libvirt filesystem device per listed share, attach each device to the agent
  VM domain, and refresh the saved inactive domain XML;
- guest side: mount each tag at its listed guest path and persist it in `/etc/fstab` with `nofail`;
- verify both sides.

It does not choose personal paths, share sync roots, clone projects, move credentials, create
snapshots, or back up disks.

## Values

Deployment overlays own concrete paths, tags, access modes, and domain names. Export a newline
separated `USER_DATA_SHARES` list before running either mode. Each non-comment line has four fields:

```text
tag|host path|guest mount path|ro-or-rw
```

Example:

```bash
export AGENT_VM_DOMAIN=agent-vm
export USER_DATA_SHARES="$(cat <<'SHARES'
example|/path/to/narrow/source|/mnt/shares/example|ro
example-write|/path/to/narrow/source/writeable-child|/mnt/shares/example/writeable-child|rw
SHARES
)"
```

Optional:

```bash
export USER_DATA_SHARE_XML_DIR="$HOME/vms"
export AGENT_VM_XML_PATH="$HOME/vms/$AGENT_VM_DOMAIN.xml"
export AGENT_VM_EXPECTED_HOSTNAME=agent-vm
```

List parent shares before nested children. For a read-only parent with one writable child, use `ro`
for the parent line and `rw` for the child line. The host enforces read-only shares with
`<readonly/>`; guest-side `ro` is only a convenience check.

Never list `$HOME`, a sync root, `~/.ssh`, browser profiles, or broad document trees. Files written
through an `rw` share are host files; VM snapshots do not roll them back.

## Apply

On the host:

```bash
cd ~/projects/agent-box-setup/modules/02-virt/agent/virtiofs-user-data-shares
./apply.sh --host
```

`apply.sh --host`:

- refuses to run as root or inside a VM;
- checks the agent VM domain exists and has shared `memfd` memory backing;
- writes one `share-$tag.xml` file under `USER_DATA_SHARE_XML_DIR`;
- attaches each filesystem device to the persistent domain definition, and to the live guest when it
  is running;
- writes the updated inactive domain XML to `AGENT_VM_XML_PATH`.

Use `./apply.sh --host --dry-run` to print generated filesystem XML without attaching devices.

Inside the agent guest:

```bash
cd ~/projects/agent-box-setup/modules/02-virt/agent/virtiofs-user-data-shares
./apply.sh --guest
```

`apply.sh --guest`:

- refuses to run as root, outside a VM, without passwordless sudo, or on the wrong hostname;
- mounts shares in the order listed, so parents can be mounted before nested writable children;
- adds one `virtiofs` fstab line per listed share with `ro,nofail` or `rw,nofail`;
- creates `~/shares` symlinks for mounted paths below `/mnt/shares`.

## Verify

On the host:

```bash
./verify.sh --host
```

Inside the agent guest:

```bash
./verify.sh --guest
```

Host verification checks the domain XML, saved filesystem XML files, source directories, shared
memory backing, access mode, and live XML when the guest is running. Guest verification checks the
hostname guard, mountpoints, filesystem type, mount tags, access options, fstab persistence, and
`~/shares` symlinks for `/mnt/shares` mounts.

## Operational Checks

After both sides pass:

- read a harmless file through each `ro` share and confirm writes fail;
- create and delete a small test file through each `rw` share;
- verify the file appears on the host and is not inside the VM disk backup;
- detach stale shares when the task no longer needs them.

Do not use this module as a shortcut for broad host access. A share is an explicit exception to the
agent boundary.

## Simplification Candidates

- `virtiofs-desktop-share` and this module now duplicate XML matching, filesystem XML generation,
  domain attachment, and fstab editing. Consider extracting a small shared shell or Python helper
  after both modules have been exercised on real boxes. Keep the different safety policies visible:
  browser Desktop is a single read-write exception, while agent user data is a multi-share list with
  read-only default behavior.
- If only one nested share set remains in practice, an overlay-specific values file may be clearer
  than exporting a heredoc at the prompt. Keep that file in the deployment overlay because concrete
  personal paths do not belong in this generic repo.
