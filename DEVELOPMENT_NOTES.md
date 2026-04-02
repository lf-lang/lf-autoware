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
