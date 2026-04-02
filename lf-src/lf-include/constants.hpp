// Copyright 2024 The LF Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef LF_AUTOWARE_CONSTANTS_HPP
#define LF_AUTOWARE_CONSTANTS_HPP

#include <string>

// Base path for launcher config (relative to LF_AUTOWARE_HOME)
const std::string LAUNCHER_CONFIG_PATH =
    "src/launcher/autoware_launch/autoware_launch/config";

// Default map directory (resolved from $HOME/autoware_map/Town01)
inline std::string get_default_map_path() {
    const char* h = std::getenv("HOME");
    return std::string(h ? h : "/root") + "/autoware_map/Town01";
}

// Default data directory (resolved from $HOME/autoware_data)
inline std::string get_default_data_path() {
    const char* h = std::getenv("HOME");
    return std::string(h ? h : "/root") + "/autoware_data";
}

// Perception: lidar_centerpoint ml_package and class_remapper configs (in data dir)
const std::string LIDAR_CENTERPOINT_ML_PACKAGE_PARAM =
    "lidar_centerpoint/centerpoint_tiny_ml_package.param.yaml";
const std::string LIDAR_CENTERPOINT_CLASS_REMAPPER_PARAM =
    "lidar_centerpoint/detection_class_remapper.param.yaml";

// Planning parameter paths
const std::string VELOCITY_SMOOTHER_PARAM_DIR =
    LAUNCHER_CONFIG_PATH + "/planning/scenario_planning/common/autoware_velocity_smoother";
const std::string VELOCITY_SMOOTHER_PARAM =
    VELOCITY_SMOOTHER_PARAM_DIR + "/velocity_smoother.param.yaml";
const std::string VELOCITY_SMOOTHER_ALGORITHM_PARAM =
    VELOCITY_SMOOTHER_PARAM_DIR + "/Analytical.param.yaml";
const std::string VELOCITY_SMOOTHER_COMMON_PARAM =
    "src/core/autoware_core/planning/autoware_velocity_smoother/config/default_common.param.yaml";

// Common planning parameters
const std::string PLANNING_COMMON_PARAM =
    LAUNCHER_CONFIG_PATH + "/planning/scenario_planning/common/common.param.yaml";
const std::string PLANNING_NEAREST_SEARCH_PARAM =
    LAUNCHER_CONFIG_PATH + "/planning/scenario_planning/common/nearest_search.param.yaml";

// Control common parameters
const std::string CONTROL_NEAREST_SEARCH_PARAM =
    LAUNCHER_CONFIG_PATH + "/control/common/nearest_search.param.yaml";

const std::string BEHAVIOR_PATH_PLANNER_PARAM_DIR =
    LAUNCHER_CONFIG_PATH + "/planning/scenario_planning/lane_driving/behavior_planning/behavior_path_planner";
const std::string BEHAVIOR_PATH_PLANNER_PARAM =
    BEHAVIOR_PATH_PLANNER_PARAM_DIR + "/behavior_path_planner.param.yaml";
const std::string BEHAVIOR_PATH_PLANNER_DRIVABLE_AREA_PARAM =
    BEHAVIOR_PATH_PLANNER_PARAM_DIR + "/drivable_area_expansion.param.yaml";
const std::string BEHAVIOR_PATH_PLANNER_SCENE_MANAGER_PARAM =
    BEHAVIOR_PATH_PLANNER_PARAM_DIR + "/scene_module_manager.param.yaml";
const std::string BEHAVIOR_PATH_PLANNER_SIDE_SHIFT_PARAM =
    BEHAVIOR_PATH_PLANNER_PARAM_DIR + "/side_shift/side_shift.param.yaml";
const std::string BEHAVIOR_PATH_PLANNER_AVOIDANCE_PARAM =
    BEHAVIOR_PATH_PLANNER_PARAM_DIR + "/autoware_behavior_path_static_obstacle_avoidance_module/static_obstacle_avoidance.param.yaml";
const std::string BEHAVIOR_PATH_PLANNER_AVOIDANCE_BY_LC_PARAM =
    BEHAVIOR_PATH_PLANNER_PARAM_DIR + "/avoidance_by_lane_change/avoidance_by_lane_change.param.yaml";
