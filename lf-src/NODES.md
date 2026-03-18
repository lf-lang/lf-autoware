# LF-Autoware Full Stack Node Inventory

Nodes to port from vanilla Autoware (CARLA Town01 config) to Lingua Franca.
Strategy: lf-avp-demo pattern (one reaction per callback, LF ports for inter-node data).

## CARLA Interface (2)
- [ ] `autoware_carla_interface` — connects to CARLA, publishes sensor data, receives commands. Replace with LF reactor using CARLA Python API + synchronous `world.tick()`.
- [ ] `raw_vehicle_cmd_converter` — converts control commands to CARLA actuator format

## Sensing (4)
- [ ] `crop_box_filter_self` — filters ego vehicle body from pointcloud
- [ ] `crop_box_filter_mirror` — filters mirrors from pointcloud
- [ ] `imu_corrector` — processes raw IMU data
- [ ] `vehicle_velocity_converter` — converts velocity status to twist

## Map (3)
- [ ] `pointcloud_map_loader` — loads PCD pointcloud map
- [ ] `lanelet2_map_loader` — loads lanelet2 OSM map
- [ ] `map_projection_loader` — loads map projection info

## Localization (6)
- [ ] `pointcloud_downsampling` — voxel grid downsample for NDT input
- [ ] `ndt_scan_matcher` — NDT-based pose estimation
- [ ] `gyro_odometer` — twist estimation from IMU/gyro
- [ ] `pose_twist_fusion_filter` — EKF fusion of pose + twist
- [ ] `pose_initializer` — initial pose setup
- [ ] `automatic_pose_initializer` — auto-init from GNSS

## Perception (~20)
- [ ] `ground_segmentation` — separates ground from obstacle points
- [ ] `probabilistic_occupancy_grid_map` — occupancy grid representation
- [ ] `lidar_centerpoint` — DNN 3D object detection
- [ ] `euclidean_cluster` — rule-based point clustering
- [ ] `pointcloud_map_filter` — map-based point filtering
- [ ] `detection_by_tracker` — tracker-assisted detection
- [ ] `object_validator` — validates detected objects
- [ ] `object_filter` — lanelet-based object filtering
- [ ] `camera_lidar_fusion` — fuses camera + LiDAR detections
- [ ] `multi_object_tracker` — tracks objects across frames
- [ ] `map_based_prediction` — predicts object trajectories using map
- [ ] `traffic_light_map_based_detector` — detects relevant traffic lights from map
- [ ] `traffic_light_fine_detector` — refines traffic light detection
- [ ] `traffic_light_classifier` — classifies traffic light state
- [ ] `traffic_light_arbiter` — arbitrates multiple traffic light sources
- [ ] `traffic_light_occlusion_predictor` — predicts traffic light occlusion
- [ ] `crosswalk_traffic_light_estimator` — estimates crosswalk traffic light

## Planning (~15)
- [ ] `mission_planner` — route planning from goals
- [ ] `behavior_path_planner` — behavior planning (lane change, avoidance)
- [ ] `behavior_velocity_planner` — velocity profiles for behaviors
- [ ] `path_smoother` — elastic band path smoothing
- [ ] `path_optimizer` — path optimization
- [ ] `motion_velocity_planner` — velocity with obstacle avoidance
- [ ] `surround_obstacle_checker` — checks obstacles around vehicle
- [ ] `scenario_selector` — selects lane driving vs parking
- [ ] `velocity_smoother` — final trajectory velocity smoothing
- [ ] `costmap_generator` — costmaps for parking
- [ ] `freespace_planner` — parking trajectory planning
- [ ] `planning_validator` — validates trajectory safety
- [ ] `external_velocity_limit_selector` — selects velocity limits

## Control (~8)
- [ ] `trajectory_follower` — lateral MPC + longitudinal PID
- [ ] `shift_decider` — gear selection
- [ ] `vehicle_cmd_gate` — command safety gate
- [ ] `operation_mode_transition_manager` — manages op mode transitions
- [ ] `lane_departure_checker` — checks lane departure risk
- [ ] `control_validator` — validates control outputs
- [ ] `autonomous_emergency_braking` — AEB system
- [ ] `collision_detector` — detects potential collisions

## Out of Scope (infra/debug, stay as ROS or omit)
- `rviz2` — visualization
- `robot_state_publisher` — TF from URDF
- image transport relay/republish nodes
- diagnostic/monitoring nodes
- `mrm_handler`, `mrm_emergency_stop_operator`
- map visualization, map hash generator
- evaluator/analytics nodes
- API nodes
