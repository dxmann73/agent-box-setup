# Specification Agent Box

1. **Ubuntu host**

   - Ubuntu is the primary desktop OS.
   - as a laptop it can be used when travelling so it will contain personal apps
   - Normal personal apps and data remain outside the agent VM. The deployment may place personal
     browsing on the host or in a separate personal browser guest; sync clients and documents stay
     on the host. Prepare the selected browser before remaining account setup.
   - A local LLM/model runtime runs directly on the host so it can efficiently use the GPU. Its
     setup is out of scope here and lives in a separate repo:
     <https://github.com/dxmann73/local-llm>.

2. **Agent isolation**

   - Coding agents should not have general access to the host filesystem.
   - Agents should not have access to personal files, browser profiles, Dropbox, SSH credentials,
     etc., unless explicitly provided.
   - Isolation must apply to subprocesses launched by agents as well.

3. **Agent VM**

   - Run a persistent Ubuntu VM on the Ubuntu host.
   - Most agent-related software lives inside this VM.
   - The VM becomes the main security boundary.
   - The VM should be relatively easy to recreate.

4. **BB**

   - Use the Linux desktop AppImage server on the host as the shared BB control plane.
   - Enroll the VM into that server as a separate execution machine. Keep unrestricted execution
     inside the VM; host execution remains supervised.
   - Run many concurrent agents plus ordinary terminals/processes in the VM: dev servers, test
     watchers, build processes, etc.
   - Authorized desktop and phone clients must be able to reach the host server. That path may be
     private Tailscale Serve; this box's URLs live in the `infra` project. Do not expose the raw BB
     port.
   - A headless BB server inside the VM may remain as a temporary standalone fallback with
     independent history. It is not the shared client entry point and can be disabled after the
     central path is proven.

5. **Coding agents**

   - Install Claude Code, Codex, Cursor CLI, and Pi on both host and VM.
   - Run multiple agent instances in the VM.

6. **Development environment**

   - Install the complete development toolchain in the VM:

     - Git
     - Node/npm/etc.
     - JDK
     - Python
     - compilers
     - jq/yq
     - project-specific tooling
     - coding-agent CLIs

7. **Browser automation**

   - Agents need browser access for testing and producing proof of their work (Screenshots, traces,
     videos, console output)
   - Install Chromium/Chrome and preferably Playwright inside the VM.
   - Browser sessions should not use your personal host Chrome profile.
   - Headless browser automation should be the normal mode.

8. **Projects**

   - Agents need read/write access to the projects they're working on.
   - Projects live inside the VM
   - Avoid exposing the entire host `$HOME` to the VM.

9. **Agent configuration repository**

   - Your existing GitHub repository remains the source of truth for:

     - skills
     - agent configurations
     - prompts/instructions
     - scripts
     - BB configuration
     - browser workflows
     - other shared agent infrastructure.

   - Clone/synchronize this repository inside the VM.
   - Prefer deterministic scripts for updating the VM from this repository rather than relying on an
     agent to manually reproduce machine state.

10. **Local model**

    - Local model runtime stays on the Ubuntu host because it needs direct GPU access.
    - Agents inside the VM should be able to reach its inference API over a controlled network
      interface.

11. **Networking**

    - VM needs outbound Internet access for LLM APIs, GitHub, package managers, browser testing,
      etc.
    - VM needs controlled connectivity to the host's local-model endpoint.
    - The host's shared BB server needs to be reachable from authorized external machines.
    - That path may use Tailscale for host URLs and SSH; the tailnet is specified and operated in
      the `infra` project, not here.

12. **Credentials**

    - Authenticate GitHub over HTTPS with the VM's full account; rotate it independently of the
      host.
    - Keep VM API credentials separate from the host.
    - Treat the VM as an environment in which agents can potentially read credentials available to
      them.

13. **Reproducibility**

    - VM setup should be scripted.
    - Ideally:

```text
fresh Ubuntu VM
      ↓
bootstrap script
      ↓
development tools
      ↓
agents
      ↓
BB
      ↓
Playwright/browser
      ↓
agent-config repository
      ↓
ready
```

1. **Persistence/recovery**

   - BB sessions and agent processes should survive disconnecting your host-side client.
   - VM can remain running continuously.
   - Set up VM snapshots/backups.