const std::string BEHAVIOR_PATH_PLANNER_DYNAMIC_AVOIDANCE_PARAM =
    BEHAVIOR_PATH_PLANNER_PARAM_DIR + "/autoware_behavior_path_dynamic_obstacle_avoidance_module/dynamic_obstacle_avoidance.param.yaml";
const std::string BEHAVIOR_PATH_PLANNER_LANE_CHANGE_PARAM =
    BEHAVIOR_PATH_PLANNER_PARAM_DIR + "/lane_change/lane_change.param.yaml";
const std::string BEHAVIOR_PATH_PLANNER_GOAL_PLANNER_PARAM =
    BEHAVIOR_PATH_PLANNER_PARAM_DIR + "/goal_planner/goal_planner.param.yaml";
const std::string BEHAVIOR_PATH_PLANNER_START_PLANNER_PARAM =
    BEHAVIOR_PATH_PLANNER_PARAM_DIR + "/start_planner/start_planner.param.yaml";
const std::string BEHAVIOR_PATH_PLANNER_BIDIRECTIONAL_TRAFFIC_PARAM =
    BEHAVIOR_PATH_PLANNER_PARAM_DIR + "/autoware_behavior_path_bidirectional_traffic_module/bidirectional_traffic.param.yaml";
const std::string BEHAVIOR_PATH_PLANNER_SAMPLING_PARAM =
    BEHAVIOR_PATH_PLANNER_PARAM_DIR + "/sampling_planner/sampling_planner.param.yaml";

const std::string MISSION_PLANNER_PARAM =
    LAUNCHER_CONFIG_PATH + "/planning/mission_planning/mission_planner/mission_planner.param.yaml";
const std::string MISSION_PLANNER_DEFAULT_PARAM =
    "src/core/autoware_core/planning/autoware_mission_planner/config/mission_planner.param.yaml";

const std::string FREESPACE_PLANNER_PARAM =
    LAUNCHER_CONFIG_PATH + "/planning/scenario_planning/parking/freespace_planner/freespace_planner.param.yaml";

// Control parameter paths
const std::string TRAJECTORY_FOLLOWER_PARAM_DIR =
    LAUNCHER_CONFIG_PATH + "/control/trajectory_follower";
const std::string TRAJECTORY_FOLLOWER_PARAM =
    TRAJECTORY_FOLLOWER_PARAM_DIR + "/trajectory_follower_node.param.yaml";
const std::string MPC_LATERAL_PARAM =
    TRAJECTORY_FOLLOWER_PARAM_DIR + "/lateral/mpc.param.yaml";
const std::string PID_LONGITUDINAL_PARAM =
    TRAJECTORY_FOLLOWER_PARAM_DIR + "/longitudinal/pid.param.yaml";

const std::string VEHICLE_CMD_GATE_PARAM =
    LAUNCHER_CONFIG_PATH + "/control/vehicle_cmd_gate/vehicle_cmd_gate.param.yaml";

const std::string SHIFT_DECIDER_PARAM =
    LAUNCHER_CONFIG_PATH + "/control/shift_decider/shift_decider.param.yaml";

// Vehicle info
const std::string VEHICLE_INFO_PARAM =
    "src/launcher/autoware_launch/vehicle/awsim_labs_vehicle_launch/"
    "awsim_labs_vehicle_description/config/vehicle_info.param.yaml";

// Scenario selector (universe default, no launcher override)
const std::string SCENARIO_SELECTOR_PARAM =
    "src/universe/autoware_universe/planning/autoware_scenario_selector/config/"
    "scenario_selector.param.yaml";

// Costmap generator
const std::string COSTMAP_GENERATOR_PARAM =
    "src/universe/autoware_universe/planning/autoware_costmap_generator/config/"
    "costmap_generator.param.yaml";

// Sensing parameter paths
const std::string IMU_CORRECTOR_PARAM =
    "src/universe/autoware_universe/sensing/autoware_imu_corrector/config/"
    "imu_corrector.param.yaml";

const std::string VEHICLE_VELOCITY_CONVERTER_PARAM =
    "src/core/autoware_core/sensing/autoware_vehicle_velocity_converter/config/"
    "vehicle_velocity_converter.param.yaml";

