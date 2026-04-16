#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

set +u
source /opt/ros/humble/setup.bash
set -u

colcon build \
  --packages-select autoware_trajectory_follower_node \
  --symlink-install \
  --cmake-args -DCMAKE_BUILD_TYPE=Debug

set +u
source install/setup.bash
set -u

export LF_AUTOWARE_HOME="$REPO_ROOT"
lfc-dev lf-src/trajectory_follower/trajectory_follower_main.lf
