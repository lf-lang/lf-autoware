#!/bin/bash
# Runs the LF-side Autoware program (bin/Autoware compiled from
# lf-src/Autoware.lf). Intended to be run alongside scripts/launch_autoware.sh,
# typically with `--lf-managed=<list>` set on the launch side so the vanilla
# composable_node(s) for the same Autoware classes are suppressed.
#
# Sources ROS Humble + the workspace install tree, pins RMW to FastDDS to
# match scripts/launch_autoware.sh, and execs bin/Autoware. Without this
# wrapper, running ./bin/Autoware in a fresh shell fails at startup with
# "Could not load library ...__rosidl_typesupport_fastrtps_cpp.so" because
# LD_LIBRARY_PATH does not include the per-package install/<pkg>/lib paths.
#
# Build it first:
#   bash lf-src/shift_decider/build.sh        # builds shift_decider_main
#   lfc-dev lf-src/Autoware.lf                # builds bin/Autoware
# (or wire bin/Autoware into a build script of its own — TODO)
#
# Usage:
#   bash scripts/run_lf_autoware.sh

set -e

# Clean conda from environment to avoid library conflicts (matches
# scripts/launch_autoware.sh).
unset CONDA_EXE CONDA_PREFIX CONDA_PROMPT_MODIFIER CONDA_SHLVL \
      CONDA_PYTHON_EXE CONDA_DEFAULT_ENV _CE_CONDA
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export LD_LIBRARY_PATH=$(echo "${LD_LIBRARY_PATH:-}" | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export PYTHONPATH=$(echo "${PYTHONPATH:-}" | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')

# Resolve repo root from this script's location so the script works regardless
# of the caller's cwd.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Pin to GPU 0 (RTX 3070) to match the rest of the Mode A stack — see lessons.md §5.
export CUDA_VISIBLE_DEVICES=0

# Match the launch side's RMW. Both must agree or topic discovery silently
# fails (see lessons.md §7).
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp

# Source ROS + workspace. ROS setup scripts touch unbound vars; suspend -u.
set +u
source /opt/ros/humble/setup.bash
source "$REPO_ROOT/install/setup.bash"
set -u

export LF_AUTOWARE_HOME="$REPO_ROOT"

if [ ! -x "$REPO_ROOT/bin/Autoware" ]; then
    echo "ERROR: $REPO_ROOT/bin/Autoware not built." >&2
    echo "  Build it first with:  lfc-dev lf-src/Autoware.lf" >&2
    exit 1
fi

echo "=== LF Autoware ==="
echo "ROS_DISTRO:        $ROS_DISTRO"
echo "RMW_IMPLEMENTATION: $RMW_IMPLEMENTATION"
echo "LF_AUTOWARE_HOME:  $LF_AUTOWARE_HOME"
echo "binary:            $REPO_ROOT/bin/Autoware"
echo ""
echo "NOTE: launch_autoware.sh should be running with --lf-managed=<list>"
echo "      so vanilla composable_nodes don't collide with the LF reactor(s)"
echo "      this binary spawns. Currently LF owns: shift_decider."
echo ""

exec "$REPO_ROOT/bin/Autoware" "$@"
