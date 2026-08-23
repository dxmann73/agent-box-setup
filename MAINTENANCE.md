# Maintenance Checklist

Perform this review periodically and after major machine, toolchain, or project changes. Record
findings and follow-up work in the owning project; this file intentionally contains no automation.

## Project Inventory

- [ ] List visible directories directly under `~/projects`.
- [ ] Compare that list with `projects/README.md`.
- [ ] Add every unlisted project, remove entries only after confirming the directory was retired,
      and update changed descriptions or dependencies.
- [ ] For every listed project, read its README, manifests, setup scripts, MAINTENANCE.md and
      `AGENTS.md`.
- [ ] Check required language runtimes, package managers, containers, browser binaries, credentials,
      mounted directories, and external services.
- [ ] Flag missing, unavailable, outdated, or undocumented dependencies and record their owner.
- [ ] Confirm dependencies between local projects still point at existing paths and current
      services.

## Agent Box

- [ ] Identify whether review runs on host or VM, then perform corresponding setup verification.
- [ ] Inspect coding-agent CLI versions, authentication state, configuration, hooks, and shared
      skill symlinks.
- [ ] Confirm agent processes and T3 Code server state match intended host and VM roles.
- [ ] Review available disk space, VM health, snapshots, backups, and recovery readiness.
- [ ] Check that project access remains limited to intended directories and credentials.
- [ ] Review toolchain updates and any upgrade failures from scheduled maintenance.

## Repository Health

- [ ] Review Git remotes, current branches, uncommitted work, and stale local branches in every
      project.
- [ ] Check symlinks in `~/` and `~/projects`, including `user-home/` dotfiles and Markdown lint
      configuration; flag broken or replaced links.
- [ ] Check documentation links and references to renamed, moved, or deleted local projects.

## Documentation Hygiene

- [ ] Keep architecture and setup documentation aligned with actual machine state.
- [ ] Keep `agents/skills/`, agent documentation, and setup verification aligned.
- [ ] Confirm project-level dependencies stay in project documentation and box-level dependencies
      stay in this repository's machine and agent guides.
- [ ] Review pending plans, TODOs, and temporary migration notes; either advance, archive, or update
      them.
