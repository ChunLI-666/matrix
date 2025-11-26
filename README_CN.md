<h1>
  <a href="#"><img alt="Forest" src="demo_gif/Forest.png" width="100%"/></a>
</h1>

# MATRiX
MATRiX 是一个集成了 **MuJoCo**、**Unreal Engine 5** 和 **CARLA** 的高级仿真平台，提供用于四足机器人研究的高保真、交互式环境。其软件在环（software-in-the-loop）架构支持真实物理仿真、沉浸式视觉效果，并优化了仿真到现实的迁移（sim-to-real）以便机器人开发与部署。

---

## 📂 目录结构

```text
├── deps/                        # 第三方依赖
│   ├── ecal_5.13.3-1ppa1~jammy_amd64.deb
│   ├── mujoco_3.3.0_x86_64_Linux.deb
│   ├── onnx_1.51.0_x86_64_jammy_Linux.deb
│   └── zsibot_common*.deb
├── scripts/                     # 构建与配置脚本
│   ├── build_mc.sh
│   ├── build_mujoco_sdk.sh
│   ├── download_uesim.sh
│   ├── install_deps.sh
│   └── modify_config.sh
├── docs/                        # 文档与使用指南
├── config/                      # 机器人与传感器配置文件
│   ├── scene/                   # 自定义场景文件
├── src/
│   ├── robot_mc/
│   ├── robot_mujoco/
│   ├── navigo/
│   └── UeSim/
├── build.sh                     # 一键构建脚本
├── run_sim.sh                   # 启动仿真脚本
├── sim_launcher                 # 启动器 UI
├── README_CN.md                 # 中文项目文档
└── README.md                    # 项目文档
```

---

## ⚙️ 环境依赖

- **操作系统：** Ubuntu 22.04  
- **推荐 GPU：** NVIDIA RTX 4060 或更高  
- **Unreal Engine：** 已集成（无需单独安装）  
- **构建环境：**  
  - GCC/G++ ≥ C++11  
  - CMake ≥ 3.16  
- **MuJoCo：** 3.3.0 开源版本（已集成）  
- **遥控器：** 必需（推荐：Logitech Wireless Gamepad F710）  
- **Python 依赖：** `gdown`  
- **ROS 依赖：** `ROS_humble`  

---

## 🚀 安装与构建

