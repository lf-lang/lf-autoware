# lf-autoware Launch Guide

This guide explains how to launch the Lingua Franca (LF) port of Autoware with the CARLA 0.9.16 simulator.

## Prerequisites

- **CARLA 0.9.16** installed at `~/carla-0.9.16/`
- **Autoware** built with colcon (`install/` directory present)
- **LF federation** built in `fed-gen/AutowareFederated/bin/` (72 federates)
- **Map data** at `~/autoware_map/Town01/` (pointcloud_map.pcd + lanelet2_map.osm)
- **NVIDIA GPUs**: GPU 0 = RTX 3070 (reserved for CARLA), GPU 1 = GTX 1050 Ti (for Autoware/TensorRT). Driver 570+
- **ROS Humble** installed at `/opt/ros/humble/`
- **No conda** in PATH (conda's numpy 2.x breaks the Python CARLA federate)

### Python dependencies (for CARLA interface)
```bash
pip install carla==0.9.16
pip install 'numpy<2'  # Must be numpy 1.x for cv_bridge compatibility
```

## Launch Modes

| Mode | Description | Terminals |
|------|-------------|-----------|
| **D. Federation** | Full 72-federate LF federation with decentralized coordination | 4 |
| **A. Hybrid** | ROS sensing/localization/perception + LF planning/control | 4 |
| **B. Full LF Stack** | All nodes as standalone LF processes (no federation) | 4 |
| **C. Vanilla Autoware** | Standard ROS nodes (no LF, for comparison) | 3 |

---

## Mode D: Federation (Recommended)

All 72 Autoware nodes run as LF federates with decentralized coordination. The Python CARLA federate drives simulation stepping from LF logical time. 79 LF connections wire the full dataflow graph — data flows through LF ports instead of ROS pub/sub.

### Terminal 1 — Start CARLA `[GPU 0: RTX 3070]`
```bash
cd ~/carla-0.9.16
./CarlaUE4.sh -prefernvidia -quality-level=low
```
Wait for CARLA to fully load before proceeding.

### Terminal 2 — Launch the federation `[GPU 1: GTX 1050 Ti]`
```bash
bash ~/Documents/projects/parking-demo/lf-autoware/lf-src/run_federation.sh
```

This starts:
- **RTI** (Runtime Infrastructure) — coordinates federation startup
- **71 CCpp federates** — all Autoware nodes (sensing, localization, perception, planning, control, system)
- **1 Python CARLA federate** — drives CARLA synchronous stepping

All federates connect to the RTI, then begin execution with coordinated logical time.

### Terminal 3 — RViz (visualization)
```bash
source /opt/ros/humble/setup.bash
source ~/Documents/projects/parking-demo/lf-autoware/install/setup.bash
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
rviz2
```

### Terminal 4 — Engage the vehicle
```bash
bash ~/Documents/projects/parking-demo/lf-autoware/engage.sh
```
Then set a **2D Goal Pose** in RViz.

---

## Mode A: Hybrid (LF Planning + Control)

ROS handles sensing, localization, and perception. LF handles planning, control, and the bridge interface (20 LF nodes). No federation coordination — nodes run as standalone processes.

### Terminal 1 — Start CARLA `[GPU 0: RTX 3070]`
```bash
cd ~/carla-0.9.16
./CarlaUE4.sh -prefernvidia -quality-level=low
```

> **Performance tip:** If GPU memory is tight (see [GPU Notes](#gpu-notes)), use:
> ```bash
> ./CarlaUE4.sh -prefernvidia -quality-level=low -RenderOffScreen -ResX=800 -ResY=600
> ```

### Terminal 2 — Launch Autoware (without planning/control) `[GPU 1: GTX 1050 Ti]`
```bash
bash ~/Documents/projects/parking-demo/lf-autoware/test_phase1_carla_no_planning.sh
```

This launches the CARLA interface, sensing, localization, perception, and RViz. Planning and control are disabled (`launch_planning:=false launch_control:=false`). Script sets `CUDA_VISIBLE_DEVICES=1`.

### Terminal 3 — Launch LF planning + control nodes `[GPU 1: GTX 1050 Ti]`
```bash
bash ~/Documents/projects/parking-demo/lf-autoware/lf-src/test_lf_planning_control.sh
```

Press `Ctrl-C` to stop all LF nodes.

### Terminal 4 — Engage the vehicle
```bash
bash ~/Documents/projects/parking-demo/lf-autoware/engage.sh
```
Then set a **2D Goal Pose** in RViz.

---

## Mode B: Full LF Stack (Standalone Processes)

All Autoware nodes run as standalone LF processes (no federation coordination). Only the CARLA interface and RViz remain as ROS nodes.

### Terminal 1 — Start CARLA `[GPU 0: RTX 3070]`
```bash
cd ~/carla-0.9.16
./CarlaUE4.sh -prefernvidia -quality-level=low
```

### Terminal 2 — Launch CARLA interface + RViz only `[GPU 1: GTX 1050 Ti]`
```bash
bash ~/Documents/projects/parking-demo/lf-autoware/test_carla_interface_only.sh
```

### Terminal 3 — Launch full LF stack `[GPU 1: GTX 1050 Ti]`
```bash
bash ~/Documents/projects/parking-demo/lf-autoware/lf-src/test_lf_full_stack.sh
```

### Terminal 4 — Engage the vehicle
```bash
bash ~/Documents/projects/parking-demo/lf-autoware/engage.sh
```
Then set a **2D Goal Pose** in RViz.

---

## Mode C: Vanilla Autoware (No LF)

For comparison/baseline. The entire Autoware stack runs as standard ROS nodes.

### Terminal 1 — Start CARLA `[GPU 0: RTX 3070]`
```bash
cd ~/carla-0.9.16
./CarlaUE4.sh -prefernvidia -quality-level=low
```

### Terminal 2 — Launch full Autoware `[GPU 1: GTX 1050 Ti]`
```bash
bash ~/Documents/projects/parking-demo/lf-autoware/test_phase1_carla.sh
```
Script sets `CUDA_VISIBLE_DEVICES=1`.

### Terminal 3 — Engage
```bash
bash ~/Documents/projects/parking-demo/lf-autoware/engage_carla.sh
```

---

## Building

### Full federation build (first time or after adding/removing federates)

```bash
cd ~/Documents/projects/parking-demo/lf-autoware
source /opt/ros/humble/setup.bash
source install/setup.bash
export LF_AUTOWARE_HOME=$(pwd)

# Step 1: Generate scaffold (fast, ~30 seconds)
lfc --no-compile lf-src/AutowareFederated.lf

# Step 2: Build all federates in parallel
ls fed-gen/AutowareFederated/src-gen/federate__*/ | xargs -I{} basename {} | \
  xargs -P4 -I{} bash -c '
    cd fed-gen/AutowareFederated/src-gen/{} && \
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX='$LF_AUTOWARE_HOME'/fed-gen/AutowareFederated \
      -DCMAKE_INSTALL_BINDIR=bin > /dev/null 2>&1 && \
    cmake --build build --target install --parallel 8 > /dev/null 2>&1 && \
    echo "✓ {}" || echo "✗ {}"
  '

# Step 3: Build Python CARLA federate
lfc lf-src/carla_interface/federate__ci.lf
# Then add federation_preamble.c and rebuild (see DEVELOPMENT_NOTES.md)
```

### Incremental build (single federate changed)

```bash
cd fed-gen/AutowareFederated/src-gen/federate__<name>/build
cmake --build . --target install --parallel 8
```

### Rebuild Autoware packages (after C++ header modifications)

```bash
colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
  --packages-select <package_name>
```

---

## Environment Variables

All launch scripts set these automatically, but if running components manually:

```bash
# Required
export LF_AUTOWARE_HOME=~/Documents/projects/parking-demo/lf-autoware
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
source /opt/ros/humble/setup.bash
source ~/Documents/projects/parking-demo/lf-autoware/install/setup.bash

# GPU: Autoware uses GPU 1 (GTX 1050 Ti); GPU 0 (RTX 3070) is reserved for CARLA
export CUDA_VISIBLE_DEVICES=1

# Clean conda (important — conda numpy 2.x breaks Python CARLA federate)
unset CONDA_EXE CONDA_PREFIX CONDA_PROMPT_MODIFIER CONDA_SHLVL CONDA_PYTHON_EXE CONDA_DEFAULT_ENV
export PATH=$(echo $PATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
```

### CARLA interface environment variables (optional)

| Variable | Default | Description |
|----------|---------|-------------|
| `CARLA_HOST` | `localhost` | CARLA server host |
| `CARLA_PORT` | `2000` | CARLA server port |
| `CARLA_MAP` | `Town01` | CARLA map name |
| `CARLA_FIXED_DELTA` | `0.05` | Simulation timestep (seconds). FPS = 1/value |
| `CARLA_VEHICLE_TYPE` | `vehicle.toyota.prius` | Ego vehicle blueprint |
| `CARLA_SPAWN_POINT` | random | Spawn location: `x,y,z,roll,pitch,yaw` |
| `CARLA_USE_TM` | `False` | Enable traffic manager (NPC vehicles) |
| `CARLA_TIMEOUT` | `20` | CARLA connection timeout (seconds) |

---

## GPU Notes

This system has two GPUs. CARLA alone consumes ~4 GB VRAM and saturates GPU utilization during rendering. To avoid GPU contention, **CARLA and Autoware are split across separate GPUs**:

| GPU | Device | Role | Typical VRAM Usage |
|-----|--------|------|--------------------|
| **GPU 0** | RTX 3070 (8 GB) | CARLA rendering (+ Xorg, desktop) | ~4.5 GB |
| **GPU 1** | GTX 1050 Ti (4 GB) | Autoware (TensorRT, RViz) | ~1 GB |

All launch scripts set `CUDA_VISIBLE_DEVICES=1` so Autoware's CUDA workloads (lidar_centerpoint TensorRT, etc.) run on the GTX 1050 Ti, leaving the RTX 3070 free for CARLA.

### Performance results

After splitting GPUs (CARLA on GPU 0, Autoware on GPU 1) and using `-quality-level=low`, the simulation runs significantly faster compared to running everything on a single GPU.

> **Important:** The quality level flag is case-sensitive. Use lowercase `low`, not `Low` or `LOW`.

### If you still see low FPS

1. **Lower CARLA quality:**
   ```bash
   ./CarlaUE4.sh -prefernvidia -quality-level=low -RenderOffScreen
   ```

2. **Use a smaller render resolution:**
   ```bash
   ./CarlaUE4.sh -prefernvidia -quality-level=low -ResX=800 -ResY=600
   ```

3. **Disable ML-based perception** (for testing planning/control only):
   Use Mode A and skip lidar_centerpoint if not needed.

---

## Architecture Overview

### Federation Mode (Mode D)

```
                         RTI (Runtime Infrastructure)
                              |  coordination
        ┌─────────────────────┼──────────────────────────┐
        |                     |                          |
   [71 CCpp federates]   [Python CARLA federate]    [RViz]
        |                     |                     (external)
        |              CARLA 0.9.16 (GPU 0)
        |                     |
        v                     v
   ┌─────────────────────────────────────────────────────┐
   |              LF Dataflow Graph (79 connections)     |
   |                                                     |
   |  Sensing: imu → gyro → ekf                         |
   |           cbf → gs → {ogm, cg, aeb, cd, soc}       |
   |           cbf → {lcp, ec, pmf}                      |
   |                                                     |
   |  Localization: ndt → ekf → (14 consumers)          |
   |                                                     |
   |  Perception: lcp → ov → of → mot → mbp → planning  |
   |                                                     |
   |  Map: l2m → (7 consumers), mp → (4 consumers)      |
   |                                                     |
   |  Planning: bpp → bvp → ps → po → mvp → ss → vs →  |
   |            pv → tf                                  |
   |                                                     |
   |  Control: tf → {sd, vcg}, sd → vcg, vcg → bridge   |
   └─────────────────────────────────────────────────────┘
```

Each federate:
1. Creates the Autoware ROS node internally with parameters loaded from YAML
2. Cancels the node's internal ROS timer (replaced by LF timer)
3. Spawns a `spin_node` pthread for TF lookups and external I/O
4. Receives data via **LF input ports** (not ROS subscriptions)
5. Produces output via **LF output ports** with `lf_set()`
6. All inter-node data carries **LF logical timestamps**

### Standalone Mode (Modes A/B)

Nodes run as independent processes without federation coordination. Data flows via ROS topics through spin threads. LF controls **when** each timer fires but not the data routing.

---

## LF Node Timer Rates

| Node | Period | Rate |
|------|--------|------|
| trajectory_follower | 30 ms | 33 Hz |
| vehicle_cmd_gate | 50 ms | 20 Hz |
| carla_interface (Python) | 50 ms | 20 Hz |
| behavior_path_planner | 100 ms | 10 Hz |
| mission_planner | 100 ms | 10 Hz |
| scenario_selector | 100 ms | 10 Hz |
| shift_decider | 100 ms | 10 Hz |
| freespace_planner | 100 ms | 10 Hz |
| mrm_handler | 100 ms | 10 Hz |
| costmap_generator | 200 ms | 5 Hz |
| automatic_pose_initializer | 1000 ms | 1 Hz |

All targets run in **real-time mode** (logical time tracks wall-clock time).

---

## Federation Details

| Metric | Value |
|--------|-------|
| Total federates | 72 (71 CCpp + 1 Python) |
| LF connections | 79 |
| Nodes with input/output ports | 47 |
| Hollow wrappers (system monitors) | 40 |
| Coordination | Decentralized |
| Serialization | ROS 2 (`serializer "ros2"`) |

### Mixed-Target Federation

The CARLA interface uses the **Python target** (CARLA only provides a Python client). All other nodes use **CCpp**. Both targets share the C runtime, so federation coordination works seamlessly. The Python federate is compiled separately and swapped in at runtime. See `DEVELOPMENT_NOTES.md` for details.

---

## File Reference

| File | Purpose |
|------|---------|
| `lf-src/run_federation.sh` | Launch 72-federate federation (Mode D) |
| `test_phase1_carla.sh` | Launch vanilla Autoware + CARLA (Mode C) |
| `test_phase1_carla_no_planning.sh` | Launch Autoware without planning/control (Mode A) |
| `test_carla_interface_only.sh` | Launch CARLA interface + RViz only (Mode B) |
| `lf-src/test_lf_planning_control.sh` | Start 20 LF planning+control nodes |
| `lf-src/test_lf_full_stack.sh` | Start all LF nodes as standalone processes |
| `engage.sh` | Engage vehicle (publish to `/autoware/engage`) |
| `engage_carla.sh` | Engage vehicle (CARLA variant) |
| `lf-src/AutowareFederated.lf` | Federation definition (72 federates, 79 connections) |
| `lf-src/carla_interface/federate__ci.lf` | Python CARLA federate |
| `lf-src/lf-include/utils.hpp` | Shared utilities (YAML loading, spin threads) |
| `lf-src/lf-include/constants.hpp` | Parameter file paths |
| `DEVELOPMENT_NOTES.md` | Technical findings and workarounds |

## Troubleshooting

### Python CARLA federate crashes with numpy error

The Python federate imports `cv_bridge` which requires numpy 1.x. If conda is active, it overrides with numpy 2.x.

**Fix:** The `run_federation.sh` script cleans conda from the environment automatically. If running manually, ensure conda is not in your PATH.

### RTI "Failed to accept socket" errors

With 72 federates connecting simultaneously, the RTI can be overwhelmed. The launcher adds `sleep 0.1` between federate launches to stagger connections.

### Federation hangs at startup

All 72 federates must connect before execution begins. If any federate crashes during startup (e.g., missing parameters), the entire federation hangs. Check the terminal output for error messages from individual federates.
