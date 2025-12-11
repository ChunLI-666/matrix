#!/bin/bash

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$PROJECT_ROOT"

USE_OFFSCREEN=0
if [[ "$3" == "offrender" ]]; then
    USE_OFFSCREEN=1
fi

SCENE="scene_terrain_wh.xml" # default
WEAPON="" # default
if [[ "$2" == "0" ]]; then
    SCENE="scene_terrain_custom.xml"
elif [[ "$2" == "1" ]]; then
    SCENE="scene_terrain_wh.xml"
elif [[ "$2" == "2" ]]; then
    SCENE="scene_terrain_t10.xml"
elif [[ "$2" == "3" ]]; then
    SCENE="scene_terrain_yard.xml"
elif [[ "$2" == "4" ]]; then
    SCENE="scene_terrain_crowd.xml"
elif [[ "$2" == "5" ]]; then
    SCENE="scene_terrain_venice.xml"
elif [[ "$2" == "7" ]]; then
    SCENE="scene_terrain_rw.xml"
elif [[ "$2" == "6" ]]; then
    SCENE="scene_terrain_house.xml"
elif [[ "$2" == "9" ]]; then
    SCENE="scene_terrain_flat.xml"
elif [[ "$2" == "10" ]]; then
    SCENE="scene_terrain_sloped.xml"
elif [[ "$2" == "8" ]]; then
    SCENE="scene_terrain_zombie.xml"
    WEAPON="gun"
elif [[ "$2" == "11" ]]; then
    SCENE="scene_terrain_flat25.xml"
elif [[ "$2" == "12" ]]; then
    SCENE="scene_terrain_sloped25.xml"
elif [[ "$2" == "13" ]]; then
    SCENE="scene_terrain_office.xml"
elif [[ "$2" == "14" ]]; then
    SCENE="3dgs.xml"
elif [[ "$2" == "15" ]]; then
    SCENE="scene_terrain_moon_dynamic.xml"
    # Copy dynamic map data for moonworld
    if [ -f "$PROJECT_ROOT/dynamicmaps/moonworld.bin" ]; then
        cp "$PROJECT_ROOT/dynamicmaps/moonworld.bin" "$PROJECT_ROOT/src/robot_mujoco/simulate/build/DynamicMapData.bin"
        echo "[INFO] Copied moonworld.bin to DynamicMapData.bin"
    else
        echo "[WARNING] moonworld.bin not found at $PROJECT_ROOT/dynamicmaps/moonworld.bin"
    fi
else
    echo "[INFO] Unknown or empty scene id '$2', using default: $SCENE"
fi

sed -i "s/^robot_scene: .*/robot_scene: \"$SCENE\"/" "$PROJECT_ROOT/src/robot_mujoco/simulate/config.yaml"

# Set robot type in config.json
ROBOTTYPE="xgb" # default
MCROBOTTYPE="XG" # default
MCRUNNINGFLAG=0

TARGET_FILE="$PROJECT_ROOT/src/robot_mc/run_mc.sh"
if [[ "$1" == "1" || "$1" == "xgb" ]]; then
    echo "[INFO] Setting robot type to xgb"
    ROBOTTYPE="xgb"
    MCROBOTTYPE="XG"
    sed -i 's/export ROBOT_TYPE=.*/export ROBOT_TYPE=XG/' "$TARGET_FILE"
elif [[ "$1" == "2" ]]; then
    echo "[INFO] Setting robot type to xgw"
    ROBOTTYPE="xgw"
    MCROBOTTYPE="XGW"
    sed -i 's/export ROBOT_TYPE=.*/export ROBOT_TYPE=XGW/' "$TARGET_FILE"
elif [[ "$1" == "3" ]]; then
    echo "[INFO] Setting robot type to zgws"
    ROBOTTYPE="zgws"
    MCROBOTTYPE="ZGWS"
    sed -i 's/export ROBOT_TYPE=.*/export ROBOT_TYPE=ZGWS/' "$TARGET_FILE"
elif [[ "$1" == "4" ]]; then
    echo "[INFO] Setting robot type to go2"
    ROBOTTYPE="go2"
    MCROBOTTYPE="GO2"
    sed -i 's/export ROBOT_TYPE=.*/export ROBOT_TYPE=GO2/' "$TARGET_FILE"
    MCRUNNINGFLAG=1
