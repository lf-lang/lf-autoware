# LF-Autoware Porting Status

Status of porting Autoware ROS 2 nodes to Lingua Franca (LF) reactors.
Each LF reactor runs as a standalone federate in `AutowareFederated.lf`.

## Ported to LF (46 nodes)

### Sensing (3)
| Node | Description |
|------|-------------|
| `crop_box_filter` | Filters ego vehicle body from pointcloud |
| `imu_corrector` | Processes raw IMU data |
| `vehicle_velocity_converter` | Converts velocity status to twist |

### Localization (3)
| Node | Description |
|------|-------------|
| `ndt_scan_matcher` | NDT-based pose estimation |
| `gyro_odometer` | Twist estimation from IMU/gyro |
| `ekf_localizer` | EKF fusion of pose + twist |

### Map (2)
| Node | Description |
|------|-------------|
| `pointcloud_map_loader` | Loads PCD pointcloud map |
| `lanelet2_map_loader` | Loads lanelet2 OSM map |

### Perception (16)
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

## Not Ported (8 nodes)

### CARLA Interface (2)
| Node | Description | Reason |
|------|-------------|--------|
| `autoware_carla_interface` | Connects to CARLA, publishes sensor data | Future: replace with LF reactor using CARLA Python API |
| `raw_vehicle_cmd_converter` | Converts control commands to CARLA actuator format | Same as above |

### Sensing (1)
| Node | Description | Reason |
|------|-------------|--------|
| `crop_box_filter_mirror` | Filters mirrors from pointcloud | Only self-filter variant ported |

### Map (1)
| Node | Description | Reason |
|------|-------------|--------|
| `map_projection_loader` | Loads map projection info | Not yet ported |

### Localization (3)
| Node | Description | Reason |
|------|-------------|--------|
| `pointcloud_downsampling` | Voxel grid downsample for NDT input | Not yet ported |
| `pose_initializer` | Initial pose setup | Not yet ported |
| `automatic_pose_initializer` | Auto-init from GNSS | Not yet ported |

### Perception (1)
| Node | Description | Reason |
|------|-------------|--------|
| `traffic_light_fine_detector` | Refines traffic light detection | Not yet ported |

## Out of Scope (stay as ROS 2 or omit)

| Node(s) | Reason |
|---------|--------|
| `rviz2` | Visualization/debug tool |
| `robot_state_publisher` | TF from URDF — infrastructure |
| image_transport relay/republish | Utilities |
| `diagnostic_aggregator`, `system_monitor` | System monitoring |
| `mrm_handler`, `mrm_emergency_stop_operator` | Minimal Risk Maneuver |
| Map visualization, map hash generator | Visualization/infra |
| Evaluator/analytics nodes | Analytics |
| API nodes | External interfaces |

## Architecture

- **Federated:** each reactor compiles as a standalone executable
- **Decentralized coordination:** no central RTI
- **ROS 2 serialization:** inter-node communication via ROS topics
- **Federation definition:** `lf-src/AutowareFederated.lf`

## Testing

```bash
# Full stack (all 46 LF nodes)
bash lf-src/test_lf_full_stack.sh

# Hybrid (LF planning+control, ROS sensing/localization/perception)
bash test_phase1_carla_no_planning.sh   # ROS nodes + RViz
bash lf-src/test_lf_planning_control.sh # LF nodes
bash engage.sh                          # Engage autonomy
```
