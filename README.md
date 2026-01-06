# MATRiX

<div align="center">
  <a href="#">
    <img alt="Forest" src="demo_gif/Forest.png" width="800" height="450"/>
  </a>
</div>

<div align="center">

[![English](https://img.shields.io/badge/Language-English-blue)](README.md)
[![中文](https://img.shields.io/badge/语言-中文-red)](docs/README_CN.md)

</div>

> **Last Updated:** 2026-01-06

MATRiX is an advanced simulation platform that integrates **MuJoCo**, **Unreal Engine 5**, and **CARLA** to provide high-fidelity, interactive environments for quadruped robot research. Its software-in-the-loop architecture enables realistic physics, immersive visuals, and optimized sim-to-real transfer for robotics development and deployment.

---

## 📂 Directory Structure

```text
matrix/
├── bin/                         # Executable binaries (created after build)
├── config/                      # System configuration files
│   └── config.json              # Core sensor and system settings
├── demo_gif/                    # Visual assets for documentation
│   ├── Maps/                    # Preview images for different maps
│   ├── Robot/                   # Preview images for supported robots
│   └── Scene/                   # Demos for custom scene setups
├── deps/                        # Third-party dependencies (.deb packages)
│   ├── ecal_*.deb               # eCAL communication library
│   ├── mujoco_*.deb             # MuJoCo simulation engine
│   └── ...                      # Other essential dependencies
├── docs/                        # Project documentation
│   ├── README_CN.md             # Chinese version of README
│   ├── CHUNK_PACKAGES_GUIDE.md  # Guide for modular chunk packages
│   └── ...                      # Development and maintenance guides
├── dynamicmaps/                 # Resources for dynamic map loading
├── releases/                    # Storage for downloaded chunk packages
│   ├── assets-*.tar.gz          # Assets package (binaries, models, libraries)
│   ├── base-*.tar.gz            # Base package (core files and default map)
│   ├── shared-*.tar.gz          # Shared resources for multiple maps
│   ├── *-*.tar.gz               # Individual map data packages
│   └── manifest-*.json          # Package version manifest
├── rviz/                        # ROS visualization (RViz) configurations
│   └── matrix.rviz              # Preconfigured RViz layout
├── scene/                       # Custom scene description files (JSON)
│   ├── scene.json               # Currently active scene configuration
│   └── scene_example_*.json     # Templates for custom scenes
├── scripts/                     # Utility and build scripts
│   ├── build.sh                 # One-click build and setup (Entry point)
│   ├── run_sim.sh               # Simulation launch script (CLI)
│   ├── install_deps.sh          # Dependency installation tool
│   └── release_manager/         # Release and package management tools
├── src/                         # Source code
│   ├── robot_mc/                # Motion control core logic
│   ├── robot_mujoco/            # MuJoCo simulation interface
│   └── UeSim/                   # Unreal Engine high-fidelity interface
├── LICENSE                      # Project license
└── README.md                    # Project documentation (this file)
```

---

## ⚙️ Environment Dependencies

- **Operating System:** Ubuntu 22.04
- **Recommended GPU:** NVIDIA RTX 4060 or above (**NVIDIA Driver >= 535** recommended)
- **Unreal Engine:** Integrated (no separate installation required)
- **Build Environment:**
  - GCC/G++ ≥ C++11
  - CMake ≥ 3.16
- **MuJoCo:** 3.3.0 open-source version (integrated)
- **Remote Controller:** Required (Recommended: *Logitech Wireless Gamepad F710*)
- **Python Dependency:** `gdown` (for downloading chunk packages from Google Drive)
- **ROS Dependency:** `ROS_humble`

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
   git clone https://github.com/zsibot/matrix.git
   cd matrix
   ```

3. **Install Dependencies**
   ```bash
   ./scripts/build.sh
   ```
   *(This script will automatically install all required dependencies.)*

4. **Install Chunk Packages (Modular Installation)**

   MATRiX uses a modular chunk package system that allows you to download only what you need:

   - **Assets Package** (Required): Runtime binaries, shared libraries, ONNX models, 3D models, and other essential files
   - **Base Package** (Required): Core files and EmptyWorld map
   - **Shared Resources** (Recommended): Shared resources used by multiple maps
   - **Map Packages** (Optional): Individual maps that can be downloaded on demand

   **Quick Installation:**

   ```bash
   bash scripts/release_manager/install_chunks.sh 0.1.1
   ```

   > 📖 **For Details:** For complete information about the chunk package system, including package sizes, map list, installation verification, and FAQs, see the [Chunk Packages Guide](docs/CHUNK_PACKAGES_GUIDE.md).

   **Alternative: Manual Installation (via Cloud Storage)**

   If GitHub access is slow, follow these steps to install manually:

   1. **Download** the package archive:
      - **Google Drive**: [Download Link](https://drive.google.com/file/d/1e_WjFg_MJgF4X-tqR9KyjC7h1rQiMQqN/view?usp=sharing)
      - **Baidu Netdisk**: [Download Link](https://pan.baidu.com/s/1o-7lICRBvshj--zq3OBTNA?pwd=nwjy)
   2. **Extract** all `.tar.gz` and `.json` files into the `matrix/releases/` directory.
   3. **Install** using the local script:
      ```bash
      bash scripts/release_manager/install_chunks_local.sh 0.1.1
      ```

      > ⚠️ **Important:** Ensure all files (base, assets, shared, etc.) are placed directly in `matrix/releases/` before running the installation script.

---

## ▶️ Running the Simulation

<div align="center">
  <img src="demo_gif/Launcher.png" alt="Simulation Running Example" width="640" height="360"/>
</div>

## 🐕 Simulation Setup Guide

1. **Run the launcher**
   ```bash
   cd matrix
   ./bin/sim_launcher
   ```
2. **Select Robot Type**
   Choose the type of quadruped robot for the simulation.

3. **Select Environment**
   Pick the desired simulation environment or map.

4. **Choose Control Device**
   Select your preferred control device:
   - **Gamepad Control**
   - **Keyboard Control**

5. **Enable Headless Mode (Optional)**
   Toggle the **Headless Mode** option for running the simulation without a graphical interface.

6. **Launch Simulation**
   Click the **Launch Simulation** button to start the simulation.

During simulation, if the UE window is active, you can press **ALT + TAB** to switch out of it.
Then, use the control-mode toggle button on the launcher to switch between gamepad and keyboard control at any time.

## 🎮 Remote Controller Instructions (Gamepad Control Guide)

| Action                              | Controller Input                        |
|--------------------------------------|-----------------------------------------|
| Stand / Sit                         | Hold **LB** + **Y**                     |
| Move Forward / Back / Left / Right  | **Left Stick** (up/down/left/right)      |
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
| Start                               | Enter                                   |

Press the **V** key to toggle between free camera and robot view.

Hold the **left mouse button** to temporarily switch to free camera mode.

---

## 🏞️ Demo Environments

<div align="center">

| **Map**         | **Demo Screenshot**                          | **Map**         | **Demo Screenshot**                          |
|:---------------:|:-------------------------------------------:|:---------------:|:-------------------------------------------:|
| **Venice**      | <img src="demo_gif/Venice.gif" alt="Matrix Demo Screenshot" width="350" height="200"/> | **Warehouse**   | <img src="demo_gif/whmap.gif" alt="Matrix Warehouse Demo" width="350" height="200"/> |
| **Town10**      | <img src="demo_gif/Town10.gif" alt="Matrix Town Demo" width="350" height="200"/>       | **Yard**        | <img src="demo_gif/Yardmap.gif" alt="Matrix Yardmap Demo" width="350" height="200"/> |

</div>

> **Note:** [Map Descriptions](docs/README_1.md).

> **Note:** The above screenshots showcase high-fidelity UE5 rendering for robotics and reinforcement learning experiments.

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
| `upload_to_release.sh` | Upload packages to GitHub Releases (with auto-consistency check and publish) | `bash scripts/release_manager/upload_to_release.sh <version>` |
| `split_large_files.sh` | Split large files (>2GB) for GitHub | `bash scripts/release_manager/split_large_files.sh <file_path>` |

#### **Offline Installation (No Internet)**

```bash
# 1. On a machine with internet, download packages
bash scripts/release_manager/install_chunks.sh 0.1.1

# 2. Copy the releases/ directory to offline machine

# 3. On offline machine, install from local files
bash scripts/release_manager/install_chunks_local.sh 0.1.1
# → Installs assets package (required) and all other packages from releases/ directory
```

#### **Adding More Maps Later**

```bash
# Option 1: Download and install new maps
bash scripts/release_manager/install_chunks.sh 0.1.1
# → Select additional maps to download

# Option 2: If files already in releases/, just install
bash scripts/release_manager/install_chunks_local.sh 0.1.1
# → Installs assets package (if needed) and all available maps from releases/
```

#### **Reinstalling Packages**

```bash
# Quick reinstall from local releases/ directory
bash scripts/release_manager/install_chunks_local.sh 0.1.1
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

```text
matrix/
├── releases/                    # Downloaded packages (created after install_chunks.sh)
│   ├── assets-0.1.1.tar.gz     # Assets package (required)
│   ├── base-0.1.1.tar.gz       # Base package (required)
│   ├── shared-0.1.1.tar.gz     # Shared resources (recommended)
│   └── *.tar.gz                # Map packages (optional)
│
└── src/UeSim/Linux/zsibot_mujoco_ue/  # Runtime directory (where packages are installed)
    └── Content/Paks/            # Installed chunk files (.pak, .ucas, .utoc)
```

**Key Points:**
- `matrix/releases/` = Storage for downloaded packages (source files)
- `src/UeSim/Linux/zsibot_mujoco_ue/Content/Paks/` = Runtime location (installed files)
- `install_chunks.sh` downloads to `matrix/releases/` AND installs to runtime directory
- `install_chunks_local.sh` only installs from `matrix/releases/` to runtime directory

> **Tip:** Keep files in `matrix/releases/` directory for future use. You can delete them to save space, but you'll need to re-download if you want to reinstall.

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

---

## 🔧 Configuration Guide

### Custom scene setup
- Write your custom scene in a json file following the existing format in `matrix/scene/`, details in [Tutorial Doc](docs/README_2.md).
- Place your custom scene file in the `matrix/scene/scene.json` file.
- Select the custom map from the launcher to load it in the simulation.

### Adjust Sensor Configuration

Edit:
```bash
vim matrix/config/config.json
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

```cpp
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

- [x] IROS competition map(4 maps)
- [x] Support for third-party quadruped robot models
- [x] Support for custom scene based on json file
- [x] Add 3DGS reconstruction Map
- [x] Add Moon map based on dynamic ground
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

- [Chinese Documentation](docs/README_CN.md) - User Guide in Chinese
- [Chunk Packages Guide](docs/CHUNK_PACKAGES_GUIDE.md) - Modular package deployment guide
- [Robot Types & Maps](docs/README_1.md) - Detailed descriptions of robots and maps
- [Custom Scene Guide](docs/README_2.md) - Creating custom scenes with JSON files

---
