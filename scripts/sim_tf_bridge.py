#!/usr/bin/env python3
"""
Matrix Simulation TF Bridge — 仿真环境的 TF + LaserScan 桥接节点

仿真环境与实机的关键差异：
  - 实机: lightning-lm 发布 map→odom TF, livox_driver 发布 CustomMsg
  - 仿真: MuJoCo 发布 /odom/mujoco_odom (真值里程计), 传感器发布标准 PointCloud2

本节点完成以下桥接：
  1. TF 树: map→odom (identity) + odom→base_link (从 mujoco odom) + base_link→livox_frame (identity)
  2. frame_id 映射: 仿真 "lidar" → 导航期望 "livox_frame"
  3. PointCloud2 → LaserScan 转换 (Nav2 局部 costmap 需要)
  4. /odom/current_pose 发布 (navigo 兼容)

Usage:
  source /opt/ros/humble/setup.bash
  python3 sim_tf_bridge.py
  # 或通过 launch 文件
  ros2 launch ... sim_tf_bridge

Author: Claude Code (for Matrix simulation)
"""

import math
import struct

import rclpy
from rclpy.node import Node
from rclpy.qos import QoSProfile, ReliabilityPolicy, DurabilityPolicy
from tf2_ros import TransformBroadcaster, StaticTransformBroadcaster
from geometry_msgs.msg import TransformStamped
from nav_msgs.msg import Odometry
from sensor_msgs.msg import PointCloud2, LaserScan


