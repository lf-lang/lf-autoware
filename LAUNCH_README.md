# lf-autoware Launch Guide

This guide explains how to launch the Lingua Franca (LF) port of Autoware with the CARLA 0.9.16 simulator.

## Prerequisites

- **CARLA 0.9.16** installed at `~/carla-0.9.16/`
- **Autoware** built with colcon (`install/` directory present)
- **LF binaries** compiled in `lf-src/bin/`
- **Map data** at `~/autoware_map/Town01/` (pointcloud_map.pcd + lanelet2_map.osm)
- **NVIDIA GPUs**: GPU 0 = RTX 3070 (reserved for CARLA), GPU 1 = GTX 1050 Ti (for Autoware/TensorRT). Driver 570+
- **ROS Humble** installed at `/opt/ros/humble/`

### Python dependencies (for CARLA interface)
```bash
pip install carla==0.9.16
```

## Launch Modes

There are three launch modes, depending on how much of the Autoware stack runs as LF processes.

| Mode | ROS nodes | LF nodes | Terminals |
|------|-----------|----------|-----------|
| **A. Hybrid** (planning+control in LF) | CARLA, sensing, localization, perception | Planning, control, bridge | 4 |
| **B. Full LF Stack** (everything in LF) | CARLA interface only | All Autoware nodes | 4 |
| **C. Vanilla Autoware** (no LF, for comparison) | Everything | None | 3 |

---

## Mode A: Hybrid (LF Planning + Control)

ROS handles sensing, localization, and perception. LF handles planning, control, and the bridge interface (20 LF nodes).

### Terminal 1 — Start CARLA `[GPU 0: RTX 3070]`
```bash
cd ~/carla-0.9.16
./CarlaUE4.sh -prefernvidia -quality-level=low
```
CARLA uses GPU 0 automatically (primary display GPU).

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

This starts 20 LF nodes:
- **Planning (11):** mission_planner, behavior_path_planner, behavior_velocity_planner, path_smoother, path_optimizer, motion_velocity_planner, surround_obstacle_checker, scenario_selector, velocity_smoother, planning_validator, external_velocity_limit_selector
- **Control (8):** trajectory_follower, shift_decider, vehicle_cmd_gate, operation_mode_transition_manager, lane_departure_checker, control_validator, autonomous_emergency_braking, collision_detector
- **Bridge (1):** bridge_interface

Press `Ctrl-C` to stop all LF nodes.

### Terminal 4 — Engage the vehicle
```bash
bash ~/Documents/projects/parking-demo/lf-autoware/engage.sh
```
Then set a **2D Goal Pose** in RViz.

---

## Mode B: Full LF Stack

Only the CARLA interface and RViz run as ROS nodes. Everything else (sensing, localization, perception, planning, control) runs as LF processes.

### Terminal 1 — Start CARLA `[GPU 0: RTX 3070]`
```bash
cd ~/carla-0.9.16
./CarlaUE4.sh -prefernvidia -quality-level=low
```
CARLA uses GPU 0 automatically (primary display GPU).

### Terminal 2 — Launch CARLA interface + RViz only `[GPU 1: GTX 1050 Ti]`
```bash
bash ~/Documents/projects/parking-demo/lf-autoware/test_carla_interface_only.sh
```

All Autoware subsystems are disabled. Only the CARLA-ROS bridge and RViz are launched. Script sets `CUDA_VISIBLE_DEVICES=1`.

### Terminal 3 — Launch full LF stack `[GPU 1: GTX 1050 Ti]`
```bash
bash ~/Documents/projects/parking-demo/lf-autoware/lf-src/test_lf_full_stack.sh
```

This starts all ~45 LF nodes across every subsystem (map, sensing, localization, perception, planning, control, bridge).

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
CARLA uses GPU 0 automatically (primary display GPU).

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
```

### CARLA interface environment variables (optional)

These apply when running the Python LF CARLA federate (`CarlaInterface.lf`):

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

> **Note:** The GTX 1050 Ti has only 4 GB VRAM. If TensorRT models don't fit, you may need to use smaller model variants or disable ML-based perception.

### Performance results

After splitting GPUs (CARLA on GPU 0, Autoware on GPU 1) and using `-quality-level=low`, the simulation runs significantly faster compared to running everything on a single GPU.

> **Important:** The quality level flag is case-sensitive. Use lowercase `low`, not `Low` or `LOW`. The value `low` is what CARLA's Unreal Engine recognizes.

### If you still see low FPS

1. **Lower CARLA quality** (recommended):
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

## LF Node Timer Rates

Each LF node is driven by a periodic timer that replaces the original ROS timer callback:

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

## Architecture Overview

```
CARLA 0.9.16 (simulator)
    |
    | (ROS topics: sensor data, vehicle status)
    v
autoware_carla_interface (ROS node)
    |
    | (ROS topics)
    v
[Sensing] -> [Localization] -> [Perception] -> [Planning] -> [Control]
    ^                                              |              |
    |              (LF timer-driven nodes)         |              |
    |                                              v              v
    +<-------- bridge_interface (LF) <--- vehicle_cmd_gate (LF) --+
                        |
                        | (ROS topics: /control/command/*)
                        v
                   CARLA (actuators)
```

Each LF node:
1. Creates the Autoware ROS node internally with parameters loaded from YAML
2. Cancels the node's internal ROS timer
3. Spawns a `spin_node` pthread for ROS subscriber polling
4. Uses an LF timer to drive the callback at the specified rate

Data between nodes flows via **ROS topics** (through spin threads). LF controls **when** each node's callback executes.

---

## File Reference

| File | Purpose |
|------|---------|
| `test_phase1_carla.sh` | Launch vanilla Autoware + CARLA (Mode C) |
| `test_phase1_carla_no_planning.sh` | Launch Autoware without planning/control (Mode A) |
| `test_carla_interface_only.sh` | Launch CARLA interface + RViz only (Mode B) |
| `lf-src/test_lf_planning_control.sh` | Start 20 LF planning+control nodes |
| `lf-src/test_lf_full_stack.sh` | Start all ~45 LF nodes |
| `engage.sh` | Engage vehicle (publish to `/autoware/engage`) |
| `engage_carla.sh` | Engage vehicle (CARLA variant) |
| `lf-src/carla_interface/build_carla_federate.sh` | Build Python CARLA federate |
| `lf-src/carla_interface/run_carla_federate.sh` | Run Python CARLA federate |
| `lf-src/AutowareFederated.lf` | Federation definition (59 federates) |
| `lf-src/AutowareMono.lf` | Monolithic (single-process) variant |
| `lf-src/lf-include/utils.hpp` | Shared utilities (YAML loading, spin threads) |
| `lf-src/lf-include/constants.hpp` | Parameter file paths |
