"""
MuJoCo 仿真单层自主导航 Launch 文件

编排 3 个组件实现导航闭环 (MuJoCo + mc_ctrl 由 run_sim.sh 单独启动):
  1. sim_tf_bridge    — /odom/mujoco_odom → TF + /odom/current_pose + /laser_scan
  2. cmd_vel_to_zsibot — /cmd_vel → SDK.move() → mc_ctrl → MuJoCo
  3. navigo Nav2 stack — 路径规划 + MPPI 控制 + 行为恢复

前置条件:
  sudo ip addr add 192.168.234.1/32 dev lo
  cd src/zsibot/matrix/scripts && ./run_sim.sh 1 xgb

用法:
  source /opt/ros/humble/setup.bash && source install/setup.bash
  export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
  ros2 launch src/zsibot/matrix/launch/sim_nav.launch.py

  # 自定义地图路径:
  ros2 launch src/zsibot/matrix/launch/sim_nav.launch.py \
    map:=/absolute/path/to/map.yaml
"""

import os
import sys

from launch import LaunchDescription
from launch.actions import (
    DeclareLaunchArgument,
    ExecuteProcess,
    IncludeLaunchDescription,
    LogInfo,
    TimerAction,
)
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory


def generate_launch_description():
    # --- 路径解析 ---
    this_dir = os.path.dirname(os.path.abspath(__file__))
    matrix_dir = os.path.dirname(this_dir)  # src/zsibot/matrix
    ws_dir = os.path.dirname(os.path.dirname(os.path.dirname(matrix_dir)))  # locnav_ws

    default_map = os.path.join(ws_dir, 'data', 'new_map', 'map.yaml')
    sim_params = os.path.join(matrix_dir, 'config', 'sim_navigo_params.yaml')
    sim_tf_bridge_script = os.path.join(matrix_dir, 'scripts', 'sim_tf_bridge.py')

    navigo_dir = get_package_share_directory('robot_navigo')
    navigo_launch_dir = os.path.join(navigo_dir, 'launch')

    # --- Launch 参数 ---
    map_yaml = LaunchConfiguration('map')
    nav2_delay = LaunchConfiguration('nav2_delay')
    auto_standup = LaunchConfiguration('auto_standup')

    declare_map_cmd = DeclareLaunchArgument(
        'map',
        default_value=default_map,
        description='地图 YAML 文件的绝对路径',
    )

    declare_nav2_delay_cmd = DeclareLaunchArgument(
        'nav2_delay',
        default_value='5.0',
        description='Nav2 启动延迟 (秒)，等待 TF 和 LaserScan 就绪',
    )

    declare_auto_standup_cmd = DeclareLaunchArgument(
        'auto_standup',
        default_value='true',
        description='启动时自动让机器人站立',
    )

    # --- 节点 1: sim_tf_bridge (立即启动) ---
    # 用 ExecuteProcess 启动独立 Python 脚本 (不在任何 ROS2 包中)
    # 桥接:
    #   /odom/mujoco_odom → TF (map→odom→base_link→livox_frame) + /odom/current_pose
    #   /livox/lidar (PointCloud2) → /laser_scan (LaserScan)
    sim_tf_bridge = ExecuteProcess(
        cmd=[
            sys.executable, sim_tf_bridge_script,
            '--ros-args',
            '-p', 'odom_topic:=/odom/mujoco_odom',
            '-p', 'lidar_topic:=/livox/lidar',
            '-p', 'odom_output_topic:=/odom/current_pose',
            '-p', 'laserscan_topic:=/laser_scan',
            '-p', 'enable_laserscan:=true',
            '-p', 'min_height:=-0.3',
            '-p', 'max_height:=0.8',
            '-p', 'range_min:=0.3',
            '-p', 'range_max:=30.0',
        ],
        output='screen',
    )

    # --- 节点 2: cmd_vel_to_zsibot (立即启动) ---
    # /cmd_vel → SDK.move(vx, vy, wz) → UDP → mc_ctrl → MuJoCo
    cmd_vel_node = Node(
        package='cmd_vel_to_zsibot',
        executable='cmd_vel_to_zsibot_node',
        name='cmd_vel_to_zsibot',
        output='screen',
        parameters=[{
            'local_ip': '127.0.0.1',
            'local_port': 43988,
            'robot_ip': '192.168.234.1',
            'auto_standup': True,
            'cmd_vel_topic': 'cmd_vel',
            'max_linear_x': 0.5,
            'max_linear_y': 0.3,
            'max_angular_z': 1.0,
            'publish_rate': 50.0,
        }],
    )

    # --- 节点 3: navigo Nav2 stack (延迟启动) ---
    nav2_bringup = TimerAction(
        period=nav2_delay,
        actions=[
            LogInfo(msg='启动 navigo Nav2 导航栈...'),
            IncludeLaunchDescription(
                PythonLaunchDescriptionSource(
                    os.path.join(navigo_launch_dir, 'bringup_launch.py')
                ),
                launch_arguments={
                    'use_sim_time': 'false',
                    'map': map_yaml,
                    'params_file': sim_params,
                    'autostart': 'true',
                    'use_composition': 'True',
                    'use_respawn': 'False',
                    'log_level': 'info',
                }.items(),
            ),
        ],
    )

    # --- 构建 Launch Description ---
    ld = LaunchDescription()

    ld.add_action(declare_map_cmd)
    ld.add_action(declare_nav2_delay_cmd)
    ld.add_action(declare_auto_standup_cmd)

    # 立即启动: TF 桥接 + SDK 桥接
    ld.add_action(sim_tf_bridge)
    ld.add_action(cmd_vel_node)

    # 延迟启动: Nav2
    ld.add_action(nav2_bringup)

    return ld
