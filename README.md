<h1>
  <a href="#"><img alt="Forest" src="demo_gif/Forest.png" width="100%"/></a>
  </h1>

# MATRIX
MATRIX is an advanced simulation platform that integrates **MuJoCo**, **Unreal Engine 5**, and **CARLA** to provide high-fidelity, interactive environments for quadruped robot research. Its software-in-the-loop architecture enables realistic physics, immersive visuals, and optimized sim-to-real transfer for robotics development and deployment.

  ---

  ## 📂 Directory Structure

  ```text
  ├── deps/                        # Third-party dependencies
  │   ├── ecal_5.13.3-1ppa1~jammy_amd64.deb
  │   ├── mujoco_3.3.0_x86_64_Linux.deb
  │   ├── onnx_1.51.0_x86_64_jammy_Linux.deb
  │   └── zsibot_common*.deb
  ├── scripts/                     # Build and configuration scripts
  │   ├── build_mc.sh
  │   ├── build_mujoco_sdk.sh
  │   ├── download_uesim.sh
  │   ├── install_deps.sh
  │   └── modify_config.sh
  ├── src/
  │   ├── robot_mc/
  │   ├── robot_mujoco/
  │   ├── navigo/
  │   └── UeSim/
  ├── build.sh                     # One-click build script
  ├── run_sim.sh                   # Simulation launch script
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

  2. **Download the UE simulator**

     - **Method 1: Google Drive**  
       [Google Drive Download Link](https://drive.google.com/drive/folders/1JN9K3m6ZvmVpHY9BLk4k_Yj9vndyh8nT?usp=sharing)

       **Download via gdown:**
       ```bash
       pip install gdown
       gdown https://drive.google.com/uc?id=1Xp7ZQrFeQO6ijKAKw5uRmbMAHoPuG-Yg
       ```

     - **Method 2: Baidu Netdisk**  
       [Baidu Netdisk Link](https://pan.baidu.com/s/1V2GsUptFS-pkpU_2ckcg4A?pwd=utjn)  

     - **Method 3: JFrog**  
       ```bash
       curl -H "Authorization: Bearer cmVmdGtuOjAxOjE3ODQ2MDY4OTQ6eFJvZVA5akpiMmRzTFVwWXQ3YWRIbTI3TEla"  -o "matrix.zip" -# "http://192.168.50.40:8082/artifactory/jszrsim/UeSim/matrix.zip"  
       ```

  3. **Unzip**
     ```bash
     unzip <downloaded_filename>
     ```

  4. **Install Dependencies**
     ```bash
     cd matrix
     ./build.sh
     ```
     *(This script will automatically install all required dependencies.)*

  ---

  ## 🏞️ Demo Environments

  <div align="center">

  <table>
    <tr>
      <th>Map</th>
      <th>Demo Screenshot</th>
      <th>Map</th>
      <th>Demo Screenshot</th>
    </tr>
    <tr>
      <td><b>Start Map</b></td>
      <td><img src="demo_gif/start_map.png" alt="Matrix Demo Screenshot" width="350" height="200"/></td>
      <td><b>Warehouse</b></td>
      <td><img src="demo_gif/whmap.gif" alt="Matrix Warehouse Demo" width="350" height="200"/></td>
    </tr>
    <tr>
      <td><b>Town10</b></td>
      <td><img src="demo_gif/Town10.gif" alt="Matrix Town Demo" width="350" height="200"/></td>
      <td><b>Yard</b></td>
      <td><img src="demo_gif/Yardmap.gif" alt="Matrix Yardmap Demo" width="350" height="200"/></td>
    </tr>
  </table>

  </div>

  > **Note:** The above screenshots showcase high-fidelity UE5 rendering for robotics and reinforcement learning experiments.

  ---

  ## ▶️ Running the Simulation

  ### Headless Mode

  ```bash
  ./run_sim.sh MapId offrender # example: ./run_sim.sh 1 offrender
  ```
  - MuJoCo physics simulation window pops up  
  - Unreal Engine runs in the background  
  - Use ROS tools to view images:
    ```bash
    sudo apt install ros-humble-image-transport*
    rqt
    ```

  ### Rendering Mode

  ```bash
  ./run_sim.sh MapId  # example: ./run_sim.sh 1 
  ```
  - UE visualization window pops up  
  - MuJoCo physics simulation window pops up  

  | MapId | Map Name      |
  |-------|--------------|
  | 1     | **warehouse** |
  | 2     | **town10**    |
  | 3     | **yard**      |
  | 4     | **crowd**     |
  | 5     | **venice**    |
  | 6     | **apartment** |
  | 7     | **house**     |

  ---

  ## 🎮 Remote Controller Instructions

  | Action                              | Controller Input                        |
  |--------------------------------------|-----------------------------------------|
  | Stand / Sit                         | Hold **LB** + **Y**                     |
  | Move Forward / Back / Left / Right  | **Left Stick** (up / down / left / right)|
  | Rotate Left / Right                 | **Right Stick** (left / right)          |
  | Jump Forward                        | Hold **RB** + **Y**                     |
  | Jump in Place                       | Hold **RB** + **X**                     |
  | Somersault                          | Hold **RB** + **B**                     |

  Press the **V** key to toggle between free camera and robot view.  
  Hold the **left mouse button** to temporarily switch to free camera mode.

  ---

  ## 🔧 Configuration Guide

  ### Adjust Sensor Configuration

  Edit:
  ```bash
  vim matrix/src/UeSim/jszr_mujoco_ue/Content/model/config/config.json
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
      "position": { "x": 29.0,
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

- Depth camera publishes in `sensor_msgs::msg::CompressedImage` with **MONO8 encoding**  
- Convert to a single-channel grayscale (`int8`) image  
- Depth values are calculated as:  

```math
depth = pixel_value / 20
```

### Example Conversion Code
```cpp
void callback(const sensor_msgs::msg::CompressedImage::SharedPtr msg)
{
    cv_bridge::CvImagePtr cv_ptr;
    try {
        cv_ptr = cv_bridge::toCvCopy(msg, sensor_msgs::image_encodings::MONO8);
    } catch (cv_bridge::Exception & e) {
        RCLCPP_ERROR(this->get_logger(), "Image conversion failed: %s", e.what());
        return;
    }
    cv_ptr->image = cv_ptr->image / 20.0;
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

  > **Tip:** Ensure your ROS environment is properly sourced and relevant topics are being published.

  <div align="center">
    <img src="./demo_gif/rviz2.png" alt="RViz Visualization Example" width="1280" height="720"/>
  </div>

  ---
