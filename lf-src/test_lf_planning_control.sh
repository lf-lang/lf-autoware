#!/bin/bash
# Test ALL LF Planning + Control nodes alongside vanilla Autoware.
#
# Prerequisites:
#   Terminal 1: CARLA running
#   Terminal 2: Autoware without planning/control:
#     bash test_phase1_carla_no_planning.sh
#   Terminal 3: This script

set -e
set -m

unset CONDA_EXE CONDA_PREFIX CONDA_PROMPT_MODIFIER CONDA_SHLVL CONDA_PYTHON_EXE CONDA_DEFAULT_ENV _CE_CONDA
export PATH=$(echo $PATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export CUDA_VISIBLE_DEVICES=1
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
source /opt/ros/humble/setup.bash
source ~/Documents/projects/parking-demo/lf-autoware/install/setup.bash 2>/dev/null
export LF_AUTOWARE_HOME=~/Documents/projects/parking-demo/lf-autoware

BIN="$LF_AUTOWARE_HOME/lf-src/bin"

cleanup() {
    echo "Killing LF nodes..."
    kill ${pids[@]} 2>/dev/null || true
    exit 0
}
trap 'cleanup' EXIT INT TERM

echo "=== Starting ALL LF Planning + Control Nodes ==="
i=0

# Planning
for node in mission_planner behavior_path_planner behavior_velocity_planner \
            path_smoother path_optimizer motion_velocity_planner \
            surround_obstacle_checker scenario_selector velocity_smoother \
            planning_validator external_velocity_limit_selector; do
    echo "  Starting $node..."
    "$BIN/${node}_main" &
    pids[$i]=$!
    i=$((i+1))
done

# Control
for node in trajectory_follower shift_decider vehicle_cmd_gate \
            operation_mode_transition_manager lane_departure_checker \
            control_validator autonomous_emergency_braking collision_detector; do
    echo "  Starting $node..."
    "$BIN/${node}_main" &
    pids[$i]=$!
    i=$((i+1))
done

# Bridge
echo "  Starting bridge_interface..."
"$BIN/bridge_interface_main" &
pids[$i]=$!

echo ""
echo "=== All $((i+1)) LF nodes started ==="
echo "Press Ctrl-C to stop."
echo ""

# Wait for any process to exit
wait
