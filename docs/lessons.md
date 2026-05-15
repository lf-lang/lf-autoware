# lf-autoware — Lessons Learned

Consolidated debugging history for the Autoware Universe + CARLA Mode A
integration. Originally split between `2026-03-04-carla-integration-debug.md`
and the manager session notes from 2026-05-07.

Setup: Autoware Universe (Humble) + CARLA 0.9.16, synchronous mode @ 20 FPS,
branch `feat/carla-integration` on both `autoware_launch` and `autoware_universe`.

---

## Quick reference (current state)

### Scripts (live in `scripts/`, renamed from the original top-level names)

| Old name | Current name |
|---|---|
| `test_phase1_carla.sh` | `scripts/launch_autoware.sh` |
| `engage_carla.sh` | `scripts/engage.sh` |
| — | `scripts/launch_carla.sh` (new) |
| — | `scripts/kill_autoware.sh` (new) |

Run order:
```bash
# Terminal 1
bash scripts/launch_carla.sh           # starts CARLA server

# Terminal 2 (after CARLA is up)
bash scripts/launch_autoware.sh        # full Autoware + carla_interface

# Terminal 3 (after RViz pose + 2D Goal Pose set)
bash scripts/engage.sh                 # sends /autoware/engage

# Teardown
bash scripts/kill_autoware.sh
```

### RMW (DDS implementation)

- **Mode A (vanilla ROS via `launch_autoware.sh`):** `rmw_fastrtps_cpp`
- **Modes B / C (LF federation, snapshot branch):** `rmw_cyclonedds_cpp`

All Mode A helper scripts (`engage.sh`, `launch_autoware.sh`, etc.) must use
the same RMW or topic discovery fails silently — see §7.

### Persistent system config (already applied)

- `/etc/sysctl.d/60-cyclonedds-buffers.conf` — rmem/wmem max = 2 GiB
- `~/.config/cyclonedds.xml` — binds Cyclone to `lo`, multicast on, 10 MB sockets
- `~/.bashrc` — exports `CYCLONEDDS_URI=file:///home/shaokai/.config/cyclonedds.xml`

### Non-persistent (re-run after reboot)

```bash
sudo ip link set lo multicast on
```

### Recovery anchor (the LF-shim mods + sm_61 CUDA + CARLA configs)

```bash
cd src/core/autoware_core      && git checkout snapshot/lf-mods-2026-05-07
cd src/universe/autoware_universe && git checkout snapshot/lf-mods-2026-05-07
```

---

## 1. CARLA bridge plumbing (2026-03-04)

### 1.1 Missing simulation flags in `e2e_simulator.launch.xml`

**Problem.** `e2e_simulator.launch.xml` did not pass `is_simulation=true` or
`enable_all_modules_auto_mode=true` to `autoware.launch.xml`. Without these,
`vehicle_cmd_gate` stays in manual mode and rejects autonomous control commands.
The planning simulator launch has these flags; the e2e simulator launch did not.

**Fix.** Added both flags:
```xml
<arg name="enable_all_modules_auto_mode" default="true"/>
...
<arg name="is_simulation" value="true"/>
<arg name="enable_all_modules_auto_mode" value="$(var enable_all_modules_auto_mode)"/>
```

**File.** `src/launcher/autoware_launch/autoware_launch/launch/e2e_simulator.launch.xml`

### 1.2 No engage mechanism for the CARLA path

**Problem.** Unlike `planning_simulator.launch.xml` which launches
`simple_planning_simulator` (auto-engages), the CARLA e2e path requires manual
engagement. Without engage, `vehicle_cmd_gate` blocks all commands.

**Fix.** `scripts/engage.sh` (was `engage_carla.sh`):
```bash
ros2 topic pub --once /autoware/engage autoware_vehicle_msgs/msg/Engage '{engage: true}'
```

### 1.3 `raw_vehicle_cmd_converter` missing `operation_mode_state` remap

**Problem.** The CARLA launch file's `raw_vehicle_cmd_converter` node was
missing a remap for `~/input/operation_mode_state`. The node subscribed to a
namespaced topic nobody published to, so it never received operation-mode data
and never produced `/control/command/actuation_cmd` — the topic CARLA actually
reads.

Control chain:
```
/planning/trajectory
  -> controller_node           -> /control/command/control_cmd
  -> vehicle_cmd_gate          -> /control/command/control_cmd (gated)
  -> raw_vehicle_cmd_converter -> /control/command/actuation_cmd   ← broken
  -> carla_ros2_interface      -> ego_actor.apply_control()
```