elif [[ "$1" == "5" ]]; then
    echo "[INFO] Setting robot type to go2w"
    ROBOTTYPE="go2w"
    MCROBOTTYPE="GO2W"
    sed -i 's/export ROBOT_TYPE=.*/export ROBOT_TYPE=GO2W/' "$TARGET_FILE"
    MCRUNNINGFLAG=1
else
    echo "[INFO] Unknown or empty robot type '$1', using default: xgb"
fi

sed -i "s/^robot: .*/robot: \"$ROBOTTYPE\"/" "$PROJECT_ROOT/src/robot_mujoco/simulate/config.yaml"

# Update config.json (use root config/config.json if exists, otherwise use UeSim config)
if [ -f "$PROJECT_ROOT/config/config.json" ]; then
    # Update root config.json
    jq ".robot.robot_type = \"$ROBOTTYPE\" | .robot.weapon = \"$WEAPON\"" "$PROJECT_ROOT/config/config.json" > "$PROJECT_ROOT/tmp_config.json" && mv "$PROJECT_ROOT/tmp_config.json" "$PROJECT_ROOT/config/config.json"
    rm -f "$PROJECT_ROOT/tmp_config.json"
    
    # Copy config.json to UeSim directory
    cp "$PROJECT_ROOT/config/config.json" "$PROJECT_ROOT/src/UeSim/Linux/jszr_mujoco_ue/Content/model/config/config.json"
    
    # Read robot position from config.json and update XML file
    ROBOT_X=$(jq -r '.robot.position.x' "$PROJECT_ROOT/config/config.json")
    ROBOT_Y=$(jq -r '.robot.position.y' "$PROJECT_ROOT/config/config.json")
    
    XML_FILE="$PROJECT_ROOT/src/robot_mujoco/jszr_robots/${ROBOTTYPE}/${ROBOTTYPE}.xml"
    if [ -f "$XML_FILE" ]; then
        sed -i "s/<body name=\"base_link\" pos=\"[^\"]*\"/<body name=\"base_link\" pos=\"${ROBOT_X} ${ROBOT_Y} 0.65\"/" "$XML_FILE"
        echo "[INFO] Updated robot position to (${ROBOT_X}, ${ROBOT_Y}) in ${XML_FILE}"
    else
        echo "[WARNING] XML file not found: $XML_FILE"
    fi
    
    # Copy scene.json if exists
    if [ -f "$PROJECT_ROOT/scene/scene.json" ]; then
        cp "$PROJECT_ROOT/scene/scene.json" "$PROJECT_ROOT/src/UeSim/Linux/jszr_mujoco_ue/Content/model/SceneLoder/scene.json"
        echo "[INFO] Copied scene.json to UeSim directory"
    fi
else
    # Fallback to direct update of UeSim config.json
    if [ -f "$PROJECT_ROOT/src/UeSim/Linux/jszr_mujoco_ue/Content/model/config/config.json" ]; then
        jq ".robot.robot_type = \"$ROBOTTYPE\" | .robot.weapon = \"$WEAPON\"" "$PROJECT_ROOT/src/UeSim/Linux/jszr_mujoco_ue/Content/model/config/config.json" > "$PROJECT_ROOT/tmp_config.json" && mv "$PROJECT_ROOT/tmp_config.json" "$PROJECT_ROOT/src/UeSim/Linux/jszr_mujoco_ue/Content/model/config/config.json"
        rm -f "$PROJECT_ROOT/tmp_config.json"
    else
        echo "[WARNING] config.json not found in either location"
    fi
fi

echo "[INFO] Killing old processes if they exist..."

ps -ef | grep robot_mujoco | grep -v grep | awk '{print $2}' | xargs -r kill -9
pkill -f mc_ctrl && echo "[INFO] Killed mc_ctrl (run_mc.sh)" || echo "[INFO] mc_ctrl not running"
pkill -f jszr_mujoco_ue.sh && echo "[INFO] Killed robot_mujoco_ue.sh" || echo "[INFO] robot_mujoco_ue.sh not running"

sleep 1
echo "[INFO] Current working directory: $(pwd)"

