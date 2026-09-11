# VM load test

**Status:** to do. Run it once the agent VM has its toolchain, agents and BB
([`../machines/vm/02-dev-and-agents.md`](../machines/vm/02-dev-and-agents.md) to
[`../machines/vm/04-bb.md`](../machines/vm/04-bb.md)).

The VM sizing was chosen on 2026-09-11 from reasoning, not measurement. This test checks it. When it
is done, record the results in
[`../machines/host/05-hypervisor.md`](../machines/host/05-hypervisor.md) §5 and delete this note.

## Starting point

- Host: AMD Ryzen AI 9 HX 370, 12 cores / 24 threads of two kinds — 4 Zen 5 cores (threads 0–3,
  12–15, up to 5.16 GHz) and 8 Zen 5c cores (threads 4–11, 16–23, up to 3.29 GHz). Laptop-class
  power limits.
- 93 GiB RAM, shared with the Radeon 890M iGPU: 512 MiB carve-out, GTT up to 46 GiB. The local LLM
  runs on the iGPU out of system RAM and system memory bandwidth.
- VM: 32 GiB RAM, vCPU count as in the `virt-install` command in `05-hypervisor.md` §5.
- cgroup CPU weights left at the default 100 for `machine.slice` (the VM), `user.slice` (the
  desktop) and `system.slice`. Weights only act under contention: an idle host leaves all CPU to the
  VM, a saturated host splits it between the busy slices.

## Assumptions to verify

1. Under full load the host desktop stays usable: Plasma, Chrome and VS Code respond.
2. With the host idle, the VM gets all the CPU it asks for.
3. VM 32 GiB + LLM model + host workload fit in RAM without the host swapping or the OOM killer
   firing. The guest fills its RAM with page cache over time, so count the full 32 GiB plus QEMU
   overhead.
4. LLM token rate under heavy VM builds stays acceptable. CPU and iGPU share memory bandwidth, so
   some drop is expected; the question is how much.
5. Sustained all-core load does not throttle the clocks so far that extra vCPUs stop paying off.

## Scenario

- in the VM: several parallel agents through BB, each building and testing (TypeScript, Maven or
  Quarkus), plus Playwright headless Chromium sessions
- on the host: LLM inference running, Chrome and VS Code open and in use
- baseline first: LLM tokens/s and a reference build time, each with nothing else running

## What to watch

| Where | Command                                                  | Tells                                           |
| ----- | -------------------------------------------------------- | ----------------------------------------------- |
| host  | `systemd-cgtop`                                          | CPU and memory per slice: VM vs desktop vs rest |
| host  | `cat /proc/pressure/cpu /proc/pressure/memory`           | time tasks stalled waiting for CPU or memory    |
| host  | `free -h`, `swapon --show`, `vmstat 5`                   | RAM headroom, swap use                          |
| host  | `virsh dommemstat agent-vm`                              | what the guest actually holds                   |
| host  | `grep MHz /proc/cpuinfo`, `sensors`                      | clocks and temperature under sustained load     |
| guest | `vmstat 5` (`st` column), `top` (`st`)                   | steal time: vCPUs ready to run, host busy       |
| guest | `free -h`, `cat /proc/pressure/memory`                   | whether 32 GiB is enough inside the VM          |
| LLM   | tokens/s from the inference server, against the baseline | cost of VM load on inference                    |

## Knobs if an assumption fails

- vCPUs: `virsh setvcpus agent-vm N --config --maximum` and `virsh setvcpus agent-vm N --config`
  with the VM shut down
- CPU priority: `sudo systemctl set-property machine.slice CPUWeight=50` gives the host about 2/3
  under contention
- VM memory: `virsh setmaxmem agent-vm 40G --config` and `virsh setmem agent-vm 40G --config` with
  the VM shut down, or smaller
- guest parallelism: cap build jobs or the number of concurrent agents
- model: pick a smaller one if RAM or bandwidth is the limit
