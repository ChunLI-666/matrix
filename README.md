<h1>
  <a href="#"><img alt="Forest" src="demo_gif/Forest.png" width="100%"/></a>
</h1>

# MATRiX
MATRiX is an advanced simulation platform that integrates **MuJoCo**, **Unreal Engine 5**, and **CARLA** to provide high-fidelity, interactive environments for quadruped robot research. Its software-in-the-loop architecture enables realistic physics, immersive visuals, and optimized sim-to-real transfer for robotics development and deployment.

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
  ├── docs/                        # Documentation and guides
  ├── config/                      # Robot and sensor configuration files
  ├── scene/                       # Custom scene files
  ├── dynamicmaps/                # Dynamic ground bin files
  ├── src/
  │   ├── robot_mc/
  │   ├── robot_mujoco/
  │   ├── navigo/
  │   └── UeSim/
  ├── build.sh                     # One-click build script
  ├── run_sim.sh                   # Simulation launch script
  ├── sim_launcher                 # Launcher UI
  ├── README_CN.md                 # Chinese Project documentation
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

  2. **Download MATRiX simulator**

     - **Method 1: Google Drive**  
       [Google Drive Download Link](https://drive.google.com/file/d/1UUepVneqrK2r_-5a1rUPmYd5wiqWbBp0/view?usp=sharing)

       **Download via gdown:**
       ```bash
       pip install gdown
       gdown https://drive.google.com/uc?id=1UUepVneqrK2r_-5a1rUPmYd5wiqWbBp0
       ```
       
     - **Method 2: Baidu Netdisk**  
       [Baidu Netdisk Link](https://pan.baidu.com/s/1thnDgDfQkmIqxnt-_7C4Cw?pwd=sicu)  


      > **Note:** When downloading from the cloud storage links, please ensure you select the latest version for the best compatibility and features.

      > **Previous version link**: [Link](https://drive.google.com/drive/folders/1JN9K3m6ZvmVpHY9BLk4k_Yj9vndyh8nT?usp=sharing)


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

  | **Map**         | **Demo Screenshot**                          | **Map**         | **Demo Screenshot**                          |
  |:---------------:|:-------------------------------------------:|:---------------:|:-------------------------------------------:|
  | **Venice**      | <img src="demo_gif/Venice.gif" alt="Matrix Demo Screenshot" width="350" height="200"/> | **Warehouse**   | <img src="demo_gif/whmap.gif" alt="Matrix Warehouse Demo" width="350" height="200"/> |
  | **Town10**      | <img src="demo_gif/Town10.gif" alt="Matrix Town Demo" width="350" height="200"/>       | **Yard**        | <img src="demo_gif/Yardmap.gif" alt="Matrix Yardmap Demo" width="350" height="200"/> |

  </div>

  > **Note:** [Map Descriptions](docs/README_1.md).

  > **Note:** The above screenshots showcase high-fidelity UE5 rendering for robotics and reinforcement learning experiments.

  ---

  ## ▶️ Running the Simulation

  <div align="center">
    <img src="demo_gif/Launcher.png" alt="Simulation Running Example" width="50%" />
  </div>

  ## 🐕 Simulation Setup Guide

  1. **Run the launcher**
  ```bash
      cd matrix
      ./sim_launcher
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
  | Start                               | Enter                                   |

  Press the **V** key to toggle between free camera and robot view.  

  Hold the **left mouse button** to temporarily switch to free camera mode.

  ---

  ## 🔧 Configuration Guide

  ### Custom scene setup
  - Write your custom scene in a json file following the existing format in `matrix/scene/`, details in [doc](docs/README_2.md).
  - Place your custom scene file in the `matrix/scene/` directory.
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
