# Move BB projects from the host OS onto the agent VM

- source: `_plans/drafts/move-bb-projects-to-agent-vm.md`
- priority: p1 (high). The user named this the next thing to do on 2026-09-25.
- status: open (executed 2026-09-26; two projects held back, see Execution status)
- written: 2026-09-25
- refined: 2026-09-26 (clean-slate precondition, BB column, editor decided)
- executed: 2026-09-26

## Goal

BB threads for day-to-day projects run on the agent VM (`xmg-evo-agent-vm`), not on the host
(`xmg-evo`). This matches the spec: the VM is the security boundary, and projects live inside the VM
(`docs/specification/agent-box.md` §4, §8).

The project-manager inventory is the source of truth. It lists every project and where it runs.
Projects marked for BB always have a matching BB project. After a project moves and the move is tested, the host
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

None.

## Background

- BB server: the host AppImage (`modules/05-dev/bb-appimage`). The VM is enrolled as an execution
  machine (`modules/05-dev/bb-enroll-execution-machine`).
- BB model (`bb guide`):
  - A project maps to a repository, and all threads belong to a project.
  - A project can have path sources on more than one machine.
  - An environment (project checkout or worktree) has a fixed machine (`hostId`) and a fixed path.
  - A thread is bound to one environment.
- **Threads cannot be re-pointed.** `bb environment update` changes only the name and the
  merge-base branch. `bb thread update` has no environment or machine option. Archived threads
  stay in the project as history.
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
  `clackworks.local-llm`. Every other project moves.
- **Clean-slate precondition.** Before work starts, the user archives every BB thread, and commits
  and pushes every repository. The migration does not check threads or dirty trees, and does not
  migrate threads.
- **BB column.** The inventory gets a "BB project" column (yes or no). `scm-tidy`, `spcsim`, and
  `website-old` are `no`: they are cloned onto the VM, but get no BB project. Every other project is
  `yes`.
- **Source of truth.** The project-manager inventory records each project, where it runs, and
  whether it has a BB project. BB always matches it. Keeping BB in sync becomes a project-manager duty. This repository holds no
  project names.
- **Switch, don't duplicate.** Keep each BB project ID. Add the VM clone as default, then delete the
  host source. Thread history stays in the project.
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
- **Git editor.** `nano` is the default everywhere, and VS Code terminals open VS Code tabs.
  - `.gitconfig` in the private repository: `core.editor = nano`.
  - Public `user-home/.bashrc`: `EDITOR=nano`, replacing `EDITOR="code --wait"`.
  - Public `user-home/vscode/settings.json`: `terminal.integrated.env.linux` sets `GIT_EDITOR` and
    `EDITOR` to `code --wait`. `GIT_EDITOR` overrides `core.editor`, so only VS Code terminals,
    including Remote SSH terminals on the VM, open a tab. Settings Sync carries this to other
    machines.
  - Reason: `code` exists only in VS Code terminals. With `code --wait`, `git commit` without `-m`
    fails in BB threads and plain SSH sessions.
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
   - Editor: set `core.editor = nano` in the private `.gitconfig`, set `EDITOR=nano` in
     `user-home/.bashrc`, and add the `terminal.integrated.env.linux` entry to
     `user-home/vscode/settings.json`. Check that the setting also applies in a Remote SSH terminal
     on the VM. If it doesn't, add it to the remote settings.
2. **Project manager (in `clackworks.agent-coordinator`).**
   - Add a "Runs on" column (`vm` or `host`) and a "BB project" column (`yes` or `no`) to
     `inventory.md`.
   - Add a "Keep BB in sync" duty to `project-manager/README.md`:
     - Every inventory project marked BB `yes` has a BB project whose only source is on the named
       machine.
     - A project marked BB `no` has no BB project.
     - BB projects not in the inventory are reported, not deleted.
   - Split "Populate a fresh machine" by machine: the VM clones `vm` projects, and the host clones
     `host` projects. Each machine maintains its own `projects.code-workspace`.
3. **Pilot with `nomap`.**
   1. Add the VM source as the default source.
   2. Start a new thread. Confirm `hostname` = `xmg-evo-agent-vm` and `pwd` = `~/projects/nomap`.
   3. Delete the host source, then delete the host checkout.
4. **Roll out** the rest of the BB `yes` projects, one project at a time, with the same checks.
5. **Clone** `scm-tidy`, `spcsim`, and `website-old` onto the VM with `gh repo clone`, and delete
   their host checkouts. They get no BB project.
6. **VS Code workspaces.**
   - Create the VM's `~/projects/projects.code-workspace`.
   - Trim the host workspace to the host-only projects.
   - Open the VM workspace over VS Code Remote SSH once, as a check.

## Execution status (2026-09-26)

Done:

