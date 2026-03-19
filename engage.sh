#!/bin/bash
# Engage Autoware vehicle.
# Set the goal manually via RViz (2D Goal Pose button).
#
# Usage: bash engage.sh

source /opt/ros/humble/setup.bash
source ~/Documents/projects/parking-demo/lf-autoware/install/setup.bash 2>/dev/null
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

echo "Engaging vehicle..."
ros2 topic pub /autoware/engage autoware_vehicle_msgs/msg/Engage '{engage: true}' --once
echo "Done. Set a goal via RViz 2D Goal Pose."
