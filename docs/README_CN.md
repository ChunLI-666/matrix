<h1>
  <a href="#"><img alt="Forest" src="demo_gif/Forest.png" width="100%"/></a>
  </h1>

<div align="center">

[![English](https://img.shields.io/badge/Language-English-blue)](../README.md)
[![中文](https://img.shields.io/badge/语言-中文-red)](README_CN.md)

</div>

# MATRiX
MATRiX 是一个先进的仿真平台，集成了 **MuJoCo**、**Unreal Engine 5** 和 **CARLA**，为四足机器人研究提供高保真、交互式环境。其软件在环架构实现了逼真的物理效果、沉浸式视觉效果以及优化的仿真到现实迁移能力，助力机器人开发与部署。

  ---

  ## 📂 目录结构

  ```text
  ├── bin/                         # 可执行二进制文件
  │   └── sim_launcher                # GUI 启动器 (24MB)
  ├── deps/                        # 第三方依赖
  │   ├── ecal_5.13.3-1ppa1~jammy_amd64.deb
  │   ├── mujoco_3.3.0_x86_64_Linux.deb
  │   ├── onnx_1.51.0_x86_64_jammy_Linux.deb
  │   └── zsibot_common*.deb
  ├── docs/                        # 文档
  │   ├── README_CN.md
  │   └── CHUNK_PACKAGES_GUIDE.md
  ├── scripts/                     # 构建与配置脚本
  │   ├── build.sh                    # 一键构建脚本
  │   ├── run_sim.sh                  # 仿真启动脚本
  │   ├── build_mc.sh
  │   ├── build_mujoco_sdk.sh
  │   ├── download_uesim.sh
  │   ├── install_deps.sh
  │   ├── modify_config.sh
  │   └── release_manager/         # 发布和包管理
  │       ├── install_chunks.sh              # 从 GitHub Releases 下载并安装
  │       ├── install_chunks_local.sh        # 从本地 releases/ 目录安装
  │       ├── package_chunks_for_release.sh  # 打包 chunks 用于发布
  │       ├── upload_to_release.sh           # 上传包到 GitHub Releases
  │       └── split_large_file.sh            # 分割大文件（>2GB）用于 GitHub
  ├── releases/                    # 下载的 chunk 包（安装后创建）
  │   ├── base-*.tar.gz               # 基础包
  │   ├── shared-*.tar.gz             # 共享资源
  │   ├── *-*.tar.gz                  # 地图包
  │   └── manifest-*.json             # 包清单
  ├── src/
  │   ├── robot_mc/
  │   ├── robot_mujoco/
  │   └── UeSim/
  └── README.md                    # 项目文档
  ```

  ---

  ## ⚙️ 环境依赖

  - **操作系统：** Ubuntu 22.04  
  - **推荐 GPU：** NVIDIA RTX 4060 或更高  
  - **Unreal Engine：** 集成（无需单独安装）  
  - **构建环境：**  
    - GCC/G++ ≥ C++11  
    - CMake ≥ 3.16  
  - **MuJoCo：** 3.3.0 开源版本（已集成）  
  - **远程控制器：** 必需（推荐：*Logitech Wireless Gamepad F710*）  
  - **Python 依赖：** `gdown`  

  ---

  ## 🚀 安装与构建

  1. **安装 LCM**
     ```bash
     sudo apt update
     sudo apt install -y cmake-qt-gui gcc g++ libglib2.0-dev python3-pip
     ```
     从 [LCM Releases](https://github.com/lcm-proj/lcm/releases) 下载源码并解压。

     构建与安装：
     ```bash
     cd lcm-<version>
     mkdir build
     cd build
     cmake ..
     make -j$(nproc)
     sudo make install
     ```
     > **注意：** 将 `<version>` 替换为实际解压的 LCM 目录名称。

  2. **克隆 MATRiX 仓库**
     ```bash
     git clone https://github.com/Alphabaijinde/matrix.git
     cd matrix
     ```

  3. **安装依赖**
     ```bash
     ./scripts/build.sh
     ```
     *(此脚本将自动安装所有必需依赖。)*

  4. **安装 Chunk 包（模块化安装）**

     MATRiX 使用模块化 chunk 包系统，允许您只下载需要的内容：
     - **基础包**（必需）：核心文件和 EmptyWorld 地图
     - **共享资源**（推荐）：多个地图共享的资源
     - **地图包**（可选）：可按需下载的独立地图

     **自动安装（推荐）：**
     ```bash
     bash scripts/release_manager/install_chunks.sh 0.0.4
     ```
     
     脚本将：
     - 下载基础包（必需）
     - 提示是否下载共享资源（推荐）
     - 交互式选择要下载的地图
     - 将所有下载的文件保存到 `releases/` 目录供后续使用

     **可用地图：**
     - SceneWorld, Town10World, YardWorld, CrowdWorld, VeniceWorld
     - RunningWorld, HouseWorld, IROSFlatWorld, IROSSlopedWorld
     - Town10Zombie, IROSFlatWorld2025, IROSSloppedWorld2025
     - OfficeWorld, Custom

     > **注意：** 所有下载的包都保存在 `releases/` 目录。您可以使用 `install_chunks_local.sh` 稍后安装其他地图，无需重新下载。

     **备选：从云存储手动下载**
     
     如果您更喜欢从云存储下载完整包：
     - **Google Drive**: [下载链接](https://drive.google.com/drive/folders/1JN9K3m6ZvmVpHY9BLk4k_Yj9vndyh8nT?usp=sharing)
       ```bash
       pip install gdown
       gdown https://drive.google.com/uc?id=1WMtHqtJEggjgTk0rOcwO6m99diUlzq_J
       unzip <downloaded_filename>
       ```
     - **百度网盘**: [下载链接](https://pan.baidu.com/s/1o8UEO1vUxPYmzeiiP9DYgg?pwd=hwqs)
     - **JFrog**:
       ```bash
       curl -H "Authorization: Bearer cmVmdGtuOjAxOjE3ODQ2MDY4OTQ6eFJvZVA5akpiMmRzTFVwWXQ3YWRIbTI3TEla" -o "matrix.zip" -# "http://192.168.50.40:8082/artifactory/jszrsim/UeSim/matrix.zip"
       unzip matrix.zip
       ```

  ---

  ## 🛠️ 脚本使用指南

  MATRiX 提供了多种脚本来帮助您构建、安装和运行仿真器。以下是合理使用这些脚本的方法：

  ### 📋 脚本分类

  #### **用户脚本**（面向最终用户）

  | 脚本 | 用途 | 使用方法 |
  |------|------|---------|
  | `build.sh` | 一键构建和依赖安装 | `./scripts/build.sh` |
  | `run_sim.sh` | 启动仿真 | `./scripts/run_sim.sh <机器人类型> <地图ID>` |
  | `install_chunks.sh` | 从 GitHub 下载并安装 chunk 包 | `bash scripts/release_manager/install_chunks.sh <版本号>` |
  | `install_chunks_local.sh` | 从本地 releases/ 目录安装 chunk 包 | `bash scripts/release_manager/install_chunks_local.sh <版本号>` |

  #### **开发者脚本**（面向贡献者）

  | 脚本 | 用途 | 使用方法 |
  |------|------|---------|
  | `build_mc.sh` | 构建 MC 控制模块 | `./scripts/build_mc.sh` |
  | `build_mujoco_sdk.sh` | 构建 MuJoCo SDK | `./scripts/build_mujoco_sdk.sh` |
  | `package_chunks_for_release.sh` | 打包 chunks 用于发布 | `bash scripts/release_manager/package_chunks_for_release.sh <版本号>` |
  | `upload_to_release.sh` | 上传包到 GitHub Releases | `bash scripts/release_manager/upload_to_release.sh <版本号>` |
  | `split_large_file.sh` | 分割大文件（>2GB）用于 GitHub | `bash scripts/release_manager/split_large_file.sh <文件路径>` |

  ### 🚀 典型工作流程

  #### **首次设置（新用户）**

  ```bash
  # 1. 克隆仓库
  git clone https://github.com/Alphabaijinde/matrix.git
  cd matrix

  # 2. 安装依赖并构建
  ./scripts/build.sh

  # 3. 安装 chunk 包（从 GitHub 下载）
  bash scripts/release_manager/install_chunks.sh 0.0.4
  # → 选择性选择要下载的地图
  # → 文件保存到 releases/ 目录
  # → 包自动安装到 src/UeSim/Linux/jszr_mujoco_ue/

  # 4. 运行仿真
  ./scripts/run_sim.sh 0 0  # EmptyWorld 默认机器人
  ```

  #### **离线安装（无网络）**

  ```bash
  # 1. 在有网络的机器上下载包
  bash scripts/release_manager/install_chunks.sh 0.0.4

  # 2. 将 releases/ 目录复制到离线机器

  # 3. 在离线机器上，从本地文件安装
  bash scripts/release_manager/install_chunks_local.sh 0.0.4
  # → 从 releases/ 目录安装所有包
  ```

  #### **后续添加更多地图**

  ```bash
  # 方式 1: 下载并安装新地图
  bash scripts/release_manager/install_chunks.sh 0.0.4
  # → 选择要下载的额外地图

  # 方式 2: 如果文件已在 releases/，直接安装
  bash scripts/release_manager/install_chunks_local.sh 0.0.4
  # → 安装 releases/ 目录下所有可用地图
  ```

  #### **重新安装包**

  ```bash
  # 从本地 releases/ 目录快速重新安装
  bash scripts/release_manager/install_chunks_local.sh 0.0.4
  # → 无需下载，快速安装
  ```

  ### 💡 脚本选择指南

  **何时使用 `install_chunks.sh`：**
  - ✅ 首次安装
  - ✅ 需要从 GitHub 下载最新版本
  - ✅ 想选择性下载地图包
  - ✅ 有网络连接

  **何时使用 `install_chunks_local.sh`：**
  - ✅ 文件已下载到 `releases/` 目录
  - ✅ 离线安装（无网络）
  - ✅ 快速重新安装现有包
  - ✅ 想自动安装所有可用地图

  ### 📁 理解文件位置

  ```
  matrix/
  ├── releases/                    # 下载的包（install_chunks.sh 后创建）
  │   ├── base-0.0.4.tar.gz       # 基础包
  │   ├── shared-0.0.4.tar.gz     # 共享资源
  │   └── *.tar.gz                # 地图包
  │
  └── src/UeSim/Linux/jszr_mujoco_ue/  # 运行目录（包安装的位置）
      └── Content/Paks/            # 已安装的 chunk 文件 (.pak, .ucas, .utoc)
  ```

  **关键要点：**
  - `releases/` = 下载包的存储位置（源文件）
  - `src/UeSim/Linux/jszr_mujoco_ue/Content/Paks/` = 运行时位置（已安装的文件）
  - `install_chunks.sh` 下载到 `releases/` **并**安装到运行目录
  - `install_chunks_local.sh` 仅从 `releases/` 安装到运行目录

  > **提示：** 保留 `releases/` 目录中的文件以便将来使用。您可以删除它们以节省空间，但如果要重新安装，则需要重新下载。

  ---

  ## 🏞️ 仿真演示

  <div align="center">

  | **Map**         | **Demo Screenshot**                          | **Map**         | **Demo Screenshot**                          |
  |:---------------:|:-------------------------------------------:|:---------------:|:-------------------------------------------:|
  | **Venice**      | <img src="demo_gif/Venice.gif" alt="Matrix Demo Screenshot" width="350" height="200"/> | **Warehouse**   | <img src="demo_gif/whmap.gif" alt="Matrix Warehouse Demo" width="350" height="200"/> |
  | **Town10**      | <img src="demo_gif/Town10.gif" alt="Matrix Town Demo" width="350" height="200"/>       | **Yard**        | <img src="demo_gif/Yardmap.gif" alt="Matrix Yardmap Demo" width="350" height="200"/> |

  </div>

  > **注意：** 上述截图展示了用于机器人和强化学习实验的高保真 UE5 渲染效果。

  ---

  ## ▶️ 运行仿真

  <div align="center">
    <img src="demo_gif/Launcher.png" alt="Simulation Running Example" width="50%" />
  </div>

  ## 🐕 仿真设置指南

  1. **选择机器人类型**  
    选择仿真中使用的四足机器人类型。

  2. **选择环境**  
    选择所需的仿真环境或地图。

  3. **选择控制设备**  
    选择首选的控制设备：  
    - **游戏手柄控制**  
    - **键盘控制**

  4. **启用无头模式（可选）**  
    切换 **无头模式** 选项以在无图形界面下运行仿真。

  5. **启动仿真**  
    点击 **启动仿真** 按钮开始仿真。

  在仿真运行过程中，如果 UE 界面处于激活状态，可按下 **ALT + TAB** 切出界面。  
  然后通过启动器上的 控制模式切换按钮，即可随时在手柄控制与键盘控制之间切换。



  ## 🎮 远程控制器说明（游戏手柄控制指南）

  | 动作                              | 控制器输入                        |
  |--------------------------------------|-----------------------------------------|
  | 站立 / 坐下                         | 按住 **LB** + **Y**                     |
  | 前进 / 后退 / 左移 / 右移            | **左摇杆**（上 / 下 / 左 / 右）         |
  | 左转 / 右转                         | **右摇杆**（左 / 右）                   |
  | 前跳                                | 按住 **RB** + **Y**                     |
  | 原地跳                              | 按住 **RB** + **X**                     |
  | 翻滚                                | 按住 **RB** + **B**                     |

  
  ## ⌨️ 远程控制器说明（键盘控制指南）

  | 动作                              | 控制器输入                        |
  |--------------------------------------|-----------------------------------------|
  | 站立                               | U                                       |
  | 坐下                               | 空格键                                 |
  | 前进 / 后退 / 左移 / 右移            | W / S / A / D                           |
  | 左转 / 右转                         | Q / E                                   |

  按 **V** 键在自由相机和机器人视角之间切换。  
  按住 **左键** 可临时切换到自由相机模式。

  ---

  ## 🔧 配置指南

  ### 调整传感器配置

  编辑：
  ```bash
  vim src/UeSim/Linux/jszr_mujoco_ue/Content/model/config/config.json
  ```

  示例片段：
  ```json
  "sensors": {
    "camera": {
      "position": { "x": 29.0, "y": 0.0, "z": 1.0 },
      "rotation": { "roll": 0.0, "pitch": 15.0, "yaw": 0.0 },
      "height": 1080,
      "width": 1920,
      "sensor_type": "rgb",
      "topic": "/image_raw/compressed"
    },
    "depth_sensor": {
      "position": { "x": 29.0, "y": 0.0, "z": 1.0 },
      "rotation": { "roll": 0.0, "pitch": 15.0, "yaw": 0.0 },
      "height": 480,
      "width": 640,
      "sensor_type": "depth",
      "topic": "/image_raw/compressed/depth"
  },
  "lidar": {
    "position": { "x": 13.011, "y": 2.329, "z": 17.598 },
    "rotation": { "roll": 0.0, "pitch": 0.0, "yaw": 0.0 },
    "sensor_type": "mid360",
    "topic": "/livox/lidar"
  }
}
```

- 根据需要调整 **位姿** 和 **传感器数量**  
- 移除未使用的传感器以提高 **UE FPS 性能**

---

## 📡 传感器数据后处理

- 深度相机以 **32FC1 编码** 输出图像为 `sensor_msgs::msg::Image`。
- 要获取灰度深度图像，可使用以下代码片段：

```bash
  void callback(const sensor_msgs::msg::Image::SharedPtr msg)
  {
    cv::Mat depth_image;
    depth_image = cv::Mat(HEIGHT, WIDTH, CV_32FC1, const_cast<uchar*>(msg->data.data()));
  }
```




  ## 📡 在 RViz 中可视化传感器数据

  要在 RViz 中可视化传感器数据：

  1. **按照上述步骤启动仿真**。
  2. **启动 RViz**：
    ```bash
    rviz2
    ```
  3. **加载配置文件**：  
    在 RViz 中打开 `rviz/matrix.rviz` 以获得预配置视图。

  <div align="center">
    <img src="./demo_gif/rviz2.png" alt="RViz Visualization Example" width="1280" height="720"/>
  </div>
  
  > **提示：** 确保您的 ROS 环境已正确配置，并且相关主题正在发布。

  ## 🙏 致谢

  本项目基于以下开源项目的卓越工作：

  - [MuJoCo-Unreal-Engine-Plugin](https://github.com/oneclicklabs/MuJoCo-Unreal-Engine-Plugin)  
  - [MuJoCo](https://github.com/google-deepmind/mujoco)  
  - [Unreal Engine](https://github.com/EpicGames/UnrealEngine)  

  我们向这些项目的开发者和贡献者致以诚挚的感谢，感谢他们为推动机器人技术和仿真技术的发展所做出的宝贵努力。

  ---

  ## 📚 文档

  - [English Documentation](../README.md) - 英文使用指南
  - [Chunk Packages 使用指南](CHUNK_PACKAGES_GUIDE.md) - 模块化打包部署说明

  ## 📦 Chunk Packages 系统

  MATRiX 使用模块化 chunk 包系统，实现灵活的安装：

  - **基础包**（必需）：核心仿真器文件和 EmptyWorld 地图
  - **共享资源**（推荐）：多个地图共享的资源
  - **地图包**（可选）：可按需下载的独立地图

  **优势：**
  - ✅ 只下载需要的内容，节省存储空间
  - ✅ 快速开始，只需基础包
  - ✅ 按需扩展，下载特定地图
  - ✅ 所有包缓存在 `releases/` 目录，支持离线使用

  **安装：**
  ```bash
  # 从 GitHub Releases 下载并安装
  bash scripts/release_manager/install_chunks.sh 0.0.4

  # 或从本地 releases/ 目录安装（如果已下载）
  bash scripts/release_manager/install_chunks_local.sh 0.0.4
  ```

  更多详情，请参阅 [Chunk Packages 使用指南](CHUNK_PACKAGES_GUIDE.md)。

  ---
