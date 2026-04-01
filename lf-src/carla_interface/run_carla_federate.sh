#!/bin/bash
# Run the Python CARLA interface federate (ID 46) as part of the
# AutowareFederated decentralized federation.
#
# The Python target uses the C runtime underneath, so federation
# coordination works seamlessly with the 46 CCpp federates.
#
# Usage:
#   bash lf-src/carla_interface/run_carla_federate.sh -i <FEDERATION_ID>
#
# Environment variables (all optional, with defaults):
#   CARLA_HOST              - CARLA server host (default: localhost)
#   CARLA_PORT              - CARLA server port (default: 2000)
#   CARLA_MAP               - CARLA map to load (default: Town01)
#   CARLA_FIXED_DELTA       - Simulation timestep in seconds (default: 0.05)
#   CARLA_VEHICLE_TYPE      - Ego vehicle blueprint (default: vehicle.toyota.prius)
#   CARLA_SPAWN_POINT       - Spawn location "x,y,z,roll,pitch,yaw" (default: random)
#   CARLA_USE_TM            - Enable traffic manager NPC vehicles (default: False)
#   CARLA_SENSOR_MAPPING    - Path to sensor_mapping.yaml
#   CARLA_SENSOR_KIT        - Sensor kit name (default: carla_sensor_kit_description)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LF_SRC_DIR="$(dirname "$SCRIPT_DIR")"
export LF_AUTOWARE_HOME="${LF_AUTOWARE_HOME:-$(dirname "$LF_SRC_DIR")}"

# Default sensor mapping path
export CARLA_SENSOR_MAPPING="${CARLA_SENSOR_MAPPING:-${LF_AUTOWARE_HOME}/src/universe/autoware_universe/simulator/autoware_carla_interface/config/sensor_mapping.yaml}"

# Find the compiled Python federate
FEDERATE_DIR="$LF_AUTOWARE_HOME/src-gen/lf-src/carla_interface/federate__ci"
if [ ! -d "$FEDERATE_DIR" ]; then
    echo "ERROR: federate__ci not compiled."
    echo "Run:  lfc lf-src/carla_interface/federate__ci.lf"
    exit 1
fi

echo "=== Starting Python CARLA federate (ID 46) ==="
echo "CARLA_HOST: ${CARLA_HOST:-localhost}"
echo "CARLA_PORT: ${CARLA_PORT:-2000}"
echo "CARLA_MAP:  ${CARLA_MAP:-Town01}"
echo "LF_AUTOWARE_HOME: $LF_AUTOWARE_HOME"
echo ""

cd "$FEDERATE_DIR"
python3 -m federate__ci "$@"
