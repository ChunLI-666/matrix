<h1>
  <a href="#"><img alt="Forest" src="demo_gif/Forest.png" width="100%"/></a>
</h1>

# MATRiX
MATRiX 是一个先进的仿真平台,集成了 **MuJoCo**、**Unreal Engine 5** 和 **CARLA**,为四足机器人研究提供高保真、交互式环境。其软件在环架构实现了逼真的物理模拟、沉浸式视觉效果,并优化了从仿真到现实的迁移,适用于机器人开发和部署。

  ---

  ## 📂 目录结构

  ```text
  ├── deps/                        # 第三方依赖
  │   ├── ecal_5.13.3-1ppa1~jammy_amd64.deb
  │   ├── mujoco_3.3.0_x86_64_Linux.deb
  │   ├── onnx_1.51.0_x86_64_jammy_Linux.deb
  │   └── zsibot_common*.deb
  ├── scripts/                     # 构建和配置脚本
  │   ├── build_mc.sh
  │   ├── build_mujoco_sdk.sh
  │   ├── download_uesim.sh
  │   ├── install_deps.sh
  │   └── modify_config.sh
  ├── docs/                        # 文档和指南
  ├── config/                      # 机器人和传感器配置文件
  ├── scene/                       # 自定义场景文件
  ├── dynamicmaps/                # 动态地面 bin 文件
  ├── src/
  │   ├── robot_mc/
  │   ├── robot_mujoco/
  │   ├── navigo/
  │   └── UeSim/
  ├── build.sh                     # 一键构建脚本
  ├── run_sim.sh                   # 仿真启动脚本
  ├── sim_launcher                 # 启动器界面
  ├── README_CN.md                 # 中文项目文档
  └── README.md                    # 项目文档
  
  ```

  ---

  ## ⚙️ 环境依赖

  - **操作系统:** Ubuntu 22.04  
  - **推荐显卡:** NVIDIA RTX 4060 或更高  
  - **Unreal Engine:** 已集成(无需单独安装)  
  - **构建环境:**  
    - GCC/G++ ≥ C++11  
    - CMake ≥ 3.16  
  - **MuJoCo:** 3.3.0 开源版本(已集成)  
  - **遥控器:** 必需(推荐:*罗技无线游戏手柄 F710*)  
  - **Python 依赖:** `gdown`  
  - **ROS 依赖:** `ROS_humble`  

  ---

  ## 🚀 安装与构建

  1. **LCM 安装**
     ```bash
     sudo apt update
     sudo apt install -y cmake-qt-gui gcc g++ libglib2.0-dev python3-pip
     ```
     从 [LCM Releases](https://github.com/lcm-proj/lcm/releases) 下载源代码并解压。

     构建和安装:
     ```bash
     cd lcm-<version>
     mkdir build
     cd build
     cmake ..
     make -j$(nproc)
     sudo make install
     ```
     > **注意:** 将 `<version>` 替换为实际解压的 LCM 目录名称。

  2. **下载 MATRiX 仿真器**

     - **方法 1: Google Drive**  
       [Google Drive 下载链接](https://drive.google.com/file/d/1UUepVneqrK2r_-5a1rUPmYd5wiqWbBp0/view?usp=sharing)

       **通过 gdown 下载:**
       ```bash
       pip install gdown
       gdown https://drive.google.com/uc?id=1UUepVneqrK2r_-5a1rUPmYd5wiqWbBp0
       ```
       
     - **方法 2: 百度网盘**  
       [百度网盘链接](https://pan.baidu.com/s/1thnDgDfQkmIqxnt-_7C4Cw?pwd=sicu)  


      > **注意:** 从云存储链接下载时,请确保选择最新版本以获得最佳兼容性和功能。

      > **旧版本链接**: [链接](https://drive.google.com/drive/folders/1JN9K3m6ZvmVpHY9BLk4k_Yj9vndyh8nT?usp=sharing)


  3. **解压**
     ```bash
     unzip <downloaded_filename>
     ```

  4. **安装依赖**
     ```bash
     cd matrix
     ./build.sh
     ```
     *(此脚本将自动安装所有必需的依赖项。)*

  ---

  ## 🏞️ 演示环境

  <div align="center">

  | **地图**         | **演示截图**                          | **地图**         | **演示截图**                          |
  |:---------------:|:-------------------------------------------:|:---------------:|:-------------------------------------------:|
  | **Venice**      | <img src="demo_gif/Venice.gif" alt="Matrix Demo Screenshot" width="350" height="200"/> | **Warehouse**   | <img src="demo_gif/whmap.gif" alt="Matrix Warehouse Demo" width="350" height="200"/> |
  | **Town10**      | <img src="demo_gif/Town10.gif" alt="Matrix Town Demo" width="350" height="200"/>       | **Yard**        | <img src="demo_gif/Yardmap.gif" alt="Matrix Yardmap Demo" width="350" height="200"/> |

  </div>

  > **注意:** [地图描述](docs/README_1.md)。

  > **注意:** 上述截图展示了用于机器人和强化学习实验的高保真 UE5 渲染效果。

  ---

  ## ▶️ 运行仿真

  <div align="center">
    <img src="demo_gif/Launcher.png" alt="Simulation Running Example" width="50%" />
  </div>

  ## 🐕 仿真设置指南

  1. **运行启动器**
  ```bash
      cd matrix
      ./sim_launcher
  ```
  2. **选择机器人类型**  
    为仿真选择四足机器人的类型。

  3. **选择环境**  
    选择所需的仿真环境或地图。

  4. **选择控制设备**  
    选择您偏好的控制设备:  
    - **手柄控制**  
    - **键盘控制**

  5. **启用无头模式(可选)**  
    切换 **无头模式** 选项以在没有图形界面的情况下运行仿真。

  6. **启动仿真**  
    点击 **启动仿真** 按钮开始仿真。

  在仿真过程中,如果 UE 窗口处于活动状态,您可以按 **ALT + TAB** 切换出来。  
  然后,使用启动器上的控制模式切换按钮随时在手柄和键盘控制之间切换。
  
  ## 🎮 遥控器说明(手柄控制指南)

  | 动作                              | 控制器输入                        |
  |--------------------------------------|-----------------------------------------|
  | 站立 / 坐下                         | 按住 **LB** + **Y**                     |
  | 前进 / 后退 / 左移 / 右移  | **左摇杆** (上 / 下 / 左 / 右)|
  | 左转 / 右转                 | **右摇杆** (左 / 右)          |
  | 向前跳跃                        | 按住 **RB** + **Y**                     |
  | 原地跳跃                       | 按住 **RB** + **X**                     |
  | 翻筋斗                          | 按住 **RB** + **B**                     |
  
  ## ⌨️ 遥控器说明(键盘控制指南)

  | 动作                              | 控制器输入                        |
  |--------------------------------------|-----------------------------------------|
  | 站立                               | U                                       |
  | 坐下                                 | Space                                   |
  | 前进 / 后退 / 左移 / 右移  | W / S / A / D                           |
  | 左转 / 右转                 | Q / E                                   |
  | 开始                               | Enter                                   |

  按 **V** 键在自由相机和机器人视角之间切换。  

  按住 **鼠标左键** 临时切换到自由相机模式。

  ---

  ## 🔧 配置指南

  ### 自定义场景设置
  - 按照 `matrix/scene/` 中现有格式在 json 文件中编写自定义场景,详见[文档](docs/README_2.md)。
  - 将自定义场景文件放置在 `matrix/scene/` 目录中。
  - 从启动器中选择自定义地图以在仿真中加载它。

  ### 调整传感器配置

  编辑:
  ```bash
  vim matrix/config/config.json
  ```

  示例片段:
  ```json
        "sensors": {
            "camera": {
                "position": {
                    "x": 29.0,
                    "y": 0.0,
                    "z": 1.0
                },
                "rotation": {
                    "roll": 0.0,
                    "pitch": 15.0,
                    "yaw": 0.0
                },
                "height": 1080,
                "width": 1920,
                "sensor_type": "rgb",
                "topic": "/image_raw/compressed",
                "fov": 90.0,
                "frequency": 10.0
            },
            "depth_sensor": {
                "position": {
                    "x": 29.0,
                    "y": 0.0,
                    "z": 1.0
                },
                "rotation": {
                    "roll": 0.0,
                    "pitch": 15.0,
                    "yaw": 0.0
                },
                "height": 480,
                "width": 640,
                "sensor_type": "depth",
                "topic": "/image_raw/compressed/depth",
                "fov": 90.0,
                "frequency": 10.0
            },
            "lidar": {
                "position": {
                    "x": 13.011,
                    "y": 2.329,
                    "z": 17.598
                },
                "rotation": {
                    "roll": 0.0,
                    "pitch": 0.0,
                    "yaw": 0.0
                },
                "sensor_type": "mid360",
                "topic": "/livox/lidar",
                "draw_points": false,
                "random_scan": false,
                "frequency": 10.0
            }
        }
```

- 根据需要调整传感器的 **位姿** 和 **数量**  
- 删除未使用的传感器以提高 **UE FPS 性能**

---

## 📡 传感器数据后处理

- 深度相机输出的图像为 `sensor_msgs::msg::Image`,采用 **32FC1 编码**。
- 要获取灰度深度图像,请使用以下代码片段:

```bash
  void callback(const sensor_msgs::msg::Image::SharedPtr msg)
  {
    cv::Mat depth_image;
    depth_image = cv::Mat(HEIGHT, WIDTH, CV_32FC1, const_cast<uchar*>(msg->data.data()));
  }
```



  ## 📡 在 RViz 中可视化传感器数据

  要在 RViz 中可视化传感器数据:

  1. **启动仿真**,如上所述。
  2. **启动 RViz**:
    ```bash
    rviz2
    ```
  3. **加载配置**:  
    在 RViz 中打开 `rviz/matrix.rviz` 以获得预配置视图。

  <div align="center">
    <img src="./demo_gif/rviz2.png" alt="RViz Visualization Example" width="1280" height="720"/>
  </div>
  
  > **提示:** 确保您的 ROS 环境已正确配置,并且相关话题正在发布。

  ## 📋 待办事项列表

  - [x] IROS 比赛地图(4 个地图)
  - [x] 支持第三方四足机器人模型
  - [x] 支持基于 json 文件的自定义场景
  - [x] 添加 3DGS 重建地图
  - [x] 添加基于动态地面的月球地图
  - [ ] 添加多机器人仿真功能

  
  ---
  ## 🙏 致谢

  本项目基于以下开源项目的出色工作:

  - [MuJoCo-Unreal-Engine-Plugin](https://github.com/oneclicklabs/MuJoCo-Unreal-Engine-Plugin)  
  - [MuJoCo](https://github.com/google-deepmind/mujoco)  
  - [Unreal Engine](https://github.com/EpicGames/UnrealEngine)
  - [CARLA](https://carla.org/)

  我们向这些项目的开发者和贡献者表示感谢,感谢他们在推进机器人和仿真技术方面做出的宝贵努力。

  ---