const std::string MIRROR_PARAM =
    "src/launcher/autoware_launch/sensor_kit/carla_sensor_kit_launch/"
    "carla_sensor_kit_launch/config/mirror.param.yaml";

// Localization parameter paths
const std::string NDT_SCAN_MATCHER_PARAM =
    LAUNCHER_CONFIG_PATH + "/localization/ndt_scan_matcher/ndt_scan_matcher.param.yaml";

const std::string GYRO_ODOMETER_PARAM =
    "src/core/autoware_core/localization/autoware_gyro_odometer/config/"
    "gyro_odometer.param.yaml";

const std::string EKF_LOCALIZER_PARAM =
    LAUNCHER_CONFIG_PATH + "/localization/ekf_localizer.param.yaml";

// Behavior velocity planner parameter paths
const std::string BEHAVIOR_VELOCITY_PLANNER_PARAM_DIR =
    LAUNCHER_CONFIG_PATH + "/planning/scenario_planning/lane_driving/behavior_planning/behavior_velocity_planner";
const std::string BEHAVIOR_VELOCITY_PLANNER_PARAM =
    BEHAVIOR_VELOCITY_PLANNER_PARAM_DIR + "/behavior_velocity_planner.param.yaml";
const std::string BEHAVIOR_VELOCITY_PLANNER_COMMON_PARAM =
    BEHAVIOR_VELOCITY_PLANNER_PARAM_DIR + "/behavior_velocity_planner_common.param.yaml";
const std::string BEHAVIOR_VELOCITY_PLANNER_BLIND_SPOT_PARAM =
    BEHAVIOR_VELOCITY_PLANNER_PARAM_DIR + "/blind_spot.param.yaml";
const std::string BEHAVIOR_VELOCITY_PLANNER_CROSSWALK_PARAM =
    BEHAVIOR_VELOCITY_PLANNER_PARAM_DIR + "/crosswalk.param.yaml";
const std::string BEHAVIOR_VELOCITY_PLANNER_WALKWAY_PARAM =
    BEHAVIOR_VELOCITY_PLANNER_PARAM_DIR + "/walkway.param.yaml";
const std::string BEHAVIOR_VELOCITY_PLANNER_DETECTION_AREA_PARAM =
    BEHAVIOR_VELOCITY_PLANNER_PARAM_DIR + "/detection_area.param.yaml";
const std::string BEHAVIOR_VELOCITY_PLANNER_INTERSECTION_PARAM =
    BEHAVIOR_VELOCITY_PLANNER_PARAM_DIR + "/intersection.param.yaml";
const std::string BEHAVIOR_VELOCITY_PLANNER_ROUNDABOUT_PARAM =
    BEHAVIOR_VELOCITY_PLANNER_PARAM_DIR + "/roundabout.param.yaml";
const std::string BEHAVIOR_VELOCITY_PLANNER_STOP_LINE_PARAM =
    BEHAVIOR_VELOCITY_PLANNER_PARAM_DIR + "/stop_line.param.yaml";
const std::string BEHAVIOR_VELOCITY_PLANNER_TRAFFIC_LIGHT_PARAM =
    BEHAVIOR_VELOCITY_PLANNER_PARAM_DIR + "/traffic_light.param.yaml";
const std::string BEHAVIOR_VELOCITY_PLANNER_VIRTUAL_TRAFFIC_LIGHT_PARAM =
    BEHAVIOR_VELOCITY_PLANNER_PARAM_DIR + "/virtual_traffic_light.param.yaml";
const std::string BEHAVIOR_VELOCITY_PLANNER_OCCLUSION_SPOT_PARAM =
    BEHAVIOR_VELOCITY_PLANNER_PARAM_DIR + "/occlusion_spot.param.yaml";
const std::string BEHAVIOR_VELOCITY_PLANNER_NO_STOPPING_AREA_PARAM =
    BEHAVIOR_VELOCITY_PLANNER_PARAM_DIR + "/no_stopping_area.param.yaml";
const std::string BEHAVIOR_VELOCITY_PLANNER_SPEED_BUMP_PARAM =
    BEHAVIOR_VELOCITY_PLANNER_PARAM_DIR + "/speed_bump.param.yaml";
