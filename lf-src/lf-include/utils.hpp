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

#ifndef LF_AUTOWARE_UTILS_HPP
#define LF_AUTOWARE_UTILS_HPP

#include "rclcpp/parameter_map.hpp"
#include "rcl_yaml_param_parser/parser.h"
#include <string>
#include <cstdlib>
#include <vector>
#include <fstream>
#include <sstream>

extern "C" {
    #include "logging/api/logging.h"
}

inline std::string _rewrite_yaml_as_global(const char* path, const char* root_name) {
    std::string root(root_name);
    if (root == "/**") { return std::string(path); }

    std::ifstream in(path);
    if (!in.is_open()) { return std::string(path); }

    rcl_params_t* params = rcl_yaml_node_struct_init(rcl_get_default_allocator());
    bool out = rcl_parse_yaml_file(path, params);
    if (!out) {
        rcl_yaml_node_struct_fini(params);
        return std::string(path);
    }

    auto options = rclcpp::parameter_map_from(params);
    for (const auto& option : options) {
        if (option.first == root) {
            static int counter = 0;
            std::string tmp_path = "/tmp/lf_params_" + std::to_string(getpid()) + "_" +
                                   std::to_string(counter++) + ".yaml";
            std::ofstream tmp(tmp_path);
            tmp << "/**:" << std::endl;
            tmp << "  ros__parameters:" << std::endl;
            for (const auto& p : option.second) {
                switch (p.get_type()) {
                    case rclcpp::ParameterType::PARAMETER_BOOL:
                        tmp << "    " << p.get_name() << ": "
                            << (p.as_bool() ? "true" : "false") << std::endl;
                        break;
                    case rclcpp::ParameterType::PARAMETER_INTEGER:
                        tmp << "    " << p.get_name() << ": " << p.as_int() << std::endl;
                        break;
                    case rclcpp::ParameterType::PARAMETER_DOUBLE:
                        tmp << "    " << p.get_name() << ": " << p.as_double() << std::endl;
                        break;
                    case rclcpp::ParameterType::PARAMETER_STRING:
                        tmp << "    " << p.get_name() << ": \"" << p.as_string() << "\""
                            << std::endl;
                        break;
                    default:
                        break;
                }
            }
            tmp.close();
            rcl_yaml_node_struct_fini(params);
            return tmp_path;
        }
    }
    rcl_yaml_node_struct_fini(params);
    return std::string(path);
}

inline rclcpp::NodeOptions get_node_options_from_yaml(const char* path, const char* root_name) {
    try { rclcpp::init(0, NULL); } catch (...) { }
    rclcpp::NodeOptions nodeOptions;
    rcl_params_t* params = rcl_yaml_node_struct_init(rcl_get_default_allocator());
    bool out = rcl_parse_yaml_file(path, params);
    if (!out) {
        lf_print_error_and_exit("Failed to load the yaml file: %s", path);
    }
    auto options = rclcpp::parameter_map_from(params);
    for (auto option : options) {
        if (option.first == root_name) {
            nodeOptions.parameter_overrides() = option.second;
        }
    }
    rcl_yaml_node_struct_fini(params);
    std::string params_file = _rewrite_yaml_as_global(path, root_name);
    nodeOptions.arguments({"--ros-args", "--params-file", params_file});
    return nodeOptions;
}

inline rclcpp::NodeOptions get_node_options_from_yaml(
    const char* path, const char* root_name, int argc, char *argv[])
{
    try { rclcpp::init(argc, argv); } catch (...) { }
    rclcpp::NodeOptions nodeOptions;
    rcl_params_t* params = rcl_yaml_node_struct_init(rcl_get_default_allocator());
    bool out = rcl_parse_yaml_file(path, params);
    if (!out) {
        lf_print_error_and_exit("Failed to load the yaml file: %s", path);
    }
    auto options = rclcpp::parameter_map_from(params);
    for (const auto& option : options) {
        if (option.first == root_name) {
            nodeOptions.parameter_overrides() = option.second;
        }
    }
    rcl_yaml_node_struct_fini(params);
    std::string params_file = _rewrite_yaml_as_global(path, root_name);
    nodeOptions.arguments({"--ros-args", "--params-file", params_file});
    return nodeOptions;
}

