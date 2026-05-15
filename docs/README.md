# End-to-End Run: Pure Autoware + CARLA (Mode A)

Practical guide for running vanilla ROS-only Autoware against CARLA, end to
end, from a cold start through engaging the vehicle.

**What this is.** A reproducible recipe for "Mode A": no Lingua Franca
runtime, no federation, no LF callback shims. Pure ROS 2 publish/subscribe.
This is the simplest configuration and the one we currently keep working on
the mainline branches.

**What this is not.** This does not cover Mode B (LF planning + control hybrid)
or Mode C (full LF federation). Those use a different branch — see
[`lessons.md` §4](./lessons.md) for the recovery path to the LF-shim
snapshot. §7 below covers a halfway point: pure mainline ROS Autoware
with **one** node (currently `shift_decider`) re-implemented as an LF
reactor running in a sidecar process — not the full federation.

**Status.** End-to-end run demonstrated 2026-05-15: goal pose → route →
trajectory → engage → vehicle moves in CARLA. Also demonstrated with the
`shift_decider` reactor under Lingua Franca management (vanilla
composable_node suppressed; gear commands flow from the LF reactor's
inner ShiftDecider into vehicle_cmd_gate). See §7 below.

---

## 0. Prerequisites

### Hardware

| Component | Requirement | Why |
|---|---|---|
| GPU 0 | RTX 3070 (or any Turing+ with sm ≥ 7.5) | CARLA Vulkan rendering + Autoware perception (TensorRT 10) |
| GPU 1 (optional) | unused for Mode A | For Mode C federation only |
| RAM | ≥ 32 GiB | colcon build linker peaks; CARLA Town01 + Autoware ≈ 6-10 GiB |
| Display | HDMI direct, NOT NoMachine | NoMachine contends with CARLA for GPU 0 — see [`lessons.md` §6](./lessons.md) |

### Software

| Software | Version | Source |
|---|---|---|
| Ubuntu | 22.04 | host |
| ROS 2 | Humble | `apt install ros-humble-desktop` |
| NVIDIA driver | ≥ 570 | `nvidia-smi` to verify |
| CARLA | 0.9.16 | `~/carla-0.9.16/CarlaUE4.sh` |
| Autoware Universe | `feat/carla-integration` | this repo's submodules |

### Repo layout (after `vcs import`)

```
parking-demo/lf-autoware/
├── docs/                                ← this file lives here
│   ├── README.md                        ← run guide (this file)
│   └── lessons.md                       ← complete debugging history
├── scripts/                             ← run/teardown wrappers
│   ├── launch_carla.sh                  ← starts CARLA server
│   ├── launch_autoware.sh               ← vanilla Autoware + CARLA bridge
│   ├── engage.sh                        ← /autoware/engage publisher
│   ├── kill_autoware.sh                 ← teardown + SHM cleanup
│   ├── build_lf_autoware.sh             ← builds bin/Autoware from lf-src/Autoware.lf
│   ├── run_lf_autoware.sh               ← runs bin/Autoware with env sourced
│   └── run_shift_decider_test.sh        ← standalone self-test for the shift_decider reactor
├── lf-src/                              ← Lingua Franca reactor sources
│   ├── Autoware.lf                      ← top-level non-federated LF program
│   └── shift_decider/                   ← validated LF reactor (more to come)
├── src/
│   ├── core/autoware_core/              ← upstream tag 1.7.0 (clean mainline)
│   ├── universe/autoware_universe/      ← branch feat/carla-integration
│   ├── launcher/autoware_launch/        ← branch feat/carla-integration
│   └── ...
├── install/                             ← colcon build output
├── bin/                                 ← lfc-dev output (Autoware, shift_decider_main)
└── ~/autoware_map/Town01/               ← NOT in repo; download separately
```

---

## 1. One-time setup (per machine, persists across reboots except where noted)

### 1.1 Kernel UDP buffers (persistent)

Already in place if you inherited this machine:

```bash
sudo tee /etc/sysctl.d/60-cyclonedds-buffers.conf > /dev/null <<'EOF'
net.core.rmem_max=2147483647
net.core.rmem_default=8388608
net.core.wmem_max=2147483647
net.core.wmem_default=8388608
EOF
sudo sysctl --system
```