const std::string BEHAVIOR_VELOCITY_PLANNER_NO_DRIVABLE_LANE_PARAM =
    BEHAVIOR_VELOCITY_PLANNER_PARAM_DIR + "/no_drivable_lane.param.yaml";

// Path smoother parameter path
const std::string PATH_SMOOTHER_PARAM =
    LAUNCHER_CONFIG_PATH + "/planning/scenario_planning/lane_driving/motion_planning/path_smoother/elastic_band_smoother.param.yaml";

// Path optimizer parameter path
const std::string PATH_OPTIMIZER_PARAM =
    LAUNCHER_CONFIG_PATH + "/planning/scenario_planning/lane_driving/motion_planning/autoware_path_optimizer/path_optimizer.param.yaml";

// Motion velocity planner parameter paths
const std::string MOTION_VELOCITY_PLANNER_PARAM_DIR =
    LAUNCHER_CONFIG_PATH + "/planning/scenario_planning/lane_driving/motion_planning/motion_velocity_planner";
const std::string MOTION_VELOCITY_PLANNER_PARAM =
    MOTION_VELOCITY_PLANNER_PARAM_DIR + "/motion_velocity_planner.param.yaml";
const std::string MOTION_VELOCITY_PLANNER_OBSTACLE_STOP_PARAM =
    MOTION_VELOCITY_PLANNER_PARAM_DIR + "/obstacle_stop.param.yaml";
const std::string MOTION_VELOCITY_PLANNER_OBSTACLE_SLOW_DOWN_PARAM =
    MOTION_VELOCITY_PLANNER_PARAM_DIR + "/obstacle_slow_down.param.yaml";
const std::string MOTION_VELOCITY_PLANNER_OBSTACLE_CRUISE_PARAM =
    MOTION_VELOCITY_PLANNER_PARAM_DIR + "/obstacle_cruise.param.yaml";
const std::string MOTION_VELOCITY_PLANNER_DYNAMIC_OBSTACLE_STOP_PARAM =
    MOTION_VELOCITY_PLANNER_PARAM_DIR + "/dynamic_obstacle_stop.param.yaml";
const std::string MOTION_VELOCITY_PLANNER_OUT_OF_LANE_PARAM =
    MOTION_VELOCITY_PLANNER_PARAM_DIR + "/out_of_lane.param.yaml";
const std::string MOTION_VELOCITY_PLANNER_OBSTACLE_VELOCITY_LIMITER_PARAM =
    MOTION_VELOCITY_PLANNER_PARAM_DIR + "/obstacle_velocity_limiter.param.yaml";
const std::string MOTION_VELOCITY_PLANNER_RUN_OUT_PARAM =
    MOTION_VELOCITY_PLANNER_PARAM_DIR + "/run_out.param.yaml";
const std::string MOTION_VELOCITY_PLANNER_BOUNDARY_DEPARTURE_PREVENTION_PARAM =
    MOTION_VELOCITY_PLANNER_PARAM_DIR + "/boundary_departure_prevention.param.yaml";
const std::string MOTION_VELOCITY_PLANNER_ROAD_USER_STOP_PARAM =
    MOTION_VELOCITY_PLANNER_PARAM_DIR + "/road_user_stop.param.yaml";

// Surround obstacle checker parameter path
const std::string SURROUND_OBSTACLE_CHECKER_PARAM =
    LAUNCHER_CONFIG_PATH + "/planning/scenario_planning/lane_driving/motion_planning/surround_obstacle_checker/surround_obstacle_checker.param.yaml";

// Planning validator parameter paths
const std::string PLANNING_VALIDATOR_PARAM_DIR =
    LAUNCHER_CONFIG_PATH + "/planning/scenario_planning/common/planning_validator";
const std::string PLANNING_VALIDATOR_PARAM =
    PLANNING_VALIDATOR_PARAM_DIR + "/planning_validator.param.yaml";
const std::string PLANNING_VALIDATOR_LATENCY_CHECKER_PARAM =
    PLANNING_VALIDATOR_PARAM_DIR + "/latency_checker.param.yaml";
