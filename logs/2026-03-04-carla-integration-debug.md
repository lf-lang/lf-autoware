# Autoware Universe + CARLA Integration: Debug Log

Date: 2026-03-04
Branch: `feature/lf-phase2-planning-control`
Setup: Autoware Universe (Humble) + CARLA 0.9.16, synchronous mode @ 20 FPS

## Initial Symptoms

After launching Autoware with the CARLA bridge (`test_phase1_carla.sh`):
1. Routes could be planned in RViz (planning stack functional)
2. Car did NOT move after engage
3. Car was NOT visible in CARLA spectator view

## Root Causes and Fixes (in order of discovery)

### 1. Missing simulation flags in e2e_simulator.launch.xml

**Problem:** `e2e_simulator.launch.xml` did not pass `is_simulation=true` or
`enable_all_modules_auto_mode=true` to `autoware.launch.xml`. Without these,
`vehicle_cmd_gate` stays in manual mode and rejects autonomous control commands.
The planning simulator launch has these flags; the e2e simulator launch did not.

**Fix:** Added both flags to `e2e_simulator.launch.xml`:
```xml
<arg name="enable_all_modules_auto_mode" default="true"/>
...
<arg name="is_simulation" value="true"/>
<arg name="enable_all_modules_auto_mode" value="$(var enable_all_modules_auto_mode)"/>
```

**File:** `src/launcher/autoware_launch/autoware_launch/launch/e2e_simulator.launch.xml`

### 2. No engage mechanism for CARLA path

**Problem:** Unlike `planning_simulator.launch.xml` which launches
`simple_planning_simulator` (auto-engages), the CARLA e2e path requires
manual engagement. Without engage, `vehicle_cmd_gate` blocks all commands.

**Fix:** Created `engage_carla.sh`:
```bash
ros2 topic pub --once /autoware/engage autoware_vehicle_msgs/msg/Engage '{engage: true}'
```

**File:** `engage_carla.sh` (new)

### 3. raw_vehicle_cmd_converter missing operation_mode_state remap

**Problem:** The CARLA launch file's `raw_vehicle_cmd_converter` node was missing
a remap for `~/input/operation_mode_state`. Without it, the node subscribed to a
namespaced topic nobody published to, so it never received operation mode data and
never produced `/control/command/actuation_cmd` (the topic CARLA actually reads).

The control chain is:
```
/planning/trajectory
  -> controller_node -> /control/command/control_cmd
  -> vehicle_cmd_gate -> /control/command/control_cmd (gated)
  -> raw_vehicle_cmd_converter -> /control/command/actuation_cmd  <-- broken here
  -> carla_ros2_interface -> ego_actor.apply_control()
```

**Fix:** Added the remap:
```xml
<remap from="~/input/operation_mode_state" to="/system/operation_mode/state"/>
```

**File:** `src/universe/autoware_universe/simulator/autoware_carla_interface/launch/autoware_carla_interface.launch.xml`

### 4. Car invisible in CARLA (spectator camera)

**Problem:** CARLA's spectator camera defaults to a fixed position far from the
spawned ego vehicle. The car exists and drives, but the camera doesn't follow it.

**Fix:** Added `_update_spectator()` method to `carla_ros.py` that moves the
spectator to a chase-cam position behind the ego vehicle every tick:
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

Also required adding the import: `from .modules.carla_data_provider import CarlaDataProvider`

**File:** `src/universe/autoware_universe/simulator/autoware_carla_interface/src/autoware_carla_interface/carla_ros.py`

### 5. Duplicate node names triggering MRM emergency stop

**Problem:** The CARLA bridge launch file creates relay nodes
(`traffic_light_image_relay`, `traffic_light_camera_info_relay`) with names
identical to nodes launched by Autoware's own perception stack. Autoware's
`duplicated_node_checker` detects these, reports ERROR on `/autoware/system`,
which triggers MRM -> emergency stop -> `vehicle_cmd_gate: Emergency!`.

**Fix:** Renamed CARLA relay nodes to avoid collisions:
```xml
<node pkg="topic_tools" exec="relay" name="carla_traffic_light_image_relay" .../>
<node pkg="topic_tools" exec="relay" name="carla_traffic_light_camera_info_relay" .../>
```

**File:** `src/universe/autoware_universe/simulator/autoware_carla_interface/launch/autoware_carla_interface.launch.xml`

### 6. Diagnostic graph aggregator crash (THE MAIN BLOCKER)

This was the hardest problem. Even after renaming relay nodes, the car still
would not drive. The full causal chain:

