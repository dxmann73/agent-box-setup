# Agent bootstrapping

NOTE: **This has already been done by the user already. It is here for future reference**

## Claude

Configured [privacy settings](https://claude.ai/settings/data-privacy-controls) to disallow chat / prompt usage.

Installed [Claude](https://code.claude.com/docs/en/setup)

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Ran `claude` and followed the authentication prompts

## Bootstrap repo

Cloned the box setup repo

```bash
mkdir ~/projects && cd ~/projects && git clone https://github.com/dxmann73/dave-box-setup
```

=> **Let the agent take over from here!**

```bash
cd dave-box-setup && claude --yolo
```