const std::string PLANNING_VALIDATOR_TRAJECTORY_CHECKER_PARAM =
    PLANNING_VALIDATOR_PARAM_DIR + "/trajectory_checker.param.yaml";
const std::string PLANNING_VALIDATOR_INTERSECTION_COLLISION_CHECKER_PARAM =
    PLANNING_VALIDATOR_PARAM_DIR + "/intersection_collision_checker.param.yaml";
const std::string PLANNING_VALIDATOR_REAR_COLLISION_CHECKER_PARAM =
    PLANNING_VALIDATOR_PARAM_DIR + "/rear_collision_checker.param.yaml";

// External velocity limit selector parameter paths
const std::string EXTERNAL_VELOCITY_LIMIT_SELECTOR_COMMON_PARAM =
    "src/universe/autoware_universe/planning/autoware_external_velocity_limit_selector/config/default_common.param.yaml";
const std::string EXTERNAL_VELOCITY_LIMIT_SELECTOR_PARAM =
    "src/universe/autoware_universe/planning/autoware_external_velocity_limit_selector/config/default.param.yaml";

// Operation mode transition manager parameter path
const std::string OPERATION_MODE_TRANSITION_MANAGER_PARAM =
    LAUNCHER_CONFIG_PATH + "/control/operation_mode_transition_manager/operation_mode_transition_manager.param.yaml";

// Lane departure checker parameter path
const std::string LANE_DEPARTURE_CHECKER_PARAM =
    LAUNCHER_CONFIG_PATH + "/control/lane_departure_checker/lane_departure_checker.param.yaml";

// Control validator parameter path
const std::string CONTROL_VALIDATOR_PARAM =
    LAUNCHER_CONFIG_PATH + "/control/control_validator/control_validator.param.yaml";

// Autonomous emergency braking parameter path
const std::string AUTONOMOUS_EMERGENCY_BRAKING_PARAM =
    LAUNCHER_CONFIG_PATH + "/control/autoware_autonomous_emergency_braking/autonomous_emergency_braking.param.yaml";

// Collision detector parameter path
const std::string COLLISION_DETECTOR_PARAM =
    LAUNCHER_CONFIG_PATH + "/control/autoware_collision_detector/collision_detector.param.yaml";

// Map parameter paths
const std::string POINTCLOUD_MAP_LOADER_PARAM =
    LAUNCHER_CONFIG_PATH + "/map/pointcloud_map_loader.param.yaml";

const std::string LANELET2_MAP_LOADER_PARAM =
    LAUNCHER_CONFIG_PATH + "/map/lanelet2_map_loader.param.yaml";

// Sensing: crop_box_filter
const std::string CROP_BOX_FILTER_PARAM =
    "src/core/autoware_core/sensing/autoware_crop_box_filter/config/"
    "crop_box_filter_node.param.yaml";

// Perception: ground_segmentation (scan_ground_filter)
const std::string SCAN_GROUND_FILTER_PARAM =
    "src/universe/autoware_universe/perception/autoware_ground_segmentation/config/"
    "scan_ground_filter.param.yaml";

// Perception: lidar_centerpoint
const std::string LIDAR_CENTERPOINT_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/object_recognition/detection/lidar_model/centerpoint.param.yaml";
const std::string LIDAR_CENTERPOINT_COMMON_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/object_recognition/detection/lidar_model/centerpoint_common.param.yaml";

// Perception: euclidean_cluster
const std::string EUCLIDEAN_CLUSTER_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/object_recognition/detection/clustering/"
    "voxel_grid_based_euclidean_cluster.param.yaml";

// Perception: pointcloud_map_filter (compare_map)
const std::string COMPARE_MAP_FILTER_PARAM =
    "src/universe/autoware_universe/perception/autoware_compare_map_segmentation/config/"
    "voxel_based_approximate_compare_map_filter.param.yaml";

// Perception: detection_by_tracker
const std::string DETECTION_BY_TRACKER_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/object_recognition/detection/"
    "detection_by_tracker/detection_by_tracker.param.yaml";

// Perception: object_validator (obstacle_pointcloud_based_validator)
const std::string OBSTACLE_POINTCLOUD_VALIDATOR_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/object_recognition/detection/"
    "detected_object_validation/obstacle_pointcloud_based_validator.param.yaml";

