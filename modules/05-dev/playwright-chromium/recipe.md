# playwright-chromium recipe

Run on the agent VM only, after `node-24`. It installs Playwright's Chromium build and its system
dependencies. It never touches the separate personal-browser guest or its profile. Agents should
normally run headless; a full Chromium build remains available for screenshots and headed debugging.

```bash
./apply.sh --target agent-vm
./verify.sh --target agent-vm
```

The verifier runs an isolated temporary-page screenshot using Playwright Chromium.