- **`git-identity` module.** `modules/00-os/git-identity/` with `README.md`, `recipe.md`, `apply.sh`,
  `verify.sh`. Catalog row in `modules/README.md` §0 (`cfg`, `sit -`, `scp gen`, `Y` on `xhost`,
  `xagt`, `bhost`; requires `kubuntu-baseline github-cli`) and a `--target "$target"` entry in
  `modules/verify-box.sh`. `apply.sh` takes `--source PATH` (required, no default) so the public
  repository carries no overlay path, and `--vm-host HOST` for `--target agent-vm`.
  Applied on both boxes; `verify.sh` passes on `daily-host` and `agent-vm`. The VM's dangling
  `~/.gitconfig` symlink and the untracked `user-home/.gitconfig` in its checkout are gone.
  `home-dotfiles` README, recipe, and apply usage now name `git-identity` as the owner.
- **Editor.** `core.editor = nano` in the overlay `.gitconfig`, `EDITOR=nano` in
  `user-home/.bashrc`, and `terminal.integrated.env.linux` with `GIT_EDITOR`/`EDITOR` =
  `code --wait` in `user-home/vscode/settings.json`.
- **Project manager.** `inventory.md` has the "Runs on" and "BB project" columns for all 19
  projects, plus the column definitions and the `agent-box-setup` exception. `README.md` gained the
  "Keep BB in sync" duty (now §3) and a per-machine "Populate a fresh machine" duty.
  `maintenance.md` checks placement and BB sync.
- **Pilot and rollout.** 10 of 12 `vm` BB projects switched: `nomap` (pilot), `clackworks.dev`,
  `clackworks.evals`, `clackworks.website`, `dave.agent-coordinator`, `dave.financial-advisor`,
  `dave.macros`, `dave.tax-advisor`, `dave.website`, `social-linkedin`. Each one: VM source added
  with `--clone --target-path /home/dave/projects/<name> --default`, a new thread confirmed
  `hostname` = `xmg-evo-agent-vm` and the expected `pwd`, host source deleted, host checkout deleted
  after re-checking clean tree, no unpushed commits, and identical HEAD on both machines.
- **Clone-only.** `scm-tidy`, `spcsim`, `website-old` cloned onto the VM with `gh repo clone`; host
  checkouts deleted. They have no BB project.
- **Workspaces.** The VM has its own `~/projects/projects.code-workspace` with its 14 folders. The
  host workspace is trimmed to its 6 remaining folders.

Held back:

- **`clackworks.agent-coordinator`** — this migration's own edits to `project-manager/` are
  uncommitted in the host checkout. Switch it after those changes are committed and pushed.
- **`clackworks.ai`** — thread `thr_7ruddakxmx` ("- grok 4.7") is still unarchived. The clean-slate
  precondition says the user archives threads; archive it, then switch.

Both are still `HOST` sources and are listed in the host workspace until they move. Everything else
in the Acceptance Criteria holds.

Notes:

- `bb project source add --clone` defaults to
  `~/.bb-machines/<server>/checkouts/<name>`, not `~/projects/<name>`. `--target-path` is required
  to land in `~/projects`. The pilot's first source was re-added for this reason.
- The VM's `claude-code` OAuth session is expired ("Failed to authenticate: OAuth session expired
  and could not be refreshed"); `codex` works. Two check threads had to be respawned with
  `--provider codex`. This belongs to `claude-login`, not to this plan.
- BB's `proj_personal` (5 archived threads) is not in the inventory. Reported, not deleted.
- `terminal.integrated.env.linux` could not be checked in a live Remote SSH terminal from here. The
  VM has no `~/.vscode-server/data/Machine/settings.json`, so nothing on the guest overrides the
  user setting, but the check itself needs an interactive VS Code window.
- The VM's `agent-box-setup` checkout still predates the `git-identity` module, so the
  `ssh xmg-evo-agent-vm '.../git-identity/verify.sh'` form in Verification works only after this
  repository's changes are committed, pushed, and pulled on the VM. The verifier was run by
  streaming the script over SSH instead.

## Acceptance Criteria

- On both the VM and the host:
  - `~/.gitconfig` is a regular file with `user.name` and `user.email` set.
  - `git-identity` verify passes.
- Every inventory project marked `vm` has a git checkout at `~/projects/<name>` on the VM.
- Every project marked `vm` and BB `yes` has exactly one BB source, and that source is on
  `xmg-evo-agent-vm`.
- Every project marked `host` and BB `yes` has exactly one BB source, on `xmg-evo`.
- The BB project list equals the inventory rows marked BB `yes`.
- A new thread in a moved project reports hostname `xmg-evo-agent-vm`.
- Thread history of moved projects is still visible in BB.
- The host `~/projects` contains only host-only projects.
- The VM `projects.code-workspace` opens over Remote SSH and lists the VM projects.
- `git config core.editor` is `nano` on the host and the VM. In a VS Code terminal,
  `echo $GIT_EDITOR` prints `code --wait`.
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

Also run the two repository greps from `AGENTS.md`.