**Fix.** Added the remap:
```xml
<remap from="~/input/operation_mode_state" to="/system/operation_mode/state"/>
```

**File.** `src/universe/autoware_universe/simulator/autoware_carla_interface/launch/autoware_carla_interface.launch.xml`

### 1.4 Car invisible in CARLA (spectator camera)

**Problem.** CARLA's spectator camera defaults to a fixed position far from
the spawned ego vehicle. The car drives but the camera doesn't follow it.

**Fix.** Added `_update_spectator()` to `carla_ros.py`, called every tick:
```python
def _update_spectator(self):
    ego_transform = self.ego_actor.get_transform()
    yaw_rad = math.radians(ego_transform.rotation.yaw)
    spectator_transform = carla.Transform(
        carla.Location(
            x=ego_transform.location.x - 10 * math.cos(yaw_rad),
            y=ego_transform.location.y - 10 * math.sin(yaw_rad),
            z=ego_transform.location.z + 5,
        ),
        carla.Rotation(pitch=-15, yaw=ego_transform.rotation.yaw),
    )
    world.get_spectator().set_transform(spectator_transform)
```

**File.** `src/universe/autoware_universe/simulator/autoware_carla_interface/src/autoware_carla_interface/carla_ros.py`

### 1.5 Duplicate node names triggering MRM emergency stop

**Problem.** The CARLA bridge launch file creates relay nodes
(`traffic_light_image_relay`, `traffic_light_camera_info_relay`) with names
identical to nodes launched by Autoware's own perception stack. Autoware's
`duplicated_node_checker` detects the collision, reports ERROR on
`/autoware/system`, triggering MRM → emergency stop → `vehicle_cmd_gate: Emergency!`.

**Fix.** Renamed CARLA relay nodes:
```xml
<node pkg="topic_tools" exec="relay" name="carla_traffic_light_image_relay" .../>
<node pkg="topic_tools" exec="relay" name="carla_traffic_light_camera_info_relay" .../>
```

**File.** `src/universe/autoware_universe/simulator/autoware_carla_interface/launch/autoware_carla_interface.launch.xml`

### 1.6 Diagnostic graph aggregator crash (the original main blocker)

Even after renaming relay nodes, the car still would not drive. Causal chain:

```
duplicated_node_checker ERROR (remaining duplicates from installed packages)
  -> /autoware/system AND gate = ERROR
  -> diagnostic_graph_aggregator publishes ERROR status
  -> hazard_status_converter -> /system/emergency/hazard_status = emergency
  -> mrm_handler triggers emergency stop
  -> vehicle_cmd_gate enters Emergency mode
  -> all control commands blocked
```

**Failed attempt 1.** Override `/autoware/system` in `autoware-carla.yaml` →
`PathConflict` exception in the graph loader because the path was already
defined in the included `system.yaml`. Aggregator crashed on startup →
`/system/operation_mode/availability` never published → mrm_handler stuck.

**Failed attempt 2.** Use the loader's `edits: remove` mechanism. Crashed
because `duplicated_node_checker` is a `diag` type (stored in `diags_`), not
a NodeUnit (stored in `nodes_`). `apply_remove_edits()` only collects paths
from `nodes_`, so `remove_paths.count(path) == 0` → `PathNotFound` → crash.

**Successful fix.** `system-carla.yaml` — a copy of `system.yaml` with two
changes:
1. Removed `duplicated_node_checker` from the `/autoware/system` AND gate list
2. Removed the `duplicated_node_checker` diag definition entirely

Updated `autoware-carla.yaml` to include `system-carla.yaml` instead of `system.yaml`:
```yaml
files:
  - { path: $(dirname)/control.yaml }
  - { path: $(dirname)/map.yaml }
  - { path: $(dirname)/perception.yaml }
  - { path: $(dirname)/system-carla.yaml }   # was system.yaml
  - { path: $(dirname)/vehicle.yaml }
```

**Files.**
- `src/launcher/autoware_launch/autoware_launch/config/system/diagnostics/system-carla.yaml` (new)
- `src/launcher/autoware_launch/autoware_launch/config/system/diagnostics/autoware-carla.yaml` (modified)

---

## 2. The LF callback shim trap (2026-05-07)

**This was the single biggest debugging episode and ate most of a day.**

### Symptom

