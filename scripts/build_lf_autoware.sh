#!/usr/bin/env bash
# Builds the LF-side monolithic program (lf-src/Autoware.lf -> bin/Autoware).
#
# Prerequisites: lf-src/Autoware.lf currently imports only `shift_decider`,
# so the only colcon dependency that has to be installed is
# `autoware_shift_decider` (and its transitive deps, which are already
# satisfied by `install/`). When more reactors are added to Autoware.lf,
# add their colcon packages to the COLCON_PKGS list below.
#
# Same idea as lf-src/shift_decider/build.sh, but for the top-level
# Autoware.lf instead of the standalone shift_decider self-test.
#
# Usage:
#   bash scripts/build_lf_autoware.sh
#   bash scripts/build_lf_autoware.sh --no-colcon   # skip the ROS-pkg rebuild
#   bash scripts/build_lf_autoware.sh --clean       # rm src-gen/ + bin/Autoware first

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# --- Argument parsing ---------------------------------------------------
DO_COLCON=1
DO_CLEAN=0
for arg in "$@"; do
    case "$arg" in
        --no-colcon) DO_COLCON=0 ;;
        --clean)     DO_CLEAN=1 ;;
        *)           echo "WARNING: unknown argument '$arg' (ignored)" >&2 ;;
    esac
done

# Clean conda from environment (mirrors lf-src/shift_decider/build.sh).
unset CONDA_EXE CONDA_PREFIX CONDA_PROMPT_MODIFIER CONDA_SHLVL \
      CONDA_PYTHON_EXE CONDA_DEFAULT_ENV _CE_CONDA 2>/dev/null || true
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export LD_LIBRARY_PATH=$(echo "${LD_LIBRARY_PATH:-}" | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export PYTHONPATH=$(echo "${PYTHONPATH:-}" | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')

# Source ROS Humble.
set +u
source /opt/ros/humble/setup.bash
set -u

# --- 1. Build / refresh the colcon dependencies of Autoware.lf -----------
COLCON_PKGS=(
    autoware_shift_decider
    # As more reactors land in Autoware.lf, add their packages here:
    # autoware_planning_validator
    # autoware_trajectory_follower_node
    # autoware_vehicle_cmd_gate
)

if [ "$DO_COLCON" -eq 1 ]; then
    echo "=== colcon build: ${COLCON_PKGS[*]} ==="
    colcon build \
        --packages-select "${COLCON_PKGS[@]}" \
        --symlink-install \
        --cmake-args -DCMAKE_BUILD_TYPE=Debug
fi

# Source the freshly-installed workspace so lfc-dev's CMake can
# find the packages above via CMAKE_PREFIX_PATH + LD_LIBRARY_PATH.
set +u
source "$REPO_ROOT/install/setup.bash"
set -u

# Required by lf-src/lf-include/utils.hpp and CMakeListsExtension.txt.
export LF_AUTOWARE_HOME="$REPO_ROOT"

# --- 2. Clean (optional) ------------------------------------------------
if [ "$DO_CLEAN" -eq 1 ]; then
    echo "=== Cleaning src-gen/ + bin/Autoware ==="
    rm -rf "$REPO_ROOT/src-gen/lf-src/Autoware"
    rm -f  "$REPO_ROOT/bin/Autoware"
fi

# --- 3. lfc-dev compile -------------------------------------------------
command -v lfc-dev >/dev/null 2>&1 || {
    echo "ERROR: lfc-dev not on PATH." >&2
    echo "  Install / activate Lingua Franca first (e.g., export PATH=\$LF_HOME/bin:\$PATH)." >&2
    exit 2
}

echo "=== lfc-dev lf-src/Autoware.lf ==="
lfc-dev "$REPO_ROOT/lf-src/Autoware.lf"

# --- 4. Sanity-check the output -----------------------------------------
if [ ! -x "$REPO_ROOT/bin/Autoware" ]; then
    echo "ERROR: lfc-dev finished but bin/Autoware was not produced." >&2
    exit 3
fi

echo ""
echo "=== Built: $REPO_ROOT/bin/Autoware ==="
echo "Run with:  bash scripts/run_lf_autoware.sh"
