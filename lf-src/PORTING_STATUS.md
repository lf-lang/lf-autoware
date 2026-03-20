# LF-Autoware Porting Status

Status of porting Autoware ROS 2 nodes to Lingua Franca (LF) reactors.
Each LF reactor runs as a standalone federate in `AutowareFederated.lf`.

## Ported to LF (59 nodes)

### Sensing (4)
| Node | Description |
|------|-------------|
| `crop_box_filter` | Filters ego vehicle body from pointcloud |
| `crop_box_filter_mirror` | Filters mirrors from pointcloud |
| `imu_corrector` | Processes raw IMU data |
| `vehicle_velocity_converter` | Converts velocity status to twist |

### Localization (6)
| Node | Description |
|------|-------------|
| `ndt_scan_matcher` | NDT-based pose estimation |
| `pointcloud_downsampling` | Voxel grid downsample for NDT input |
| `gyro_odometer` | Twist estimation from IMU/gyro |
| `ekf_localizer` | EKF fusion of pose + twist |
| `pose_initializer` | Initial pose setup via service |
| `automatic_pose_initializer` | Auto-init from GNSS |

### Map (3)
| Node | Description |
|------|-------------|
| `pointcloud_map_loader` | Loads PCD pointcloud map |
| `lanelet2_map_loader` | Loads lanelet2 OSM map |
| `map_projection_loader` | Loads map projection info |

### Perception (17)
| Node | Description |
|------|-------------|
| `ground_segmentation` | Separates ground from obstacle points |
| `lidar_centerpoint` | DNN 3D object detection |
| `euclidean_cluster` | Rule-based point clustering |
| `pointcloud_map_filter` | Map-based point filtering |
| `detection_by_tracker` | Tracker-assisted detection |
| `object_validator` | Validates detected objects |
| `object_filter` | Lanelet-based object filtering |
| `camera_lidar_fusion` | Fuses camera + LiDAR detections |
| `multi_object_tracker` | Tracks objects across frames |
| `map_based_prediction` | Predicts object trajectories using map |
| `occupancy_grid_map` | Occupancy grid representation |
| `traffic_light_map_based_detector` | Detects relevant traffic lights from map |
| `traffic_light_fine_detector` | Refines traffic light detection (CUDA) |
| `traffic_light_classifier` | Classifies traffic light state |
| `traffic_light_arbiter` | Arbitrates multiple traffic light sources |
| `traffic_light_occlusion_predictor` | Predicts traffic light occlusion |
| `crosswalk_traffic_light_estimator` | Estimates crosswalk traffic light state |

### Planning (13)
| Node | Description |
|------|-------------|
| `mission_planner` | Route planning from goals |
| `behavior_path_planner` | Behavior planning (lane change, avoidance) |
| `behavior_velocity_planner` | Velocity profiles for behaviors |
| `path_smoother` | Elastic band path smoothing |
| `path_optimizer` | Path optimization |
| `motion_velocity_planner` | Velocity with obstacle avoidance |
| `surround_obstacle_checker` | Checks obstacles around vehicle |
| `scenario_selector` | Selects lane driving vs parking |
| `velocity_smoother` | Final trajectory velocity smoothing |
| `costmap_generator` | Costmaps for parking |
| `freespace_planner` | Parking trajectory planning |
| `planning_validator` | Validates trajectory safety |
| `external_velocity_limit_selector` | Selects velocity limits |

### Control (8)
| Node | Description |
|------|-------------|
| `trajectory_follower` | Lateral MPC + longitudinal PID |
| `shift_decider` | Gear selection |
| `vehicle_cmd_gate` | Command safety gate |
| `operation_mode_transition_manager` | Manages op mode transitions |
| `lane_departure_checker` | Checks lane departure risk |
| `control_validator` | Validates control outputs |
| `autonomous_emergency_braking` | AEB system |
| `collision_detector` | Detects potential collisions |

### Bridge (1)
| Node | Description |
|------|-------------|
| `bridge_interface` | Publishes control commands to ROS for CARLA |

### Vehicle (2)
| Node | Description |
|------|-------------|
| `robot_state_publisher` | Publishes TF transforms from URDF |
| `image_transport_relay` | Relays camera info/image topics |

### System (5)
| Node | Description |
|------|-------------|
| `mrm_handler` | Monitors state, triggers MRM behaviors |
| `mrm_emergency_stop_operator` | Generates emergency stop control commands |
| `diagnostic_aggregator` | Aggregates diagnostics into graph |
| `system_monitor` | CPU/memory/net/GPU/HDD/NTP/process/voltage monitors |
| `default_adapi` | AD API nodes (state, motion, routing, etc.) |

## Not Ported (2 nodes)

### CARLA Interface (2)
| Node | Description | Reason |
|------|-------------|--------|
| `autoware_carla_interface` | Connects to CARLA, publishes sensor data | Future: replace with LF reactor using CARLA Python API |
| `raw_vehicle_cmd_converter` | Converts control commands to CARLA actuator format | Same as above |

## Out of Scope (stay as ROS 2 or omit)

| Node(s) | Reason |
|---------|--------|
| `rviz2` | Visualization/debug tool — standalone GUI |
| Map visualization, map hash generator | Visualization helpers — not in driving loop |
| Evaluator/analytics nodes | Offline analysis — not in driving loop |

## Architecture

- **Federated:** each reactor compiles as a standalone executable
- **Decentralized coordination:** no central RTI
- **ROS 2 serialization:** inter-node communication via ROS topics
- **Federation definition:** `lf-src/AutowareFederated.lf`
- **Multi-node reactors:** `system_monitor` (8 monitors), `default_adapi` (15 API nodes) run multiple ROS nodes in a single federate via MultiThreadedExecutor

## Testing

```bash
# Full stack (all LF nodes)
bash lf-src/test_lf_full_stack.sh

# Hybrid (LF planning+control, ROS sensing/localization/perception)
bash test_phase1_carla_no_planning.sh   # ROS nodes + RViz
bash lf-src/test_lf_planning_control.sh # LF nodes
bash engage.sh                          # Engage autonomy
```
