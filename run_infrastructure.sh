#!/bin/bash
# Minimal ROS infrastructure for the LF federation (Mode D).
#
# Launches only the nodes that the federation can't handle yet:
# - map_tf_generator: publishes "map" TF frame (deferred from federation)
# - robot_state_publisher: publishes vehicle URDF TF transforms
# - RViz: visualization
#
# The federation handles everything else (sensing, localization, perception,
# planning, control, CARLA interface).
#
# Usage:
#   Terminal 1: CARLA server
#   Terminal 2: This script
#   Terminal 3: bash lf-src/run_federation.sh
#   Terminal 4: bash engage.sh + set goal in RViz

set -m

unset CONDA_EXE CONDA_PREFIX CONDA_PROMPT_MODIFIER CONDA_SHLVL CONDA_PYTHON_EXE CONDA_DEFAULT_ENV _CE_CONDA
export PATH=$(echo $PATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')

export CUDA_VISIBLE_DEVICES=1
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
source /opt/ros/humble/setup.bash
source ~/Documents/projects/parking-demo/lf-autoware/install/setup.bash 2>/dev/null
export LF_AUTOWARE_HOME=~/Documents/projects/parking-demo/lf-autoware

MAP_PATH="$HOME/autoware_map/Town01"

cleanup() {
    echo "Killing infrastructure nodes..."
    kill ${pids[@]} 2>/dev/null || true
    exit 0
}
trap 'cleanup' EXIT INT TERM

echo "=== Launching minimal infrastructure for LF federation ==="
echo ""
i=0

# 0. lanelet2_map_loader: subscribes to /map/map_projector_info and publishes
#    /map/vector_map. Start it before map_projection_loader so it is already
#    subscribed when the one-shot projector info message is published.
echo "  [map] lanelet2_map_loader"
ros2 run autoware_map_loader autoware_lanelet2_map_loader \
    --ros-args \
    -p allow_unsupported_version:=true \
    -p center_line_resolution:=5.0 \
    -p use_waypoints:=true \
    -p lanelet2_map_path:="$MAP_PATH/lanelet2_map.osm" \
    -r output/lanelet2_map:=/map/vector_map \
    -r output/lanelet2_map_marker:=/map/vector_map_marker \
    -r input/map_projector_info:=/map/map_projector_info &
pids[$i]=$!; i=$((i+1))
sleep 1

# 1. map_tf_generator: subscribes to /map/vector_map, publishes the "map" TF frame.
echo "  [map] autoware_vector_map_tf_generator"
ros2 run autoware_map_tf_generator autoware_vector_map_tf_generator \
    --ros-args \
    -r vector_map:=/map/vector_map \
    -p map_frame:=map \
    -p viewer_frame:=viewer &
pids[$i]=$!; i=$((i+1))

# 2b. Explicit static map frame fallback. This keeps RViz's fixed frame valid
#     even if map_tf_generator misses the one-shot transient vector_map sample.
echo "  [map] static map->viewer tf fallback"
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 map viewer &
pids[$i]=$!; i=$((i+1))

# 2c. lanelet2_map_visualization: subscribes to /map/vector_map, publishes
#     /map/vector_map_marker (what RViz's "Lanelet2VectorMap" display reads).
#     Without this the map is loaded but invisible in RViz.
echo "  [map] lanelet2_map_visualization"
ros2 run autoware_lanelet2_map_visualizer autoware_lanelet2_map_visualizer \
    --ros-args \
    -r input/lanelet2_map:=/map/vector_map \
    -r output/lanelet2_map_marker:=/map/vector_map_marker &
pids[$i]=$!; i=$((i+1))

# Wait until lanelet2_map_loader has actually subscribed to
# /map/map_projector_info BEFORE starting map_projection_loader.
# map_projection_loader publishes a single transient_local sample and exits
# its main loop; if the loader isn't subscribed yet, the message is missed
# and /map/vector_map is silently never published (which then leaves the
# "map" TF frame and /map/vector_map_marker permanently empty).
# A flat `sleep` is unreliable — ros2 run's Python wrapper + autoware C++
# binary commonly take 2–4s to reach the subscription, so we poll instead.
echo -n "  [map] waiting for lanelet2_map_loader to subscribe to /map/map_projector_info"
for _ in $(seq 1 30); do
    if ros2 topic info /map/map_projector_info 2>/dev/null \
         | grep -q "Subscription count: [1-9]"; then
        echo " ✓"
        break
    fi
    sleep 1; echo -n "."
done
if ! ros2 topic info /map/map_projector_info 2>/dev/null \
       | grep -q "Subscription count: [1-9]"; then
    echo " TIMEOUT after 30s — projection_loader will likely race"
fi

# 3. map_projection_loader: publishes /map/map_projector_info (needed by
#    lanelet2_map_loader). Needs BOTH lanelet2_map_path AND
#    map_projector_info_path — omitting the latter silently crashes with
#    "No map projector info files found". -r __ns:=/map puts the publisher
#    on /map/map_projector_info which is what downstream subs expect.
#
# NOTE: do NOT pass --params-file here. Autoware's param YAML contains
# literal '$(var lanelet2_map_path)' strings (launch-time substitutions
# that ros2 run doesn't expand), and they override our -p flags, landing
# the node in the "No map projector info files found" error path.
echo "  [map] map_projection_loader"
ros2 run autoware_map_projection_loader autoware_map_projection_loader_node \
    --ros-args \
    -p lanelet2_map_path:="$MAP_PATH/lanelet2_map.osm" \
    -p map_projector_info_path:="$MAP_PATH/map_projector_info.yaml" \
    -r __ns:=/map &
pids[$i]=$!; i=$((i+1))

# 4. Vehicle description (robot_state_publisher + joint_state_publisher)
echo "  [vehicle] robot_state_publisher via vehicle.launch.xml"
ros2 launch tier4_vehicle_launch vehicle.launch.xml \
    vehicle_model:=sample_vehicle \
    sensor_model:=carla_sensor_kit \
    launch_vehicle_interface:=false &
pids[$i]=$!; i=$((i+1))

# 3. RViz
echo "  [viz] rviz2"
rviz2 -d "$LF_AUTOWARE_HOME/src/launcher/autoware_launch/autoware_launch/rviz/autoware.rviz" &
pids[$i]=$!; i=$((i+1))

echo ""
echo "=== $i infrastructure nodes started ==="
echo "Now launch the federation: bash lf-src/run_federation.sh"
echo "Press Ctrl-C to stop."
echo ""

wait