inline rclcpp::NodeOptions get_node_options_from_yamls(
    const std::vector<std::pair<std::string, std::string>>& yaml_configs)
{
    try { rclcpp::init(0, NULL); } catch (...) { }
    rclcpp::NodeOptions nodeOptions;
    std::vector<std::string> args = {"--ros-args"};

    for (const auto& [path, root_name] : yaml_configs) {
        rcl_params_t* params = rcl_yaml_node_struct_init(rcl_get_default_allocator());
        bool out = rcl_parse_yaml_file(path.c_str(), params);
        if (!out) {
            lf_print_warning("Failed to load yaml file: %s", path.c_str());
            rcl_yaml_node_struct_fini(params);
            continue;
        }
        auto options = rclcpp::parameter_map_from(params);
        for (const auto& option : options) {
            if (option.first == root_name) {
                auto& overrides = nodeOptions.parameter_overrides();
                overrides.insert(overrides.end(), option.second.begin(), option.second.end());
            }
        }
        rcl_yaml_node_struct_fini(params);
        std::string params_file = _rewrite_yaml_as_global(path.c_str(), root_name.c_str());
        args.push_back("--params-file");
        args.push_back(params_file);
    }

    nodeOptions.arguments(args);
    return nodeOptions;
}

inline std::string get_lf_autoware_home() {
    const char* home = std::getenv("LF_AUTOWARE_HOME");
    if (!home) {
        lf_print_error_and_exit("ERROR: Environment variable $LF_AUTOWARE_HOME is not declared.");
    }
    return std::string(home);
}

template <typename T>
void* spin_node(void* args) {
    auto node_shared_ptr_ptr = static_cast<T*>(args);
    auto node_shared_ptr = *node_shared_ptr_ptr;
    while (rclcpp::ok()) {
        rclcpp::spin_some(node_shared_ptr);
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }
    delete node_shared_ptr_ptr;
    return 0;
}

template <typename T>
void* spin_node_with_executor(void* args) {
    auto node_shared_ptr_ptr = static_cast<T*>(args);
    auto node_shared_ptr = *node_shared_ptr_ptr;
    rclcpp::executors::SingleThreadedExecutor executor;
    executor.add_node(node_shared_ptr);
    while (rclcpp::ok()) {
        executor.spin_some(std::chrono::milliseconds(1));
    }
    delete node_shared_ptr_ptr;
    return 0;
}

/**
 * Replace $(var ...) launch substitutions in a YAML file, write
 * a resolved temp copy and return its path.
 */
inline std::string resolve_yaml_vars(
    const std::string& yaml_path,
    const std::vector<std::pair<std::string, std::string>>& replacements)
{
    std::ifstream in(yaml_path);
    if (!in.is_open()) {
        lf_print_error_and_exit("resolve_yaml_vars: cannot open %s", yaml_path.c_str());
    }
    std::ostringstream buf;
    buf << in.rdbuf();
    std::string content = buf.str();

    for (const auto& [pattern, value] : replacements) {
        std::string::size_type pos = 0;
        while ((pos = content.find(pattern, pos)) != std::string::npos) {
            content.replace(pos, pattern.size(), value);
            pos += value.size();
        }
    }

    static int counter = 0;
    std::string tmp_path = "/tmp/lf_resolved_" + std::to_string(getpid()) + "_" +
                           std::to_string(counter++) + ".yaml";
    std::ofstream out(tmp_path);
    out << content;
    out.close();
    return tmp_path;
}

#endif // LF_AUTOWARE_UTILS_HPP
