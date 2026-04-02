# lf-autoware Development Notes

Technical findings, workarounds, and design decisions encountered during the port of Autoware to Lingua Franca.

## Build System

### Parallel Federation Builds

`lfc` builds federates sequentially — a full 72-federate build takes ~2 hours. **Workaround: generate scaffold first, then build in parallel with cmake:**

```bash
# Step 1: Generate scaffold only (fast, ~30 seconds)
lfc --no-compile lf-src/AutowareFederated.lf

# Step 2: Build all federates in parallel (4 at a time)
ls fed-gen/AutowareFederated/src-gen/federate__*/ | xargs -P4 -I{} bash -c '
  cd {} && cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=.../fed-gen/AutowareFederated \
    -DCMAKE_INSTALL_BINDIR=bin > /dev/null 2>&1
  cmake --build build --target install --parallel 8 > /dev/null 2>&1
'
```

This cuts build time from ~2 hours to ~30-40 minutes. Each federate still takes ~1.5 minutes to link (Autoware has massive dependency trees), but 4 concurrent builds saturate the CPU.

**When is a full rebuild needed?**
- Adding/removing federates from `AutowareFederated.lf` (changes `NUMBER_OF_FEDERATES` in every binary)
- Changing LF port connections (changes generated network sender/receiver code)

**Incremental builds** (fast, seconds):
- Fixing a single node's CMakeListsExtension.txt → re-cmake that one federate
- Changing a .lf reaction body → `lfc --no-compile` to regenerate, then rebuild that federate

### TinyXML2 Vendor Issue

Every CMakeListsExtension.txt that transitively depends on `tinyxml2_vendor` needs this workaround at the top:

```cmake
set(TinyXML2_FOUND TRUE)
set(TINYXML2_LIBRARY "/usr/lib/x86_64-linux-gnu/libtinyxml2.so")
set(TINYXML2_INCLUDE_DIR "/usr/include")
```

Without this, cmake fails with: `CMake Error at tinyxml2_vendor-extras.cmake:27`. This affects nearly all nodes because ROS 2 message types transitively depend on tinyxml2.

### PCL/CURL Transitive Dependency

Nodes linking against `autoware_pointcloud_preprocessor` pull in PCL → gdal → netcdf → curl, causing undefined CURL symbols at link time. Fix:

```cmake
find_package(PCL REQUIRED COMPONENTS common io)
find_package(CURL REQUIRED)
target_link_libraries(${LF_MAIN_TARGET} PUBLIC ${PCL_LIBRARIES} CURL::libcurl ncurses)
```

For `occupancy_grid_map_outlier_filter`, the `libconcatenate_data.so` has undefined symbols from `libpointcloud_preprocessor_filter_base.so`. Requires `--no-as-needed` linker flag:

```cmake
target_link_libraries(${LF_MAIN_TARGET} PUBLIC
    ${LIB_OGM_OUTLIER_FILTER}
    -Wl,--no-as-needed
    ${LIB_PP_FILTER_BASE}
    ${LIB_CONCATENATE_DATA}
    ${LIB_PP_FILTER_BASE}
    -Wl,--as-needed
    ...)
```

### Autoware Source Files Not Tracked by Git

The `src/` directory has its own `.gitignore` that ignores everything. Autoware source is managed separately (via `vcs import`). All C++ header modifications (making `timer_`/callbacks public) are **local changes** that persist across builds but aren't version-controlled in this repo. The `.lf` files and `CMakeListsExtension.txt` files in `lf-src/` are tracked.

## Mixed-Target Federation: Python CARLA Federate

### The Problem

`AutowareFederated.lf` uses `target CCpp`, but the CARLA interface requires Python (CARLA only provides a Python client). LF doesn't natively support mixed-target federations.

### The Solution: CCpp Stub + Python Swap

1. `AutowareFederated.lf` imports a **CCpp stub** (`carla_interface_main.lf`) — a no-op placeholder so `lfc` can generate the federation scaffold with `federate__ci` included.