```
duplicated_node_checker ERROR (remaining duplicates from installed packages)
  -> /autoware/system AND gate = ERROR (requires duplicated_node_checker OK)
  -> diagnostic_graph_aggregator publishes ERROR status
  -> hazard_status_converter -> /system/emergency/hazard_status = emergency
  -> mrm_handler triggers emergency stop
  -> vehicle_cmd_gate enters Emergency mode
  -> all control commands blocked
  -> car doesn't move
```

**Failed fix attempt 1: Override /autoware/system in autoware-carla.yaml**

Tried adding a second definition of `/autoware/system` (without
`duplicated_node_checker`) directly in `autoware-carla.yaml`. This caused
`PathConflict` exception in the graph loader (`loader.cpp:212`) because the
path was already defined in the included `system.yaml`. The aggregator crashed
on startup -> converter_node never received input -> `/system/operation_mode/availability`
never published -> mrm_handler stuck "waiting for operation_mode_availability msg"
-> vehicle_cmd_gate never exits emergency mode.

**Failed fix attempt 2: Use edits:remove mechanism**

The diagnostic graph loader has a built-in `edits` system (`loader.cpp:318-401`).
Tried:
```yaml
edits:
  - type: remove
    path: /autoware/system/duplicated_node_checker
```

This also crashed the aggregator. The `apply_remove_edits()` function
(`loader.cpp:330-336`) only collects paths from `nodes_` (AND/OR gate types).
`duplicated_node_checker` is a `diag` type -> stored in `diags_` not `nodes_`
-> `remove_paths.count(path) == 0` -> `PathNotFound` exception -> crash.

**Successful fix: CARLA-specific system.yaml**

Created `system-carla.yaml` — a copy of `system.yaml` with two changes:
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

**Files:**
- `src/launcher/autoware_launch/autoware_launch/config/system/diagnostics/system-carla.yaml` (new)
- `src/launcher/autoware_launch/autoware_launch/config/system/diagnostics/autoware-carla.yaml` (modified)

## Key Architectural Insights

### Autoware Diagnostic Graph System

The diagnostic system is a directed acyclic graph defined in YAML:
- **diag nodes**: Leaf nodes monitoring real ROS2 node heartbeats/diagnostics
- **AND/OR nodes**: Logical gates combining child results
- **modes**: Top-level nodes defining what must be healthy for each operation mode

The graph is loaded by `diagnostic_graph_aggregator` (aggregator_node), which:
1. Loads YAML files recursively via `files:` includes
2. Creates NodeUnits (AND/OR) and DiagUnits (diag)
3. Resolves link references between nodes
4. Topologically sorts the graph
5. Applies `edits` (remove only, and only for NodeUnits — not DiagUnits)
6. Publishes `CommandModeAvailability` to converter_node
7. converter_node publishes `OperationModeAvailability`
8. mrm_handler consumes this to decide emergency actions

If the aggregator crashes at any step, the entire safety chain stalls.

### CARLA Control Flow

```
CARLA Server (UE4, separate process)
  <-- world.tick() (synchronous mode) --
CARLA Python Client (autoware_carla_interface)
  -- publishes sensor data --> ROS2 topics
  -- subscribes /control/command/actuation_cmd -->
  -- calls ego_actor.apply_control(throttle, brake, steer) -->
CARLA Server applies physics
```

The `raw_vehicle_cmd_converter` is critical: it converts high-level control
(velocity/acceleration/steering angle) to low-level actuation (throttle 0-1,
brake 0-1, steer -1 to 1) using CSV calibration maps.

### Why e2e_simulator differs from planning_simulator

| Feature | planning_simulator | e2e_simulator (CARLA) |
|---------|-------------------|----------------------|
| Vehicle sim | simple_planning_simulator (internal) | CARLA (external process) |
| Auto-engage | Yes (built-in) | No (manual engage required) |
| Vehicle interface | Dummy (launch_vehicle_interface=false) | CARLA bridge |
| Sensor data | None (ground truth) | CARLA sensors via bridge |
| is_simulation | Set by default | Was missing, had to add |

## Files Modified (from vanilla Autoware)

1. `src/launcher/autoware_launch/autoware_launch/launch/e2e_simulator.launch.xml` — simulation flags
2. `src/launcher/autoware_launch/autoware_launch/config/system/diagnostics/autoware-carla.yaml` — use system-carla.yaml
3. `src/launcher/autoware_launch/autoware_launch/config/system/diagnostics/system-carla.yaml` — new, no duplicated_node_checker
4. `src/universe/autoware_universe/simulator/autoware_carla_interface/launch/autoware_carla_interface.launch.xml` — operation_mode remap, renamed relays
5. `src/universe/autoware_universe/simulator/autoware_carla_interface/src/autoware_carla_interface/carla_ros.py` — spectator follow cam
6. `engage_carla.sh` — new helper script
7. `test_phase1_carla.sh` — updated instructions
