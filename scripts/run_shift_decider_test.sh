#!/bin/bash
# Runs the standalone shift_decider self-test (bin/shift_decider_main, compiled
# from lf-src/shift_decider/shift_decider_main.lf).
#
# The self-test instantiates an in-process ShiftDeciderTestSource that feeds
# synthetic control_cmd / autoware_state / current_gear inputs, then a
# ShiftDeciderChecker validates that the wrapper produces exactly one DRIVE
# gear command and calls lf_request_stop().
#
# Same purpose as run_lf_autoware.sh, just for the test binary instead of
# bin/Autoware.
#
# Build it first:
#   bash lf-src/shift_decider/build.sh
#
# Usage:
#   bash scripts/run_shift_decider_test.sh

set -e

# Clean conda from environment (matches scripts/launch_autoware.sh).
unset CONDA_EXE CONDA_PREFIX CONDA_PROMPT_MODIFIER CONDA_SHLVL \
      CONDA_PYTHON_EXE CONDA_DEFAULT_ENV _CE_CONDA
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export LD_LIBRARY_PATH=$(echo "${LD_LIBRARY_PATH:-}" | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export PYTHONPATH=$(echo "${PYTHONPATH:-}" | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# RMW must match what bin/Autoware and scripts/launch_autoware.sh use, so the
# self-test exercises the same typesupport stack as production. (See
# lessons.md §7 for why this matters.)
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp

# Source ROS + workspace. The latter is what populates LD_LIBRARY_PATH so
# rcutils' dlopen() of the FastDDS typesupport .so's succeeds.
set +u
source /opt/ros/humble/setup.bash
source "$REPO_ROOT/install/setup.bash"
set -u

export LF_AUTOWARE_HOME="$REPO_ROOT"

if [ ! -x "$REPO_ROOT/bin/shift_decider_main" ]; then
    echo "ERROR: $REPO_ROOT/bin/shift_decider_main not built." >&2
    echo "  Build it first with:  bash lf-src/shift_decider/build.sh" >&2
    exit 1
fi

echo "=== shift_decider self-test ==="
echo "RMW_IMPLEMENTATION: $RMW_IMPLEMENTATION"
echo "binary:             $REPO_ROOT/bin/shift_decider_main"
echo "expected:           'observed gear_cmd=2' (= DRIVE), exit 0"
echo ""

exec "$REPO_ROOT/bin/shift_decider_main" "$@"
