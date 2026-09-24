# losslesscut

What: LosslessCut, an ffmpeg GUI for lossless trimming and cutting of video and audio.

Does: Provides host-side lossless cut/merge of media without re-encoding. Installed as the upstream
AppImage in `~/Applications/LosslessCut.AppImage`, with an application-menu entry and icon. The
weekly `~/update-tools.sh` run keeps it current through [update.sh](update.sh), because LosslessCut
has no built-in updater.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `./apply.sh`

Verify: `./verify.sh`

Not the snap: the snap is built on `core18` and bundles a 2018 Mesa that cannot drive current AMD
GPUs. Its GPU process fails to initialize EGL and the main process segfaults.
