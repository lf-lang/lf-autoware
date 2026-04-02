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

# 1. map_tf_generator: subscribes to /vector_map, publishes map TF frame
echo "  [map] autoware_vector_map_tf_generator"
ros2 run autoware_map_tf_generator autoware_vector_map_tf_generator \
    --ros-args \
    -r vector_map:=/vector_map \
    -p map_frame:=map \
    -p viewer_frame:=viewer &
pids[$i]=$!; i=$((i+1))

# 2. Vehicle description (robot_state_publisher + joint_state_publisher)
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
