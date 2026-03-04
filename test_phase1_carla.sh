#!/bin/bash
# Phase 1 Test Script: Autoware Universe + CARLA (Synchronous Mode)
#
# CARLA runs in synchronous mode with fixed_delta_seconds=0.05 (20 FPS).
# Each world.tick() advances simulation by exactly 0.05s, making it deterministic.
#
# Usage:
#   Terminal 1: Start CARLA server (headless — use rviz for visualization)
#     cd ~/carla-0.9.16 && ./CarlaUE4.sh -prefernvidia -quality-level=Low -RenderOffScreen
#     # With display (may crash on some GPU/driver combos):
#     # cd ~/carla-0.9.16 && ./CarlaUE4.sh -prefernvidia -quality-level=Low
#
#   Terminal 2: Run this script
#     bash ~/Documents/projects/parking-demo/lf-autoware/test_phase1_carla.sh
#     bash ~/Documents/projects/parking-demo/lf-autoware/test_phase1_carla.sh --no-rviz

set -e

# Clean conda from environment to avoid library conflicts
unset CONDA_EXE CONDA_PREFIX CONDA_PROMPT_MODIFIER CONDA_SHLVL CONDA_PYTHON_EXE CONDA_DEFAULT_ENV _CE_CONDA
export PATH=$(echo $PATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export PYTHONPATH=$(echo $PYTHONPATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')

# Pin Autoware's CUDA/TensorRT to GPU 0 (RTX 3070)
export CUDA_VISIBLE_DEVICES=0

# Use CycloneDDS for reliable large-message transport
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# Source ROS2 and workspace
source /opt/ros/humble/setup.bash
source ~/Documents/projects/parking-demo/lf-autoware/install/setup.bash 2>/dev/null

echo "=== Phase 1: Autoware + CARLA (Synchronous) ==="
echo "ROS_DISTRO: $ROS_DISTRO"
echo "Make sure CARLA server is running in another terminal first!"
echo ""

MAP_PATH="$HOME/autoware_map/Town01"

if [ ! -f "$MAP_PATH/pointcloud_map.pcd" ]; then
    echo "ERROR: Map data not found at $MAP_PATH"
    echo "Download from: https://bitbucket.org/carla-simulator/autoware-contents/"
    exit 1
fi

echo "Using map: $MAP_PATH"
echo "Vehicle model: sample_vehicle"
echo "Sensor model: carla_sensor_kit"
echo "Simulator: CARLA (synchronous mode, 20 FPS)"
echo ""

RVIZ="true"
if [ "$1" = "--no-rviz" ]; then
    RVIZ="false"
    echo "(rviz disabled)"
fi

echo "Launching Autoware with CARLA interface..."
echo ""
echo "NOTE: After Autoware initializes, you must engage the vehicle."
echo "  In another terminal, run:"
echo "    ros2 topic pub /autoware/engage autoware_vehicle_msgs/msg/Engage '{engage: true}' --once"
echo ""

ros2 launch autoware_launch e2e_simulator.launch.xml \
    map_path:="$MAP_PATH" \
    vehicle_model:=sample_vehicle \
    sensor_model:=carla_sensor_kit \
    simulator_type:=carla \
    rviz:="$RVIZ"