1. **LCM 安装**
   ```bash
   sudo apt update
   sudo apt install -y cmake-qt-gui gcc g++ libglib2.0-dev python3-pip
   ```
   从 [LCM Releases](https://github.com/lcm-proj/lcm/releases) 下载源码并解压。

   构建并安装：
   ```bash
   cd lcm-<version>
   mkdir build
   cd build
   cmake ..
   make -j$(nproc)
   sudo make install
   ```
   > **注意：** 将 `<version>` 替换为实际解压出的 LCM 目录名。

2. **下载 MATRiX 仿真器**

   - **方法1：Google Drive**  
     [Google Drive 下载链接](https://drive.google.com/file/d/12rQuKy8xM15gcIN_T3G5cg2NeqdtSKkW/view?usp=sharing)

     **通过 gdown 下载：**
     ```bash
     pip install gdown
     gdown https://drive.google.com/uc?id=12rQuKy8xM15gcIN_T3G5cg2NeqdtSKkW
     ```
     
   - **方法2：百度网盘**  
     [百度网盘链接](https://pan.baidu.com/s/1TBVFYA75YVPeR4KBMY1t2g?pwd=a3r6)  

   - **方法3：JFrog**  
     ```bash
     curl -H "Authorization: Bearer cmVmdGtuOjAxOjE3ODQ2MDY4OTQ6eFJvZVA5akpiMmRzTFVwWXQ3YWRIbTI3TEla"  -o "matrix.zip" -# "http://192.168.50.40:8082/artifactory/jszrsim/UeSim/matrix.zip"  
     ```
   > **注意：** 从云存储链接下载时，请确保选择最新版本以获取最佳兼容性和功能。

   > **历史版本链接**: [Link](https://drive.google.com/file/d/1WMtHqtJEggjgTk0rOcwO6m99diUlzq_J/view?usp=sharing)

3. **解压**
   ```bash
   unzip <downloaded_filename>
   ```

4. **安装依赖**
   ```bash
   cd matrix
   ./build.sh
   ```
   *(该脚本将自动安装所有所需依赖)*

---

## 🏞️ 演示场景

<div align="center">

| **地图**         | **演示截图**                          | **地图**         | **演示截图**                          |
|:---------------:|:-----------------------------------:|:---------------:|:-------------------------------------:|
| **Venice**      | <img src="demo_gif/Venice.gif" alt="Matrix Demo Screenshot" width="350" height="200"/> | **Warehouse**   | <img src="demo_gif/whmap.gif" alt="Matrix Warehouse Demo" width="350" height="200"/> |
| **Town10**      | <img src="demo_gif/Town10.gif" alt="Matrix Town Demo" width="350" height="200"/>       | **Yard**        | <img src="demo_gif/Yardmap.gif" alt="Matrix Yardmap Demo" width="350" height="200"/> |

</div>

> **说明：** 地图描述见 [doc](docs/README_1.md)。

> **说明：** 上述截图展示了用于机器人和强化学习实验的高保真 UE5 渲染效果。

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
   选择用于仿真的四足机器人类型。

3. **选择环境**  
   选择所需的仿真环境或地图。

4. **选择控制设备**  
   选择首选控制设备：  
   - **手柄控制（Gamepad Control）**  
   - **键盘控制（Keyboard Control）**

5. **启用无界面模式（可选）**  
   切换 **Headless Mode** 以在无图形界面的情况下运行仿真。

6. **启动仿真**  
   点击 **Launch Simulation** 按钮以开始仿真。

仿真运行期间，如果 UE 窗口处于激活状态，可按 **ALT + TAB** 切换出窗口。  
然后使用启动器上的控制模式切换按钮随时在手柄和键盘控制之间切换。

## 🎮 遥控器说明（手柄控制指南）

| 操作                                 | 控制输入                                |
|--------------------------------------|-----------------------------------------|
| 站立 / 坐下                          | 按住 **LB** + **Y**                     |
| 前进 / 后退 / 左移 / 右移            | **左摇杆**（上 / 下 / 左 / 右）         |
| 向左 / 向右旋转                      | **右摇杆**（左 / 右）                   |
| 向前跳（冲刺）                       | 按住 **RB** + **Y**                     |
| 原地跳                               | 按住 **RB** + **X**                     |
| 翻筋斗                               | 按住 **RB** + **B**                     |

## ⌨️ 键盘控制指南

| 操作                                 | 控制输入                                |
|--------------------------------------|-----------------------------------------|
| 站立                                 | U                                       |
| 坐下                                 | 空格键（Space）                         |
| 前进 / 后退 / 左移 / 右移            | W / S / A / D                           |
| 向左 / 向右旋转                      | Q / E                                   |

按 **V** 键在自由相机与机器人视角之间切换。  
按住 **鼠标左键** 可临时切换到自由相机模式。

---

## 🔧 配置指南

### 自定义场景设置
- 按照 `matrix/scene/` 中已有格式在 json 文件中编写自定义场景，详情见 [doc](docs/README_2.md)。
- 将自定义场景文件放置到 `matrix/scene/` 目录下。
- 在启动器中选择自定义地图以在仿真中加载它。

### 调整传感器配置

编辑：
```bash
vim matrix/config/config.json
```

示例片段：
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

- 根据需要调整 **位置（pose）** 和 **传感器数量**  
- 删除未使用的传感器以提升 **UE 帧率（FPS）**

---

## 📡 传感器数据后处理

- 深度相机输出的图像为 `sensor_msgs::msg::Image`，编码为 **32FC1**。
- 获取灰度深度图像的示例代码：

```bash
  void callback(const sensor_msgs::msg::Image::SharedPtr msg)
  {
    cv::Mat depth_image;
    depth_image = cv::Mat(HEIGHT, WIDTH, CV_32FC1, const_cast<uchar*>(msg->data.data()));
  }
```

## 📡 在 RViz 中可视化传感器数据

要在 RViz 中可视化传感器数据：

1. 按上述方式启动仿真。
2. 启动 RViz：
  ```bash
  rviz2
  ```
3. 加载配置：  
   在 RViz 中打开 `rviz/matrix.rviz`，该文件提供预配置视图。

<div align="center">
  <img src="./demo_gif/rviz2.png" alt="RViz Visualization Example" width="1280" height="720"/>
</div>

> **提示：** 确保已正确 source ROS 环境并且相关话题已被发布。

## 📋 待办事项

- [x] IROS 比赛地图（4 张地图）
- [x] 支持第三方四足机器人模型
- [x] 支持基于 json 文件的自定义场景
- [ ] 添加多机器人仿真能力

---

## 🙏 致谢

本项目基于以下开源项目的出色工作构建：

- [MuJoCo-Unreal-Engine-Plugin](https://github.com/oneclicklabs/MuJoCo-Unreal-Engine-Plugin)  
- [MuJoCo](https://github.com/google-deepmind/mujoco)  
- [Unreal Engine](https://github.com/EpicGames/UnrealEngine)
- [CARLA](https://carla.org/)

我们感谢这些项目的开发者和贡献者，他们为推进机器人与仿真技术提供了宝贵支持。

---
