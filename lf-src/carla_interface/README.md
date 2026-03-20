# CARLA Interface — LF Synchronous Federate

Replaces `autoware_carla_interface` + `raw_vehicle_cmd_converter` with an LF reactor
where **LF logical time drives CARLA simulation stepping** (`world.tick()`).

## Architecture

```
AutowareFederated.lf (CCpp, decentralized)
├── 59 CCpp federates (sensing, localization, perception, planning, control, ...)
├── carla_interface CCpp stub (placeholder for lfc code generation)
└── CarlaInterface.lf (Python, built separately, swapped in at runtime)
        ├── Carla reactor: world.tick() per LF step, publishes sensor data via ROS
        └── ControlBridge reactor: reads /control/command/actuation_cmd from ROS
```

Mixed-target trick: LF doesn't natively support mixed Python+CCpp federations,
but since both targets use the C runtime and the same wire protocol, a separately
compiled Python federate can join a CCpp federation.

## Files

| File | Purpose |
|------|---------|
| `carla_interface_main.lf` | CCpp stub for federation code generation |
| `CarlaInterface.lf` | Real Python implementation |
| `carla_bridge.py` | CARLA client + ROS publisher logic |
| `build_carla_federate.sh` | Compiles the Python federate |
| `run_carla_federate.sh` | Runs the Python federate |

## Usage

```bash
# 1. Build the federation (generates CCpp stub federate)
cd $LF_AUTOWARE_HOME
lfc lf-src/AutowareFederated.lf

# 2. Build the Python CARLA federate separately
bash lf-src/carla_interface/build_carla_federate.sh

# 3. Start CARLA simulator
cd ~/carla-0.9.16 && ./CarlaUE4.sh -prefernvidia -quality-level=Low

# 4. Start all CCpp federates (skip the stub carla_interface)
bash lf-src/test_lf_full_stack.sh

# 5. Start the Python CARLA federate
bash lf-src/carla_interface/run_carla_federate.sh
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CARLA_HOST` | `localhost` | CARLA server host |
| `CARLA_PORT` | `2000` | CARLA server port |
| `CARLA_MAP` | `Town01` | Map to load |
| `CARLA_FIXED_DELTA` | `0.05` | Timestep (seconds) |
| `CARLA_VEHICLE_TYPE` | `vehicle.toyota.prius` | Ego vehicle blueprint |
| `CARLA_SPAWN_POINT` | random | `x,y,z,roll,pitch,yaw` |
| `CARLA_USE_TM` | `False` | Enable NPC traffic |