Verify: `sysctl net.core.rmem_max` should print `2147483647`.

This isn't strictly required (the Mode A bug we hit had nothing to do with
kernel buffers — see [`lessons.md` §2](./lessons.md)) but it's correct hygiene
for ROS 2 + large transient_local messages.

### (Optional) In the setup Shaokai ran, FastDDS was used.
### 1.2 Cyclone DDS config (persistent, only relevant if you switch RMW)

`~/.config/cyclonedds.xml` — not used by Mode A (which is on FastDDS) but
kept around for Mode B/C runs:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<CycloneDDS xmlns="https://cdds.io/config">
    <Domain id="any">
        <General>
            <Interfaces>
                <NetworkInterface name="lo" priority="default" multicast="true"/>
            </Interfaces>
            <AllowMulticast>true</AllowMulticast>
            <MaxMessageSize>65500B</MaxMessageSize>
        </General>
        <Internal>
            <SocketReceiveBufferSize min="10MB"/>
            <SocketSendBufferSize min="10MB"/>
            <Watermarks>
                <WhcHigh>2MB</WhcHigh>
            </Watermarks>
        </Internal>
    </Domain>
</CycloneDDS>
```

And in `~/.bashrc`:

```bash
export CYCLONEDDS_URI=file:///home/shaokai/.config/cyclonedds.xml
```

### 1.3 Loopback multicast (NOT persistent — re-run after every reboot)

```bash
sudo ip link set lo multicast on
```

Check with `ip link show lo` — must show `<LOOPBACK,MULTICAST,UP,LOWER_UP>`.

If this is missing after reboot, Mode A still works (FastDDS doesn't need it
on `lo`), but any Mode B/C run using Cyclone will hang.

### 1.4 Map data

Download Town01 from
[carla-simulator/autoware-contents](https://bitbucket.org/carla-simulator/autoware-contents/)
into `~/autoware_map/Town01/`:

```bash
ls ~/autoware_map/Town01/
# expected:
# lanelet2_map.osm
# map_projector_info.yaml
# pointcloud_map.pcd
```

The `map_projector_info.yaml` ships as `projector_type: Local`. That's
correct — the loader fills in the rest of the schema at runtime.

---

## 2. Build (one time, then incrementally)

### 2.1 Clean mainline state (only if you've been on the LF snapshot branch)

```bash
cd ~/Documents/projects/parking-demo/lf-autoware/src/core/autoware_core
git checkout 1.7.0          # detached HEAD at the upstream tag

cd ../universe/autoware_universe
git checkout feat/carla-integration
git status --short          # should be empty for Mode A
```

If either repo has uncommitted modifications, see
[`lessons.md` §4](./lessons.md) for what they almost certainly are.

### 2.2 Full build

```bash
cd ~/Documents/projects/parking-demo/lf-autoware
source /opt/ros/humble/setup.bash

colcon build --base-paths src \
    --cmake-args -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
    --packages-skip rosapi parking_planner velodyne_nodes \
                    parking_planner_nodes xsens_nodes
```

Notes:

- `--base-paths src` is required. Without it, colcon discovers `fed-gen/`
  and `lf-src/fed-gen/` as duplicate packages and aborts.
- The 5 packages in `--packages-skip` are pre-existing broken upstream
  packages and are not used by Mode A.
- Expected time: ~35 min wall-clock for 442 packages on the dev machine.
- If the link step OOMs on one package (typically
  `autoware_image_projection_based_fusion`), retry the affected packages
  with reduced parallelism:

  ```bash
  MAKEFLAGS='-j4' colcon build --base-paths src \
      --packages-select <package-names> \
      --parallel-workers 2 \
      --cmake-args -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
                   -DCMAKE_BUILD_PARALLEL_LEVEL=4
  ```

### 2.3 Incremental rebuild after editing one package

```bash
colcon build --base-paths src --packages-select <package_name> \
    --cmake-args -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF
