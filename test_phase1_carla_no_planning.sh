#!/bin/bash
# Launch Autoware with CARLA but WITHOUT planning+control.
# Use with test_lf_planning_control.sh to run LF planning+control.
#
# Usage:
#   Terminal 1: Start CARLA
#   Terminal 2: Run this script
#   Terminal 3: Run lf-src/test_lf_planning_control.sh

set -e

unset CONDA_EXE CONDA_PREFIX CONDA_PROMPT_MODIFIER CONDA_SHLVL CONDA_PYTHON_EXE CONDA_DEFAULT_ENV _CE_CONDA
export PATH=$(echo $PATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export PYTHONPATH=$(echo $PYTHONPATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')

export CUDA_VISIBLE_DEVICES=1
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
source /opt/ros/humble/setup.bash
source ~/Documents/projects/parking-demo/lf-autoware/install/setup.bash 2>/dev/null

MAP_PATH="$HOME/autoware_map/Town01"

echo "=== Autoware + CARLA (no planning/control) ==="
echo "Planning and control will be handled by LF nodes."
echo ""

ros2 launch autoware_launch e2e_simulator.launch.xml \
    map_path:="$MAP_PATH" \
    vehicle_model:=sample_vehicle \
    sensor_model:=carla_sensor_kit \
    simulator_type:=carla \
    rviz:=true \
    launch_planning:=false \
    launch_control:=false
