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

#endif // LF_AUTOWARE_CONSTANTS_HPP