```

Then restart the launch — running ROS 2 processes don't pick up new `.so`
files until they start fresh.

---

## 3. Run sequence

Three terminals. Each one fresh so it picks up `~/.bashrc` env (especially
`CYCLONEDDS_URI`, though Mode A doesn't use it).

### Terminal 1 — start CARLA

```bash
bash ~/Documents/projects/parking-demo/lf-autoware/scripts/launch_carla.sh
```

This runs `~/carla-0.9.16/CarlaUE4.sh -prefernvidia -quality-level=Low`.
Add `-RenderOffScreen` for headless if your driver crashes with a display
window — RViz is your visualization, not the CARLA window.

Wait for CARLA to fully load Town01. CPU/GPU usage settles within ~15 s.

### Terminal 2 — start Autoware

```bash
bash ~/Documents/projects/parking-demo/lf-autoware/scripts/launch_autoware.sh
# Add --no-rviz to skip RViz if you only want the ROS stack.
```

This sources ROS Humble, sources the workspace, sets
`RMW_IMPLEMENTATION=rmw_fastrtps_cpp`, and runs:

```
ros2 launch autoware_launch e2e_simulator.launch.xml \
    map_path:=~/autoware_map/Town01 \
    vehicle_model:=sample_vehicle \
    sensor_model:=carla_sensor_kit \
    simulator_type:=carla \
    rviz:=true
