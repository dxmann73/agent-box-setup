# 03 - Development Environment

Programming languages and runtimes.

## Prerequisites

- Completed `02-core-tools.md`
- Package manager available

---

## 1. Node.js

Install Node.js **system-wide from the NodeSource apt repository**, not with nvm.

Two reasons, both of which cost real time otherwise:

- **Services cannot see an nvm Node.** nvm lives in `~/.nvm` and is wired up by an interactive
  `.bashrc`. The T3 Code server runs as a systemd user unit and the provider CLIs it launches
  inherit that non-interactive environment, so an nvm-installed `node`, `claude` or `codex` is
  simply not on `PATH` — this is the single most common reason a provider shows up as missing in
  T3 Code ([`../vm/04-t3code.md`](../vm/04-t3code.md) §1). Cron jobs and SSH-launched environments
  have the same problem.
- **Updates.** An apt-installed Node is patched by the same unattended-upgrades run as everything
  else ([08-auto-updates.md](08-auto-updates.md)). An nvm Node is patched when you remember.

```bash
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
  | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt update && sudo apt install -y nodejs
```

Node 22 is the current LTS and satisfies T3 Code's `^22.16 || ^23.11 || >=24.10`. To move to the
next LTS later, change `node_22.x` in that file and `apt upgrade`.

**Verify installation:**

```bash
node --version                      # v22.x
npm --version
command -v node                     # /usr/bin/node, not a path under ~/.nvm
```

### A user-owned global prefix

By default an apt-installed Node puts global packages in `/usr/lib/node_modules`, so every
`npm install -g` needs `sudo` — and an unattended update timer
([08-auto-updates.md](08-auto-updates.md)) cannot use `sudo` at all. Point the prefix at the home
directory instead:

```bash
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
```

`~/.npm-global/bin` is already on `PATH` via this repo's `.bashrc`
([00-home-environment.md](00-home-environment.md)). Confirm, in a new shell:

```bash
npm config get prefix        # /home/you/.npm-global
npm root -g                  # /home/you/.npm-global/lib/node_modules
```

Every `npm install -g` below then runs as your own user, and so does the weekly update.

### If you already have nvm

Leaving nvm installed alongside is fine as long as it does not shadow the system Node in
non-interactive shells. Check with:

```bash
ssh localhost 'command -v node'     # must print /usr/bin/node
```

If it prints an `~/.nvm` path, comment the nvm block out of `.bashrc` and reinstall the global CLIs
against the system Node. Keep nvm only if you actually need to switch Node versions per project.

---

## 2. Package Managers and Global JS Tools

Bootstrap `pnpm` with Corepack and install global JS tools.

```bash
corepack enable
corepack prepare pnpm@latest --activate
hash -r
pnpm --version
npm install -g typescript ts-node
```

If `pnpm --version` still shows an older globally installed release, open a new shell or run
`hash -r` again so Bash stops using a cached `/usr/bin/pnpm` path and picks up the Corepack shim.

**Verify installation:**

```bash
tsc --version
ts-node --version
type -a pnpm
hash -r
pnpm --version
```

Expected output: Version numbers for TypeScript and ts-node, plus `pnpm` resolving to the Corepack
shim under your active Node installation and reporting the latest stable release (currently 11.x).

---

## 3. Markdown Tooling

For faster Markdown workflows, install `markdownlint-cli` globally:

```bash
npm install -g markdownlint-cli
```

**Verify installation:**

```bash
markdownlint --version
```

Expected output: `markdownlint-cli x.x.x` or similar

If you skip the global install, the shared markdownlint skill still works by falling back to
`npx --yes markdownlint-cli`.

---

## 4. Search Tools (ripgrep)

Install `ripgrep` as a dedicated search tool.

```bash
sudo apt install -y ripgrep
```

**Verify installation:**

```bash
rg --version
```

Expected output: `ripgrep x.x.x` or similar

---

## 5. Firecrawl CLI

Install Firecrawl CLI globally. This is required for the `firecrawl` skill used by agents.

```bash
npm install -g firecrawl-cli
```

**Verify installation and authentication status:**

```bash
firecrawl --status
```

Expected output should include:

- CLI version
- `Authenticated` status

If authentication is missing, tell the user to set up FIRECRAWL_API_KEY in ~/.bash_secrets

---

## 6. Playwright Browser Runtime (for frontend browser tests)

Some frontend test suites run in a real browser through Playwright. Install Chromium and its system
libraries once, machine-wide, so those tests do not fail at startup and no project has to repeat
the download.

```bash
sudo npx --yes playwright@latest install-deps chromium
npx --yes playwright@latest install chromium
```

`install-deps` installs apt packages and needs root; `install` writes into
`~/.cache/ms-playwright` and must run as your own user. If the system packages are already there,
`install-deps` is effectively a no-op.

