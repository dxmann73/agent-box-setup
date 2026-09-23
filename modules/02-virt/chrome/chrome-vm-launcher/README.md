# chrome-vm-launcher

What: Host launcher for the personal browser guest.

Does: Adds a pinned desktop launcher that starts `chrome-vm` on demand and attaches `virt-viewer`.
It deliberately rejects URL arguments, so the host stock browser remains responsible for local
callbacks, device-code flows, and utility browsing.

Catalog metadata: see [Modular machine catalog](../../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `./apply.sh`

Verify: `./verify.sh`
