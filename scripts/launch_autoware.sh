#!/bin/bash
# Launches Autoware Universe + CARLA bridge (Mode A: vanilla ROS).
#
# CARLA runs in synchronous mode with fixed_delta_seconds=0.05 (20 FPS).
# Each world.tick() advances simulation by exactly 0.05s, making it deterministic.
#
# Usage:
#   Terminal 1: Start CARLA server
#     bash scripts/launch_carla.sh
#
#   Terminal 2: Run this script
#     bash scripts/launch_autoware.sh
#     bash scripts/launch_autoware.sh --no-rviz
#     bash scripts/launch_autoware.sh --lf-managed=shift_decider
#     bash scripts/launch_autoware.sh --lf-managed=shift_decider,vehicle_cmd_gate
#
# --lf-managed=<comma-separated-list>
#   Suppresses the listed vanilla composable_nodes so an LF reactor (in
#   lf-src/Autoware.lf) can own them without colliding. Currently
#   supported: shift_decider. Future additions: planning_validator,
#   trajectory_follower, vehicle_cmd_gate, bridge_interface — one for
#   each fully-ported reactor.

set -e

# Clean conda from environment to avoid library conflicts
unset CONDA_EXE CONDA_PREFIX CONDA_PROMPT_MODIFIER CONDA_SHLVL CONDA_PYTHON_EXE CONDA_DEFAULT_ENV _CE_CONDA
export PATH=$(echo $PATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export PYTHONPATH=$(echo $PYTHONPATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')

# Single-GPU layout — everything on GPU 0 (RTX 3070, 8 GB).
# CARLA is slim (cameras disabled in autoware_carla_interface/config/sensor_mapping.yaml,
# headless tiny window) so it fits alongside Autoware's full perception (lidar_centerpoint
# TRT engine). GPU 1 (GTX 1050 Ti, sm_6.1) is unused — TRT 10 dropped Pascal support.
export CUDA_VISIBLE_DEVICES=0

# Use FastDDS — works out-of-the-box for large transient_local messages
# (CycloneDDS in this environment silently dropped /map/vector_map; see
# 2026-05-07 debug session. Switch back with rmw_cyclonedds_cpp + a proper
# CYCLONEDDS_URI config + sysctl rmem/wmem bumps + `ip link set lo multicast on`.)
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp

# Source ROS2 and workspace
source /opt/ros/humble/setup.bash
source ~/Documents/projects/parking-demo/lf-autoware/install/setup.bash 2>/dev/null

# --- Argument parsing ---------------------------------------------------
RVIZ="true"
LF_MANAGED=""

for arg in "$@"; do
    case "$arg" in
        --no-rviz)
            RVIZ="false"
            ;;
        --lf-managed=*)
            LF_MANAGED="${arg#--lf-managed=}"
            ;;
        *)
            echo "WARNING: unknown argument '$arg' (ignored)" >&2
            ;;
    esac
done

# Translate --lf-managed into ros2 launch args. Add one branch per
# fully-ported reactor as it lands in lf-src/Autoware.lf.
EXTRA_ARGS=()
add_lf_managed_arg() {
    local name="$1"
    if [[ ",$LF_MANAGED," == *,"$name",* ]]; then
        EXTRA_ARGS+=("lf_managed_${name}:=true")
        echo "  - suppressing vanilla ${name} (LF reactor owns it)"
    fi
}

echo "=== Mode A: Autoware Universe + CARLA (Synchronous) ==="
echo "ROS_DISTRO: $ROS_DISTRO"
echo "Make sure CARLA server is running (scripts/launch_carla.sh) first!"
if [ -n "$LF_MANAGED" ]; then
    echo "LF-managed nodes:"
    add_lf_managed_arg shift_decider
    # Future:
    # add_lf_managed_arg planning_validator
    # add_lf_managed_arg trajectory_follower
    # add_lf_managed_arg vehicle_cmd_gate
    # add_lf_managed_arg bridge_interface
fi
echo ""

MAP_PATH="$HOME/autoware_map/Town01"

if [ ! -f "$MAP_PATH/pointcloud_map.pcd" ]; then
    echo "ERROR: Map data not found at $MAP_PATH"
    echo "Download from: https://bitbucket.org/carla-simulator/autoware-contents/"
    exit 1
fi

echo "Using map:     $MAP_PATH"
echo "Vehicle model: sample_vehicle"
echo "Sensor model:  carla_sensor_kit"
echo "Simulator:     CARLA (synchronous mode, 20 FPS)"
echo "RViz:          $RVIZ"
echo ""

echo "Launching Autoware with CARLA interface..."
echo ""
echo "NOTE: After Autoware initializes, you must engage the vehicle."
echo "  In another terminal, run:"
echo "    bash scripts/engage.sh"
echo ""

ros2 launch autoware_launch e2e_simulator.launch.xml \
    map_path:="$MAP_PATH" \
    vehicle_model:=sample_vehicle \
    sensor_model:=carla_sensor_kit \
    simulator_type:=carla \
    rviz:="$RVIZ" \
    "${EXTRA_ARGS[@]}"
