# Agent rules for agent-box-setup

This repository configures machines that run coding agents in YOLO mode. The agent VM is the
security boundary. [docs/specification/agent-box.md](docs/specification/agent-box.md) is the
architecture source of truth; [modules/README.md](modules/README.md) is the capability catalog.

Hardware, locale, personal applications, machine sizes, identities, and remote URLs live in the
[deployment overlay](https://github.com/dxmann73/dave.box-setup/tree/main/agent-box).

## Project rules

- Every setup capability belongs to exactly one catalog module under `modules/`. Classify it before
  adding files; keep each module's README short and put implementation in adjacent scripts,
  configuration, or unit files.
- Do not add dual-boot, migration, or WSL instructions. This grep must stay empty:

  ```bash
  grep -rilE 'bitlocker|fast startup|dual.?boot|windows partition|shrink windows|ntfs|WSL|/mnt/c|winget install|DrvFs' \
    modules agents user-home START-HERE.md docs verify-setup.sh --exclude-dir=skills
  ```

- Do not put deployment-specific identities or values in reusable payload trees. This grep must
  stay empty:

  ```bash
  grep -rilE 'xmg-evo|890M|HX 370|tailb67542|dxmann73@gmail|clackworks\.agents|/Dropbox/Docs/Geld|de_DE|plasma-localerc|VibeTyper|vibe-typer' \
    agents user-home START-HERE.md docs verify-setup.sh --exclude-dir=skills
  ```

- Box-level work lives in `modules/`, `agents/`, and `user-home/`. Project-level skills and
  language toolchains are installed globally as an interim measure.
- The local LLM/model runtime is out of scope; reference
  <https://github.com/dxmann73/local-llm> instead.
- `agents/skills/` is the single source of truth for installed skills. Keep `agents/README.md` and
  the relevant module verifier in sync with it.
- Everything in `user-home/` is symlinked into `~`, never copied. The repository-root
  `.markdownlint.json` is symlinked to `~/projects/.markdownlint.json`.

## Running setup

- Choose the catalog box ID before applying any recipe. Read its tick, requirements, and `sit`.
- Follow the catalog operator schedule. On daily hosts, start `host-sudo-session` before rootful
  work.
- Check existing installation state. Ask before optional tools or unapproved data/security choices.
- Never embed secrets in recipes. Diagnose failures before continuing.
- Verify with `./modules/verify-box.sh BOX --bootstrap|--operational|--full`; use `--list` to
  preview the exact catalog-derived commands.