# Check if build directory exists, if not, try to find the executable
MUJOCO_BUILD_DIR="$PROJECT_ROOT/src/robot_mujoco/simulate/build"
if [ ! -d "$MUJOCO_BUILD_DIR" ]; then
    echo "[WARNING] Build directory $MUJOCO_BUILD_DIR does not exist."
    echo "[INFO] Please build the project first using: ./scripts/build.sh"
    echo "[INFO] Or if the executable is elsewhere, please update the path in run_sim.sh"
    exit 1
fi

cd "$MUJOCO_BUILD_DIR" || { echo "cd $MUJOCO_BUILD_DIR failed"; exit 1; }
if [ ! -f "./jszr_mujoco" ]; then
    echo "[ERROR] jszr_mujoco executable not found in $MUJOCO_BUILD_DIR"
    echo "[INFO] Please build the project first using: ./scripts/build.sh"
    exit 1
fi
echo "[INFO] Starting robot_mujoco"
./jszr_mujoco > robot_mujoco.log 2>&1 &
PID_JSZR=$!

cd "$PROJECT_ROOT/src/robot_mc" || { echo "cd src/robot_mc failed"; exit 1; }
if [[ $MCRUNNINGFLAG -eq 0 ]]; then
    echo "[INFO] Starting run_mc.sh r (MC control enabled for robot type $ROBOTTYPE)"
    ./run_mc.sh r mc_enable=true > run_mc.log 2>&1 &
    PID_MC=$!
else
    echo "[INFO] MC control disabled for robot type $ROBOTTYPE"
    PID_MC=""
fi

cd "$PROJECT_ROOT/src/UeSim/Linux" || { echo "cd src/UeSim/Linux failed"; exit 1; }
echo "[INFO] Starting robot_mujoco_ue.sh"

if [[ $USE_OFFSCREEN -eq 1 ]]; then
    ./jszr_mujoco_ue.sh -RenderOffScreen > robot_mujoco_ue.log 2>&1 &
else
    ./jszr_mujoco_ue.sh > robot_mujoco_ue.log 2>&1 &
fi
PID_UESIM=$!

#cd "$PROJECT_ROOT/src/navigo" || { echo "cd src/navigo failed"; exit 1; }
#echo "[INFO] Starting ROS2 pub_tf.launch.py"
#source install/setup.bash
#ros2 launch pub_tf pub_tf.launch.py tf_type:=mujoco_tf > "$PROJECT_ROOT/pub_tf.log" 2>&1 &
#PID_PUBTF=$!

echo "[INFO] All started. Waiting for processes..."
if [ -n "$PID_MC" ]; then
    wait $PID_JSZR $PID_MC $PID_UESIM $PID_PUBTF
else
    wait $PID_JSZR $PID_UESIM $PID_PUBTF
fi
echo "[INFO] All processes exited."

trap "echo '[INFO] Caught SIGINT, killing all child processes...'; \
    kill -9 $PID_JSZR $PID_UESIM 2>/dev/null; \
    [ -n \"\$PID_MC\" ] && kill -9 \$PID_MC 2>/dev/null; \
    [ -n \"\$PID_PUBTF\" ] && kill -9 \$PID_PUBTF 2>/dev/null; \
    pkill -9 -f jszr_mujoco_ue.sh; \
    pkill -9 -f robot_mujoco; \
    pkill -9 -f mc_ctrl; \
    pkill -9 -f mujoco; \
    pkill -9 -f MuJoCo; \
    pkill -9 -f tf_manager; \
    wmctrl -c 'MuJoCo' 2>/dev/null; \
    wmctrl -c 'jszr_mujoco_ue' 2>/dev/null; \
    exit 1" SIGINT

trap "echo '[INFO] Caught SIGTERM, killing all child processes...'; \
    kill -9 $PID_JSZR $PID_UESIM 2>/dev/null; \
    [ -n \"\$PID_MC\" ] && kill -9 \$PID_MC 2>/dev/null; \
    [ -n \"\$PID_PUBTF\" ] && kill -9 \$PID_PUBTF 2>/dev/null; \
    pkill -9 -f jszr_mujoco_ue.sh; \
    pkill -9 -f robot_mujoco; \
    pkill -9 -f mc_ctrl; \
    pkill -9 -f mujoco; \
    pkill -9 -f MuJoCo; \
    pkill -9 -f tf_manager; \
    wmctrl -c 'MuJoCo' 2>/dev/null; \
    wmctrl -c 'jszr_mujoco_ue' 2>/dev/null; \
    exit 1" SIGTERM
