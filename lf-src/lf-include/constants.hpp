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

const std::string BEHAVIOR_PATH_PLANNER_PARAM_DIR =
    LAUNCHER_CONFIG_PATH + "/planning/scenario_planning/lane_driving/behavior_planning/behavior_path_planner";
const std::string BEHAVIOR_PATH_PLANNER_PARAM =
    BEHAVIOR_PATH_PLANNER_PARAM_DIR + "/behavior_path_planner.param.yaml";
const std::string BEHAVIOR_PATH_PLANNER_DRIVABLE_AREA_PARAM =
    BEHAVIOR_PATH_PLANNER_PARAM_DIR + "/drivable_area_expansion.param.yaml";
const std::string BEHAVIOR_PATH_PLANNER_SCENE_MANAGER_PARAM =
    BEHAVIOR_PATH_PLANNER_PARAM_DIR + "/scene_module_manager.param.yaml";

const std::string MISSION_PLANNER_PARAM =
    LAUNCHER_CONFIG_PATH + "/planning/mission_planning/mission_planner/mission_planner.param.yaml";

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

// Map parameter paths
const std::string POINTCLOUD_MAP_LOADER_PARAM =
    LAUNCHER_CONFIG_PATH + "/map/pointcloud_map_loader.param.yaml";

const std::string LANELET2_MAP_LOADER_PARAM =
    LAUNCHER_CONFIG_PATH + "/map/lanelet2_map_loader.param.yaml";

#endif // LF_AUTOWARE_CONSTANTS_HPP
