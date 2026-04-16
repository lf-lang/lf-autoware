#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

set +u
source /opt/ros/humble/setup.bash
set -u

colcon build \
  --packages-select autoware_vehicle_cmd_gate \
  --symlink-install \
  --cmake-args -DCMAKE_BUILD_TYPE=Debug

set +u
source install/setup.bash
set -u

export LF_AUTOWARE_HOME="$REPO_ROOT"
lfc-dev lf-src/vehicle_cmd_gate/vehicle_cmd_gate_main.lf
