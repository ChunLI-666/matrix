<h1>
  <a href="#"><img alt="Forest" src="demo_gif/Forest.png" width="100%"/></a>
</h1>

# MATRiX
MATRiX 是一个高级仿真平台，集成了 **MuJoCo**、**Unreal Engine 5** 和 **CARLA**，为四足机器人研究提供高保真、交互式环境。其软件在环（software-in-the-loop）架构实现了逼真的物理模拟、沉浸式视觉效果，并优化了仿真到真实（sim-to-real）的迁移，用于机器人开发与部署。

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
├── config/                      # 机器人与传感器配置文件
├── scene/                       # 自定义场景文件
├── dynamicmaps/                 # 动态地面二进制文件
├── src/
│   ├── robot_mc/
│   ├── robot_mujoco/
│   ├── navigo/
│   └── UeSim/
├── build.sh                     # 一键构建脚本
├── run_sim.sh                   # 仿真启动脚本
├── sim_launcher                 # 启动器 UI
├── README_CN.md                 # 中文项目文档
└── README.md                    # 项目文档
```

---

## ⚙️ 环境依赖

- **操作系统：** Ubuntu 22.04  
- **推荐 GPU：** NVIDIA RTX 4060 或以上  
- **Unreal Engine：** 已集成（无需单独安装）  
- **构建环境：**  
  - GCC/G++ ≥ 支持 C++11  
  - CMake ≥ 3.16  
- **MuJoCo：** 3.3.0 开源版本（已集成）  
- **远程手柄：** 必需（推荐：Logitech Wireless Gamepad F710）  
- **Python 依赖：** `gdown`  
- **ROS 依赖：** `ROS_humble`  

---

## 🚀 安装与构建

1. **安装 LCM**
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
   > **注意：** 将 `<version>` 替换为实际解压后的 LCM 目录名。

2. **下载 MATRiX 仿真器**

   - **方法 1：Google Drive**  
     [Google Drive 下载链接](https://drive.google.com/file/d/1FjDGq0DoYdvrwiAP077Z-vJKUNozOU5h/view?usp=sharing)

     **使用 gdown 下载：**
     ```bash
     pip install gdown
     gdown https://drive.google.com/uc?id=1FjDGq0DoYdvrwiAP077Z-vJKUNozOU5h
     ```
     
   - **方法 2：百度网盘**  
     [百度网盘链接](https://pan.baidu.com/s/1-U-_5Uc4dKPJ7ab2Cgpg2Q?pwd=uera)  


    > **注意：** 从云存储链接下载时，请确保选择最新版本以获得最佳兼容性与功能。

    > **历史版本链接：** [Link](https://drive.google.com/drive/folders/1JN9K3m6ZvmVpHY9BLk4k_Yj9vndyh8nT?usp=sharing)


3. **解压**
   ```bash
   unzip <downloaded_filename>
   ```

4. **安装依赖**
   ```bash
   cd matrix
   ./build.sh
   ```
   *(该脚本将自动安装所有所需依赖。)*

---

## 🏞️ 演示环境

<div align="center">

| **地图**         | **演示截图**                          | **地图**         | **演示截图**                          |
|:---------------:|:------------------------------------:|:---------------:|:------------------------------------:|
| **Venice**      | <img src="demo_gif/Venice.gif" alt="Matrix Demo Screenshot" width="350" height="200"/> | **Warehouse**   | <img src="demo_gif/whmap.gif" alt="Matrix Warehouse Demo" width="350" height="200"/> |
| **Town10**      | <img src="demo_gif/Town10.gif" alt="Matrix Town Demo" width="350" height="200"/>       | **Yard**        | <img src="demo_gif/Yardmap.gif" alt="Matrix Yardmap Demo" width="350" height="200"/> |

</div>

> **说明：** 参见 [地图说明](docs/README_1.md)。

> **说明：** 上述截图展示了用于机器人与强化学习实验的高保真 UE5 渲染效果。

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
   选择首选的控制设备：  
   - **手柄控制**  
   - **键盘控制**

5. **启用无头模式（可选）**  
   可切换 **Headless Mode** 以在无图形界面下运行仿真。

6. **启动仿真**  
   点击 **Launch Simulation** 按钮以启动仿真。

仿真运行期间，如果 UE 窗口处于活动状态，可按 **ALT + TAB** 切换窗口。  
然后使用启动器上的控制模式切换按钮随时在手柄和键盘控制之间切换。

## 🎮 手柄控制说明（Gamepad 控制指南）

| 操作                              | 控制输入                        |
|-----------------------------------|---------------------------------|
| 站立 / 坐下                       | 长按 **LB** + **Y**             |
| 前进 / 后退 / 左移 / 右移         | **左摇杆**（上 / 下 / 左 / 右）  |
| 向左 / 右 转向                    | **右摇杆**（左 / 右）           |
| 向前跳                            | 长按 **RB** + **Y**             |
| 原地跳                            | 长按 **RB** + **X**             |
| 翻筋斗                            | 长按 **RB** + **B**             |
  
## ⌨️ 键盘控制说明（Keyboard 控制指南）

| 操作                              | 控制输入                        |
|-----------------------------------|---------------------------------|
| 站立                               | U                               |
| 坐下                               | 空格（Space）                   |
| 前进 / 后退 / 左移 / 右移         | W / S / A / D                   |
| 向左 / 向右 旋转                  | Q / E                           |
| 开始                               | Enter                           |

按 **V** 键可在自由相机与机器人视角间切换。  

按住 **左键** 可临时切换到自由相机模式。

---

## 🔧 配置指南

### 自定义场景配置
- 按照 `matrix/scene/` 中现有格式，在 json 文件中编写自定义场景，详细信息见 [教程](docs/README_2.md)。
- 将自定义场景文件放置为 `matrix/scene/scene.json`。
- 从启动器选择自定义地图以在仿真中加载。

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

- 根据需要调整 **位置** 和 **传感器数量**  
- 删除未使用的传感器以提升 **UE 帧率（FPS）**

---

## 📡 传感器数据后处理

- 深度相机输出图像为 `sensor_msgs::msg::Image`，编码为 **32FC1**。
- 获取灰度深度图像的示例代码如下：

```bash
  void callback(const sensor_msgs::msg::Image::SharedPtr msg)
  {
    cv::Mat depth_image;
    depth_image = cv::Mat(HEIGHT, WIDTH, CV_32FC1, const_cast<uchar*>(msg->data.data()));
  }