// Perception: object_filter (object_lanelet_filter)
const std::string OBJECT_LANELET_FILTER_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/object_recognition/detection/"
    "object_filter/object_lanelet_filter.param.yaml";

// Perception: camera_lidar_fusion (roi_cluster_fusion)
const std::string ROI_CLUSTER_FUSION_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/object_recognition/detection/"
    "image_projection_based_fusion/roi_cluster_fusion.param.yaml";
const std::string FUSION_COMMON_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/object_recognition/detection/"
    "image_projection_based_fusion/fusion_common.param.yaml";

// Perception: multi_object_tracker
const std::string MULTI_OBJECT_TRACKER_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/object_recognition/tracking/"
    "multi_object_tracker/multi_object_tracker_node.param.yaml";
const std::string MULTI_OBJECT_TRACKER_DATA_ASSOCIATION_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/object_recognition/tracking/"
    "multi_object_tracker/data_association_matrix.param.yaml";
const std::string MULTI_OBJECT_TRACKER_INPUT_CHANNELS_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/object_recognition/tracking/"
    "multi_object_tracker/input_channels.param.yaml";

// Perception: map_based_prediction
const std::string MAP_BASED_PREDICTION_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/object_recognition/prediction/"
    "map_based_prediction.param.yaml";

// Perception: occupancy_grid_map
const std::string OCCUPANCY_GRID_MAP_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/occupancy_grid_map/"
    "pointcloud_based_occupancy_grid_map.param.yaml";
const std::string OCCUPANCY_GRID_MAP_UPDATER_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/occupancy_grid_map/"
    "binary_bayes_filter_updater.param.yaml";

// Perception: traffic_light_map_based_detector
const std::string TRAFFIC_LIGHT_MAP_BASED_DETECTOR_PARAM =
    "src/universe/autoware_universe/perception/autoware_traffic_light_map_based_detector/config/"
    "traffic_light_map_based_detector.param.yaml";

// Perception: traffic_light_classifier
const std::string TRAFFIC_LIGHT_CLASSIFIER_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/traffic_light_recognition/"
    "traffic_light_classifier/car_traffic_light_classifier.param.yaml";

// Perception: traffic_light_arbiter
const std::string TRAFFIC_LIGHT_ARBITER_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/traffic_light_recognition/"
    "traffic_light_arbiter/traffic_light_arbiter.param.yaml";

// Perception: traffic_light_occlusion_predictor
const std::string TRAFFIC_LIGHT_OCCLUSION_PREDICTOR_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/traffic_light_recognition/"
    "traffic_light_occlusion_predictor/traffic_light_occlusion_predictor.param.yaml";

// Perception: crosswalk_traffic_light_estimator
const std::string CROSSWALK_TRAFFIC_LIGHT_ESTIMATOR_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/traffic_light_recognition/"
    "crosswalk_traffic_light_estimator/crosswalk_traffic_light_estimator.param.yaml";

// Perception: traffic_light_fine_detector
const std::string TRAFFIC_LIGHT_FINE_DETECTOR_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/traffic_light_recognition/"
    "traffic_light_fine_detector/traffic_light_fine_detector.param.yaml";

// Map: map_projection_loader
const std::string MAP_PROJECTION_LOADER_PARAM =
    "src/core/autoware_core/map/autoware_map_projection_loader/config/"
    "map_projection_loader.param.yaml";

// Localization: pointcloud_downsampling (voxel grid filter)
const std::string POINTCLOUD_DOWNSAMPLING_PARAM =
    LAUNCHER_CONFIG_PATH + "/localization/ndt_scan_matcher/pointcloud_preprocessor/"
    "voxel_grid_filter.param.yaml";

// Localization: pose_initializer
const std::string POSE_INITIALIZER_PARAM =
    "src/core/autoware_core/localization/autoware_pose_initializer/config/"
    "pose_initializer.param.yaml";

// System: MRM handler
const std::string MRM_HANDLER_PARAM =
    LAUNCHER_CONFIG_PATH + "/system/mrm_handler/mrm_handler.param.yaml";

