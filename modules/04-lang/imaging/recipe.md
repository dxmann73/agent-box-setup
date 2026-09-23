# imaging recipe

Run after `kubuntu-baseline` and `node-24` on catalog-ticked daily hosts only. This is a Dave
overlay module; Chrome guests and agent VMs do not receive these tools.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/04-lang/imaging
sudo ./apply.sh --target daily-host
```

Apply installs ImageMagick, FFmpeg, Inkscape, GraphicsMagick, pngquant, optipng, ExifTool, and
Pillow through apt. It installs `sharp`, `sharp-cli`, and `@resvg/resvg-js` in the invoking user's
`~/.npm-global` prefix.

## Verify

```bash
./verify.sh --target daily-host
```

Run the verifier as the normal desktop user. It checks the apt packages and executables plus the
Node and Python module imports.
