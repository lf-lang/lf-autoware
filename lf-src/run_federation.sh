#!/bin/bash
# Launcher for federated AutowareFederated.lf (72 federates: 70 CCpp + 1 Python CARLA)
set -m
shopt -s huponexit

# Clean conda from environment to avoid numpy/library conflicts
unset CONDA_EXE CONDA_PREFIX CONDA_PROMPT_MODIFIER CONDA_SHLVL CONDA_PYTHON_EXE CONDA_DEFAULT_ENV _CE_CONDA
export PATH=$(echo $PATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')
export PYTHONPATH=$(echo $PYTHONPATH | tr ':' '\n' | grep -v conda | tr '\n' ':' | sed 's/:$//')

cleanup() {
    printf "Killing federates: %s\n" "${pids[*]}"
    kill ${pids[@]} 2>/dev/null || true
    printf "Killing RTI %s\n" "${RTI}"
    kill ${RTI} 2>/dev/null || true
    exit 1
}
trap 'cleanup; exit' EXIT

FEDERATION_ID=$(openssl rand -hex 24)
echo "Federation ID: $FEDERATION_ID"

# Source ROS and Autoware
source /opt/ros/humble/setup.bash
source /home/shaokai/Documents/projects/parking-demo/lf-autoware/install/setup.bash 2>/dev/null
export LF_AUTOWARE_HOME=/home/shaokai/Documents/projects/parking-demo/lf-autoware
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export CUDA_VISIBLE_DEVICES=1

BIN_DIR="$LF_AUTOWARE_HOME/fed-gen/AutowareFederated/bin"
CARLA_FED_DIR="$LF_AUTOWARE_HOME/src-gen/lf-src/carla_interface/federate__ci"

echo "#### Launching RTI"
"$BIN_DIR/RTI" -i ${FEDERATION_ID} -n 71 &
RTI=$!
sleep 2

i=0

# 73 CCpp federates (IDs 0-72)
for fed in cbf imu vvc rdf ptf vgof adf idec \
           ndt gyro ekf lem pid sf \
           pcm l2m \
           gs lcp ec pmf dbt ov of clf mot mbp ogm tlmbd tlc tla tlop ctle \
           tls tlcm som ors ogmof \
           mp bpp bvp ps po mvp soc ss vs fp cg pv evls pg psa \
           tf sd vcg omtm ldc cv aeb cd occ ppc ecs \
           bridge \
           mcso hsc dnc ptc plm csm; do
    echo "#### Launching federate__${fed}"
    if [ "$fed" = "lcp" ]; then
        # lidar_centerpoint needs GPU 0 (RTX 3070) for TensorRT
        CUDA_VISIBLE_DEVICES=0 "$BIN_DIR/federate__${fed}" -i $FEDERATION_ID &
    else
        "$BIN_DIR/federate__${fed}" -i $FEDERATION_ID &
    fi
    pids[$i]=$!
    i=$((i+1))
    sleep 0.1  # Stagger launches to avoid RTI accept() overload
done

# Python CARLA federate (ID 73)
echo "#### Launching federate__ci (Python CARLA interface)"
(cd "$CARLA_FED_DIR" && python3 -m federate__ci -i $FEDERATION_ID) &
pids[$i]=$!

echo "#### All 72 federates launched (70 CCpp + 1 Python). Bringing RTI to foreground."
fg %1
echo "RTI exited. Waiting for federates..."
for pid in "${pids[@]}"; do
    wait $pid 2>/dev/null
done
echo "All done."
