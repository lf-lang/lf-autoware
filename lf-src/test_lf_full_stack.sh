#!/bin/bash
# Run the FULL Autoware stack as LF nodes.
# Only CARLA interface and RViz remain as vanilla ROS nodes.
#
# Prerequisites:
#   Terminal 1: CARLA running
#   Terminal 2: CARLA interface + RViz only:
#     bash test_carla_interface_only.sh
#   Terminal 3: This script (all LF nodes)

set -e
set -m

unset CONDA_EXE CONDA_PREFIX CONDA_PROMPT_MODIFIER CONDA_SHLVL CONDA_PYTHON_EXE CONDA_DEFAULT_ENV _CE_CONDA
export PATH=$(echo $PATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export CUDA_VISIBLE_DEVICES=0
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
source /opt/ros/humble/setup.bash
source ~/Documents/projects/parking-demo/lf-autoware/install/setup.bash 2>/dev/null
export LF_AUTOWARE_HOME=~/Documents/projects/parking-demo/lf-autoware

BIN="$LF_AUTOWARE_HOME/lf-src/bin"

cleanup() {
    echo "Killing all LF nodes..."
    kill ${pids[@]} 2>/dev/null || true
    exit 0
}
trap 'cleanup' EXIT INT TERM

echo "=== Starting FULL LF Autoware Stack ==="
i=0

# Map
for node in pointcloud_map_loader lanelet2_map_loader; do
    echo "  [map] $node"
    "$BIN/${node}_main" &
    pids[$i]=$!; i=$((i+1))
done

# Sensing
for node in crop_box_filter imu_corrector vehicle_velocity_converter; do
    echo "  [sensing] $node"
    "$BIN/${node}_main" &
    pids[$i]=$!; i=$((i+1))
done

# Localization
for node in ndt_scan_matcher gyro_odometer ekf_localizer; do
    echo "  [localization] $node"
    "$BIN/${node}_main" &
    pids[$i]=$!; i=$((i+1))
done

# Perception
for node in ground_segmentation lidar_centerpoint euclidean_cluster \
            pointcloud_map_filter detection_by_tracker object_validator \
            object_filter camera_lidar_fusion multi_object_tracker \
            map_based_prediction occupancy_grid_map \
            traffic_light_map_based_detector traffic_light_classifier \
            traffic_light_arbiter traffic_light_occlusion_predictor \
            crosswalk_traffic_light_estimator; do
    echo "  [perception] $node"
    "$BIN/${node}_main" &
    pids[$i]=$!; i=$((i+1))
done

# Planning
for node in mission_planner behavior_path_planner behavior_velocity_planner \
            path_smoother path_optimizer motion_velocity_planner \
            surround_obstacle_checker scenario_selector velocity_smoother \
            costmap_generator freespace_planner \
            planning_validator external_velocity_limit_selector; do
    echo "  [planning] $node"
    "$BIN/${node}_main" &
    pids[$i]=$!; i=$((i+1))
done

# Control
for node in trajectory_follower shift_decider vehicle_cmd_gate \
            operation_mode_transition_manager lane_departure_checker \
            control_validator autonomous_emergency_braking collision_detector; do
    echo "  [control] $node"
    "$BIN/${node}_main" &
    pids[$i]=$!; i=$((i+1))
done

# Bridge
echo "  [bridge] bridge_interface"
"$BIN/bridge_interface_main" &
pids[$i]=$!

echo ""
echo "=== All $((i+1)) LF nodes started ==="
echo "Press Ctrl-C to stop."
echo ""

wait