class SimTfBridge(Node):
    """仿真环境 TF 桥接节点。

    订阅 MuJoCo 真值里程计，发布完整 TF 树和 LaserScan。

    TF 树结构:
        map → odom (identity, 真值里程计无漂移)
            odom → base_link (MuJoCo 里程计位姿)
                base_link → livox_frame (identity, 雷达在机器人中心)

    话题桥接:
        /odom/mujoco_odom → TF + /odom/current_pose
        /livox/lidar (PointCloud2, frame_id="lidar") → /laser_scan (frame_id="livox_frame")
    """

    def __init__(self):
        super().__init__('sim_tf_bridge')

        # -- Parameters --
        self.declare_parameter('odom_topic', '/odom/mujoco_odom')
        self.declare_parameter('lidar_topic', '/livox/lidar')
        self.declare_parameter('odom_output_topic', '/odom/current_pose')
        self.declare_parameter('laserscan_topic', '/laser_scan')
        self.declare_parameter('enable_laserscan', True)

        # LaserScan parameters
        self.declare_parameter('min_height', -0.3)
        self.declare_parameter('max_height', 0.8)
        self.declare_parameter('angle_min', -3.14159)
        self.declare_parameter('angle_max', 3.14159)
        self.declare_parameter('angle_increment', 0.0087)  # ~0.5°
        self.declare_parameter('range_min', 0.3)
        self.declare_parameter('range_max', 30.0)

        odom_topic = self.get_parameter('odom_topic').value
        lidar_topic = self.get_parameter('lidar_topic').value
        odom_output = self.get_parameter('odom_output_topic').value
        laserscan_topic = self.get_parameter('laserscan_topic').value
        self.enable_laserscan = self.get_parameter('enable_laserscan').value

        self.min_height = self.get_parameter('min_height').value
        self.max_height = self.get_parameter('max_height').value
        self.angle_min = self.get_parameter('angle_min').value
        self.angle_max = self.get_parameter('angle_max').value
        self.angle_increment = self.get_parameter('angle_increment').value
        self.range_min = self.get_parameter('range_min').value
        self.range_max = self.get_parameter('range_max').value

        self.num_ranges = int(
            (self.angle_max - self.angle_min) / self.angle_increment
        ) + 1

        # -- QoS: match simulation's BEST_EFFORT --
        qos_be = QoSProfile(
            reliability=ReliabilityPolicy.BEST_EFFORT,
            durability=DurabilityPolicy.VOLATILE,
            depth=10,
        )

        # -- Broadcasters --
        self.tf_broadcaster = TransformBroadcaster(self)
        self.static_tf_broadcaster = StaticTransformBroadcaster(self)

        # Publish all static TFs in one call (multiple calls overwrite)
        self._publish_all_static_tfs()

        # -- Subscribers --
        self.odom_sub = self.create_subscription(
            Odometry, odom_topic, self.odom_callback, qos_be
        )

        # -- Publishers --
        self.odom_pub = self.create_publisher(Odometry, odom_output, 10)

        if self.enable_laserscan:
            self.lidar_sub = self.create_subscription(
                PointCloud2, lidar_topic, self.lidar_callback, qos_be
            )
            self.scan_pub = self.create_publisher(LaserScan, laserscan_topic, qos_be)
            self.get_logger().info(
                f'LaserScan: {lidar_topic} → {laserscan_topic} '
                f'(h=[{self.min_height},{self.max_height}], '
                f'r=[{self.range_min},{self.range_max}])'
            )

        # -- State --
        self.odom_count = 0
        self.scan_count = 0

        # Watchdog
        self.create_timer(5.0, self.watchdog)

        self.get_logger().info(
            f'SimTfBridge started: {odom_topic} → TF + {odom_output}'
        )

    def _publish_all_static_tfs(self):
        """Publish all static TFs in a single call.

        StaticTransformBroadcaster overwrites on each sendTransform call,
        so we must send all static transforms together.
        """
        stamp = self.get_clock().now().to_msg()
        transforms = []

        # map → odom (identity, 真值里程计无漂移)
        t_map = TransformStamped()
        t_map.header.stamp = stamp
        t_map.header.frame_id = 'map'
        t_map.child_frame_id = 'odom'
        t_map.transform.rotation.w = 1.0
        transforms.append(t_map)

        # base_link → livox_frame (identity, 导航系统期望的 frame)
        t_livox = TransformStamped()
        t_livox.header.stamp = stamp
        t_livox.header.frame_id = 'base_link'
        t_livox.child_frame_id = 'livox_frame'
        t_livox.transform.rotation.w = 1.0
        transforms.append(t_livox)

        # base_link → lidar (identity, 仿真器使用的 frame_id)
        t_lidar = TransformStamped()
        t_lidar.header.stamp = stamp
        t_lidar.header.frame_id = 'base_link'
        t_lidar.child_frame_id = 'lidar'
        t_lidar.transform.rotation.w = 1.0
        transforms.append(t_lidar)

        self.static_tf_broadcaster.sendTransform(transforms)
        self.get_logger().info(
            'Static TFs: map→odom, base_link→livox_frame, '
            'base_link→lidar (all identity)'
        )

    def odom_callback(self, msg: Odometry):
        """从 MuJoCo 里程计发布 odom→base_link TF + /odom/current_pose"""
        self.odom_count += 1

        # -- TF: odom → base_link --
        t = TransformStamped()
        t.header.stamp = msg.header.stamp
        t.header.frame_id = 'odom'
        t.child_frame_id = 'base_link'
        t.transform.translation.x = msg.pose.pose.position.x
        t.transform.translation.y = msg.pose.pose.position.y
        t.transform.translation.z = msg.pose.pose.position.z
        t.transform.rotation = msg.pose.pose.orientation
        self.tf_broadcaster.sendTransform(t)

        # -- Republish as /odom/current_pose (navigo 兼容) --
        odom_out = Odometry()
        odom_out.header.stamp = msg.header.stamp
        odom_out.header.frame_id = 'odom'
        odom_out.child_frame_id = 'base_link'
        odom_out.pose = msg.pose
        odom_out.twist = msg.twist
        self.odom_pub.publish(odom_out)

    def lidar_callback(self, msg: PointCloud2):
        """PointCloud2 → LaserScan 转换"""
        self.scan_count += 1

        # Parse field offsets
        x_off = y_off = z_off = -1
        for f in msg.fields:
            if f.name == 'x':
                x_off = f.offset
            elif f.name == 'y':
                y_off = f.offset
            elif f.name == 'z':
                z_off = f.offset

        if x_off < 0 or y_off < 0 or z_off < 0:
            self.get_logger().warn('PointCloud2 missing x/y/z fields', once=True)
            return

        step = msg.point_step
        data = msg.data
        n_points = msg.width * msg.height

        # Initialize ranges
        ranges = [float('inf')] * self.num_ranges

        for i in range(n_points):
            off = i * step
            x = struct.unpack_from('f', data, off + x_off)[0]
            y = struct.unpack_from('f', data, off + y_off)[0]
            z = struct.unpack_from('f', data, off + z_off)[0]

            if math.isnan(x) or math.isnan(y) or math.isnan(z):
                continue
            if z < self.min_height or z > self.max_height:
                continue

            r = math.sqrt(x * x + y * y)
            if r < self.range_min or r > self.range_max:
                continue

            angle = math.atan2(y, x)
            if angle < self.angle_min or angle > self.angle_max:
                continue

            idx = int((angle - self.angle_min) / self.angle_increment)
            if 0 <= idx < self.num_ranges and r < ranges[idx]:
                ranges[idx] = r

        scan = LaserScan()
        scan.header.stamp = msg.header.stamp
        scan.header.frame_id = 'livox_frame'  # 统一 frame_id
        scan.angle_min = self.angle_min
        scan.angle_max = self.angle_max
        scan.angle_increment = self.angle_increment
        scan.time_increment = 0.0
        scan.scan_time = 0.1
        scan.range_min = self.range_min
        scan.range_max = self.range_max
        scan.ranges = ranges
        self.scan_pub.publish(scan)

    def watchdog(self):
        if self.odom_count == 0:
            self.get_logger().warn(
                'No odometry received yet. Is the simulation running?',
                throttle_duration_sec=10.0,
            )
        elif self.odom_count % 2000 == 0:
            self.get_logger().info(
                f'Stats: odom={self.odom_count}, scans={self.scan_count}'
            )


def main(args=None):
    rclpy.init(args=args)
    node = SimTfBridge()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        if rclpy.ok():
            rclpy.shutdown()


if __name__ == '__main__':
    main()