// System: MRM emergency stop operator
const std::string MRM_EMERGENCY_STOP_OPERATOR_PARAM =
    LAUNCHER_CONFIG_PATH + "/system/mrm_emergency_stop_operator/"
    "mrm_emergency_stop_operator.param.yaml";

// System: diagnostic_aggregator
const std::string DIAGNOSTIC_AGGREGATOR_PARAM =
    "src/universe/autoware_universe/system/autoware_diagnostic_graph_aggregator/config/"
    "default.param.yaml";
const std::string DIAGNOSTIC_AGGREGATOR_GRAPH_PARAM =
    LAUNCHER_CONFIG_PATH + "/system/diagnostics/autoware-main.yaml";

// System: system_monitor
const std::string SYSTEM_MONITOR_CPU_PARAM =
    LAUNCHER_CONFIG_PATH + "/system/system_monitor/cpu_monitor.param.yaml";
const std::string SYSTEM_MONITOR_GPU_PARAM =
    LAUNCHER_CONFIG_PATH + "/system/system_monitor/gpu_monitor.param.yaml";
const std::string SYSTEM_MONITOR_HDD_PARAM =
    LAUNCHER_CONFIG_PATH + "/system/system_monitor/hdd_monitor.param.yaml";
const std::string SYSTEM_MONITOR_MEM_PARAM =
    LAUNCHER_CONFIG_PATH + "/system/system_monitor/mem_monitor.param.yaml";
const std::string SYSTEM_MONITOR_NET_PARAM =
    LAUNCHER_CONFIG_PATH + "/system/system_monitor/net_monitor.param.yaml";
const std::string SYSTEM_MONITOR_NTP_PARAM =
    LAUNCHER_CONFIG_PATH + "/system/system_monitor/ntp_monitor.param.yaml";
const std::string SYSTEM_MONITOR_PROCESS_PARAM =
    LAUNCHER_CONFIG_PATH + "/system/system_monitor/process_monitor.param.yaml";
const std::string SYSTEM_MONITOR_VOLTAGE_PARAM =
    LAUNCHER_CONFIG_PATH + "/system/system_monitor/voltage_monitor.param.yaml";

// System: default ADAPI
const std::string DEFAULT_ADAPI_PARAM =
    "src/universe/autoware_universe/system/autoware_default_adapi_universe/config/"
    "default_adapi.param.yaml";

// Vehicle: robot_state_publisher URDF xacro path
const std::string VEHICLE_XACRO_PATH =
    "src/launcher/autoware_launch/vehicle/awsim_labs_vehicle_launch/"
    "awsim_labs_vehicle_description/urdf/vehicle.xacro";

// ===== NEW NODES (batch 2) =====

// Sensing: pointcloud preprocessor filters
const std::string RANDOM_DOWNSAMPLE_FILTER_PARAM =
    "src/universe/autoware_universe/sensing/autoware_pointcloud_preprocessor/config/"
    "random_downsample_filter_node.param.yaml";
const std::string PASSTHROUGH_FILTER_PARAM =
    "src/universe/autoware_universe/sensing/autoware_pointcloud_preprocessor/config/"
    "passthrough_filter_uint16_node.param.yaml";
const std::string VOXEL_GRID_OUTLIER_FILTER_PARAM =
    "src/universe/autoware_universe/sensing/autoware_pointcloud_preprocessor/config/"
    "voxel_grid_outlier_filter_node.param.yaml";
const std::string APPROXIMATE_DOWNSAMPLE_FILTER_PARAM =
    "src/universe/autoware_universe/sensing/autoware_pointcloud_preprocessor/config/"
    "approximate_downsample_filter_node.param.yaml";
const std::string POINTCLOUD_CONCATENATOR_PARAM =
    "src/universe/autoware_universe/sensing/autoware_pointcloud_preprocessor/config/"
    "concatenate_and_time_sync_node.param.yaml";

// Sensing: image decompressor
const std::string IMAGE_DECOMPRESSOR_PARAM =
    "src/universe/autoware_universe/sensing/autoware_image_transport_decompressor/config/"
    "image_transport_decompressor.param.yaml";

// Localization: error monitor, stop filter, pose instability detector
const std::string LOCALIZATION_ERROR_MONITOR_PARAM =
    LAUNCHER_CONFIG_PATH + "/localization/localization_error_monitor.param.yaml";