2. A separate **Python federate** (`federate__ci.lf`) is compiled independently with `lfc`. It has the same `FEDERATE_ID`, `NUMBER_OF_FEDERATES`, and coordination parameters as the generated CCpp stub.

3. At runtime, the **launcher script** (`run_federation.sh`) launches the Python binary instead of the CCpp stub:
   ```bash
   # 71 CCpp federates
   for fed in cbf imu vvc ...; do
       "$BIN_DIR/federate__${fed}" -i $FEDERATION_ID &
   done
   # Python CARLA federate (replaces CCpp stub)
   (cd "$CARLA_FED_DIR" && python3 -m federate__ci -i $FEDERATION_ID) &
   ```

4. Both targets use the **C runtime** underneath, so decentralized coordination (P2P sockets, RTI handshake) works seamlessly.

### Federation Preamble for Python

The Python target's code generator doesn't emit the federation preamble symbols (`_lf_executable_preamble`, `num_port_absent_reactions`, etc.) that the C runtime requires. Fix: manually create a `federation_preamble.c` file and add it to the CMakeLists:

```c
// federation_preamble.c
void _lf_executable_preamble(environment_t* env) {
    _lf_my_fed_id = 71;  // Must match FEDERATE_ID
    _fed.number_of_inbound_p2p_connections = 0;
    _fed.number_of_outbound_p2p_connections = 0;
    // ... socket initialization ...
    lf_connect_to_rti("localhost", 0);
}
```

This file must be regenerated whenever `FEDERATE_ID` or `NUMBER_OF_FEDERATES` changes.

### RTI Socket Backlog

With 72 federates connecting simultaneously, the RTI's `accept()` loop can't keep up. The launcher adds `sleep 0.1` between federate launches to stagger connections:

```bash
for fed in cbf imu vvc ...; do
    "$BIN_DIR/federate__${fed}" -i $FEDERATION_ID &
    sleep 0.1  # Stagger to avoid RTI accept() overload
done
```

## Node Porting Patterns

### Pattern A: Timer-Driven Node (e.g., shift_decider, vehicle_cmd_gate)

The ROS node has an internal `rclcpp::TimerBase::SharedPtr timer_` that periodically triggers processing. The LF reactor replaces it:

1. **C++ header modification**: Make `timer_` and `onTimer()` public
2. **Startup reaction**: Create node, cancel internal timer, spawn spin thread
3. **LF timer reaction**: Calls `node->onTimer()`, checks output flags, calls `lf_set()`

```lf
timer t(0, 100 msec);
reaction (t) -> gear_cmd {=
    self->node->onTimer();
    if (self->node->lf_gear_cmd_is_set) {
        lf_set(gear_cmd, std::make_shared<...>(self->node->lf_output_gear_cmd));
        self->node->lf_gear_cmd_is_set = false;
    }
=}
```

### Pattern B: Subscription-Driven Node (e.g., behavior_velocity_planner)

The ROS node processes data when a subscription callback fires. The LF reactor triggers the callback directly:

1. **C++ header modification**: Make callback public, add `lf_output_*` fields
2. **C++ source modification**: Intercept `publisher->publish()` to set `lf_output_*`
3. **LF input reaction**: Calls callback, checks output flag, calls `lf_set()`

```lf
reaction (path_in) -> path_out {=
    if (path_in->is_present) {
        self->node->onTrigger(path_in->value);
        if (self->node->lf_path_is_set) {
            lf_set(path_out, std::make_shared<...>(self->node->lf_output_path));
            self->node->lf_path_is_set = false;
        }
    }
=}
```

### Pattern C: Filter-Based Node (e.g., ground_segmentation, crop_box_filter)

Inherits from `autoware::pointcloud_preprocessor::Filter` base class. The subscription is managed by the base class and can't easily be intercepted. These nodes keep the **spin thread** for subscription handling. The LF input port receives data but the actual processing happens via the ROS callback in the spin thread.