After a fresh launch with Mode A:
- Map loader logs `"Succeeded to load lanelet2_map. Map is published."`
- `ros2 topic info /map/vector_map` shows 1 publisher, 23 subscribers, all on
  `TRANSIENT_LOCAL` durability — QoS-compatible
- `ros2 topic echo /map/vector_map` hangs forever; **no subscriber ever receives**
- `mission_planner` logs `waiting lanelet map... Route API is not ready.`
  every 5 seconds
- Same pattern silently breaks `ekf_localizer`, `ndt_scan_matcher`,
  `gyro_odometer`, `behavior_velocity_planner`, `motion_velocity_planner`,
  `multi_object_tracker`, `velocity_smoother`, `crop_box_filter`,
  `mission_planner` (route output), and others.

### Root cause

The lf-autoware repo had **uncommitted working-tree modifications** to ~10
source files that replaced `pub_*->publish(msg)` with:

```cpp
/* pub_map_bin_->publish(map_bin_msg); */ lf_output_map = map_bin_msg; lf_map_is_set = true;
```

The publisher was *created* normally, so it appeared in topic discovery and
matched subscribers. But `publish()` was never called — the data was stashed in
an `lf_output_*` member field for the Lingua Franca runtime to forward through
the federation. In vanilla Mode A there *is* no LF runtime, so the message
simply never went anywhere.

The misleading log line `"Map is published"` ran *after* the commented-out
publish — a one-character difference that hides everything.

### Red herrings chased (none of them mattered for this bug)

1. **Cyclone DDS UDP receive buffer.** `net.core.rmem_max = 212992` (208 KB) vs
   Cyclone's 2 MiB request → bumped to 2 GiB. Did not help.
2. **UDP send buffer.** `net.core.wmem_max = 212992` → bumped to 2 GiB. Did not help.
3. **Loopback multicast.** `lo` interface missing `MULTICAST` flag →
   `sudo ip link set lo multicast on`. Did not help.
4. **CYCLONEDDS_URI config** binding to `lo` with 10 MB sockets and 2 MB
   WhcHigh write-history. Did not help.
5. **Switching from Cyclone to FastDDS.** Identical symptoms under both. This
   was actually the critical clue that DDS wasn't the layer at fault.

All five "fixes" were applied anyway because they're good hygiene for ROS 2 on
Linux — they're persistent in `/etc/sysctl.d/` and `~/.bashrc` — but **none
of them is why routing eventually started working.**

### Diagnostic move that found it

```bash
find src -name "lanelet2_map_loader_node.cpp" | xargs grep -n "publish"
```

Showed the commented-out `pub_map_bin_->publish` line directly. Then
`git diff` on each modified package showed the same `lf_output_*` shim
everywhere.

### Resolution

```bash
# In each modified submodule:
git checkout -b snapshot/lf-mods-2026-05-07
git add -A
git commit -m "Snapshot of LF shims + sm_61 + CARLA configs before mainline revert"
git checkout <original-branch-or-tag>     # autoware_core@1.7.0, autoware_universe@feat/carla-integration
# working tree now clean
```

Then a full `colcon build --base-paths src --cmake-args -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF`
took 34 min for 442 packages + a 3m43s retry for 8 OOM casualties (one linker
OOM cascaded into 7 collateral aborts). After the rebuild, `/map/vector_map`
published immediately and `mission_planner` advanced past the "waiting lanelet
map" stage.

### Files reverted

72 total: 21 in `autoware_core`, 51 in `autoware_universe`. Categories:

- ~62 LF source shims (`.hpp`/`.cpp` with `lf_output_*` pattern)
- 6 CUDA `CMakeLists.txt` (sm_61 PTX fallback for GTX 1050 Ti — only matters
  for Mode C federation on GPU 1)
- 4 CARLA / config tweaks (`sensor_mapping.yaml`, `imu_corrector.param.yaml`,
  `concatenate_and_time_sync_node.param.yaml`, `carla_ros.py`) — these
  *did* matter for the CARLA bridge

All preserved on `snapshot/lf-mods-2026-05-07` branches in both repos.

### Lesson

When a publish/subscribe pair has **matched endpoints, compatible QoS, and
zero throughput**, the problem is almost never the DDS layer. Check that the
publish call actually runs:

```bash
grep -rn '/\*\s*[a-z_]*\.publish' src/    # commented-out publishes
grep -rn '/\*\s*[a-z_]*->publish' src/
grep -rn '\<lf_output_\|\<lf_.*_is_set'   # the LF-shim signature in this repo
```

---

## 3. Kernel + DDS plumbing (2026-05-07)

