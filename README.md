<h1>
  <a href="#"><img alt="Forest" src="demo_gif/Forest.png" width="100%"/></a>
  </h1>

<div align="center">

[![English](https://img.shields.io/badge/Language-English-blue)](README.md)
[![中文](https://img.shields.io/badge/语言-中文-red)](docs/README_CN.md)

</div>

# MATRiX
MATRiX is an advanced simulation platform that integrates **MuJoCo**, **Unreal Engine 5**, and **CARLA** to provide high-fidelity, interactive environments for quadruped robot research. Its software-in-the-loop architecture enables realistic physics, immersive visuals, and optimized sim-to-real transfer for robotics development and deployment.

  ---

  ## 📂 Directory Structure

  ```text
  ├── bin/                         # Executable binaries
  │   └── sim_launcher                # GUI launcher (24MB)
  ├── deps/                        # Third-party dependencies
  │   ├── ecal_5.13.3-1ppa1~jammy_amd64.deb
  │   ├── mujoco_3.3.0_x86_64_Linux.deb
  │   ├── onnx_1.51.0_x86_64_jammy_Linux.deb
  │   └── zsibot_common*.deb
  ├── docs/                        # Documentation
  │   ├── README_CN.md
  │   ├── CHUNK_PACKAGES_GUIDE.md
  │   ├── GIT_LFS_GUIDE.md
  │   ├── README_1.md
  │   └── README_2.md
  ├── scripts/                     # Build and configuration scripts
  │   ├── build.sh                    # One-click build script
  │   ├── run_sim.sh                  # Simulation launch script
  │   ├── build_mc.sh
  │   ├── build_mujoco_sdk.sh
  │   ├── download_uesim.sh
  │   ├── install_deps.sh
  │   ├── modify_config.sh
  │   └── release_manager/         # Release and package management
  │       ├── install_chunks.sh              # Download and install from GitHub Releases
  │       ├── install_chunks_local.sh        # Install from local releases/ directory
  │       ├── package_chunks_for_release.sh  # Package chunks for release
  │       ├── upload_to_release.sh           # Upload packages to GitHub Releases (with auto-consistency check and publish)
  │       └── split_large_file.sh            # Split large files (>2GB) for GitHub
  ├── releases/                    # Downloaded chunk packages (created after installation)
  │   ├── base-*.tar.gz               # Base package
  │   ├── shared-*.tar.gz             # Shared resources
  │   ├── *-*.tar.gz                  # Map packages
  │   └── manifest-*.json             # Package manifest
  ├── src/
  │   ├── robot_mc/
  │   ├── robot_mujoco/
  │   └── UeSim/
  └── README.md                    # Project documentation
  ```

  ---

  ## ⚙️ Environment Dependencies

  - **Operating System:** Ubuntu 22.04  
  - **Recommended GPU:** NVIDIA RTX 4060 or above  
  - **Unreal Engine:** Integrated (no separate installation required)  
  - **Build Environment:**  
    - GCC/G++ ≥ C++11  
    - CMake ≥ 3.16  
  - **MuJoCo:** 3.3.0 open-source version (integrated)  
  - **Remote Controller:** Required (Recommended: *Logitech Wireless Gamepad F710*)  
  - **Python Dependency:** `gdown`  

  ---

  ## 🚀 Installation & Build

  1. **LCM Installation**
     ```bash
     sudo apt update
     sudo apt install -y cmake-qt-gui gcc g++ libglib2.0-dev python3-pip
     ```
     Download the source code from [LCM Releases](https://github.com/lcm-proj/lcm/releases) and extract it.

     Build and install:
     ```bash
     cd lcm-<version>
     mkdir build
     cd build
     cmake ..
     make -j$(nproc)
     sudo make install
     ```
     > **Note:** Replace `<version>` with the actual extracted LCM directory name.

  2. **Clone MATRiX Repository**
     ```bash
     git clone https://github.com/Alphabaijinde/matrix.git
     cd matrix
     ```

  3. **Install Dependencies**
     ```bash
     ./scripts/build.sh
     ```
     *(This script will automatically install all required dependencies.)*

  4. **Install Chunk Packages (Modular Installation)**

     MATRiX uses a modular chunk package system that allows you to download only what you need:
     - **Base Package** (Required): Core files and EmptyWorld map
     - **Shared Resources** (Recommended): Shared resources used by multiple maps
     - **Map Packages** (Optional): Individual maps that can be downloaded on demand

     **Quick Installation:**
     ```bash
     bash scripts/release_manager/install_chunks.sh 0.0.4
     ```
     
     > 📖 **For Details:** For complete information about the chunk package system, including package sizes, map list, installation verification, and FAQs, see the [Chunk Packages Guide](docs/CHUNK_PACKAGES_GUIDE.md).

     **Alternative: Manual Download from Cloud Storage**
     
     If you prefer to download the full package from cloud storage:
     - **Google Drive**: [Download Link](https://drive.google.com/file/d/1mxIU5sj0l6S4mHeCyCVg5Bx84nmDWg8R/view?usp=sharing)
       ```bash
       pip install gdown
       gdown https://drive.google.com/uc?id=1WMtHqtJEggjgTk0rOcwO6m99diUlzq_J
       unzip <downloaded_filename>
       ```
     - **Baidu Netdisk**: [Download Link](https://pan.baidu.com/s/15he0Yr2iqP6Ko0vN-pioOg?pwd=hgea)
     - **JFrog**:
       ```bash
       curl -H "Authorization: Bearer cmVmdGtuOjAxOjE3ODQ2MDY4OTQ6eFJvZVA5akpiMmRzTFVwWXQ3YWRIbTI3TEla" -o "matrix.zip" -# "http://192.168.50.40:8082/artifactory/jszrsim/UeSim/matrix.zip"
       unzip matrix.zip
       ```

  ---

  ## 🛠️ Script Usage Guide

  MATRiX provides various scripts to help you build, install, and run the simulator. Here's how to use them effectively:

  ### 📋 Script Categories

  #### **User Scripts** (For End Users)

  | Script | Purpose | Usage |
  |--------|---------|-------|
  | `build.sh` | One-click build and dependency installation | `./scripts/build.sh` |
  | `run_sim.sh` | Launch simulation | `./scripts/run_sim.sh <robot_type> <map_id>` |
  | `install_chunks.sh` | Download and install chunk packages from GitHub | `bash scripts/release_manager/install_chunks.sh <version>` |
  | `install_chunks_local.sh` | Install chunk packages from local releases/ directory | `bash scripts/release_manager/install_chunks_local.sh <version>` |

  #### **Developer Scripts** (For Contributors)

  | Script | Purpose | Usage |
  |--------|---------|-------|
  | `build_mc.sh` | Build MC control module | `./scripts/build_mc.sh` |
  | `build_mujoco_sdk.sh` | Build MuJoCo SDK | `./scripts/build_mujoco_sdk.sh` |
  | `package_chunks_for_release.sh` | Package chunks for release | `bash scripts/release_manager/package_chunks_for_release.sh <version>` |
  | `upload_to_release.sh` | Upload packages to GitHub Releases (with auto-consistency check and publish) | `bash scripts/release_manager/upload_to_release.sh <version>` |
  | `commit_and_push.sh` | Commit and push chunk package changes | `bash scripts/release_manager/commit_and_push.sh <version>` |
  | `split_large_file.sh` | Split large files (>2GB) for GitHub | `bash scripts/release_manager/split_large_file.sh <file_path>` |

  ### 🚀 Typical Workflows

  #### **First-Time Setup (New User)**

  ```bash
  # 1. Clone the repository
  git clone https://github.com/Alphabaijinde/matrix.git
  cd matrix

  # 2. Install dependencies and build
  ./scripts/build.sh

  # 3. Install chunk packages (download from GitHub)
  bash scripts/release_manager/install_chunks.sh 0.0.4
  # → Selectively choose maps to download
  # → Files are saved to releases/ directory
  # → Packages are automatically installed to src/UeSim/Linux/jszr_mujoco_ue/

  # 4. Run simulation
  ./scripts/run_sim.sh 0 0  # EmptyWorld with default robot
  ```

  #### **Offline Installation (No Internet)**

  ```bash
  # 1. On a machine with internet, download packages
  bash scripts/release_manager/install_chunks.sh 0.0.4

  # 2. Copy the releases/ directory to offline machine

  # 3. On offline machine, install from local files
  bash scripts/release_manager/install_chunks_local.sh 0.0.4
  # → Installs all packages from releases/ directory
  ```

  #### **Adding More Maps Later**

  ```bash
  # Option 1: Download and install new maps
  bash scripts/release_manager/install_chunks.sh 0.0.4
  # → Select additional maps to download

  # Option 2: If files already in releases/, just install
  bash scripts/release_manager/install_chunks_local.sh 0.0.4
  # → Installs all available maps from releases/
  ```

  #### **Reinstalling Packages**

  ```bash
  # Quick reinstall from local releases/ directory
  bash scripts/release_manager/install_chunks_local.sh 0.0.4
  # → No download needed, fast installation
  ```

  ### 💡 Script Selection Guide

  **When to use `install_chunks.sh`:**
  - ✅ First-time installation
  - ✅ Need to download latest version from GitHub
  - ✅ Want to selectively choose maps to download
  - ✅ Have internet connection

  **When to use `install_chunks_local.sh`:**
  - ✅ Files already downloaded to `releases/` directory
  - ✅ Offline installation (no internet)
  - ✅ Quick reinstall of existing packages
  - ✅ Want to install all available maps automatically

  ### 📁 Understanding File Locations

  ```
  matrix/
  ├── releases/                    # Downloaded packages (created after install_chunks.sh)
  │   ├── base-0.0.4.tar.gz       # Base package
  │   ├── shared-0.0.4.tar.gz     # Shared resources
  │   └── *.tar.gz                # Map packages
  │
  └── src/UeSim/Linux/jszr_mujoco_ue/  # Runtime directory (where packages are installed)
      └── Content/Paks/            # Installed chunk files (.pak, .ucas, .utoc)
  ```

  **Key Points:**
  - `releases/` = Storage for downloaded packages (source files)
  - `src/UeSim/Linux/jszr_mujoco_ue/Content/Paks/` = Runtime location (installed files)
  - `install_chunks.sh` downloads to `releases/` AND installs to runtime directory
  - `install_chunks_local.sh` only installs from `releases/` to runtime directory

  > **Tip:** Keep files in `releases/` directory for future use. You can delete them to save space, but you'll need to re-download if you want to reinstall.

  ---

  ## 🗺️ Map ID Reference

  When using `run_sim.sh`, you can specify maps by ID:

  | Map ID | Map Name | Description |
  |--------|----------|-------------|
  | 0 | CustomWorld | Custom map |
  | 1 | Warehouse | Warehouse environment |
  | 2 | Town10World | Town10 map |
  | 3 | YardWorld | Yard environment |
  | 4 | CrowdWorld | Crowd simulation |
  | 5 | VeniceWorld | Venice map |
  | 6 | HouseWorld | House environment |
  | 7 | RunningWorld | Running track |
  | 8 | Town10Zombie | Town10 with zombies |
  | 9 | IROSFlatWorld | IROS flat terrain |
  | 10 | IROSSlopedWorld | IROS sloped terrain |
  | 11 | IROSFlatWorld2025 | IROS flat terrain 2025 |
  | 12 | IROSSloppedWorld2025 | IROS sloped terrain 2025 |
  | 13 | OfficeWorld | Office environment |
  | 14 | 3DGSWorld | 3D Gaussian Splatting world |
  | 15 | MoonWorld | Moon environment |

  **Usage Examples:**
  ```bash
  ./scripts/run_sim.sh 1 1   # XGB robot, Warehouse map
  ./scripts/run_sim.sh 4 4   # GO2 robot, CrowdWorld map
  ./scripts/run_sim.sh 1 0   # XGB robot, CustomWorld map
  ```

  > **Note:** EmptyWorld is the default map included in the base package and configured via `DefaultEngine.ini`. It is not run via map ID, but serves as the engine's default startup map.

  ---

  ## 🔍 Troubleshooting

  ### Common Issues

  **1. "jszr_mujoco executable not found" Error**
  
  **Solution:**
  ```bash
  # Make sure you have built the MuJoCo SDK
  ./scripts/build_mujoco_sdk.sh
  
  # Verify the executable exists
  ls -lh src/robot_mujoco/simulate/build/jszr_mujoco
  ```

  **2. "Build directory does not exist" Error**
  
  **Solution:**
  ```bash
  # The build script should create the directory, but if it doesn't:
  mkdir -p src/robot_mujoco/simulate/build
  cd src/robot_mujoco/simulate
  cmake -S . -B build
  cmake --build build -j$(nproc)
  ```

  **3. Simulation Fails to Start**
  
  **Check:**
  - Ensure all chunk packages are installed: `ls src/UeSim/Linux/jszr_mujoco_ue/Content/Paks/`
  - Check log files: `cat src/robot_mujoco/simulate/build/robot_mujoco.log`
  - Verify UE5 executable exists: `ls src/UeSim/Linux/jszr_mujoco_ue/Binaries/Linux/`

  **4. Missing Map Files**
  
  **Solution:**
  ```bash
  # Reinstall missing maps
  bash scripts/release_manager/install_chunks.sh 0.0.4
  # Select the missing maps when prompted
  ```

  ---

  ## 🏞️ Demo Environments

  <div align="center">

  | **Map**         | **Demo Screenshot**                          | **Map**         | **Demo Screenshot**                          |
  |:---------------:|:-------------------------------------------:|:---------------:|:-------------------------------------------:|
  | **Venice**      | <img src="demo_gif/Venice.gif" alt="Matrix Demo Screenshot" width="350" height="200"/> | **Warehouse**   | <img src="demo_gif/whmap.gif" alt="Matrix Warehouse Demo" width="350" height="200"/> |
  | **Town10**      | <img src="demo_gif/Town10.gif" alt="Matrix Town Demo" width="350" height="200"/>       | **Yard**        | <img src="demo_gif/Yardmap.gif" alt="Matrix Yardmap Demo" width="350" height="200"/> |

  </div>

  > **Note:** The above screenshots showcase high-fidelity UE5 rendering for robotics and reinforcement learning experiments.

  ---

  ## ▶️ Running the Simulation

  <div align="center">
    <img src="demo_gif/Launcher.png" alt="Simulation Running Example" width="50%" />
  </div>

  ## 🐕 Simulation Setup Guide

  1. **Select Robot Type**  
    Choose the type of quadruped robot for the simulation.

  2. **Select Environment**  
    Pick the desired simulation environment or map.

  3. **Choose Control Device**  
    Select your preferred control device:  
    - **Gamepad Control**  
    - **Keyboard Control**

  4. **Enable Headless Mode (Optional)**  
    Toggle the **Headless Mode** option for running the simulation without a graphical interface.

  5. **Launch Simulation**  
    Click the **Launch Simulation** button to start the simulation.

  During simulation, if the UE window is active, you can press **ALT + TAB** to switch out of it.  
  Then, use the control-mode toggle button on the launcher to switch between gamepad and keyboard control at any time.
  ## 🎮 Remote Controller Instructions (Gamepad Control Guide)

  | Action                              | Controller Input                        |
  |--------------------------------------|-----------------------------------------|
  | Stand / Sit                         | Hold **LB** + **Y**                     |
  | Move Forward / Back / Left / Right  | **Left Stick** (up / down / left / right)|
  | Rotate Left / Right                 | **Right Stick** (left / right)          |
  | Jump Forward                        | Hold **RB** + **Y**                     |
  | Jump in Place                       | Hold **RB** + **X**                     |
  | Somersault                          | Hold **RB** + **B**                     |

  
  ## ⌨️ Remote Controller Instructions (Keyboard Control Guide)

  | Action                              | Controller Input                        |
  |--------------------------------------|-----------------------------------------|
  | Stand                               | U                                       |
  | Sit                                 | Space                                   |
  | Move Forward / Back / Left / Right  | W / S / A / D                           |
  | Rotate Left / Right                 | Q / E                                   |

  Press the **V** key to toggle between free camera and robot view.  
  Hold the **left mouse button** to temporarily switch to free camera mode.

  ---

  ## 🔧 Configuration Guide

  ### Adjust Sensor Configuration

  Edit:
  ```bash
  vim src/UeSim/Linux/jszr_mujoco_ue/Content/model/config/config.json
  ```

  Example snippet:
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

- Adjust **pose** and **number of sensors** as needed  
- Remove unused sensors to improve **UE FPS performance**

---

  ## 📡 Sensor Data Post-processing

  - The depth camera outputs images as `sensor_msgs::msg::Image` with **32FC1 encoding**.
  - To obtain a grayscale depth image, use the following code snippet:

  ```bash
    void callback(const sensor_msgs::msg::Image::SharedPtr msg)
    {
      cv::Mat depth_image;
      depth_image = cv::Mat(HEIGHT, WIDTH, CV_32FC1, const_cast<uchar*>(msg->data.data()));
    }
  ```

  ---




  ## 📡 Sensor Data Visualization in RViz

  To visualize sensor data in RViz:

  1. **Launch the simulation** as described above.
  2. **Start RViz**:
    ```bash
    rviz2
    ```
  3. **Load the configuration**:  
    Open `rviz/matrix.rviz` in RViz for a pre-configured view.

  <div align="center">
    <img src="./demo_gif/rviz2.png" alt="RViz Visualization Example" width="1280" height="720"/>
  </div>
  
  > **Tip:** Ensure your ROS environment is properly sourced and relevant topics are being published.

  ## 📋 TODO List

  - [x] IROS competition map
  - [ ] Support for third-party quadruped robot models
  - [ ] Add multi-robot simulation capabilities

  
  ---
  ## 🙏 Acknowledgements

  This project builds upon the incredible work of the following open-source projects:

  - [MuJoCo-Unreal-Engine-Plugin](https://github.com/oneclicklabs/MuJoCo-Unreal-Engine-Plugin)  
  - [MuJoCo](https://github.com/google-deepmind/mujoco)  
  - [Unreal Engine](https://github.com/EpicGames/UnrealEngine)
  - [CARLA](https://carla.org/)

  We extend our gratitude to the developers and contributors of these projects for their invaluable efforts in advancing robotics and simulation technologies.

  ---

  ## 📚 Documentation

  - [中文文档](docs/README_CN.md) - 中文使用指南
  - [Chunk Packages 使用指南](docs/CHUNK_PACKAGES_GUIDE.md) - 模块化打包部署说明
  - [机器人类型与地图选择](docs/README_1.md) - 详细的机器人类型和地图说明（含图片）
  - [自定义场景指南](docs/README_2.md) - 通过 JSON 文件创建自定义场景
  - [Git LFS 使用指南](docs/GIT_LFS_GUIDE.md) - 大文件管理指南（面向开发者）

  ---
