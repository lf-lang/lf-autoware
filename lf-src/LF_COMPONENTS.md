# LF Components — Currently Running

These 20 LF components replace vanilla Autoware's planning+control pipeline.
Each runs as a standalone LF program, communicating via ROS topics.

## Planning (11)

| # | Component | Description |
|---|-----------|-------------|
| 1 | mission_planner | Route planning from goals |
| 2 | behavior_path_planner | Behavior planning (lane change, avoidance) |
| 3 | behavior_velocity_planner | Velocity profiles for behaviors |
| 4 | path_smoother | Elastic band path smoothing |
| 5 | path_optimizer | Path optimization |
| 6 | motion_velocity_planner | Velocity with obstacle avoidance |
| 7 | surround_obstacle_checker | Checks obstacles around vehicle |
| 8 | scenario_selector | Selects lane driving vs parking |
| 9 | velocity_smoother | Final trajectory velocity smoothing |
| 10 | planning_validator | Validates trajectory safety |
| 11 | external_velocity_limit_selector | Selects velocity limits |

## Control (8)

| # | Component | Description |
|---|-----------|-------------|
| 12 | trajectory_follower | Lateral MPC + longitudinal PID |
| 13 | shift_decider | Gear selection |
| 14 | vehicle_cmd_gate | Command safety gate |
| 15 | operation_mode_transition_manager | Manages op mode transitions |
| 16 | lane_departure_checker | Checks lane departure risk |
| 17 | control_validator | Validates control outputs |
| 18 | autonomous_emergency_braking | AEB system |
| 19 | collision_detector | Detects potential collisions |

## Bridge (1)

| # | Component | Description |
|---|-----------|-------------|
| 20 | bridge_interface | Publishes control commands to ROS for CARLA |

## How to Test

```bash
# Terminal 1: CARLA
cd ~/carla-0.9.16 && ./CarlaUE4.sh -prefernvidia -quality-level=Low

# Terminal 2: Autoware (sensing/localization/perception + RViz)
bash ~/Documents/projects/parking-demo/lf-autoware/test_phase1_carla_no_planning.sh

# Terminal 3: LF planning+control
bash ~/Documents/projects/parking-demo/lf-autoware/lf-src/test_lf_planning_control.sh

# Terminal 4: Engage
bash ~/Documents/projects/parking-demo/lf-autoware/engage.sh
# Then set goal via RViz 2D Goal Pose button
```
