#!/bin/bash
# Build the Python CARLA interface federate.
#
# The federation (AutowareFederated.lf) uses a CCpp stub for carla_interface
# so lfc can generate the federation scaffold. This script builds the real
# Python federate that replaces the stub at runtime.
#
# Usage:
#   bash lf-src/carla_interface/build_carla_federate.sh
#
# Prerequisites:
#   - LF_AUTOWARE_HOME is set
#   - lfc (Lingua Franca compiler) is on PATH
#   - Python carla package installed (pip install carla==0.9.16)
#   - autoware_carla_interface ROS package built (colcon build)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LF_SRC_DIR="$(dirname "$SCRIPT_DIR")"
LF_AUTOWARE_HOME="${LF_AUTOWARE_HOME:-$(dirname "$LF_SRC_DIR")}"

echo "=== Building Python CARLA interface federate ==="
echo "LF_AUTOWARE_HOME: $LF_AUTOWARE_HOME"

# 1. Compile the Python CarlaInterface.lf
echo "Compiling CarlaInterface.lf..."
lfc "$SCRIPT_DIR/CarlaInterface.lf"

echo ""
echo "=== Build complete ==="
echo ""
echo "The Python CARLA federate is ready."
echo ""
echo "To run the full stack:"
echo "  1. Start CARLA:  cd ~/carla-0.9.16 && ./CarlaUE4.sh"
echo "  2. Start CCpp federates:  bash lf-src/test_lf_full_stack.sh"
echo "  3. Start CARLA federate:  bash lf-src/carla_interface/run_carla_federate.sh"
echo ""
echo "The Python federate connects to the same decentralized coordination"
echo "as the CCpp federates (both use the C runtime underneath)."
