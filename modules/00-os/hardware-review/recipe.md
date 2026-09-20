# hardware-review recipe

Run this on daily hosts after `kubuntu-desktop` and `kubuntu-baseline`.

## Collect baselines

```bash
cd ~/projects/agent-box-setup/modules/00-os/hardware-review
./collect-baseline.sh
```

The collector installs the standard Mesa/Vulkan inspection tools if they are missing and writes
fresh output under `~/system-info/`.

Use deployment-profile values without storing them here:

```bash
HARDWARE_REVIEW_EXPECT_RAM_GIB=PROFILE_RAM_GIB ./verify.sh
```

## Manual checks

Use the physical configurations the host will actually use:

- expected RAM detected from the deployment profile
- vendor GPU uses the expected kernel driver
- Vulkan detects the vendor GPU
- Wi-Fi stable
- Bluetooth stable
- speakers, microphone, webcam, touchpad, and brightness control work
- suspend/resume works repeatedly on AC and battery
- battery life acceptable
- USB-C, external displays, and docks work where applicable
- host locks on resume, does not idle-lock while plugged in and working, and does not autologin

Keep Kubuntu's stock power profile initially. Measure before adding power or thermal tuning tools.

## Verify

```bash
./verify.sh
```

Set expected values from the active profile when needed:

```bash
HARDWARE_REVIEW_EXPECT_RAM_GIB=PROFILE_RAM_GIB \
HARDWARE_REVIEW_EXPECT_GPU_DRIVER=amdgpu \
./verify.sh
```
