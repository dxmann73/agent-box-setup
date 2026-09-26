# Move BB projects from the host OS onto the agent VM

- source: `_plans/drafts/move-bb-projects-to-agent-vm.md`
- priority: p1 (high). The user named this the next thing to do on 2026-09-25.
- status: next
- written: 2026-09-25
- refined: 2026-09-26 (second round of user answers)

## Goal

BB threads for day-to-day projects run on the agent VM (`xmg-evo-agent-vm`), not on the host
(`xmg-evo`). This matches the spec: the VM is the security boundary, and projects live inside the VM
(`docs/specification/agent-box.md` §4, §8).

The project-manager inventory is the source of truth. It lists every project and where it runs.
BB projects always match that inventory. After a project moves and the move is tested, the host
deletes its checkout of that project.

The VM gets a proper `~/.gitconfig` with the user's identity, set up by a module that runs on both
the host and the VM.

## Non-goals

- Moving the BB server. The host AppImage stays the shared control plane (`bb-appimage`).
- Tailscale, Serve, or ACL changes. Those belong to `infra`.
- blade-14 setup. The user will set it up later as a `bb-client` of the xmg server. It needs no
  project-specific setup.
- Automatic code sync between the host and VM checkouts. Each project ends up with exactly one
  checkout, so there is nothing to sync.
- Cloning `dave.box-setup` onto the VM (see Decisions).
- Project-specific toolchains or secrets beyond what the VM already has.

## Open Questions