```

## 📡 在 RViz 中可视化传感器数据

要在 RViz 中可视化传感器数据：

1. 按上述方法启动仿真。
2. 启动 RViz：
  ```bash
  rviz2
  ```
3. 加载配置：  
   在 RViz 中打开 `rviz/matrix.rviz`，使用预配置视图。

<div align="center">
  <img src="./demo_gif/rviz2.png" alt="RViz Visualization Example" width="1280" height="720"/>
</div>

> **提示：** 请确保已正确 source ROS 环境并且相关主题正在发布。

## 📋 待办事项

- [x] IROS 比赛地图（4 张地图）
- [x] 支持第三方四足机器人模型
- [x] 支持基于 json 的自定义场景
- [x] 添加 3DGS 重建地图
- [x] 基于动态地面添加月球地图
- [ ] 添加多机器人仿真能力

---
## 🙏 致谢

本项目基于以下优秀开源项目构建，特此致谢：

- [MuJoCo-Unreal-Engine-Plugin](https://github.com/oneclicklabs/MuJoCo-Unreal-Engine-Plugin)  
- [MuJoCo](https://github.com/google-deepmind/mujoco)  
- [Unreal Engine](https://github.com/EpicGames/UnrealEngine)
- [CARLA](https://carla.org/)

感谢上述项目的开发者与贡献者，为机器人与仿真技术的发展所作出的卓越贡献。

---