```

Expect ~60-90 s for everything to come up. RViz appears around the 30 s mark.

**Do not change `RMW_IMPLEMENTATION` here without also updating
`scripts/engage.sh`** — see [`lessons.md` §7](./lessons.md).

### In RViz

1. Wait for the vehicle to appear and `/localization/initialization_state` to
   reach `3` (initialized). Visually, the vehicle pose lock-in.
2. If localization fails to converge, set **2D Pose Estimate** in RViz near
   the vehicle's actual spawn position.
3. Click **2D Goal Pose** somewhere on a drivable lanelet. RViz must show
   the goal arrow on a colored lane centerline — clicks off-lanelet are
   silently rejected.
4. RViz should render the computed route in colored polygons. If it doesn't,
   skip to §4 and find where it broke.
5. Drag the speed limit bar to a value > 0.

### Terminal 3 — engage

```bash
bash ~/Documents/projects/parking-demo/lf-autoware/scripts/engage.sh
```

Should print `Engage command sent.` in under a second. The vehicle in CARLA
starts moving along the route.

If this hangs on `Waiting for at least 1 matching subscription(s)...` for
more than ~3 s, the most likely cause is the RMW mismatch documented in
[`lessons.md` §7](./lessons.md). Confirm both scripts agree on
`RMW_IMPLEMENTATION`.

---

## 4. Verification checklist

Run these in a 4th terminal (sourced and on the same RMW):

```bash
source /opt/ros/humble/setup.bash
source ~/Documents/projects/parking-demo/lf-autoware/install/setup.bash
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp
```

| # | Check | Expected |
|---|---|---|
| 1 | `ros2 topic list \| wc -l` | ≥ 600 |
| 2 | `timeout 3 ros2 topic echo /map/vector_map --once --no-arr \| head -3` | prints header in <1 s |
| 3 | `ros2 topic echo /localization/kinematic_state` | ~50 Hz stream |
| 4 | `ros2 topic echo /localization/initialization_state` | `state: 3` |
| 5 | `ros2 topic echo /planning/route_state` (before goal) | `state: 1` (UNSET) |
| 6 | Click 2D Goal Pose → re-echo `/planning/route_state` | transitions `1 → 2 → 3` (UNSET → ROUTING → SET) |
| 7 | `ros2 topic echo /planning/route --no-arr \| head -10` | populated `LaneletRoute` |
| 8 | `ros2 topic hz /planning/scenario_planning/trajectory` | ~10 Hz |
| 9 | After engage: `ros2 topic hz /control/command/control_cmd` | ~30 Hz |
| 10 | After engage: `ros2 topic hz /control/command/actuation_cmd` | ~30 Hz |
| 11 | Visual in CARLA spectator view | vehicle moves along route |

Any check that fails sends you to [`lessons.md`](./lessons.md):

- Check 2 (map silent) → §2 (LF callback shim)
- Check 3 silent → §2 (same LF pattern in ekf_localizer / ndt_scan_matcher)
- Check 6 (route stays UNSET) → goal clicked off-lanelet, or §1.6 (diag-graph crash)
- Check 9-10 silent after engage → §1.3 (operation_mode remap), §1.6 (MRM emergency), or §7 (RMW mismatch)

---

## 5. Teardown

```bash
bash ~/Documents/projects/parking-demo/lf-autoware/scripts/kill_autoware.sh
```

Kills all `component_container_mt-*`, the standalone launch-spawned nodes
under `install/`, RViz, the engage publisher, the relay/republish helpers,
**and** clears stale FastDDS SHM locks from `/dev/shm/` plus restarts the
ros2 daemon. Use it between every session — see [`lessons.md` §9.7](./lessons.md)
for what happens if you don't.

If you were also running the LF reactor binary (§8), kill it separately —
the kill script's pattern doesn't include it:

```bash
pkill -KILL -f "bin/Autoware"
```

CARLA is **not** killed by `kill_autoware.sh`. To stop CARLA:

```bash
pkill -KILL -f "CarlaUE4"
```

---

## 6. Common failure modes (and where to look)

| Symptom | Likely cause | Reference |
|---|---|---|
| `Waiting for at least 1 matching subscription(s)` from any helper script | RMW mismatch between script and launch | [`lessons.md` §7](./lessons.md) |
| `ros2 topic echo /map/vector_map` hangs forever | Map subscriber sees no publish (was: LF shim suppressing publish) | [`lessons.md` §2](./lessons.md) |
| `mission_planner: waiting lanelet map... Route API is not ready` | Same as above — map message not delivered | [`lessons.md` §2](./lessons.md) |
| `mission_planner: waiting odometry... Route API is not ready` | Same LF shim pattern in ekf_localizer / gyro_odometer | [`lessons.md` §2](./lessons.md) |
| `vehicle_cmd_gate: Emergency!` after route is set | `duplicated_node_checker` triggered MRM | [`lessons.md` §1.5, §1.6](./lessons.md) |
| Vehicle invisible in CARLA spectator | Spectator chase-cam disabled or `carla_ros.py` reverted | [`lessons.md` §1.4](./lessons.md) |
| `localization/initialization_state` stuck at 1 or 2 | Display server contention (NoMachine), or `ndt_scan_matcher` LF shim | [`lessons.md` §2, §6](./lessons.md) |
| Linker OOM during build | Too many CUDA libraries linking in parallel | §2.2 retry with reduced parallelism |
| `lanelet2_map_loader` warning `format_version: null` | Town01 map has no version tag | [`lessons.md` §8](./lessons.md) — ignore |
| `RTPS_TRANSPORT_SHM Error: open_and_lock_file failed` floods | Stale `/dev/shm/fastrtps_*` locks from prior killed runs | [`lessons.md` §9.7](./lessons.md) — `kill_autoware.sh` clears them |
| `kill_autoware.sh` says "No Autoware processes found" but `ros2 node list` shows ~70 nodes | Script's `REPO` path used to resolve to `scripts/` not the repo root | [`lessons.md` §9.8](./lessons.md) — fixed |
| LF reactor publishes to `/output/gear_cmd` instead of `/control/shift_decider/gear_cmd` | `get_node_options_from_yaml` doesn't apply launch-file `<remap>` tags | [`lessons.md` §9.5](./lessons.md) — fix is `nodeOptions.arguments({...})` in the reactor's startup reaction |
| `Publisher count: ≥2` on `/control/shift_decider/gear_cmd` with `--lf-managed=shift_decider` | Launch XML edits not yet built into `install/share/...launch/`; OR zombie `bin/Autoware` from a previous run | [`lessons.md` §9.4, §9.9](./lessons.md) — rebuild `autoware_launch tier4_control_launch`; `pkill bin/Autoware` |
| `dlopen` error: `lib…__rosidl_typesupport_fastrtps_cpp.so: No such file or directory` when running an LF binary | Shell didn't source `install/setup.bash` → `LD_LIBRARY_PATH` empty; `dlopen` ignores RUNPATH | [`lessons.md` §9.6](./lessons.md) — use the wrapper scripts |
| `undefined reference to autoware::shift_decider::ShiftDecider::onControlCmd(...)` at link time | Header declares the methods but `.cpp` lacks definitions | [`lessons.md` §9.2](./lessons.md) — add 3 setter-style method bodies |

For anything not covered here, read [`lessons.md`](./lessons.md) — it has
the complete debug history including the dead ends so you don't waste time
re-chasing them.

---

## 7. Running with an LF reactor in the mix (Mode A + shift_decider via LF)

Demonstrated 2026-05-15. This is the same Mode A stack as §3, but the
vanilla `autoware_shift_decider` composable_node is **suppressed** and an
LF reactor (`lf-src/shift_decider/shift_decider_main.lf`, instantiated by
`lf-src/Autoware.lf`) takes over publishing on
`/control/shift_decider/gear_cmd`. The downstream `vehicle_cmd_gate`
subscriber doesn't notice the difference.

### 7.1 Quick check before you start

```bash
# 1. Have the LF binary built?
ls bin/Autoware && ls bin/shift_decider_main
# If not, see §7.2.

