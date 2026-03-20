"""
CarlaBridge: step-based CARLA interface for LF synchronous execution.

Wraps CARLA connection, ego vehicle, sensors, and ROS publishing into
a simple initialize() / step() / cleanup() API that the LF reactor calls.

Reuses autoware_carla_interface modules for sensor data conversion and
ROS topic publishing.
"""

import math
import os
import random
import threading

import carla
import numpy
import rclpy
from rclpy.node import Node

from builtin_interfaces.msg import Time
from rosgraph_msgs.msg import Clock

# Reuse autoware_carla_interface modules for sensor data -> ROS conversion.
from autoware_carla_interface.carla_ros import carla_ros2_interface
from autoware_carla_interface.modules.carla_data_provider import CarlaDataProvider, GameTime
from autoware_carla_interface.modules.carla_wrapper import SensorWrapper


class CarlaBridge:
    """Step-based CARLA bridge for deterministic LF-driven simulation."""

    def __init__(self, config):
        self.config = config
        self.world = None
        self.ego_actor = None
        self.interface = None
        self.sensor_wrapper = None
        self.current_control = carla.VehicleControl()
        self.frame_count = 0

    def initialize(self):
        """Connect to CARLA, set synchronous mode, spawn ego + sensors, init ROS."""
        # 1. Initialize the ROS interface (creates ROS node, publishers, subscribers)
        self.interface = carla_ros2_interface()

        # Override params with our config
        for key, value in self.config.items():
            self.interface.param_values[key] = value

        # 2. Connect to CARLA and load world
        client = carla.Client(self.config["host"], self.config["port"])
        client.set_timeout(self.config["timeout"])
        client.load_world(self.config["carla_map"])
        self.world = client.get_world()

        # 3. Set synchronous mode with fixed timestep
        settings = self.world.get_settings()
        settings.fixed_delta_seconds = self.config["fixed_delta_seconds"]
        settings.synchronous_mode = True
        self.world.apply_settings(settings)

        CarlaDataProvider.set_world(self.world)
        CarlaDataProvider.set_client(client)

        # 4. Spawn ego vehicle
        spawn_point = self._parse_spawn_point(self.config["spawn_point"])
        self.ego_actor = CarlaDataProvider.request_new_actor(
            self.config["vehicle_type"],
            spawn_point,
            self.config["ego_vehicle_role_name"],
            random_location=(self.config["spawn_point"] == "None"),
        )
        self.interface.ego_actor = self.ego_actor
        self.interface.physics_control = self.ego_actor.get_physics_control()

        # 5. Setup sensors
        self.sensor_wrapper = SensorWrapper(self.interface)
        self.sensor_wrapper.setup_sensors(self.ego_actor, False)

        # 6. Optional traffic manager
        if self.config.get("use_traffic_manager", False):
            self._setup_traffic_manager(client)

        # 7. Initial tick to activate sensors
        self.world.tick()

        print(f"[CarlaBridge] Initialized: map={self.config['carla_map']}, "
              f"vehicle={self.config['vehicle_type']}, "
              f"dt={self.config['fixed_delta_seconds']}s")

    def step(self):
        """Advance CARLA by one tick, collect sensor data, publish to ROS.

        This is the core method called by the LF reactor on each logical step.
        Returns sensor data dictionary.
        """
        # 1. Apply current control to ego vehicle
        self.ego_actor.apply_control(self.current_control)

        # 2. Tick the world — this is the key synchronous step
        self.world.tick()
        self.frame_count += 1

        # 3. Get timestamp
        snapshot = self.world.get_snapshot()
        timestamp = snapshot.timestamp

        # Update game time
        GameTime.on_carla_tick(timestamp)
        CarlaDataProvider.on_carla_tick()

        # 4. Collect sensor data from the sensor interface
        input_data = self.interface.sensor_interface.get_data()

        # 5. Run the ROS publishing step (publishes all sensor data + vehicle status)
        control = self.interface.run_step(input_data, timestamp.elapsed_seconds)
        self.current_control = control

        return input_data

    def apply_control(self, control_override):
        """Override the current control command (from Autoware via LF port)."""
        if control_override is not None:
            self.current_control = control_override

    def cleanup(self):
        """Clean up all CARLA and ROS resources."""
        print("[CarlaBridge] Cleaning up...")

        if self.sensor_wrapper:
            try:
                self.sensor_wrapper.cleanup()
            except Exception as e:
                print(f"Warning: Sensor cleanup failed: {e}")

        if self.interface:
            try:
                self.interface.shutdown()
            except Exception as e:
                print(f"Warning: ROS interface shutdown failed: {e}")

        if self.ego_actor:
            try:
                self.ego_actor.destroy()
            except Exception as e:
                print(f"Warning: Ego actor destruction failed: {e}")

        try:
            CarlaDataProvider.cleanup()
        except Exception as e:
            print(f"Warning: CARLA data provider cleanup failed: {e}")

        print("[CarlaBridge] Cleanup complete.")

    def _parse_spawn_point(self, spawn_str):
        """Parse spawn point string into carla.Transform."""
        spawn_point = carla.Transform()
        if spawn_str and spawn_str != "None":
            items = spawn_str.split(",")
            if len(items) == 6:
                spawn_point.location.x = float(items[0])
                spawn_point.location.y = float(items[1])
                spawn_point.location.z = float(items[2]) + 2  # +2 to avoid ground clip
                spawn_point.rotation.roll = float(items[3])
                spawn_point.rotation.pitch = float(items[4])
                spawn_point.rotation.yaw = float(items[5])
        return spawn_point

    def _setup_traffic_manager(self, client):
        """Set up CARLA traffic manager with NPC vehicles."""
        traffic_manager = client.get_trafficmanager()
        traffic_manager.set_synchronous_mode(True)
        traffic_manager.set_random_device_seed(0)
        random.seed(0)

        spawn_points = self.world.get_map().get_spawn_points()
        models = [
            "dodge", "audi", "model3", "mini", "mustang",
            "lincoln", "prius", "nissan", "crown", "impala",
        ]
        blueprints = [
            v for v in self.world.get_blueprint_library().filter("*vehicle*")
            if any(m in v.id for m in models)
        ]

        max_vehicles = min(30, len(spawn_points))
        for spawn_point in random.sample(spawn_points, max_vehicles):
            vehicle = self.world.try_spawn_actor(random.choice(blueprints), spawn_point)
            if vehicle is not None:
                vehicle.set_autopilot(True)
