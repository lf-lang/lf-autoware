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

# Compile federate__ci.lf — the Python variant whose FEDERATE_ID and
# NUMBER_OF_FEDERATES match the CCpp stub scaffolded by lfc from
# AutowareFederated.lf. Output lands in
# $LF_AUTOWARE_HOME/src-gen/lf-src/carla_interface/federate__ci/
# and run_federation.sh launches it as `python3 -m federate__ci`.
echo "Compiling federate__ci.lf..."
lfc-dev "$SCRIPT_DIR/federate__ci.lf"

# The Python target doesn't emit the federation preamble symbols that the
# C runtime needs for link (_lf_executable_preamble, num_port_absent_reactions,
# initialize_triggers_for_federate, lf_send_neighbor_structure_to_RTI).
# The CCpp stub generated from AutowareFederated.lf does — and because both
# share FEDERATE_ID=70 / NUMBER_OF_FEDERATES=71, we can lift the stub's
# preamble verbatim. Without this the loader fails with:
#     undefined symbol: num_port_absent_reactions
FED_CI_DIR="$LF_AUTOWARE_HOME/src-gen/lf-src/carla_interface/federate__ci"
STUB_PREAMBLE="$LF_AUTOWARE_HOME/fed-gen/AutowareFederated/src/include/_federate__ci_preamble.h"
if [ ! -f "$STUB_PREAMBLE" ]; then
    echo "ERROR: CCpp stub preamble not found at $STUB_PREAMBLE"
    echo "       Run: lfc-dev --no-compile lf-src/AutowareFederated.lf"
    exit 1
fi
echo "Injecting federation preamble from CCpp stub..."
cp "$STUB_PREAMBLE" "$FED_CI_DIR/federation_preamble.c"

# The stub's preamble defines initialize_triggers_for_federate as a macro.
# That only works when the header is #included before call sites — which
# doesn't happen in the Python federate (we link a separately-compiled
# object). Convert the macro into a real function symbol.
python3 - "$FED_CI_DIR/federation_preamble.c" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
txt = p.read_text()
# Replace the do/while macro form with a real function definition.
patched = re.sub(
    r'#define initialize_triggers_for_federate\(\)\s*\\\s*\n'
    r'do\s*\{\s*\\\s*\n'
    r'(?P<body>.*?)\\\s*\n'
    r'\}\s*\\\s*\nwhile\s*\(0\)\s*\n',
    r'void initialize_triggers_for_federate(void) {\n\g<body>\n}\n',
    txt, count=1, flags=re.DOTALL,
)
if patched == txt:
    sys.stderr.write("WARNING: initialize_triggers_for_federate macro pattern not found; link may fail.\n")
p.write_text(patched)
PY

# Register it with the Python federate's CMakeLists (idempotent: only append
# once even if the script is re-run).
CMAKE="$FED_CI_DIR/CMakeLists.txt"
if ! grep -q 'federation_preamble.c' "$CMAKE"; then
    cat >> "$CMAKE" <<'EOF'

# Federation preamble providing symbols the C runtime needs but the Python
# target code generator does not emit. Sourced from the matching CCpp stub
# by build_carla_federate.sh.
target_sources(LinguaFrancafederate__ci PRIVATE
    ${CMAKE_CURRENT_LIST_DIR}/federation_preamble.c)
EOF
fi

# Rebuild just the C extension with the preamble linked in. cmake writes the
# .so directly to $FED_CI_DIR/LinguaFrancafederate__ci.so (next to federate__ci.py).
echo "Rebuilding C extension with preamble..."
cmake --build "$FED_CI_DIR/build" --target LinguaFrancafederate__ci --parallel 4

echo ""
echo "=== Build complete ==="
echo "  Output: $FED_CI_DIR/"
echo ""
echo "To run the full stack:"
echo "  1. Start CARLA:             cd ~/carla-0.9.16 && ./CarlaUE4.sh"
echo "  2. Start ROS infrastructure: bash run_infrastructure.sh"
echo "  3. Start the federation:    bash lf-src/run_federation.sh"
echo "  4. Engage:                  bash engage.sh"