Inside a project that pins its own Playwright version, `pnpm exec playwright install chromium`
fetches the matching build; that is a per-project step, not part of machine setup.

This is the agent VM's browser automation path — see
[`../vm/02-dev-and-agents.md`](../vm/02-dev-and-agents.md) §4 for why it must never touch the
host's personal Chrome profile.

---

## 7. SDKMAN

[SDKMAN](https://sdkman.io/) manages different versions of Java, Maven, Quarkus, etc. It supports
auto-switching SDKs when you `cd` into a directory with a `.sdkmanrc`.

```bash
cd ~
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
```

Enable auto-env so SDKMAN auto-loads SDK versions from `.sdkmanrc` on `cd`:

```bash
sed -i 's/sdkman_auto_env=false/sdkman_auto_env=true/' ~/.sdkman/etc/config
```

**Verify SDKMAN installation:**

```bash
sdk version
```

Expected output: `SDKMAN x.x.x` or similar

**Verify auto-env is enabled:**

```bash
grep sdkman_auto_env ~/.sdkman/etc/config
```

Expected output: `sdkman_auto_env=true`

### Manually trigger an SDKMAN environment reload (if needed)

If you don't see the environment updating on `cd`, you can force a reload with:

```bash
sdk env
```

This should activate the SDKs as defined in `.sdkmanrc` and print the versions being used.

---

## 8. Java (via SDKMAN)

```bash
sdk install java 21.0.8-oracle
```

**Verify installation:**

```bash
java --version
```

Expected output: `java 21.0.8` or similar

---

## 9. Quarkus and Maven (via SDKMAN)

```bash
sdk install quarkus
sdk install maven
```

**Verify installation:**

```bash
quarkus --version
mvn --version
```

Expected output: Version numbers for both Quarkus CLI and Maven

### Enable Quarkus Build Analytics

Opt in to anonymous build analytics so the Quarkus community can track adoption
([details](https://quarkus.io/usage/)). This prevents the interactive prompt that blocks
non-interactive dev runs.

```bash
mkdir -p ~/.redhat
echo '{"disabled":false}' > ~/.redhat/io.quarkus.analytics.localconfig
```

**Verify:**

```bash
cat ~/.redhat/io.quarkus.analytics.localconfig
```

Expected output: `{"disabled":false}`

---

---

## Complete Verification

Run all verification commands:

```bash
echo "=== Node.js & npm ===" && \
node --version && \
npm --version && \
echo -e "\n=== Global JS tools ===" && \
tsc --version && \
ts-node --version && \
type -a pnpm && \
hash -r && \
pnpm --version && \
echo -e "\n=== Markdown tooling ===" && \
(markdownlint --version || npx --yes markdownlint-cli --version) && \
echo -e "\n=== Search tools ===" && \
rg --version && \
echo -e "\n=== Firecrawl ===" && \
firecrawl --status && \
echo -e "\n=== SDKMAN ===" && \
sdk version && \
echo "Auto-env: $(grep sdkman_auto_env ~/.sdkman/etc/config)" && \
echo -e "\n=== Playwright (frontend browser tests) ===" && \
ls ~/.cache/ms-playwright || echo "No Playwright browser cache found yet" && \
echo -e "\n=== Java Development ===" && \
java --version && \
quarkus --version && \
mvn --version | head -1
```

All commands should complete successfully and show version numbers.

## Verification Checklist

Confirm all tools are working:

- [ ] Node.js installed: `node --version` shows v22.x or similar
- [ ] npm available: `npm --version` shows version
- [ ] `command -v node` is `/usr/bin/node`, in an interactive *and* a non-interactive shell
- [ ] `npm config get prefix` is `~/.npm-global`, and `npm install -g` needs no `sudo`
- [ ] TypeScript compiler: `tsc --version` shows version
- [ ] ts-node runtime: `ts-node --version` shows version
- [ ] Markdown linting available: `markdownlint --version || npx --yes markdownlint-cli --version`
- [ ] pnpm package manager: `type -a pnpm` shows the Corepack shim first, then
      `hash -r && pnpm --version` shows the latest stable version
- [ ] ripgrep installed: `rg --version` shows version
- [ ] Firecrawl CLI installed and authenticated: `firecrawl --status` shows `Authenticated`
- [ ] Playwright Chromium installed for frontend browser tests
- [ ] SDKMAN installed: `sdk version` shows version
- [ ] SDKMAN auto-env enabled: config shows `sdkman_auto_env=true`
- [ ] Java installed: `java --version` shows 21.x
- [ ] Quarkus installed: `quarkus --version` shows version
- [ ] Maven installed: `mvn --version` shows version

**Next:** Continue to `04-ide+tooling.md`. For imaging tools (ImageMagick, sharp, resvg), see
`07-imaging-tools.md`.
