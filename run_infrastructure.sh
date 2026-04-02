#!/bin/bash
# Minimal ROS infrastructure for the LF federation.
#
# Launches only the nodes that the federation can't handle yet:
# - map_tf_generator: publishes "map" TF frame (deferred from federation)
# - robot_state_publisher: publishes vehicle URDF TF transforms
# - RViz: visualization
#
# Usage:
#   Terminal 1: CARLA
#   Terminal 2: This script
#   Terminal 3: bash lf-src/run_federation.sh
#   Terminal 4: bash engage.sh

set -e

unset CONDA_EXE CONDA_PREFIX CONDA_PROMPT_MODIFIER CONDA_SHLVL CONDA_PYTHON_EXE CONDA_DEFAULT_ENV _CE_CONDA
export PATH=$(echo $PATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')

export CUDA_VISIBLE_DEVICES=1
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
source /opt/ros/humble/setup.bash
source ~/Documents/projects/parking-demo/lf-autoware/install/setup.bash 2>/dev/null
export LF_AUTOWARE_HOME=~/Documents/projects/parking-demo/lf-autoware

MAP_PATH="$HOME/autoware_map/Town01"

echo "=== Launching minimal infrastructure for LF federation ==="
echo ""

# Launch map + vehicle (TF) + system + RViz
# Do NOT use simulator_type=carla — the CARLA bridge is handled by the Python federate
# Use planning_simulator launch instead (no simulator, just infrastructure)
ros2 launch autoware_launch planning_simulator.launch.xml \
    map_path:="$MAP_PATH" \
    vehicle_model:=sample_vehicle \
    sensor_model:=carla_sensor_kit \
    rviz:=true \
    launch_sensing:=false \
    launch_localization:=false \
    launch_perception:=false \
    launch_planning:=false \
    launch_control:=false