Applied during the LF debugging hunt. None of these were the actual fix, but
all are recommended hygiene for ROS 2 on Linux with large transient_local
messages and are now persistent.

### sysctl

`/etc/sysctl.d/60-cyclonedds-buffers.conf`:
```
net.core.rmem_max=2147483647
net.core.rmem_default=8388608
net.core.wmem_max=2147483647
net.core.wmem_default=8388608
```

Without this, default Ubuntu rmem/wmem of ~208 KB silently caps Cyclone DDS's
2 MiB request. Large messages (vector_map, occupancy grids) fragment over
UDP without enough buffer and can drop on busy hosts. Mostly invisible on
modern systems but harmless to fix.

### Cyclone DDS config

`~/.config/cyclonedds.xml`:
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

`~/.bashrc`:
```bash
export CYCLONEDDS_URI=file:///home/shaokai/.config/cyclonedds.xml
```

### Loopback multicast (NOT persistent)

```bash
sudo ip link set lo multicast on
```

Lost on reboot. If Cyclone DDS topics misbehave after reboot, this is the
first thing to re-apply.

### Mode A RMW switch

`scripts/launch_autoware.sh` now uses `rmw_fastrtps_cpp` (was Cyclone). The
switch was made during debugging; both DDS impls showed identical LF-shim
symptoms, so the choice is arbitrary. FastDDS is the ROS 2 Humble default
and has fewer config knobs to misconfigure, so it stays.

---

## 4. Mode A vs Modes B/C — and the snapshot branch

