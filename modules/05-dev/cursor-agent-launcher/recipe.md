# cursor-agent-launcher recipe

Run on catalog-ticked daily hosts after `cursor-cli` and `imaging`. It installs Cursor's public
favicon as a scalable menu icon, renders standard PNG sizes with ImageMagick, and links the tracked
desktop launcher. The launcher opens the separately installed `cursor-agent` CLI in WezTerm.

```bash
./apply.sh --target daily-host
./verify.sh --target daily-host
```
