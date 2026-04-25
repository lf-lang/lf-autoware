#!/usr/bin/env bash
# Kill every process spawned by run_infrastructure.sh:
#   - the wrapper script itself          (run_infrastructure.sh)
#   - autoware_lanelet2_map_loader       (publishes /map/vector_map)
#   - autoware_vector_map_tf_generator   (publishes the "map" TF frame)
#   - autoware_lanelet2_map_visualizer   (publishes /map/vector_map_marker)
#   - autoware_map_projection_loader     (publishes /map/map_projector_info)
#   - static_transform_publisher map->viewer  (the script's TF fallback)
#   - tier4_vehicle_launch + its robot_state_publisher / joint_state_publisher
#   - rviz2 launched with autoware.rviz config
#
# Also clears DDS shared-memory leftovers and resets the ros2 daemon
# so the next run starts from a clean discovery state.
#
# Usage:
#   bash kill_infrastructure.sh           # SIGTERM, then SIGKILL stragglers
#   bash kill_infrastructure.sh --force   # SIGKILL immediately
#   bash kill_infrastructure.sh --dry-run # show what would be killed
#
# Exits 0 if nothing was running or everything was killed cleanly.

set -u

FORCE=0
DRY=0
while [ $# -gt 0 ]; do
    case "$1" in
        --force)   FORCE=1; shift ;;
        --dry-run) DRY=1;   shift ;;
        -h|--help)
            sed -n '2,21p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *) echo "unknown flag: $1" >&2; exit 2 ;;
    esac
done

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# One regex covers every process class spawned by run_infrastructure.sh.
# Anchored to absolute paths / unique argument fragments so we never match
# unrelated static_transform_publisher or robot_state_publisher instances.
PATTERN="run_infrastructure\.sh"
PATTERN="${PATTERN}|${REPO}/install/autoware_map_loader"
PATTERN="${PATTERN}|${REPO}/install/autoware_map_tf_generator"
PATTERN="${PATTERN}|${REPO}/install/autoware_lanelet2_map_visualizer"
PATTERN="${PATTERN}|${REPO}/install/autoware_map_projection_loader"
PATTERN="${PATTERN}|tf2_ros/static_transform_publisher 0 0 0 0 0 0 map viewer"
PATTERN="${PATTERN}|tier4_vehicle_launch vehicle\.launch\.xml"
# robot_state_publisher / joint_state_publisher are launched by
# tier4_vehicle_launch and load their URDF from a /tmp/launch_params_*
# params file, so we can't filter by URDF name. Match the binary path
# instead — anything else publishing robot/joint state on this machine
# almost certainly came from this script.
PATTERN="${PATTERN}|/robot_state_publisher/robot_state_publisher"
PATTERN="${PATTERN}|/joint_state_publisher/joint_state_publisher"
PATTERN="${PATTERN}|rviz2 .*autoware_launch/rviz/autoware\.rviz"

list_matches() {
    # Exclude this script itself and any grep/pkill helpers from the listing.
    pgrep -af "$PATTERN" 2>/dev/null | grep -v "kill_infrastructure\.sh" || true
}

alive_count() {
    pgrep -f "$PATTERN" 2>/dev/null | grep -cv "kill_infrastructure\.sh" || true
}

before=$(list_matches)
count=$(alive_count)

if [ "${count:-0}" -eq 0 ]; then
    echo "No infrastructure processes found."
else
    echo "Found $count infrastructure process(es):"
    printf '  %s\n' "$before"

    if [ "$DRY" -eq 1 ]; then
        echo "[dry-run] no signals sent."
        exit 0
    fi

    if [ "$FORCE" -eq 1 ]; then
        echo "Sending SIGKILL..."
        pkill -9 -f "$PATTERN"
    else
        echo "Sending SIGTERM..."
        pkill -f "$PATTERN"
        # Give them up to 3s to clean up.
        for _ in 1 2 3; do
            [ "$(alive_count)" -eq 0 ] && break
            sleep 1
        done
        remaining=$(alive_count)
        if [ "${remaining:-0}" -gt 0 ]; then
            echo "$remaining straggler(s) after SIGTERM; sending SIGKILL..."
            pkill -9 -f "$PATTERN"
            sleep 1
        fi
    fi
fi

# DDS cleanup — phantom discovery state survives process death.
if [ "$DRY" -eq 0 ]; then
    echo "Clearing DDS shared-memory leftovers..."
    rm -f /dev/shm/fastrtps_* /dev/shm/iceoryx_* 2>/dev/null || true

    echo "Restarting ros2 daemon..."
    ros2 daemon stop  >/dev/null 2>&1 || true
    ros2 daemon start >/dev/null 2>&1 || true
fi

# Final check
remaining=$(alive_count)
if [ "${remaining:-0}" -eq 0 ]; then
    echo "All infrastructure processes terminated."
    exit 0
else
    echo "WARNING: $remaining process(es) still alive:"
    list_matches
    exit 1
fi