| Mode | What runs Autoware | DDS | Branch |
|---|---|---|---|
| **A** (vanilla ROS, the user's current target) | All ROS 2 nodes | FastDDS | Mainline `autoware_core@1.7.0` + `autoware_universe@feat/carla-integration` |
| **B** (LF planning + control hybrid) | ROS + LF binaries for planning/control | Cyclone | snapshot branch |
| **C** (full LF federation) | All LF federates | Cyclone | snapshot branch |

Mode A on the current mainline branches **cannot** federate with LF runtime —
the LF callback shims required to forward data via `lf_output_*` were
deliberately removed. To resume Mode B/C work later:

```bash
cd src/core/autoware_core      && git checkout snapshot/lf-mods-2026-05-07
cd src/universe/autoware_universe && git checkout snapshot/lf-mods-2026-05-07
# Then rebuild affected packages.
```

The snapshot branches contain:
- All ~62 LF callback shims (`lf_output_*` pattern)
- 6 sm_61 CUDA `CMakeLists.txt` with PTX fallback (for GTX 1050 Ti)
- 4 CARLA configs and `carla_ros.py` tweaks

---

## 5. Hardware constraint: TensorRT 10.8 vs GTX 1050 Ti (sm_6.1)

TensorRT 10.8 (`libnvinfer10`) **drops support for compute capability 6.1**.
The GTX 1050 Ti has sm_6.1 and cannot run any TensorRT-using perception node
(`lidar_centerpoint`, `tensorrt_yolox`, `tensorrt_classifier`,
`probabilistic_occupancy_grid_map`, `cuda_pointcloud_preprocessor`).

### Implications

- **Mode A on RTX 3070 (sm_8.6, GPU 0):** No issue. This is the recommended
  setup. `launch_autoware.sh` sets `CUDA_VISIBLE_DEVICES=0` to pin Autoware
  to the 3070.
- **Mode C federation on GPU 1 (1050 Ti):** Requires the 5 sm_61 PTX-fallback
  CMakeLists changes from the snapshot branch. Even then, runtime TRT engine
  build on sm_6.1 fails. Workaround: run with `perception:=false` and spoof
  empty perception topics (see `perception_spoof.sh` if/when restored).
- **Long-term fix:** Rebuild Autoware against TensorRT 8 (libnvinfer8, already
  installed) — would let the 1050 Ti run perception again.

---

## 6. Display server pitfall: NoMachine vs HDMI

**Observation (2026-05-07).** Localization that consistently failed to reach
`state=3` over NoMachine started working "almost for no reason" after
switching to a physical HDMI monitor. Likely causes:

- **GPU display contention.** NoMachine's H.264 encoder runs on GPU 0,
  competing with CARLA's Vulkan/UE4 renderer. HDMI uses direct DRM output
  with no encoder thread.
- **Power-state pinning.** NoMachine often keeps GPUs in P5/P8 because it
  thinks nothing's drawing. Localization's `ndt_scan_matcher` is heavy CUDA —
  if the 3070 was stuck at low clocks, scan matching underruns.
- **CUDA device enumeration.** Without NoMachine's `nxnode` in the loop,
  `CUDA_VISIBLE_DEVICES=0` reliably maps to the 3070.
- **Vulkan ICD ordering.** Some NoMachine configs place `libGLX_indirect` or
  VirtualGL in front of the real driver, breaking Vulkan-CUDA interop.

**Rule of thumb.** For runs that exercise heavy CUDA (perception, NDT,
Vulkan), use the physical HDMI display. Remote work via SSH + a separate web
viewer (Foxglove) is fine for non-CUDA windows.

---

## 7. Helper-script RMW gotcha (2026-05-14)

After switching `launch_autoware.sh` to FastDDS on 2026-05-07, the helper
scripts still had `RMW_IMPLEMENTATION=rmw_cyclonedds_cpp` hard-coded. Running
`scripts/engage.sh` against a FastDDS launch produced:

```
Waiting for at least 1 matching subscription(s)...
Waiting for at least 1 matching subscription(s)...
...forever...
```

The engage publisher (Cyclone) and `/autoware/engage` subscriber (FastDDS)
were on different DDS impls and didn't discover each other.

**Fix.** All Mode A helper scripts now match `launch_autoware.sh`:
- `scripts/launch_autoware.sh` — `rmw_fastrtps_cpp`
- `scripts/engage.sh`          — `rmw_fastrtps_cpp`

Mode B/C scripts (under the snapshot branch) stay on `rmw_cyclonedds_cpp`
because the LF runtime uses Cyclone.

**Lesson.** Any script that talks to a running ROS 2 stack must use the
*same* `RMW_IMPLEMENTATION` and the *same* `ROS_DOMAIN_ID` as the running
launch. Discovery mismatch presents as "I can see the topic in `ros2 topic
list` but `pub`/`echo` waits forever" — which can be mistaken for QoS or
publish-side bugs.

---

## 8. Benign warnings (do not chase these)

Three messages appear during every build/launch and have caused wasted
debugging time. None of them indicate real problems.

### `format_version: null` on lanelet2_map.osm

```
[map.lanelet2_map_loader]: <map>.osm has no format_version(null) or
  non semver-style format_version(null) information
[map.lanelet2_map_loader]: Loaded map format_version: null
```

The Autoware-contents CARLA Town01 lanelet map doesn't include a
`format_version` tag. Autoware's loader logs a warning and continues. Routing
works fine without it.

### `ament_auto_package` Kilted Kaiju notice

```
In this package, headers install destination is set to `include` by
ament_auto_package. It is recommended to install
`include/<package_name>` instead and will be the default behavior of
ament_auto_package from ROS 2 Kilted Kaiju.
```

Forward-compatibility note for a future ROS 2 release. Harmless on Humble.

### `parameter_traits::OK` deprecation

```
warning: 'parameter_traits::OK' is deprecated: When returning
  tl::expected<void, std::string> default construct for OK with `{}`.
```

Compiler warning in a transitive dependency. Doesn't affect runtime.

---

## 9. Bringing a validated LF reactor onto the current branch (2026-05-15)

First end-to-end run with an LF-managed Autoware node was `shift_decider`,
pulled from `checkpoint/2026-04-23-shallow-wrappers-5-validated`. Five
distinct gotchas surfaced. Most of them generalize to the remaining four
validated reactors (`planning_validator`, `trajectory_follower`,
`vehicle_cmd_gate`, `bridge_interface`).

### 9.1 Two versions of the same reactor exist on the checkpoint branch

`shift_decider_main.lf` was reduced from 214 lines to 89 lines by the
checkpoint commit (`c8f42af`). The earlier version (`8159b96 Polish shift
decider`) is the **testable** one — three LF inputs + a self-checking
`main reactor` (`ShiftDeciderTestSource` → reactor → `ShiftDeciderChecker`).
The checkpoint version is the **federation-shape** one — one LF input,
trivial main, matches the AutowareFederated.lf wiring exactly.

When porting forward, take **8159b96's version** for local-test usability;
strip back to the c8f42af shape only when wiring into a federation. The
extra LF inputs are legal-but-dangling when the reactor is instantiated
standalone; the underlying ROS subscriptions in the spin thread still feed
real data in.

### 9.2 The C++ class needs LF entry-point method bodies

Mainline `autoware_shift_decider.hpp` already **declares** public
`onControlCmd / onAutowareState / onCurrentGear` methods and adds
`lf_output_gear_cmd / lf_gear_cmd_is_set` public fields — the LF-fork
hooks are committed on `feat/carla-integration`. But the corresponding
**implementations** were only in the snapshotted working-tree mods. Linker
error when building the reactor:

```
undefined reference to `autoware::shift_decider::ShiftDecider::onControlCmd(...)'
```

Fix: add 3 setter-style method bodies to the .cpp. Each is one line
(`control_cmd_ = msg;`) — they stash data where `onTimer()` would have
written it from the polling subscriber. Keep the ROS publish in `onTimer`
intact so vanilla Mode A keeps working; only suppress the vanilla
**composable_node**, not the publish itself.

This will be the same fix for every reactor in §9 with `lf_output_*`
hooks — check `<pkg>/include/.../<class>.hpp` for declarations that lack
.cpp definitions.

### 9.3 Suppressing the vanilla composable_node when LF owns it

Pattern, already idiomatic in this codebase (`use_control_command_gate` on
`vehicle_cmd_gate`): add `unless="$(var lf_managed_<name>)"` to the
composable_node, plumb `lf_managed_<name>` (default `false`) up through
all enclosing launch files. For `shift_decider` this was 4 files:

```
control.launch.xml             ← composable_node + arg declaration + unless=
tier4_control_component.launch ← forward
autoware.launch.xml            ← forward
e2e_simulator.launch.xml       ← forward
scripts/launch_autoware.sh     ← --lf-managed=<csv> flag
```

`scripts/launch_autoware.sh --lf-managed=shift_decider` is the public
interface. Each future validated reactor needs the same 5-file change
plus one `add_lf_managed_arg <name>` line in the script.

### 9.4 Launch-XML edits don't take effect without colcon rebuild

`ros2 launch` reads from `install/<pkg>/share/<pkg>/launch/<file>.xml`,
not from `src/`. After editing the launch files, you **must**:

```bash
colcon build --packages-select autoware_launch tier4_control_launch \
    --base-paths src
```

…then start a new launch. This caught us during the first integration
attempt — the vanilla `autoware_shift_decider` kept appearing alongside
the LF reactor because the install-side XML was the pre-suppression
copy. The two packages above rebuild in ~5 seconds.

### 9.5 `get_node_options_from_yaml()` does not apply launch remappings

The LF reactor instantiates the underlying ROS node directly:

```cpp
rclcpp::NodeOptions nodeOptions = get_node_options_from_yaml(yaml, "/**");
self->node = new autoware::shift_decider::ShiftDecider(nodeOptions);
```

`get_node_options_from_yaml()` applies **parameters** from the YAML, but
the `<remap>` tags inside the launch file are *only* applied when the
node is loaded by `ros2 launch`. Without remaps the inner node ends up
on `input/control_cmd`, `output/gear_cmd`, etc. in the **root** namespace,
where neither vanilla Autoware nor `vehicle_cmd_gate` can find it.

Fix: inject remappings into `NodeOptions` explicitly in the reactor's
`startup` reaction, mirroring exactly what the suppressed composable_node
launch entry would have done:

```cpp
nodeOptions.arguments({
    "--ros-args",
    "-r", "input/control_cmd:=/control/trajectory_follower/control_cmd",
    "-r", "input/state:=/autoware/state",
    "-r", "input/current_gear:=/vehicle/status/gear_status",
    "-r", "output/gear_cmd:=/control/shift_decider/gear_cmd",
});
self->node = new autoware::shift_decider::ShiftDecider(nodeOptions);
```

**General rule.** For every reactor moved into `Autoware.lf`, look up its
`<composable_node>` entry in the launch file it would have come from, copy
every `<remap from="X" to="Y"/>` into a `"-r", "X:=Y"` pair. Don't trust
the YAML parameter file alone — remaps live in the launch graph, not in
parameters.

### 9.6 `dlopen()` ignores RUNPATH — every binary needs `LD_LIBRARY_PATH`

ROS 2's typesupport dispatcher uses `dlopen()` with bare library names.
`dlopen` only consults `LD_LIBRARY_PATH` and the loader cache; it does
**not** look at the binary's RUNPATH (which `colcon`'s rpath does set).
So even though `bin/Autoware` has every `install/<pkg>/lib` in its
RUNPATH, this still fails:

