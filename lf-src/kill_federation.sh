#!/usr/bin/env bash
# Kill every process spawned by lf-src/run_federation.sh:
#   - the RTI                        ($BIN_DIR/RTI)
#   - all CCpp federates             ($BIN_DIR/federate__*)
#   - the Python CARLA federate      (python3 -m federate__ci)
#
# Patterns use absolute-path fragments so they never match grep/pkill itself.
#
# Usage:
#   bash lf-src/kill_federation.sh           # SIGTERM, then SIGKILL stragglers
#   bash lf-src/kill_federation.sh --force   # SIGKILL immediately
#   bash lf-src/kill_federation.sh --dry-run # show what would be killed
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
            sed -n '2,15p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *) echo "unknown flag: $1" >&2; exit 2 ;;
    esac
done

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="$REPO/fed-gen/AutowareFederated/bin"

# One regex covers all three process classes.
PATTERN="${BIN_DIR}/(federate__|RTI)|python3 -m federate__ci"

list_matches() {
    pgrep -af "$PATTERN" 2>/dev/null
}

alive_count() {
    pgrep -f "$PATTERN" 2>/dev/null | wc -l
}

before=$(list_matches)
count=$(alive_count)

if [ "$count" -eq 0 ]; then
    echo "No federation processes found."
    exit 0
fi

echo "Found $count federation process(es):"
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
    # Give them up to 3s to clean up sockets / flush logs.
    for _ in 1 2 3; do
        [ "$(alive_count)" -eq 0 ] && break
        sleep 1
    done
    remaining=$(alive_count)
    if [ "$remaining" -gt 0 ]; then
        echo "$remaining straggler(s) after SIGTERM; sending SIGKILL..."
        pkill -9 -f "$PATTERN"
        sleep 1
    fi
fi

# Final check
remaining=$(alive_count)
if [ "$remaining" -eq 0 ]; then
    echo "All federation processes terminated."
    exit 0
else
    echo "WARNING: $remaining process(es) still alive:"
    list_matches
    exit 1
fi
