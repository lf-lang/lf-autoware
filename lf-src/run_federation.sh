#!/bin/bash -l
# Launcher for federated AutowareFederated.lf
set -m
shopt -s huponexit

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

BIN_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "#### Launching RTI"
"$BIN_DIR/RTI" -i ${FEDERATION_ID} -n 46 &
RTI=$!
sleep 2

echo "#### Launching federate__aeb"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__aeb" -i $FEDERATION_ID &
pids[0]=$!
echo "#### Launching federate__bpp"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__bpp" -i $FEDERATION_ID &
pids[1]=$!
echo "#### Launching federate__bridge"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__bridge" -i $FEDERATION_ID &
pids[2]=$!
echo "#### Launching federate__bvp"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__bvp" -i $FEDERATION_ID &
pids[3]=$!
echo "#### Launching federate__cbf"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__cbf" -i $FEDERATION_ID &
pids[4]=$!
echo "#### Launching federate__cd"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__cd" -i $FEDERATION_ID &
pids[5]=$!
echo "#### Launching federate__cg"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__cg" -i $FEDERATION_ID &
pids[6]=$!
echo "#### Launching federate__clf"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__clf" -i $FEDERATION_ID &
pids[7]=$!
echo "#### Launching federate__ctle"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__ctle" -i $FEDERATION_ID &
pids[8]=$!
echo "#### Launching federate__cv"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__cv" -i $FEDERATION_ID &
pids[9]=$!
echo "#### Launching federate__dbt"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__dbt" -i $FEDERATION_ID &
pids[10]=$!
echo "#### Launching federate__ec"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__ec" -i $FEDERATION_ID &
pids[11]=$!
echo "#### Launching federate__ekf"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__ekf" -i $FEDERATION_ID &
pids[12]=$!
echo "#### Launching federate__evls"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__evls" -i $FEDERATION_ID &
pids[13]=$!
echo "#### Launching federate__fp"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__fp" -i $FEDERATION_ID &
pids[14]=$!
echo "#### Launching federate__gs"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__gs" -i $FEDERATION_ID &
pids[15]=$!
echo "#### Launching federate__gyro"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__gyro" -i $FEDERATION_ID &
pids[16]=$!
echo "#### Launching federate__imu"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__imu" -i $FEDERATION_ID &
pids[17]=$!
echo "#### Launching federate__l2m"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__l2m" -i $FEDERATION_ID &
pids[18]=$!
echo "#### Launching federate__lcp"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__lcp" -i $FEDERATION_ID &
pids[19]=$!
echo "#### Launching federate__ldc"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__ldc" -i $FEDERATION_ID &
pids[20]=$!
echo "#### Launching federate__mbp"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__mbp" -i $FEDERATION_ID &
pids[21]=$!
echo "#### Launching federate__mot"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__mot" -i $FEDERATION_ID &
pids[22]=$!
echo "#### Launching federate__mp"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__mp" -i $FEDERATION_ID &
pids[23]=$!
echo "#### Launching federate__mvp"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__mvp" -i $FEDERATION_ID &
pids[24]=$!
echo "#### Launching federate__ndt"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__ndt" -i $FEDERATION_ID &
pids[25]=$!
echo "#### Launching federate__of"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__of" -i $FEDERATION_ID &
pids[26]=$!
echo "#### Launching federate__ogm"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__ogm" -i $FEDERATION_ID &
pids[27]=$!
echo "#### Launching federate__omtm"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__omtm" -i $FEDERATION_ID &
pids[28]=$!
echo "#### Launching federate__ov"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__ov" -i $FEDERATION_ID &
pids[29]=$!
echo "#### Launching federate__pcm"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__pcm" -i $FEDERATION_ID &
pids[30]=$!
echo "#### Launching federate__pmf"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__pmf" -i $FEDERATION_ID &
pids[31]=$!
echo "#### Launching federate__po"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__po" -i $FEDERATION_ID &
pids[32]=$!
echo "#### Launching federate__ps"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__ps" -i $FEDERATION_ID &
pids[33]=$!
echo "#### Launching federate__pv"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__pv" -i $FEDERATION_ID &
pids[34]=$!
echo "#### Launching federate__sd"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__sd" -i $FEDERATION_ID &
pids[35]=$!
echo "#### Launching federate__soc"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__soc" -i $FEDERATION_ID &
pids[36]=$!
echo "#### Launching federate__ss"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__ss" -i $FEDERATION_ID &
pids[37]=$!
echo "#### Launching federate__tf"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__tf" -i $FEDERATION_ID &
pids[38]=$!
echo "#### Launching federate__tla"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__tla" -i $FEDERATION_ID &
pids[39]=$!
echo "#### Launching federate__tlc"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__tlc" -i $FEDERATION_ID &
pids[40]=$!
echo "#### Launching federate__tlmbd"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__tlmbd" -i $FEDERATION_ID &
pids[41]=$!
echo "#### Launching federate__tlop"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__tlop" -i $FEDERATION_ID &
pids[42]=$!
echo "#### Launching federate__vcg"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__vcg" -i $FEDERATION_ID &
pids[43]=$!
echo "#### Launching federate__vs"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__vs" -i $FEDERATION_ID &
pids[44]=$!
echo "#### Launching federate__vvc"
"/home/shaokai/Documents/projects/parking-demo/lf-autoware/lf-src/fed-gen/AutowareFederated/bin/federate__vvc" -i $FEDERATION_ID &
pids[45]=$!

echo "#### All 46 federates launched. Bringing RTI to foreground."
fg %1
echo "RTI exited. Waiting for federates..."
for pid in "${pids[@]}"; do
    wait $pid 2>/dev/null
done
echo "All done."
