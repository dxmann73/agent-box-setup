# Maintenance Checklist

Perform this review periodically and after major machine or toolchain changes.

## Agent Box

- [ ] Identify whether review runs on host or VM, then perform corresponding setup verification.
- [ ] Inspect coding-agent CLI versions, authentication state, configuration, hooks, and shared
      skill symlinks.
- [ ] Confirm agent processes and T3 Code server state match intended host and VM roles.
- [ ] Review available disk space, VM health, snapshots, backups, and recovery readiness.
- [ ] Check that project access remains limited to intended directories and credentials.
- [ ] Review toolchain updates and any upgrade failures from scheduled maintenance.
- [ ] Check symlinks in `~/` and `~/projects`, including `user-home/` dotfiles and Markdown lint
      configuration; flag broken or replaced links.

## Documentation Hygiene

- [ ] Keep architecture and setup documentation aligned with actual machine state.
- [ ] Keep `agents/skills/`, agent documentation, and setup verification aligned.
- [ ] Confirm project-level dependencies stay in project documentation and box-level dependencies
      stay in this repository's machine and agent guides.
- [ ] Review pending plans, TODOs, and temporary migration notes; either advance, archive, or update
      them.
