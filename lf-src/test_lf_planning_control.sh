#!/bin/bash
# Test LF Planning + Control nodes alongside vanilla Autoware.
#
# Usage:
#   Terminal 1: Start CARLA
#     cd ~/carla-0.9.16 && ./CarlaUE4.sh -prefernvidia -quality-level=Low -RenderOffScreen
#
#   Terminal 2: Launch Autoware (without planning+control)
#     bash ~/Documents/projects/parking-demo/lf-autoware/test_phase1_carla_no_planning.sh
#
#   Terminal 3: Run this script (LF planning+control)
#     bash ~/Documents/projects/parking-demo/lf-autoware/lf-src/test_lf_planning_control.sh

set -e
set -m

# Clean conda
unset CONDA_EXE CONDA_PREFIX CONDA_PROMPT_MODIFIER CONDA_SHLVL CONDA_PYTHON_EXE CONDA_DEFAULT_ENV _CE_CONDA
export PATH=$(echo $PATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')

export CUDA_VISIBLE_DEVICES=0
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
source /opt/ros/humble/setup.bash
source ~/Documents/projects/parking-demo/lf-autoware/install/setup.bash 2>/dev/null
export LF_AUTOWARE_HOME=~/Documents/projects/parking-demo/lf-autoware

BIN_DIR="$LF_AUTOWARE_HOME/lf-src/bin"

cleanup() {
    echo "Killing LF nodes..."
    kill ${pids[@]} 2>/dev/null || true
    exit 0
}
trap 'cleanup' EXIT INT TERM

echo "=== Starting LF Planning + Control Nodes ==="

# Planning nodes
echo "Starting mission_planner..."
"$BIN_DIR/mission_planner_main" &
pids[0]=$!

echo "Starting behavior_path_planner..."
"$BIN_DIR/behavior_path_planner_main" &
pids[1]=$!

echo "Starting scenario_selector..."
"$BIN_DIR/scenario_selector_main" &
pids[2]=$!

echo "Starting velocity_smoother..."
"$BIN_DIR/velocity_smoother_main" &
pids[3]=$!

echo "Starting freespace_planner..."
"$BIN_DIR/freespace_planner_main" &
pids[4]=$!

echo "Starting costmap_generator..."
"$BIN_DIR/costmap_generator_main" &
pids[5]=$!

# Control nodes
echo "Starting trajectory_follower..."
"$BIN_DIR/trajectory_follower_main" &
pids[6]=$!

echo "Starting shift_decider..."
"$BIN_DIR/shift_decider_main" &
pids[7]=$!

echo "Starting vehicle_cmd_gate..."
"$BIN_DIR/vehicle_cmd_gate_main" &
pids[8]=$!

# Bridge
echo "Starting bridge_interface..."
"$BIN_DIR/bridge_interface_main" &
pids[9]=$!

echo ""
echo "=== All 10 LF nodes started ==="
echo "PIDs: ${pids[*]}"
echo "Press Ctrl-C to stop all nodes."
echo ""

# Wait for any process to exit
wait
