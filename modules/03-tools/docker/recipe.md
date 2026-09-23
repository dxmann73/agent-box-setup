# docker recipe

Docker is catalog-ticked only on the agent VM. Do not apply it to a daily host: membership in the
`docker` group is equivalent to root because the daemon can mount the host filesystem into a
container. The agent VM is the intended boundary for that trade-off.

Run after `kubuntu-baseline`. Docker Compose remains a deployment-overlay choice and is not part of
this generic module.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/03-tools/docker
sudo ./apply.sh --target agent-vm
```

Apply installs Ubuntu's `docker.io`, adds the invoking desktop user to `docker`, and enables the
daemon. Log out and back in before using Docker without `sudo`.

## Verify

```bash
./verify.sh --target agent-vm
```

This verifies the package, service, active group membership, and daemon access without pulling an
image. After a new login, use the explicit networked smoke test:

```bash
./verify.sh --target agent-vm --smoke
```