### Publish Interception

To capture a node's output in an LF port, we add fields to the C++ class:

```cpp
// In the header (public section):
autoware_planning_msgs::msg::Path lf_output_path;
bool lf_path_is_set = false;

// In the source, alongside the ROS publish:
path_pub_->publish(output_path_msg);
lf_output_path = output_path_msg;  // LF interception
lf_path_is_set = true;
```

The LF reaction checks `lf_path_is_set` after calling the callback and emits the output via `lf_set()`.

## GPU Configuration

### Dual-GPU Split

CARLA rendering alone consumes ~4 GB VRAM and saturates GPU utilization. Running Autoware's CUDA workloads (lidar_centerpoint TensorRT) on the same GPU causes ~1 FPS.

**Solution**: Split across two GPUs:
- **GPU 0 (RTX 3070)**: CARLA rendering only
- **GPU 1 (GTX 1050 Ti)**: Autoware CUDA workloads (`CUDA_VISIBLE_DEVICES=1`)

This is configured in all launch scripts. `CUDA_VISIBLE_DEVICES` only affects CUDA — RViz uses OpenGL through the X server on GPU 0 regardless.

### CARLA Quality Setting

The `-quality-level` flag is **case-sensitive**. Use lowercase `low`, not `Low` or `LOW`:
```bash
./CarlaUE4.sh -prefernvidia -quality-level=low
```

## Deferred Nodes

Two nodes couldn't be ported as LF federates due to build issues:

1. **pointcloud_concatenator**: Uses a C++ template class (`PointCloudConcatenateDataSynchronizerComponentTemplated`) whose `initialize_pub_sub()` method is not exported from the shared library. Would need to include the `.cpp`/`.ipp` source directly.

2. **map_tf_generator**: Class is defined entirely inline in a `.cpp` file (no separate header). Would need to use `class_loader` or include the source directly.

Both remain as ROS nodes in hybrid mode.

## Architecture Decisions

### Why Spin Threads Remain

Even with LF connections, most nodes still spawn a `pthread` spin thread because:
- **TF lookups**: Many nodes need `tf2` transform lookups which require spinning
- **Service servers**: Some nodes host ROS services that need to be responsive
- **Polling subscribers**: `InterProcessPollingSubscriber` requires spinning to receive data
- **Filter base class**: The pointcloud filter base class manages its own subscriptions

The spin thread is only removed when a node's subscriptions are **fully replaced** by LF input ports and it doesn't need TF or services.

### Connection Serialization

All LF connections use `serializer "ros2"`:
```lf
bpp.path_out ~> bvp.path_in serializer "ros2";
```

This uses `rclcpp::Serialization<MessageT>` to serialize/deserialize ROS messages over the LF network layer. This is necessary for federated execution where each federate is a separate process.

## ROS Callback ↔ LF Runtime Boundary

### Overview

Each LF reactor wraps a ROS node. The boundary between ROS and LF has two directions:
- **Output**: How does a ROS node's `publish()` become an LF port output?
- **Input**: How does an LF port input reach a ROS node's subscription callback?

### Pattern 1: Output Interception (ROS → LF)

The ROS node's internal `publish()` call is intercepted. We modify the C++ source to also store the published data in a public `lf_output_*` field. The LF reaction checks this field after calling the node's processing method.

**C++ header modification** (public section):
```cpp
autoware_control_msgs::msg::Control lf_output_control_cmd;
bool lf_control_cmd_is_set = false;
```

**C++ source modification** (alongside existing publish):
```cpp
control_cmd_pub_->publish(msg);      // original ROS publish (still happens)
lf_output_control_cmd = msg;         // LF interception: copy data
lf_control_cmd_is_set = true;        // LF interception: set flag
```

**LF reaction** (checks flag after calling node method):
```lf
reaction (t) -> control_cmd {=
    self->node->onTimer();
    if (self->node->lf_control_cmd_is_set) {
        auto msg = std::make_shared<...>(self->node->lf_output_control_cmd);
        lf_set(control_cmd, msg);
        self->node->lf_control_cmd_is_set = false;
    }
=}
```

