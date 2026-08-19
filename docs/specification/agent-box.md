## Requirements Agent Box

1. **Ubuntu host**

   * Ubuntu is the primary desktop OS.
   * as a laptop it can be used when travelling so it will contain personal apps
   * Normal personal apps and data remain on the host: Chrome, Dropbox, documents, etc.
   * A local LLM/model runtime runs directly on the host so it can efficiently use the GPU.

2. **Agent isolation**

   * Coding agents should not have general access to the host filesystem.
   * Agents should not have access to personal files, browser profiles, Dropbox, SSH credentials, etc., unless explicitly provided.
   * Isolation must apply to subprocesses launched by agents as well.

3. **Agent VM**

   * Run a persistent Ubuntu VM on the Ubuntu host.
   * Most agent-related software lives inside this VM.
   * The VM becomes the main security boundary.
   * The VM should be relatively easy to recreate.

4. **Herdr**

   * Run one Herdr server inside the VM.
   * Run many concurrent agents under that Herdr instance.
   * Also run ordinary terminals/processes there: dev servers, test watchers, build processes, etc.
   * Connect to this Herdr instance from the Ubuntu host.
   * Also connect to it from laptops/other machines over the network.
   * Herdr remains the primary UI for observing and interacting with the agents.

5. **Multiple agents**

   * Claude Code, Codex, Pi, etc. should coexist in the VM.
   * Multiple instances should run simultaneously.
   * Agent choice should not affect the isolation architecture.

6. **Development environment**

   * Install the complete development toolchain in the VM:

     * Git
     * Node/npm/etc.
     * JDK
     * Python
     * compilers
     * jq/yq
     * project-specific tooling
     * coding-agent CLIs

7. **Browser automation**

   * Agents need browser access for testing and producing proof of their work (Screenshots, traces, videos, console output)
   * Install Chromium/Chrome and preferably Playwright inside the VM.
   * Browser sessions should not use your personal host Chrome profile.
   * Headless browser automation should be the normal mode.

8. **Projects**

   * Agents need read/write access to the projects they're working on.
   * Projects live inside the VM
   * Avoid exposing the entire host `$HOME` to the VM.

9. **Agent configuration repository**

   * Your existing GitHub repository remains the source of truth for:

     * skills
     * agent configurations
     * prompts/instructions
     * scripts
     * Herdr configuration
     * browser workflows
     * other shared agent infrastructure.
   * Clone/synchronize this repository inside the VM.
   * Prefer deterministic scripts for updating the VM from this repository rather than relying on an agent to manually reproduce machine state.

10. **Local model**

    * Local model runtime stays on the Ubuntu host because it needs direct GPU access.
    * Agents inside the VM should be able to reach its inference API over a controlled network interface.

11. **Networking**

    * VM needs outbound Internet access for LLM APIs, GitHub, package managers, browser testing, etc.
    * VM needs controlled connectivity to the host's local-model endpoint.
    * Herdr needs to be reachable from authorized external machines.
    * Find a way to access Herdr from the public Internet (tailscale, herdr app).

12. **Credentials**

    * Maintain agent-specific credentials inside the VM.
    * Don't share the host's entire `.ssh`, cloud configuration, browser credentials, etc.
    * Prefer purpose-specific GitHub/SSH/API credentials.
    * Treat the VM as an environment in which agents can potentially read credentials available to them.

13. **Reproducibility**

    * VM setup should be scripted.
    * Ideally:

```text
fresh Ubuntu VM
      ↓
bootstrap script
      ↓
development tools
      ↓
agents
      ↓
Herdr
      ↓
Playwright/browser
      ↓
agent-config repository
      ↓
ready
```

14. **Persistence/recovery**

    * Herdr sessions and agent processes should survive disconnecting your host-side client.
    * VM can remain running continuously.
    * Set up VM snapshots/backups.
