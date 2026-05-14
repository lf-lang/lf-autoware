#!/bin/bash
# Engage the Autoware vehicle for CARLA simulation.
#
# Run this AFTER launching test_phase1_carla.sh and setting the initial pose + goal.
# The CARLA bridge does not auto-engage like the planning simulator does,
# so this script sends the engage command to let control commands flow through
# the vehicle_cmd_gate to CARLA.
#
# Usage:
#   bash ~/Documents/projects/parking-demo/lf-autoware/engage_carla.sh

# Clean conda from environment
unset CONDA_EXE CONDA_PREFIX CONDA_PROMPT_MODIFIER CONDA_SHLVL CONDA_PYTHON_EXE CONDA_DEFAULT_ENV _CE_CONDA
export PATH=$(echo $PATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')

source /opt/ros/humble/setup.bash
source ~/Documents/projects/parking-demo/lf-autoware/install/setup.bash 2>/dev/null
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp  # was cyclonedds; switched 2026-05-07 to match Mode A launch

echo "Sending engage command to Autoware..."
ros2 topic pub --once /autoware/engage autoware_vehicle_msgs/msg/Engage '{engage: true}'
echo "Engage command sent."
echo ""
echo "To verify control commands are flowing:"
echo "  ros2 topic hz /control/command/control_cmd"
echo "  ros2 topic hz /control/command/actuation_cmd"