```
$ ./bin/Autoware
Could not load library libautoware_system_msgs__rosidl_typesupport_fastrtps_cpp.so:
  cannot open shared object file: No such file or directory
```

Sourcing `install/setup.bash` populates `LD_LIBRARY_PATH`. The wrapper
scripts (`run_lf_autoware.sh`, `run_shift_decider_test.sh`) encapsulate
that step so you can't forget it.

Same underlying issue affects three layers (this comes up *constantly* —
write the wrapper):

| Layer | Symptom | Env var fix |
|---|---|---|
| Build (lfc-dev → CMake) | `find_package(autoware_shift_decider) … NOT FOUND` | `CMAKE_PREFIX_PATH` |
| Runtime (binary startup) | `dlopen: lib…__rosidl_typesupport_fastrtps_cpp.so: No such file or directory` | `LD_LIBRARY_PATH` |
| Both | `source install/setup.bash` populates both | — |

### 9.7 FastDDS stale SHM locks accumulate

Every hard-killed FastDDS process leaves files behind in `/dev/shm/`:

```
/dev/shm/fastrtps_*
/dev/shm/sem.fastrtps_*
```

On the next launch, FastDDS tries to claim the same SHM ports and gets
`open_and_lock_file failed → open_port_internal`. Symptoms cascade:
RViz prints SHM errors, carla_interface fails to bind, TRT engine loads
fail on top of that, control_container ends up empty even though the
container process is up. `ros2 topic hz` queries time out because the
ephemeral subscriber can't acquire its own SHM port.