# 2. Underlying ROS package has the 3 LF entry-point method bodies?
#    (onControlCmd / onAutowareState / onCurrentGear)
grep "ShiftDecider::onControlCmd" \
    src/universe/autoware_universe/control/autoware_shift_decider/src/autoware_shift_decider.cpp
# Expect one match (the method body). Empty → see lessons.md §9.2.

# 3. Launch XML has the lf_managed_shift_decider plumbing INSTALLED?
grep lf_managed_shift_decider \
    install/autoware_launch/share/autoware_launch/launch/e2e_simulator.launch.xml
# Expect 2 matches (declaration + forward). Empty → colcon-rebuild autoware_launch.
```

### 7.2 Build the LF artifacts

The pure-Mode-A build from §2.2 already builds the underlying ROS
packages. Two additional steps for the LF binaries:

```bash
# Builds the standalone self-test (also installs autoware_shift_decider
# afresh in case you edited its source):
bash lf-src/shift_decider/build.sh

# Builds the top-level non-federated LF program (bin/Autoware):
bash scripts/build_lf_autoware.sh
#   --no-colcon     # skip the ROS-pkg refresh if only the .lf changed
#   --clean         # rm src-gen/ + bin/Autoware before regenerating
```

Both scripts source the workspace internally, so they work in any fresh
shell. Total build time: ~20-30 sec for the underlying ROS package +
~30-60 sec for `lfc-dev` codegen and the LF executable link.

### 7.3 Smoke-test the reactor in isolation (recommended)

Before running it against the full Autoware stack, verify the reactor
works standalone:

```bash
bash scripts/run_shift_decider_test.sh
```

Pass criteria:
- Prints `ShiftDeciderTestSource: sending synthetic inputs`
- Prints `ShiftDeciderChecker: observed gear_cmd=2` (`2` = DRIVE)
- Exits 0 (a `WARNING: ---- There are 1 unprocessed future events` line
  is harmless — see [`lessons.md` §9.10](./lessons.md))

If this fails, fix it here. Don't proceed to §7.4 until the standalone
test passes.

### 7.4 Run sequence (4 terminals)

Same setup as §3 plus one extra terminal for the LF reactor:

```bash
# Terminal 1 — CARLA (unchanged from §3)
bash scripts/launch_carla.sh

# Terminal 2 — Autoware with vanilla shift_decider SUPPRESSED
bash scripts/launch_autoware.sh --lf-managed=shift_decider
# Wait ~90 sec for full load. Watch for
#   "Loaded node '/control/vehicle_cmd_gate'"
# in the launch output — that's the cue control is ready.

# Terminal 3 — LF reactor that owns shift_decider
bash scripts/run_lf_autoware.sh
# (idles forever; takes over publishing /control/shift_decider/gear_cmd)

# RViz: 2D Pose Estimate → 2D Goal Pose → drag speed limit > 0

