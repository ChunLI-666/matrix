#!/bin/bash
UE_TRUE_SCRIPT_NAME=$(echo \"$0\" | xargs readlink -f)
UE_PROJECT_ROOT=$(dirname "$UE_TRUE_SCRIPT_NAME")
chmod +x "$UE_PROJECT_ROOT/zsibot_mujoco_ue/Binaries/Linux/zsibot_mujoco_ue-Linux-Shipping"
"$UE_PROJECT_ROOT/zsibot_mujoco_ue/Binaries/Linux/zsibot_mujoco_ue-Linux-Shipping" zsibot_mujoco_ue "$@" 
