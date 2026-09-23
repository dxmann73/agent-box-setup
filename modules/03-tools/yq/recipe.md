# yq recipe

Run after `kubuntu-baseline` on every catalog-ticked daily host or agent VM. Chrome guests do not
receive this module.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/03-tools/yq
sudo ./apply.sh --target daily-host
```

Use `--target agent-vm` inside the agent VM. This preserves the established Ubuntu `yq` package; it
is the Python/jq wrapper rather than mikefarah/yq, so use its documented jq-style expression syntax.

## Verify

```bash
./verify.sh --target daily-host
```

The verifier checks the package, PATH, and a small YAML query.