# Terminal 4 — engage (same as §3)
bash scripts/engage.sh
```

### 7.5 Verification

The decisive single-command check is:

```bash
ros2 topic info /control/shift_decider/gear_cmd
```

| Output | Verdict |
|---|---|
| `Publisher count: 1` + `Subscription count: 1` | ✓ Healthy. LF reactor publishing, `vehicle_cmd_gate` listening. |
| `Publisher count: ≥2` | Suppression failed (launch XML not rebuilt, or zombie `bin/Autoware`) — see §6 / [`lessons.md` §9.4, §9.9](./lessons.md) |
| `Publisher count: 1`, `Subscription count: 0` | `vehicle_cmd_gate` didn't load — usually a TRT engine build failure earlier in the launch |
| Topic doesn't exist | Remap missing in the LF reactor — see [`lessons.md` §9.5](./lessons.md) |

Once the topic is healthy, the rest of the §4 checklist applies unchanged.
You should see gear commands at ~10 Hz once the reactor's three input
topics (`/control/trajectory_follower/control_cmd`, `/autoware/state`,
`/vehicle/status/gear_status`) are all flowing.

### 7.6 Teardown (always run between sessions)

```bash
bash scripts/kill_autoware.sh        # kills the launched stack + cleans SHM
pkill -KILL -f "bin/Autoware"        # kills the LF reactor (separate process)
```

`kill_autoware.sh` does not catch `bin/Autoware`. Forgetting to kill it
manually leaves a zombie LF reactor that will collide with the next run
(two publishers on `/control/shift_decider/gear_cmd`).

### 7.7 Extending to more validated reactors

The other 4 validated reactors from
`checkpoint/2026-04-23-shallow-wrappers-5-validated`
(`planning_validator`, `trajectory_follower`, `vehicle_cmd_gate`,
`bridge_interface`) follow the same pattern. For each:

1. Bring over the reactor's `.lf`, `build.sh`, `include/CMakeListsExtension.txt`.
2. Ensure the underlying ROS package's `.hpp` declarations have matching
   `.cpp` definitions (see [`lessons.md` §9.2](./lessons.md)).
3. Add a `lf_managed_<name>` arg + `unless="$(var ...)"` on the
   corresponding `<composable_node>`, plumb through the same 4 launch
   files (`e2e_simulator.launch.xml` → `autoware.launch.xml` →
   `tier4_control_component.launch.xml` → `control.launch.xml` for
   control-side reactors; planning has its own chain).
4. Add `add_lf_managed_arg <name>` to `scripts/launch_autoware.sh`.
5. Add the colcon package name to `COLCON_PKGS` in
   `scripts/build_lf_autoware.sh`.
6. Add `import` and `new` lines to `lf-src/Autoware.lf`.
7. Apply remappings via `nodeOptions.arguments({...})` in the reactor's
   `startup` reaction (see [`lessons.md` §9.5](./lessons.md)).
8. Rebuild `autoware_launch tier4_control_launch` so the install/share
   XMLs pick up step 3.

That's 8 mechanical steps per reactor.

---

## 8. Differences from the Autoware-documented planning_simulator workflow

If you're following the upstream Autoware tutorial and adapting to CARLA:

| Feature | `planning_simulator` (upstream) | `e2e_simulator` (CARLA, here) |
|---|---|---|
| Vehicle sim | `simple_planning_simulator` (internal) | CARLA (external process) |
| Auto-engage | Yes (built-in) | No — `scripts/engage.sh` required |
| Vehicle interface | Dummy (`launch_vehicle_interface=false`) | CARLA bridge (`autoware_carla_interface`) |
| Sensor data | None (ground truth) | CARLA sensors via bridge |
| `is_simulation` flag | Set by default | Was missing from `e2e_simulator.launch.xml`; added in this fork |
| MRM behavior | Lax | Strict — needed `system-carla.yaml` workaround to disable `duplicated_node_checker` |

The committed branch fixes (in `autoware_launch` and `autoware_universe`)
make `e2e_simulator` work for CARLA the way `planning_simulator` works
out-of-the-box. The launch you run via
`scripts/launch_autoware.sh` is `e2e_simulator.launch.xml` with all those
fixes in place.