**Best example:** `lf-src/vehicle_cmd_gate/vehicle_cmd_gate_main.lf` (lines 69-97) — timer-driven node with 4 output ports.

**Note:** The ROS publish still happens (dual publishing). Data flows through both ROS topics AND LF connections simultaneously. The goal is to eventually remove the ROS publish, but this requires ensuring all downstream consumers use LF ports.

### Pattern 2: Input Forwarding (LF → ROS)

An LF input port triggers a reaction that calls the node's subscription callback directly, bypassing ROS subscription entirely.

```lf
reaction (auto_control_cmd_in) {=
    if (auto_control_cmd_in->is_present) {
        self->node->onAutoCtrlCmd(auto_control_cmd_in->value);
    }
=}
```

**Best example:** `lf-src/vehicle_cmd_gate/vehicle_cmd_gate_main.lf` (lines 74-78) — receives control command from trajectory_follower via LF port, calls the node's callback directly.

**Requires:** The node's callback method must be `public` in the C++ header.

### Pattern 3: Subscription-Driven with Output (Combined)

For nodes that are triggered by incoming data (not timers), the reaction receives input via LF port, calls the callback, and checks for output:

```lf
reaction (path_in) -> path_out {=
    if (path_in->is_present) {
        self->node->onTrigger(path_in->value);      // call callback
        if (self->node->lf_path_is_set) {            // check output
            auto msg = std::make_shared<...>(self->node->lf_output_path);
            lf_set(path_out, msg);                   // emit to LF
            self->node->lf_path_is_set = false;
        }
    }
=}
```

**Best example:** `lf-src/behavior_velocity_planner/behavior_velocity_planner_main.lf` — subscription-driven planning node.

### How lf-avp-demo Does It (The Ideal)

In lf-avp-demo, nodes were designed to store output in member variables instead of publishing. No `publish()` interception needed:

```lf
// From lf-avp-demo mpc_controller:
reaction (vehicle_kinematic_state) -> command {=
    self->node->on_state(vehicle_kinematic_state->value);
    if (self->node->cmd_is_set) {
        lf_set(command, make_shared<...>(self->node->cmd));
        self->node->cmd_is_set = false;
    }
=}
```

The key difference: lf-avp-demo's Autoware (AutowareAuto) had simpler node classes where output member variables could be added cleanly. The current Autoware Universe has more complex node architectures with private publishers, requiring the `publish()` interception workaround.

### Current Status vs. Ideal

| Aspect | lf-avp-demo (ideal) | Current lf-autoware |
|--------|---------------------|---------------------|
| Output capture | Node stores in member var | Intercept `publish()` + `lf_output_*` field |
| Input delivery | Reaction calls callback directly | ~15 direct, ~32 via spin thread stubs |
| Spin thread | Only for TF | Most nodes still have spin thread |
| ROS pub/sub | Fully replaced by LF | Coexists — both ROS and LF |
| Dual publishing | No | Yes (data flows through both) |
| Nodes fully converted | All ~15 | ~15 planning+control pipeline |
| Nodes with stub reactions | 0 | ~32 (ports declared but data not intercepted) |

### Path to Full lf-avp-demo Style

To fully replicate the lf-avp-demo approach for all nodes:

1. **For each node's output:** Add `lf_output_*` field + `lf_*_is_set` flag to C++ header, add interception alongside `publish()` in source, add LF reaction that checks flag after callback.

2. **For each node's input:** Make callback method public, write LF reaction that calls it with `input->value`.

3. **Remove spin thread** once all subscriptions are replaced by LF input ports (keep only for TF lookups and services).

4. **Eventually remove ROS publish** once all downstream consumers use LF ports (eliminate dual publishing).

## Federation Bootstrap Issues (Mode D)

### Bootstrap Dependency Chain