1. **Can an old thread continue on the VM after its fork?** `bb thread fork --environment <vm env>`
   copies the conversation into a new thread on the VM. It is unknown whether the provider session
   (for example, Claude Code's session state on the host) carries over, or whether the fork starts
   with only the transcript. Test this in the pilot. Impact: at worst, forked threads keep their
   history but lose provider-side context.

## Background

- BB server: the host AppImage (`modules/05-dev/bb-appimage`). The VM is enrolled as an execution
  machine (`modules/05-dev/bb-enroll-execution-machine`).
- BB model (`bb guide`):
  - A project maps to a repository, and all threads belong to a project.
  - A project can have path sources on more than one machine.
  - An environment (project checkout or worktree) has a fixed machine (`hostId`) and a fixed path.
  - A thread is bound to one environment.
- **Threads cannot be re-pointed.** `bb environment update` changes only the name and the
  merge-base branch. `bb thread update` has no environment or machine option.
- The supported way to continue an old thread on the VM is
  `bb thread fork <thread> --environment <vm-env-id>`. The original thread stays in the project as
  history.
- BB cannot move a source to another machine in place. `bb project source update` changes only
  `--path` and `--default`. A switch means:
  1. `bb project source add <id> --clone --machine xmg-evo-agent-vm --default`
  2. `bb project source delete <id> <hostSourceId>`
- `bb project create --machine xmg-evo-agent-vm --root <path>` creates projects that are missing.
- The project manager is `clackworks.agent-coordinator/project-manager/`, with `README.md`,
  `inventory.md`, and `maintenance.md`. Its "Populate a fresh machine" duty already clones the
  inventory into `~/projects` and keeps `projects.code-workspace` in line with it.

## Evidence

Collected 2026-09-25/26:

- `bb machine list`: `xmg-evo` (server, `host_mxiu8qwjrp`) and `xmg-evo-agent-vm`
  (`host_72n75d4h7t`, manual) are both connected.
- `bb project list`: 16 projects. Every one has a single `local_path` source on the host.
  `bb environment list` shows only host paths.
- `scm-tidy`, `spcsim`, and `website-old` are in the inventory but have no BB project.
- VM `~/projects`: only `agent-box-setup`. The VM's virtiofs mounts are only the `geld` /
  `geld-2026` user-data shares.
- VM `gh auth status`: logged in as `dxmann73`, HTTPS protocol.
- **Git identity gap on the VM:**
  - VM `~/.gitconfig` is a symlink (dated 2026-09-12, left over from the old guest baseline) to
    `~/projects/agent-box-setup/user-home/.gitconfig`.
  - That file is untracked. `gh auth setup-git` created it with only the credential helpers, and
    there is no `[user]` section.
  - On the host, `~/.gitconfig` is a symlink to
    `dave.box-setup/agent-box/user-home/.gitconfig`, which has `[user]`, the aliases, the pull/push
    defaults, and the credential helpers. Tools write into `~/.gitconfig` through that symlink, so
    those writes land in the private repository's working tree.
  - `home-dotfiles` excludes `.gitconfig`. `modules/00-os/git-identity/` is an empty folder, which
    the security draft records as finding #15.
- `dave.box-setup` tracks Windows and Office license keys under `windows-box/licenses/`.
- All 19 inventory projects have a `github.com/dxmann73/...` origin.

## Decisions

- **Project placement.** Stay on the host: `agent-box-setup`, `dave.box-setup`, `dave.infra`,
  `clackworks.local-llm`. Every other project moves, including `scm-tidy`, `spcsim`, and
  `website-old`, which do not get new BB projects on the VM.
- **Source of truth.** The project-manager inventory records each project and where it runs. BB
  always matches it. Keeping BB in sync becomes a project-manager duty. This repository holds no
  project names.
- **Switch, don't duplicate.** Keep each BB project ID. Add the VM clone as default, then delete the
  host source. Thread history stays in the project.
- **Old threads.** Migrate the active threads that are cleared and empty first, and the rest
  afterwards.
  - A cleared, empty thread has no live context, so a fork brings nothing useful. Instead, create a
    new thread on the VM with the same provider, model, and title, then archive the old thread.
  - Threads with work after their last clear follow later (Open Question 2).
- **Clone from GitHub** (`--clone`), not virtiofs. The host `$HOME` stays unexposed.
- **Host cleanup.** Delete a project's host checkout only after its BB switch has been tested. Do
  not use a holding folder.
- **Git config.** There is one real `~/.gitconfig` file per box. It is not a symlink, and there is no
  `.gitconfig.local`.
  - Owner: `modules/00-os/git-identity/`, ticked on `xhost`, `xagt`, and `bhost`.
  - The content comes from the private repository's
    `dave.box-setup/agent-box/user-home/.gitconfig`.
  - A real file lets `gh auth setup-git` and other tools write to it without changing a repository.
  - On the host, `apply.sh` replaces the symlink with a copy.
  - On the VM, the host streams the file over SSH, like the guest baseline. `dave.box-setup` is not
    cloned onto the VM, because it holds license keys and the VM runs agents in YOLO mode.
  - The rule "everything in `user-home/` is symlinked" covers the public `user-home/`.
    `.gitconfig` is the private repository's file, and the `git-identity` README states this
    exception.
- **VS Code workspace.** The VM gets its own `~/projects/projects.code-workspace` for VS Code
  Remote SSH. It lists the VM projects. The host workspace keeps only the host-only projects. The
  project manager maintains both.
- blade-14 is out of scope.

## Implementation

1. **`git-identity` module (this repository).**
   - Add `modules/00-os/git-identity/` with `README.md`, `recipe.md`, `apply.sh`, and `verify.sh`.
   - Add a catalog row to `modules/README.md` §0 (`cfg`, `sit -`, `scp both`, ticked on `xhost`,
     `xagt`, and `bhost`).
   - `apply.sh --target daily-host` copies the private repository's file to `~/.gitconfig` and
     replaces an existing symlink. It fails fast if the source file is missing.
   - `apply.sh --target agent-vm` runs on the host. It streams the same file to the VM's
     `~/.gitconfig` over the libvirt-bridge SSH path, and replaces the dangling symlink there.
   - After the copy, run `gh auth setup-git` again on each box so the credential helpers are present.
   - `verify.sh`: `~/.gitconfig` is a regular file, `user.name` and `user.email` are set, and the
     credential helper for `https://github.com` is set.
   - Remove the untracked `user-home/.gitconfig` from the VM's `agent-box-setup` checkout.
   - Update the `home-dotfiles` README and recipe: `.gitconfig` is owned by `git-identity`.
2. **Project manager (in `clackworks.agent-coordinator`).**
   - Add a "Runs on" column to `inventory.md` (`vm` or `host`).
   - Add a "Keep BB in sync" duty to `project-manager/README.md`:
     - Every inventory project has a BB project whose only source is on the named machine.
     - BB projects not in the inventory are reported, not deleted.
   - Split "Populate a fresh machine" by machine: the VM clones `vm` projects, and the host clones
     `host` projects. Each machine maintains its own `projects.code-workspace`.
3. **Pilot with `nomap`.**
   1. Check that the host tree is clean and pushed.
   2. Add the VM source as the default source.
   3. Start a new thread. Confirm `hostname` = `xmg-evo-agent-vm` and `pwd` = `~/projects/nomap`.
   4. Fork one old `nomap` thread onto the VM environment, and record what carries over (Open
      Question 1).
   5. Delete the host source, then delete the host checkout.
4. **Roll out** the rest, one project at a time, with the same checks. Before
   `dave.financial-advisor` and `dave.macros` move, the user commits or discards their uncommitted
   changes.
5. **Create** BB projects on the VM for `scm-tidy`, `spcsim`, and `website-old`.
6. **Migrate cleared threads.** Do this after each owning project has its VM source:
   - Repeat the scan from Evidence to catch threads cleared since.
   - For each active thread that is cleared and empty in a moved project, create a thread on the
     VM checkout with the same provider, model, and title, then archive the old thread.
7. **Migrate the remaining active threads** by the method chosen for Open Question 2.
8. **VS Code workspaces.**
   - Create the VM's `~/projects/projects.code-workspace`.
   - Trim the host workspace to the host-only projects.
   - Open the VM workspace over VS Code Remote SSH once, as a check.

## Acceptance Criteria

- On both the VM and the host:
  - `~/.gitconfig` is a regular file with `user.name` and `user.email` set.
  - `git-identity` verify passes.
- Every inventory project marked `vm` has exactly one BB source, and that source is on
  `xmg-evo-agent-vm`.
- Every project marked `host` has exactly one BB source, on `xmg-evo`.
- The BB project list and the inventory agree. No project is missing and none is extra.
- A new thread in a moved project reports hostname `xmg-evo-agent-vm`.
- Thread history of moved projects is still visible in BB.
- The host `~/projects` contains only host-only projects.
- The VM `projects.code-workspace` opens over Remote SSH and lists the VM projects.
- `dave.box-setup` is not present on the VM.
- No host directory beyond the existing user-data shares is exposed to the VM.

## Verification

```bash
./modules/00-os/git-identity/verify.sh --target daily-host
ssh xmg-evo-agent-vm '~/projects/agent-box-setup/modules/00-os/git-identity/verify.sh --target agent-vm'
./modules/verify-box.sh xagt --list | grep git-identity
bb project list
bb project show <id>          # one source, on the machine named in the inventory
ssh xmg-evo-agent-vm 'ls ~/projects; test ! -e ~/projects/dave.box-setup'
ls ~/projects                 # host: only host-only projects remain
```

Also run the two repository greps from `AGENTS.md`. The module must not embed the user's name or
email.