Cleanup is one line:

```bash
rm -f /dev/shm/fastrtps_* /dev/shm/sem.fastrtps_*
ros2 daemon stop && ros2 daemon start
```

`scripts/kill_autoware.sh` already does both as its final step. Just
remember to actually run it between sessions.

### 9.8 `kill_autoware.sh` REPO path bug (now fixed)

The script was moved from the repo root into `scripts/` at some point,
but the line that derives the repo path stayed wrong for the new
location:

```bash
# BROKEN — resolves to scripts/, not the repo root
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# FIXED — goes up one level
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
```

With the broken `REPO`, every `${REPO}/install/` reference in the kill
pattern was `…/scripts/install/` — a non-existent path matching no
process. The script reported "No Autoware processes found" while 47
launch-spawned binaries lived on, polluting the ROS graph and exhausting
SHM ports.

Two other rename leftovers fixed: `grep -v "kill_workflow3\.sh"`
self-exclusion → `kill_autoware\.sh`, and stale `Workflow 3` strings in
help text.

If you move *any* of these scripts in the future, audit every `dirname`,
every name in `grep -v`, and every documentation string. They are
boring, fragile lines that all break silently.

### 9.9 Two `bin/Autoware` processes can run simultaneously

Building `bin/Autoware` does not stop a previously-started one. If you
forget to kill it (very easy because it has no test peers and no timeout,
so the previous instance happily idles forever), you end up with two
processes both claiming `/shift_decider` as their node name. The
discovery system reports both, often with one showing
`_NODE_NAME_UNKNOWN_` because its publisher cache is stale.

`pkill -KILL -f "bin/Autoware"` before each `scripts/run_lf_autoware.sh`,
or extend `kill_autoware.sh` to catch this class.

### 9.10 Two flavors of "Done" for the test harness

Standalone `bin/shift_decider_main` exits 0 after one DRIVE command and
prints `Elapsed physical time (in nsec): N` plus an "unprocessed future
events on the event queue" warning. The warning is harmless: `lf_request_stop()`
fires before the next 100 ms timer tick, so the one queued timer event
gets purged at shutdown. Pass criterion is `observed gear_cmd=2` and
exit 0; the warning line is noise.

### 9.11 Sanity-checking the LF reactor in the live stack

The decisive single command:

```bash
ros2 topic info /control/shift_decider/gear_cmd
```

| Output | Verdict |
|---|---|
| `Publisher count: 1` + `Subscription count: 1` | Healthy: LF reactor publishing, vehicle_cmd_gate listening |
| `Publisher count: ≥2` | Suppression failed (launch XML not rebuilt) or zombie LF binary |
| `Publisher count: 1`, `Subscription count: 0` | `vehicle_cmd_gate` didn't load — usually TRT engine build failed earlier in the launch |
| Topic doesn't exist | Remap from §9.5 missing — inner node is publishing to `/output/gear_cmd` instead |

This single query distinguishes all four failure modes we hit while
landing shift_decider end-to-end.

---

## Architectural reference

### Autoware diagnostic graph system

The diagnostic system is a directed acyclic graph defined in YAML:

