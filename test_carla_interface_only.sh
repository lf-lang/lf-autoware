#!/bin/bash
# Launch ONLY the CARLA interface + RViz + system essentials.
# All other nodes (sensing, localization, perception, planning, control)
# will be run as LF nodes via test_lf_full_stack.sh.
#
# Usage:
#   Terminal 1: CARLA server
#   Terminal 2: This script
#   Terminal 3: bash lf-src/test_lf_full_stack.sh
#   Terminal 4: bash engage.sh + set goal in RViz

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

echo "=== CARLA Interface + RViz Only ==="
echo "All Autoware nodes will be LF processes."
echo ""

ros2 launch autoware_launch e2e_simulator.launch.xml \
    map_path:="$MAP_PATH" \
    vehicle_model:=sample_vehicle \
    sensor_model:=carla_sensor_kit \
    simulator_type:=carla \
    rviz:=true \
    launch_sensing:=false \
    launch_localization:=false \
    launch_perception:=false \
    launch_planning:=false \
    launch_control:=false