The federation cannot run fully standalone — some nodes must publish data before others can start. The bootstrap chain is:

```
map_projection_loader → /map/map_projector_info
    → lanelet2_map_loader → /vector_map
        → vector_map_tf_generator → "map" TF frame
            → ALL other nodes (need map → base_link transform)
```

**Solution:** `map_projection_loader`, `vector_map_tf_generator`, and `robot_state_publisher` run as **ROS infrastructure nodes** (`run_infrastructure.sh`), separate from the federation. This avoids the chicken-and-egg problem where the federation can't start without TF, but TF can't be published without the federation's map data.

### NUMBER_OF_FEDERATES Mismatch

Every CCpp federate has `NUMBER_OF_FEDERATES` baked in at compile time. Adding or removing a federate requires **rebuilding all** binaries. The RTI's `-n` flag must match.

If you add a node to the federation but only rebuild that one binary, the RTI will accept all connections but the old federates' socket arrays are sized wrong, causing "Broken pipe" errors and cascade failure.

**Workaround:** For nodes that don't need LF connections (like `map_projection_loader`), run them as standalone ROS nodes in the infrastructure script instead of adding them to the federation.

### TensorRT Compute Capability

`tensorrt_yolox` builds TensorRT engines for a specific GPU compute capability. The engine file is cached in `~/autoware_data/`. If `CUDA_VISIBLE_DEVICES` switches GPUs (e.g., from RTX 3070 compute 8.6 to GTX 1050 Ti compute 6.1), the cached engine is incompatible and the node crashes:

```
IRuntime::deserializeCudaEngine: Error Code 6: expecting compute 6.1 got compute 8.6
```

**Fix:** Either rebuild the TensorRT engine on the target GPU, or exclude `tensorrt_yolox` from the federation (it's not on the critical driving path).

### YAML Launch Substitution Variables

Autoware YAML parameter files contain `$(var ...)` launch substitution variables (e.g., `$(var lanelet2_map_path)`). These are resolved by the ROS 2 launch system but **not** by LF's YAML loader.

**Fix:** Use `resolve_yaml_vars()` from `utils.hpp` to string-replace the substitutions before loading:

```cpp
std::string resolved_yaml = resolve_yaml_vars(yaml_path, {
    {"$(var lanelet2_map_path)", map_path + "/lanelet2_map.osm"}
});
rclcpp::NodeOptions nodeOptions = get_node_options_from_yaml(resolved_yaml.c_str(), "/**");
```

### NumPy Version Conflict

The Python CARLA federate imports `cv_bridge` and `transforms3d` which require NumPy 1.x. Conda environments override system NumPy with 2.x, causing `_ARRAY_API not found` and `np.float` removal errors.

**Fix:**
1. `run_federation.sh` strips conda from PATH/LD_LIBRARY_PATH/PYTHONPATH
2. System NumPy must be `<= 1.23.5` (1.24+ removed `np.float`, 2.x is incompatible with `cv_bridge`)

```bash
pip install 'numpy==1.23.5'
```

### Infrastructure Script (`run_infrastructure.sh`)

The infrastructure script launches exactly 3 node groups:

1. **map_projection_loader** — publishes `/map/map_projector_info` (needed by `lanelet2_map_loader` in the federation)
2. **vector_map_tf_generator** — subscribes to `/vector_map`, publishes `map` TF frame
3. **vehicle.launch.xml** — `robot_state_publisher` with proper xacro arguments (`vehicle_model`, `sensor_model`)
4. **RViz** — with Autoware config file

Key learnings:
- Must use `autoware_vector_map_tf_generator` (not `vector_map_tf_generator_node`) as the executable name
- `robot_state_publisher` needs the vehicle xacro with `vehicle_model` and `sensor_model` arguments — use `tier4_vehicle_launch/vehicle.launch.xml` instead of raw xacro
- Don't use `set -e` — background processes returning non-zero kill the script
- RViz needs `-d autoware.rviz` config for the Autoware UI
