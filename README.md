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
  │   └── CHUNK_PACKAGES_GUIDE.md
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
  │       ├── upload_to_release.sh           # Upload packages to GitHub Releases
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

     **Automatic Installation (Recommended):**
     ```bash
     bash scripts/release_manager/install_chunks.sh 0.0.4
     ```
     
     The script will:
     - Download the base package (required)
     - Prompt you to download shared resources (recommended)
     - Let you select which maps to download interactively
     - Save all downloaded files to `releases/` directory for future use

     **Available Maps:**
     - SceneWorld, Town10World, YardWorld, CrowdWorld, VeniceWorld
     - RunningWorld, HouseWorld, IROSFlatWorld, IROSSlopedWorld
     - Town10Zombie, IROSFlatWorld2025, IROSSloppedWorld2025
     - OfficeWorld, Custom

     > **Note:** All downloaded packages are saved in the `releases/` directory. You can use `install_chunks_local.sh` to install additional maps later without re-downloading.

     **Alternative: Manual Download from Cloud Storage**
     
     If you prefer to download the full package from cloud storage:
     - **Google Drive**: [Download Link](https://drive.google.com/drive/folders/1JN9K3m6ZvmVpHY9BLk4k_Yj9vndyh8nT?usp=sharing)
       ```bash
       pip install gdown
       gdown https://drive.google.com/uc?id=1WMtHqtJEggjgTk0rOcwO6m99diUlzq_J
       unzip <downloaded_filename>
       ```
     - **Baidu Netdisk**: [Download Link](https://pan.baidu.com/s/1o8UEO1vUxPYmzeiiP9DYgg?pwd=hwqs)
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
  | `upload_to_release.sh` | Upload packages to GitHub Releases | `bash scripts/release_manager/upload_to_release.sh <version>` |
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

  ## 📦 Chunk Packages System

  MATRiX uses a modular chunk package system for flexible installation:

  - **Base Package** (Required): Core simulator files and EmptyWorld map
  - **Shared Resources** (Recommended): Shared assets used by multiple maps
  - **Map Packages** (Optional): Individual maps that can be downloaded on demand

  **Benefits:**
  - ✅ Download only what you need, saving storage space
  - ✅ Quick start with just the base package
  - ✅ Expand on demand by downloading specific maps
  - ✅ All packages cached in `releases/` directory for offline use

  **Installation:**
  ```bash
  # Download and install from GitHub Releases
  bash scripts/release_manager/install_chunks.sh 0.0.4

  # Or install from local releases/ directory (if already downloaded)
  bash scripts/release_manager/install_chunks_local.sh 0.0.4
  ```

  For more details, see [Chunk Packages Guide](docs/CHUNK_PACKAGES_GUIDE.md).

  ---