- **diag nodes**: leaf nodes monitoring ROS 2 node heartbeats/diagnostics
- **AND/OR nodes**: logical gates combining child results
- **modes**: top-level nodes defining what must be healthy for each operation mode

The graph is loaded by `diagnostic_graph_aggregator`:

1. Loads YAML files recursively via `files:` includes
2. Creates NodeUnits (AND/OR) and DiagUnits (diag)
3. Resolves link references between nodes
4. Topologically sorts the graph
5. Applies `edits` (remove only, and **only for NodeUnits — not DiagUnits**)
6. Publishes `CommandModeAvailability` to `converter_node`
7. `converter_node` publishes `OperationModeAvailability`
8. `mrm_handler` consumes this to decide emergency actions

If the aggregator crashes at any step, the entire safety chain stalls.

### CARLA control flow

```
CARLA Server (UE4, separate process)
  <-- world.tick() (synchronous mode) --
CARLA Python Client (autoware_carla_interface)
  -- publishes sensor data --> ROS 2 topics
  -- subscribes /control/command/actuation_cmd -->
  -- calls ego_actor.apply_control(throttle, brake, steer) -->
CARLA Server applies physics
```

`raw_vehicle_cmd_converter` is critical: it converts high-level control
(velocity / acceleration / steering angle) to low-level actuation (throttle
0-1, brake 0-1, steer -1 to 1) using CSV calibration maps.

### Why `e2e_simulator` differs from `planning_simulator`

| Feature | `planning_simulator` | `e2e_simulator` (CARLA) |
|---------|---------------------|------------------------|
| Vehicle sim | `simple_planning_simulator` (internal) | CARLA (external process) |
| Auto-engage | Yes (built-in) | No (manual engage required) |
| Vehicle interface | Dummy (`launch_vehicle_interface=false`) | CARLA bridge |
| Sensor data | None (ground truth) | CARLA sensors via bridge |
| `is_simulation` | Set by default | Was missing; had to add |

---

## Files modified from vanilla Autoware (Mode A current state)

Mode A on `autoware_core@1.7.0` + `autoware_universe@feat/carla-integration`.

### Committed on `feat/carla-integration` (survived the 2026-05-07 revert)

1. `src/launcher/autoware_launch/autoware_launch/launch/e2e_simulator.launch.xml` — simulation flags (§1.1)
2. `src/launcher/autoware_launch/autoware_launch/config/system/diagnostics/autoware-carla.yaml` — include system-carla.yaml (§1.6)
3. `src/launcher/autoware_launch/autoware_launch/config/system/diagnostics/system-carla.yaml` — new, no duplicated_node_checker (§1.6)
4. `src/universe/autoware_universe/simulator/autoware_carla_interface/launch/autoware_carla_interface.launch.xml` — operation_mode remap, renamed relays (§1.3, §1.5)
5. `src/universe/autoware_universe/simulator/autoware_carla_interface/src/autoware_carla_interface/carla_ros.py` — spectator follow cam (§1.4)

### Top-level helper scripts under `scripts/`

6. `scripts/launch_carla.sh` — launches CARLA server
7. `scripts/launch_autoware.sh` — Autoware + CARLA bridge (was `test_phase1_carla.sh`)
8. `scripts/engage.sh` — sends `/autoware/engage` (was `engage_carla.sh`)
9. `scripts/kill_autoware.sh` — teardown

### Preserved on snapshot branches (NOT applied in Mode A)

- 6 sm_61 CUDA `CMakeLists.txt` (Mode B/C only — see §5)
- ~62 LF callback shims (`lf_output_*` pattern — see §2)
- 4 additional CARLA configs (e.g., `sensor_mapping.yaml`, `imu_corrector.param.yaml`)

---

## Open follow-ups (2026-05-14)

- **End-to-end verification of Mode A pending.** After the 2026-05-07 revert
  and 2026-05-14 RMW patch of helper scripts, the goal-pose → route →
  trajectory → engage → vehicle-moves chain has not been confirmed in a
  single uninterrupted run.
- **`perception_spoof.sh` no longer in the tree.** Was used in earlier
  testing to spoof empty `PredictedObjects` and `TrafficLightGroupArray` so
  `behavior_*_planner` would proceed when `perception:=false`. If Mode A is
  ever run with perception disabled (e.g., to bypass TRT on GPU 1), it will
  need to be re-created.
- **Loopback multicast persistence.** `sudo ip link set lo multicast on`
  still has to be re-run after every reboot.
