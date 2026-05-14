#!/usr/bin/env bash
# Kill the full Workflow 3 demo stack:
#   - test_carla_interface_only.sh        (the infra launcher script)
#   - ros2 launch autoware_launch e2e_simulator.launch.xml   (Autoware infra)
#   - rviz2 + robot_state_publisher + static_transform_publisher
#     and any Autoware install binaries it forked
#   - test_lf_full_stack.sh               (the LF launcher script)
#   - all per-node LF binaries from lf-src/bin/*_main
#
# Workflow 3 doesn't use the federated RTI/federate__ binaries, so this
# script does NOT touch fed-gen/. If you also have a federation running,
# use lf-src/kill_federation.sh (different branches) or pkill -f federate__.
#
# Usage:
#   bash kill_workflow3.sh           # SIGTERM, then SIGKILL stragglers
#   bash kill_workflow3.sh --force   # SIGKILL immediately
#   bash kill_workflow3.sh --dry-run # show what would be killed
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

# One regex covers every process class in Workflow 3.
# Anchored to absolute paths / unique fragments so we don't sweep up
# unrelated workloads (other ROS launches, other rviz instances, etc.).
PATTERN="test_carla_interface_only\.sh"
PATTERN="${PATTERN}|test_lf_full_stack\.sh"
PATTERN="${PATTERN}|ros2 launch autoware_launch e2e_simulator"
PATTERN="${PATTERN}|${REPO}/lf-src/bin/"
PATTERN="${PATTERN}|${REPO}/install/"
PATTERN="${PATTERN}|/robot_state_publisher/robot_state_publisher"
PATTERN="${PATTERN}|/joint_state_publisher/joint_state_publisher"
PATTERN="${PATTERN}|tf2_ros/static_transform_publisher"
PATTERN="${PATTERN}|rviz2 .*autoware"
# Generic ROS2 launch helpers spawned by e2e_simulator.launch.xml.
# These survive a SIGTERM to the parent `ros2 launch` and are the most
# common cause of "ports already in use" / duplicate-publisher symptoms
# when restarting. Match by binary path so we don't catch unrelated
# scripts that happen to contain the word "relay" in their cmdline.
PATTERN="${PATTERN}|/topic_tools/relay"
PATTERN="${PATTERN}|/image_transport/republish"
PATTERN="${PATTERN}|/rclcpp_components/component_container"

list_matches() {
    pgrep -af "$PATTERN" 2>/dev/null | grep -v "kill_workflow3\.sh" || true
}

alive_count() {
    pgrep -f "$PATTERN" 2>/dev/null | grep -cv "kill_workflow3\.sh" || true
}

before=$(list_matches)
count=$(alive_count)

if [ "${count:-0}" -eq 0 ]; then
    echo "No Workflow 3 processes found."
else
    echo "Found $count Workflow 3 process(es):"
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
        # Give them up to 4s to clean up (ros2 launch needs more than federates)
        for _ in 1 2 3 4; do
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
    rm -f /dev/shm/fastrtps_* /dev/shm/iceoryx_* /dev/shm/sem.fastrtps_* 2>/dev/null || true

    echo "Restarting ros2 daemon..."
    ros2 daemon stop  >/dev/null 2>&1 || true
    ros2 daemon start >/dev/null 2>&1 || true
fi

# Final check
remaining=$(alive_count)
if [ "${remaining:-0}" -eq 0 ]; then
    echo "All Workflow 3 processes terminated."
    exit 0
else
    echo "WARNING: $remaining process(es) still alive:"
    list_matches
    exit 1
fi