const std::string STOP_FILTER_PARAM =
    "src/core/autoware_core/localization/autoware_stop_filter/config/"
    "stop_filter.param.yaml";
const std::string POSE_INSTABILITY_DETECTOR_PARAM =
    "src/universe/autoware_universe/localization/autoware_pose_instability_detector/config/"
    "pose_instability_detector.param.yaml";

// Map: TF generator
const std::string MAP_TF_GENERATOR_PARAM =
    "src/universe/autoware_universe/map/autoware_map_tf_generator/config/"
    "map_tf_generator.param.yaml";

// Perception: object range splitter, simple object merger, OGM outlier filter
const std::string OBJECT_RANGE_SPLITTER_PARAM =
    "src/universe/autoware_universe/perception/autoware_object_range_splitter/config/"
    "object_range_splitter.param.yaml";
const std::string SIMPLE_OBJECT_MERGER_PARAM =
    "src/universe/autoware_universe/perception/autoware_simple_object_merger/config/"
    "simple_object_merger.param.yaml";
const std::string OCCUPANCY_GRID_MAP_OUTLIER_FILTER_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/obstacle_segmentation/"
    "occupancy_grid_based_outlier_filter/occupancy_grid_map_outlier_filter.param.yaml";

// Perception: tensorrt_yolox
const std::string TENSORRT_YOLOX_PARAM =
    LAUNCHER_CONFIG_PATH + "/perception/traffic_light_recognition/"
    "tensorrt_yolox/yolox_traffic_light_detector.param.yaml";

// Planning: path_generator, path_sampler
const std::string PATH_GENERATOR_PARAM =
    LAUNCHER_CONFIG_PATH + "/planning/scenario_planning/lane_driving/"
    "behavior_planning/path_generator/path_generator.param.yaml";
const std::string PATH_SAMPLER_PARAM =
    LAUNCHER_CONFIG_PATH + "/planning/scenario_planning/lane_driving/"
    "motion_planning/path_sampler/path_sampler.param.yaml";

// Control: obstacle_collision_checker, predicted_path_checker, external_cmd_selector
const std::string OBSTACLE_COLLISION_CHECKER_PARAM =
    LAUNCHER_CONFIG_PATH + "/control/obstacle_collision_checker/"
    "obstacle_collision_checker.param.yaml";
const std::string PREDICTED_PATH_CHECKER_PARAM =
    LAUNCHER_CONFIG_PATH + "/control/predicted_path_checker/"
    "predicted_path_checker.param.yaml";
const std::string EXTERNAL_CMD_SELECTOR_PARAM =
    LAUNCHER_CONFIG_PATH + "/control/external_cmd_selector/"
    "external_cmd_selector.param.yaml";

// System: mrm_comfortable_stop, hazard_status_converter, checkers/monitors
const std::string MRM_COMFORTABLE_STOP_OPERATOR_PARAM =
    LAUNCHER_CONFIG_PATH + "/system/mrm_comfortable_stop_operator/"
    "mrm_comfortable_stop_operator.param.yaml";
const std::string HAZARD_STATUS_CONVERTER_PARAM =
    "src/universe/autoware_universe/system/autoware_hazard_status_converter/config/"
    "hazard_status_converter.param.yaml";
const std::string DUPLICATED_NODE_CHECKER_PARAM =
    LAUNCHER_CONFIG_PATH + "/system/duplicated_node_checker/"
    "duplicated_node_checker.param.yaml";
const std::string PROCESSING_TIME_CHECKER_PARAM =
    LAUNCHER_CONFIG_PATH + "/system/processing_time_checker/"
    "processing_time_checker.param.yaml";
const std::string PIPELINE_LATENCY_MONITOR_PARAM =
    LAUNCHER_CONFIG_PATH + "/system/pipeline_latency_monitor/"
    "pipeline_latency_monitor.param.yaml";
const std::string COMPONENT_STATE_MONITOR_PARAM =
    LAUNCHER_CONFIG_PATH + "/system/component_state_monitor/topics.yaml";

#endif // LF_AUTOWARE_CONSTANTS_HPP
