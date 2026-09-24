# Agent Box Setup

Modular setup recipes for daily Kubuntu hosts and their persistent agent or browser guests. The
[specification](docs/specification/agent-box.md) defines the architecture; the
[module catalog](modules/README.md) defines each box's ticked capabilities.

## Start here

On a fresh physical Kubuntu host, follow [START-HERE.md](START-HERE.md). It bootstraps one local
agent and the required public and private checkouts. The agent then follows the catalog's operator
schedule and each ticked module's `README.md` and `recipe.md`.

Do not install unchecked modules. Confirm optional tools and deployment-specific choices first.
The separate [local-llm](https://github.com/dxmann73/local-llm) runtime is out of scope.

## Repository map

| Directory | Purpose |
| --- | --- |
| [modules/](modules/) | Catalog, recipes, scripts, module-specific verifiers, and catalog runner |
| [agents/](agents/) | Agent CLI configuration, global rules, and shared skill index |
| [user-home/](user-home/) | Files symlinked into the user's home directory |
| [docs/specification/](docs/specification/) | Agent-box architecture |

Hardware, locale, personal app choices, machine sizes, identities, and remote URLs belong in the
[deployment overlay](https://github.com/dxmann73/dave.box-setup/tree/main/agent-box), not here.

## Module workflow

Each catalog row maps to one directory under `modules/`. Its short `README.md` explains ownership;
`recipe.md`, scripts, configuration, and unit files contain implementation. The catalog's
`requires` column controls dependency order and `sit` controls the human window:

- `boot`: daily-host bootstrap and cached sudo session.
- `iso`: guest installation and console bootstrap.
- `-`: unattended recipe work.
- `login` or `gcred`: explicit authentication after the credential-free acceptance gate.

Keep `agents/` and `user-home/` as payload trees. Every file in `user-home/` is symlinked, never
copied. The repository-root `.markdownlint.json` is likewise symlinked to
`~/projects/.markdownlint.json`.

## Verification

Use the catalog runner on the box being checked:

```bash
cd ~/projects/agent-box-setup
./modules/verify-box.sh xhost --operational
./modules/verify-box.sh xagt --bootstrap
./modules/verify-box.sh xagt --full
./modules/verify-box.sh xchr --full
```

`--list` previews every selected tick and command. The runner reads ticks from `modules/README.md`,
never applies recipes, and skips a host-owned lifecycle check when running inside a guest. Snapshot,
backup, remote-BB, and overlay checks require the non-secret context variables documented by
`./modules/verify-box.sh --help`.

`./verify-setup.sh BOX ...` remains a thin compatibility entry point for the catalog runner.

## Current state

The catalog is the target state. Its **Live vs catalog** table records known differences; reconcile
those boxes only after their module verifier reports the mismatch.
