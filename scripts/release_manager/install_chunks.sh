#!/bin/bash
set -e

# ============================================================================
# 安装Chunk包到运行目录
# 自动下载并组织文件到正确的目录结构
# 下载的文件会保存到 releases/ 目录，支持断点续传和进度显示
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 加载公共函数库
source "${SCRIPT_DIR}/common.sh"

VERSION="${1:-0.1.1}"
GITHUB_REPO="zsibot/matrix"
GITHUB_RELEASE_URL="https://github.com/${GITHUB_REPO}/releases/download/v${VERSION}"
TARGET_DIR="${PROJECT_ROOT}/src/UeSim/Linux/zsibot_mujoco_ue"
PAK_DIR="${TARGET_DIR}/Content/Paks"

# 检查并安装下载工具（优先多线程工具）
check_and_install_download_tools() {
    # 如果已有 aria2 或 axel，直接返回
    if command -v aria2c &> /dev/null || command -v axel &> /dev/null; then
        return 0
    fi
    
    # 如果没有多线程工具，尝试安装 aria2
    log "未找到多线程下载工具（aria2/axel），尝试安装 aria2 以提升下载速度..."
    
    # 检查是否有 sudo 权限（无需密码）
    if command -v sudo &> /dev/null && sudo -n true 2>/dev/null; then
        # 有 sudo 权限且无需密码，直接安装
        log "正在安装 aria2..."
        if sudo apt update -qq 2>/dev/null && sudo apt install -y aria2 2>/dev/null; then
            log "✓ aria2 安装成功"
            return 0
        fi
    elif [ "$EUID" -eq 0 ]; then
        # 已经是 root
        log "正在安装 aria2..."
        if apt update -qq 2>/dev/null && apt install -y aria2 2>/dev/null; then
            log "✓ aria2 安装成功"
            return 0
        fi
    else
        # 需要密码，询问用户
        log "需要 sudo 权限来安装 aria2（多线程下载工具，可显著提升下载速度）"
        read -p "是否现在安装 aria2? [Y/n]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            log "正在安装 aria2（可能需要输入密码）..."
            if sudo apt update && sudo apt install -y aria2; then
                log "✓ aria2 安装成功"
                return 0
            else
                log "⚠️  aria2 安装失败，将使用 wget/curl"
            fi
        else
            log "跳过 aria2 安装，将使用 wget/curl（下载速度可能较慢）"
        fi
    fi
    
    return 1
}

# 检查下载工具
check_and_install_download_tools

# 最终检查：至少需要一个下载工具
if ! command -v aria2c &> /dev/null && ! command -v axel &> /dev/null && ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
    error_exit "未找到任何下载工具。请安装: sudo apt install aria2 或 sudo apt install wget curl"
fi

# 获取代理设置（从 Git 配置）
get_proxy() {
    local proxy=$(git config --get http.proxy 2>/dev/null || echo "")
    echo "$proxy"
}

# 转换代理格式为 aria2c 兼容格式
normalize_proxy_for_aria2() {
    local proxy=$1
    if [ -z "$proxy" ]; then
        echo ""
        return
    fi
    
    # aria2c 支持 http://, https://, socks5:// 格式
    # 如果已经是完整格式，直接返回
    if [[ "$proxy" =~ ^(http|https|socks5):// ]]; then
        echo "$proxy"
    elif [[ "$proxy" =~ ^socks5h?:// ]]; then
        # socks5h 转换为 socks5
        echo "${proxy/socks5h/socks5}"
    else
        # 假设是 http 代理
        echo "http://${proxy#http://}"
    fi
}

# 验证文件完整性（大小和 SHA256）
verify_file_integrity() {
    local file="$1"
    local expected_size="$2"  # 可选：manifest 中的期望大小
    local expected_sha256="$3"  # 可选：manifest 中的期望 SHA256
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    # 验证文件大小
    if [ -n "$expected_size" ] && [ "$expected_size" != "0" ] && [ "$expected_size" != "null" ]; then
        local actual_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
        if [ "$actual_size" != "$expected_size" ]; then
            log "⚠️  文件大小不匹配: $(basename "$file") (期望: ${expected_size}, 实际: ${actual_size})"
            return 1
        fi
    fi
    
    # 验证 SHA256
    if [ -n "$expected_sha256" ] && [ "$expected_sha256" != "null" ]; then
        local actual_sha256=$(sha256sum "$file" 2>/dev/null | awk '{print $1}')
        if [ "$actual_sha256" != "$expected_sha256" ]; then
            log "⚠️  SHA256 校验失败: $(basename "$file")"
            log "  期望: ${expected_sha256}"
            log "  实际: ${actual_sha256}"
            return 1
        fi
        log "✓ SHA256 校验通过: $(basename "$file")"
    fi
    
    return 0
}

# 流式下载并解压（边下载边解压）
# 注意：为了显示下载进度，改为先下载到临时文件再解压
download_and_extract_stream() {
    local url=$1
    local extract_dir=$2
    local package_name=$3
    local expected_size="${4:-}"  # 可选：manifest 中的期望大小
    local expected_sha256="${5:-}"  # 可选：manifest 中的期望 SHA256
    
    log "下载并解压: $package_name"
    mkdir -p "$extract_dir"
    
    # 确定最终文件名
    local final_file="${DOWNLOAD_DIR}/$(basename "$url" | sed 's/?.*$//')"
    
    # 如果文件已存在，验证完整性
    if [ -f "$final_file" ]; then
        if verify_file_integrity "$final_file" "$expected_size" "$expected_sha256"; then
            log "文件已存在且完整，直接解压: $(basename "$final_file")"
            if tar -xzf "$final_file" -C "$extract_dir" 2>/dev/null; then
                return 0
            else
                log "文件解压失败，可能损坏，重新下载..."
                rm -f "$final_file"
            fi
        else
            log "文件已存在但完整性验证失败，重新下载..."
            rm -f "$final_file"
        fi
    fi
    
    # 获取代理设置
    local proxy=$(get_proxy)
    local proxy_args=""
    if [ -n "$proxy" ]; then
        if [[ "$proxy" =~ ^socks5:// ]]; then
            # wget 的 SOCKS5 代理格式
            proxy_args="--proxy=on --proxy-type=socks5 --proxy=${proxy#socks5://}"
        else
            proxy_args="--proxy=on --proxy=${proxy}"
        fi
    fi
    
    # 临时禁用 set -e
    set +e
    
    local download_exit=1
    
    # 优先使用多线程下载工具
    # 检查是否应该跳过 aria2c（SOCKS5 代理）
    local skip_aria2=false
    if [ -n "$proxy" ] && [[ "$proxy" =~ ^socks5 ]]; then
        skip_aria2=true
    fi
    
    if command -v aria2c &> /dev/null && [ "$skip_aria2" = false ]; then
        log "使用 aria2c 多线程下载..."
        local aria2_args=(-x 16 -s 16 --max-tries=3 --retry-wait=2 --continue=true)
        if [ -n "$proxy" ] && [[ "$proxy" =~ ^(http|https):// ]]; then
            # 对于 HTTP/HTTPS 代理，使用环境变量方式
            export ALL_PROXY="$proxy"
            export all_proxy="$proxy"
        fi
        aria2c "${aria2_args[@]}" -d "$DOWNLOAD_DIR" -o "$(basename "$final_file")" "$url"
        download_exit=$?
        unset ALL_PROXY all_proxy 2>/dev/null || true
        if [ $download_exit -eq 0 ]; then
            mv "${DOWNLOAD_DIR}/$(basename "$final_file")" "$final_file" 2>/dev/null || true
        fi
    elif [ "$skip_aria2" = true ]; then
        log "  ⚠️  aria2c 对 SOCKS5 代理支持不佳，改用 wget/curl..."
        download_exit=1  # 标记为失败，继续尝试其他工具
    fi
    
    # 如果 aria2c 失败或跳过，尝试其他工具
    if [ $download_exit -ne 0 ]; then
        # 对于 SOCKS5 代理，优先使用 curl（原生支持）
        if [ -n "$proxy" ] && [[ "$proxy" =~ ^socks5 ]] && command -v curl &> /dev/null; then
            log "使用 curl 下载（原生支持 SOCKS5 代理）..."
            local curl_args=(-L --progress-bar -C - --retry 5 --retry-delay 3 --retry-all-errors --connect-timeout 30 --max-time 3600 --ssl-no-revoke --proxy "$proxy")
            curl "${curl_args[@]}" -o "$final_file" "$url"
            download_exit=$?
        elif command -v axel &> /dev/null; then
            log "使用 axel 多线程下载..."
            local axel_args=(-n 16 -a)
            if [ -n "$proxy" ]; then
                axel_args+=("--proxy=${proxy}")
            fi
            axel "${axel_args[@]}" -o "$final_file" "$url"
            download_exit=$?
        elif command -v wget &> /dev/null; then
            log "使用 wget 下载（支持断点续传）..."
            local wget_args=(--continue --show-progress --timeout=30 --tries=3)
            if [ -n "$proxy" ]; then
                wget_args+=(--proxy=on)
                export http_proxy="$proxy"
                export https_proxy="$proxy"
            fi
            wget "${wget_args[@]}" -O "$final_file" "$url"
            download_exit=$?
            unset http_proxy https_proxy 2>/dev/null || true
        elif command -v curl &> /dev/null; then
            log "使用 curl 下载（支持断点续传）..."
            local curl_args=(-L --progress-bar -C - --retry 5 --retry-delay 3 --retry-all-errors --connect-timeout 30 --max-time 3600 --ssl-no-revoke)
            if [ -n "$proxy" ]; then
                curl_args+=(--proxy "$proxy")
            fi
            curl "${curl_args[@]}" -o "$final_file" "$url"
            download_exit=$?
        else
            log "ERROR: 未找到可用的下载工具"
            return 1
        fi
    fi
    
    # 重新启用 set -e
    set -e
    
    # 检查下载是否成功
    if [ $download_exit -ne 0 ]; then
        log "⚠️  下载失败 (退出码: $download_exit)"
        # 如果文件部分下载，保留以便断点续传
        if [ -f "$final_file" ] && [ -s "$final_file" ]; then
            log "文件已部分下载，保留以便下次续传"
        else
            rm -f "$final_file"
        fi
        return 1
    fi
    
    # 验证文件完整性（大小和 SHA256）
    if ! verify_file_integrity "$final_file" "$expected_size" "$expected_sha256"; then
        log "⚠️  文件完整性验证失败，删除损坏的文件..."
        rm -f "$final_file"
        return 1
    fi
    
    # 解压文件
    log "解压: $package_name"
    if tar -xzf "$final_file" -C "$extract_dir" 2>/dev/null; then
        return 0
    else
        log "⚠️  解压失败，文件可能损坏"
        return 1
    fi
}

# 下载文件到本地（用于分片文件等需要保存的情况）
download_file() {
    local url=$1
    local output=$2
    log "下载: $(basename "$output")"
    
    # 获取代理设置
    local proxy=$(get_proxy)
    
    # 临时禁用 set -e
    set +e
    
    local download_exit=1
    
    # 优先使用多线程下载工具
    # 检查是否应该跳过 aria2c（SOCKS5 代理）
    local skip_aria2=false
    if [ -n "$proxy" ] && [[ "$proxy" =~ ^socks5 ]]; then
        skip_aria2=true
    fi
    
    if command -v aria2c &> /dev/null && [ "$skip_aria2" = false ]; then
        local aria2_args=(-x 16 -s 16 --max-tries=3 --retry-wait=2 --continue=true -q)
        if [ -n "$proxy" ] && [[ "$proxy" =~ ^(http|https):// ]]; then
            # 对于 HTTP/HTTPS 代理，使用环境变量方式
            export ALL_PROXY="$proxy"
            export all_proxy="$proxy"
        fi
        aria2c "${aria2_args[@]}" -d "$(dirname "$output")" -o "$(basename "$output")" "$url"
        download_exit=$?
        unset ALL_PROXY all_proxy 2>/dev/null || true
        if [ $download_exit -eq 0 ] && [ "$(dirname "$output")/$(basename "$output")" != "$output" ]; then
            mv "$(dirname "$output")/$(basename "$output")" "$output" 2>/dev/null || true
        fi
    elif [ "$skip_aria2" = true ]; then
        download_exit=1  # 标记为失败，继续尝试其他工具
    fi
    
    # 如果 aria2c 失败或跳过，尝试其他工具
    if [ $download_exit -ne 0 ]; then
        # 对于 SOCKS5 代理，优先使用 curl（原生支持）
        if [ -n "$proxy" ] && [[ "$proxy" =~ ^socks5 ]] && command -v curl &> /dev/null; then
            local curl_args=(-L --progress-bar -C - --retry 5 --retry-delay 3 --retry-all-errors --connect-timeout 30 --max-time 3600 --ssl-no-revoke --proxy "$proxy" -q)
            curl "${curl_args[@]}" -o "$output" "$url"
            download_exit=$?
        elif command -v axel &> /dev/null; then
            local axel_args=(-n 16 -a -q)
            if [ -n "$proxy" ]; then
                axel_args+=("--proxy=${proxy}")
            fi
            axel "${axel_args[@]}" -o "$output" "$url"
            download_exit=$?
        elif command -v wget &> /dev/null; then
            # wget 不支持 SOCKS5 代理，如果检测到 SOCKS5，跳过 wget
            if [ -n "$proxy" ] && [[ "$proxy" =~ ^socks5 ]]; then
                download_exit=1
            else
                local wget_args=(--continue --show-progress --timeout=30 --tries=3)
                if [ -n "$proxy" ]; then
                    wget_args+=(--proxy=on)
                    export http_proxy="$proxy"
                    export https_proxy="$proxy"
                fi
                wget "${wget_args[@]}" -O "$output" "$url"
                download_exit=$?
                unset http_proxy https_proxy 2>/dev/null || true
            fi
        elif command -v curl &> /dev/null; then
            local curl_args=(-L --progress-bar -C - --retry 5 --retry-delay 3 --retry-all-errors --connect-timeout 30 --max-time 3600 --ssl-no-revoke -q)
            if [ -n "$proxy" ]; then
                curl_args+=(--proxy "$proxy")
            fi
            curl "${curl_args[@]}" -o "$output" "$url"
            download_exit=$?
        else
            log "ERROR: 未找到可用的下载工具"
            set -e
            return 1
        fi
    fi
    
    # 重新启用 set -e
    set -e
    
    if [ $download_exit -eq 0 ]; then
        # 检查下载的文件是否有效（不是 "Not Found" 或空文件）
        if [ ! -s "$output" ]; then
            log "  ⚠️  下载的文件为空"
            rm -f "$output"
            return 1
        fi
        # 检查是否是 HTTP 错误页面（包含 "Not Found" 或 "404"）
        if head -1 "$output" 2>/dev/null | grep -qiE "(Not Found|404|Error)"; then
            log "  ⚠️  下载的文件是错误页面（可能文件不存在）"
            rm -f "$output"
            return 1
        fi
        return 0
    else
        return 1
    fi
}

# extract_tar() 函数已在 common.sh 中定义，无需重复定义

log_section "MATRiX Chunk包安装器 v${VERSION}"

# 创建下载目录
DOWNLOAD_DIR="${PROJECT_ROOT}/releases"
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

# 确保目标目录存在
mkdir -p "$PAK_DIR"

# ============================================================================
# 第零步：优先下载并验证 manifest 文件（必需）
# ============================================================================

log_section "[0] 下载 manifest 文件"

MANIFEST_FILE="manifest-${VERSION}.json"
MANIFEST_URL="${GITHUB_RELEASE_URL}/${MANIFEST_FILE}"
    
# 检查 manifest 文件是否存在且有效
manifest_valid=false
if [ -f "$MANIFEST_FILE" ]; then
    # 验证是否是有效的 JSON
    if command -v jq &> /dev/null; then
        if jq empty "$MANIFEST_FILE" 2>/dev/null; then
            manifest_valid=true
            log "✓ manifest 文件已存在且有效"
        else
            log "⚠️  现有 manifest 文件无效，重新下载..."
            rm -f "$MANIFEST_FILE"
        fi
    else
        # 如果没有 jq，简单检查文件大小和内容
        if [ -s "$MANIFEST_FILE" ] && grep -q '"version"' "$MANIFEST_FILE" 2>/dev/null; then
            manifest_valid=true
            log "✓ manifest 文件已存在"
        else
            log "⚠️  现有 manifest 文件可能损坏，重新下载..."
            rm -f "$MANIFEST_FILE"
        fi
    fi
fi

# 如果 manifest 无效或不存在，下载它
if [ "$manifest_valid" = false ]; then
    log "正在下载 manifest 文件..."
    if download_file "$MANIFEST_URL" "$MANIFEST_FILE"; then
        # 验证下载的文件是否有效
        if command -v jq &> /dev/null; then
            if jq empty "$MANIFEST_FILE" 2>/dev/null; then
                log "✓ manifest 文件下载成功并验证通过"
                manifest_valid=true
            else
                log "⚠️  下载的 manifest 文件无效（不是有效的 JSON）"
                rm -f "$MANIFEST_FILE"
            fi
        else
            # 简单验证
            if [ -s "$MANIFEST_FILE" ] && grep -q '"version"' "$MANIFEST_FILE" 2>/dev/null; then
                log "✓ manifest 文件下载成功"
                manifest_valid=true
        else
                log "⚠️  下载的 manifest 文件可能损坏"
                rm -f "$MANIFEST_FILE"
            fi
        fi
    else
        log "⚠️  manifest 文件下载失败"
    fi
fi

# 如果 manifest 仍然无效，警告但继续（使用默认列表）
if [ "$manifest_valid" = false ]; then
    log "⚠️  无法获取有效的 manifest 文件，将使用默认地图列表"
    log "   提示: 请检查网络连接或版本号是否正确"
fi

# ============================================================================
# 第一步：收集用户选择（在开始下载前）
# ============================================================================

log_section "[1] 选择要安装的包"

# 共享资源包默认下载（多个地图依赖）
DOWNLOAD_SHARED=true
log "共享资源包: 默认下载 (推荐)"

# 显示可用地图并让用户选择

# 显示可用地图并让用户选择
map_names=()
if [ "$manifest_valid" = true ] && [ -f "$MANIFEST_FILE" ] && command -v jq &> /dev/null; then
        log "从 manifest 读取可用地图包..."
        echo ""
        echo "可用地图包:"
        map_index=1
        while IFS= read -r map_name; do
            if [ -n "$map_name" ]; then
                map_size=$(jq -r ".packages.maps[] | select(.name==\"$map_name\") | .size" "$MANIFEST_FILE" 2>/dev/null || echo "未知")
                map_desc=$(jq -r ".packages.maps[] | select(.name==\"$map_name\") | .description" "$MANIFEST_FILE" 2>/dev/null || echo "")
                if [ "$map_size" != "null" ] && [ "$map_size" != "" ]; then
                size_mb=$(echo "scale=1; $map_size / 1024 / 1024" | bc 2>/dev/null || echo "0")
                    printf "  %2d. %-25s (%6.1f MB) %s\n" "$map_index" "$map_name" "$size_mb" "$map_desc"
                else
                    printf "  %2d. %-25s\n" "$map_index" "$map_name"
                fi
                map_names+=("$map_name")
                ((map_index++))
            fi
        done < <(jq -r '.packages.maps[].name' "$MANIFEST_FILE" 2>/dev/null)
        
        if [ ${#map_names[@]} -eq 0 ]; then
            log "⚠️  无法解析 manifest，使用默认地图列表（按地图ID顺序）"
            map_names=("CustomWorld" "SceneWorld" "Town10World" "YardWorld" "CrowdWorld" "VeniceWorld" "HouseWorld" "RunningWorld" "Town10Zombie" "IROSFlatWorld" "IROSSlopedWorld" "IROSFlatWorld2025" "IROSSloppedWorld2025" "OfficeWorld" "3DGSWorld" "MoonWorld")
        map_index=1
            for map_name in "${map_names[@]}"; do
                printf "  %2d. %s\n" "$map_index" "$map_name"
                ((map_index++))
            done
        fi
    else
        # 如果没有 manifest 或 jq，使用默认列表（按地图ID顺序）
        echo "可用地图包:"
        map_names=("CustomWorld" "SceneWorld" "Town10World" "YardWorld" "CrowdWorld" "VeniceWorld" "HouseWorld" "RunningWorld" "Town10Zombie" "IROSFlatWorld" "IROSSlopedWorld" "IROSFlatWorld2025" "IROSSloppedWorld2025" "OfficeWorld" "3DGSWorld" "MoonWorld")
        map_index=1
        for map_name in "${map_names[@]}"; do
            printf "  %2d. %s\n" "$map_index" "$map_name"
            ((map_index++))
        done
    fi
    
    echo ""
echo "输入要下载的地图（支持数字索引或地图名称，用空格分隔）:"
echo "  例如: 0 1 2  或  CustomWorld SceneWorld Town10World  或  0 CustomWorld 14"
echo "  输入 'all' 下载全部，直接回车跳过"
    read -r maps_input
    
# 解析用户选择的地图
SELECTED_MAPS=()
if [ -z "$maps_input" ]; then
    log "已选择：跳过所有地图包"
elif [ "$maps_input" = "all" ]; then
    SELECTED_MAPS=("${map_names[@]}")
    log "已选择：下载所有地图包 (${#SELECTED_MAPS[@]} 个)"
else
    for map_input in $maps_input; do
        found=false
        
        # 1. 检查是否是数字索引（1-based）
        if [[ "$map_input" =~ ^[0-9]+$ ]]; then
            idx=$((map_input - 1))  # 转换为 0-based 索引
            if [ $idx -ge 0 ] && [ $idx -lt ${#map_names[@]} ]; then
                SELECTED_MAPS+=("${map_names[$idx]}")
                found=true
            else
                log "⚠️  无效的索引: $map_input (范围: 1-${#map_names[@]})，跳过"
            fi
        else
            # 2. 检查是否是有效的地图名
            for map_name in "${map_names[@]}"; do
                if [ "$map_input" = "$map_name" ]; then
                    SELECTED_MAPS+=("$map_name")
                    found=true
                    break
                fi
            done
            if [ "$found" = false ]; then
                log "⚠️  未知地图名: $map_input，跳过"
            fi
        fi
    done
    
    # 去重（如果用户输入了重复的索引或名称）
    if [ ${#SELECTED_MAPS[@]} -gt 0 ]; then
        # 使用关联数组去重
        declare -A unique_maps
        for map in "${SELECTED_MAPS[@]}"; do
            unique_maps["$map"]=1
        done
        SELECTED_MAPS=("${!unique_maps[@]}")
        log "已选择：下载 ${#SELECTED_MAPS[@]} 个地图包: ${SELECTED_MAPS[*]}"
    fi
fi

echo ""
log "=========================================="
log "选择完成！开始自动下载和安装..."
log "  - 基础包: ✓ (必需)"
log "  - 共享资源包: ✓ (默认)"
log "  - 地图包: ${#SELECTED_MAPS[@]} 个"
log "=========================================="
echo ""
read -p "按回车键开始下载，或 Ctrl+C 取消..." -r
echo ""

# ============================================================================
# 第二步：自动下载和安装所有选中的包
# ============================================================================

log_section "[2] 下载并安装资源文件包 (必需)"
{
    ASSETS_FILE="assets-${VERSION}.tar.gz"
    ASSETS_URL="${GITHUB_RELEASE_URL}/${ASSETS_FILE}"
    
    # 从 manifest 读取资源包的大小和 SHA256
    ASSETS_SIZE=""
    ASSETS_SHA256=""
    ASSETS_REQUIRED=false
    if [ -f "$MANIFEST_FILE" ] && command -v jq &> /dev/null; then
        ASSETS_SIZE=$(jq -r '.packages.assets.size // empty' "$MANIFEST_FILE" 2>/dev/null || echo "")
        ASSETS_SHA256=$(jq -r '.packages.assets.sha256 // empty' "$MANIFEST_FILE" 2>/dev/null || echo "")
        ASSETS_REQUIRED=$(jq -r '.packages.assets.required // false' "$MANIFEST_FILE" 2>/dev/null || echo "false")
    fi
    
    # 检查资源文件是否已安装（检查一些关键文件是否存在）
    ASSETS_INSTALLED=false
    if [ -f "${PROJECT_ROOT}/bin/sim_launcher" ] && [ -f "${PROJECT_ROOT}/src/UeSim/Linux/zsibot_mujoco_ue/Binaries/Linux/zsibot_mujoco_ue-Linux-Shipping" ]; then
        # 检查文件大小（资源文件应该较大，不是指针文件）
        launcher_size=$(stat -f%z "${PROJECT_ROOT}/bin/sim_launcher" 2>/dev/null || stat -c%s "${PROJECT_ROOT}/bin/sim_launcher" 2>/dev/null || echo 0)
        if [ "$launcher_size" -gt 1000000 ]; then  # 大于 1MB，应该是实际文件
            ASSETS_INSTALLED=true
        fi
    fi
    
    if [ "$ASSETS_INSTALLED" = true ]; then
        log "✓ 资源文件已安装，跳过"
    elif [ -f "${DOWNLOAD_DIR}/${ASSETS_FILE}" ]; then
        # 验证已下载文件的完整性
        if verify_file_integrity "${DOWNLOAD_DIR}/${ASSETS_FILE}" "$ASSETS_SIZE" "$ASSETS_SHA256"; then
            log "✓ 资源文件包已下载且完整，跳过下载，直接解压..."
            if extract_tar "${DOWNLOAD_DIR}/${ASSETS_FILE}" "${PROJECT_ROOT}"; then
                log "✓ 资源文件包安装完成"
            else
                error_exit "资源文件包解压失败"
            fi
        else
            log "⚠️  已下载的资源文件包完整性验证失败，重新下载..."
            rm -f "${DOWNLOAD_DIR}/${ASSETS_FILE}"
            # 继续下载流程
        fi
    fi
    
    # 如果需要下载
    if [ "$ASSETS_INSTALLED" = false ] && [ ! -f "${DOWNLOAD_DIR}/${ASSETS_FILE}" ]; then
        if [ "$ASSETS_REQUIRED" = "true" ] || [ -n "$ASSETS_SHA256" ]; then
            log "开始下载资源文件包..."
            if download_and_extract_stream "$ASSETS_URL" "${PROJECT_ROOT}" "资源文件包" "$ASSETS_SIZE" "$ASSETS_SHA256"; then
                log "✓ 资源文件包安装完成"
            else
                if [ "$ASSETS_REQUIRED" = "true" ]; then
                    error_exit "资源文件包下载失败（必需），请检查网络连接和版本号"
                else
                    log "⚠️  资源文件包下载失败，跳过（可选）"
                fi
            fi
        else
            log "⚠️  manifest 中未找到资源包信息，跳过"
        fi
    fi
}

log_section "[3] 下载并安装基础包 (必需)"
{
    BASE_FILE="base-${VERSION}.tar.gz"
    BASE_URL="${GITHUB_RELEASE_URL}/${BASE_FILE}"
    
    # 从 manifest 读取基础包的大小和 SHA256
    BASE_SIZE=""
    BASE_SHA256=""
    if [ -f "$MANIFEST_FILE" ] && command -v jq &> /dev/null; then
        BASE_SIZE=$(jq -r '.packages.base.size // empty' "$MANIFEST_FILE" 2>/dev/null || echo "")
        BASE_SHA256=$(jq -r '.packages.base.sha256 // empty' "$MANIFEST_FILE" 2>/dev/null || echo "")
    fi
    
    # 检查基础包是否已安装（检查关键文件是否存在）
    if [ -f "${PAK_DIR}/pakchunk0-Linux.pak" ]; then
        log "✓ 基础包已安装，跳过"
    elif [ -f "${DOWNLOAD_DIR}/${BASE_FILE}" ]; then
        # 验证已下载文件的完整性
        if verify_file_integrity "${DOWNLOAD_DIR}/${BASE_FILE}" "$BASE_SIZE" "$BASE_SHA256"; then
            log "✓ 基础包已下载且完整，跳过下载，直接解压..."
            if extract_tar "${DOWNLOAD_DIR}/${BASE_FILE}" "$TARGET_DIR"; then
                # 使用公共函数移动 chunk 文件
                move_chunk_files_to_paks "${TARGET_DIR}/Content/Paks" "$PAK_DIR"
                
                # 从 UeSim 目录拷贝模型到 robot_mujoco 目录
                copy_models_from_uesim_to_robot_mujoco
                
                log "✓ 基础包安装完成"
            else
                error_exit "基础包解压失败"
            fi
        else
            log "⚠️  已下载的基础包完整性验证失败，重新下载..."
            rm -f "${DOWNLOAD_DIR}/${BASE_FILE}"
            # 继续下载流程
        fi
    fi
    
    # 如果需要下载
    if [ ! -f "${PAK_DIR}/pakchunk0-Linux.pak" ] && [ ! -f "${DOWNLOAD_DIR}/${BASE_FILE}" ]; then
        log "开始下载基础包..."
        if download_and_extract_stream "$BASE_URL" "$TARGET_DIR" "基础包" "$BASE_SIZE" "$BASE_SHA256"; then
            # 使用公共函数移动 chunk 文件
            move_chunk_files_to_paks "${TARGET_DIR}/Content/Paks" "$PAK_DIR"
            
            # 从 UeSim 目录拷贝模型到 robot_mujoco 目录
            copy_models_from_uesim_to_robot_mujoco
            
            log "✓ 基础包安装完成"
        else
            error_exit "基础包下载失败，请检查网络连接和版本号"
        fi
    fi
}

# 下载并安装共享资源包
if [ "$DOWNLOAD_SHARED" = true ]; then
    log_section "[4] 下载并安装共享资源包"
    {
        SHARED_FILE="shared-${VERSION}.tar.gz"
        SHARED_URL="${GITHUB_RELEASE_URL}/${SHARED_FILE}"
        
        # 从 manifest 读取共享资源包的大小和 SHA256
        SHARED_SIZE=""
        SHARED_SHA256=""
        SHARED_IS_SPLIT=false
        if [ -f "$MANIFEST_FILE" ] && command -v jq &> /dev/null; then
            SHARED_SIZE=$(jq -r '.packages.shared.size // empty' "$MANIFEST_FILE" 2>/dev/null || echo "")
            SHARED_SHA256=$(jq -r '.packages.shared.sha256 // empty' "$MANIFEST_FILE" 2>/dev/null || echo "")
            SHARED_IS_SPLIT=$(jq -r '.packages.shared.is_split // false' "$MANIFEST_FILE" 2>/dev/null || echo "false")
        fi
        
        # 检查共享资源包是否已安装
        if [ -f "${PAK_DIR}/pakchunk1-Linux.pak" ]; then
            log "✓ 共享资源包已安装，跳过"
        elif [ -f "${DOWNLOAD_DIR}/${SHARED_FILE}" ]; then
            # 验证已下载文件的完整性
            if verify_file_integrity "${DOWNLOAD_DIR}/${SHARED_FILE}" "$SHARED_SIZE" "$SHARED_SHA256"; then
                log "✓ 共享资源包已下载且完整，跳过下载，直接解压..."
                extract_tar "${DOWNLOAD_DIR}/${SHARED_FILE}" "$PAK_DIR"
                log "✓ 共享资源包安装完成"
            else
                log "⚠️  已下载的共享资源包完整性验证失败，重新下载..."
                rm -f "${DOWNLOAD_DIR}/${SHARED_FILE}"
                # 继续下载流程
            fi
        fi
        
        # 如果需要下载
        if [ ! -f "${PAK_DIR}/pakchunk1-Linux.pak" ] && [ ! -f "${DOWNLOAD_DIR}/${SHARED_FILE}" ]; then
            # 如果是分片文件，使用分片下载逻辑
            if [ "$SHARED_IS_SPLIT" = "true" ]; then
                log "检测到共享资源包为分片文件，使用分片下载..."
                # 这里可以调用分片下载逻辑（类似地图包的分片下载）
                # 暂时先尝试下载完整包
                log "⚠️  分片下载功能待完善，尝试下载完整包..."
            fi
            
            log "开始下载共享资源包..."
            if download_and_extract_stream "$SHARED_URL" "$PAK_DIR" "共享资源包" "$SHARED_SIZE" "$SHARED_SHA256"; then
                log "✓ 共享资源包安装完成"
            else
                log "⚠️  共享资源包下载失败，跳过"
            fi
        fi
    }
fi

# 下载并安装地图包
if [ ${#SELECTED_MAPS[@]} -gt 0 ]; then
    log_section "[5] 下载并安装地图包"
    
    # 函数：下载并安装单个地图包（支持分片和流式处理）
    download_and_install_map() {
        local map_name=$1
        local map_file="${map_name}-${VERSION}.tar.gz"
        local map_url="${GITHUB_RELEASE_URL}/${map_file}"
        
        log ""
        log "处理地图包: $map_name"
        
        # 从 manifest 读取地图包的大小和 SHA256
        local map_size=""
        local map_sha256=""
        local is_split=false
        if [ -f "$MANIFEST_FILE" ] && command -v jq &> /dev/null; then
            map_size=$(jq -r ".packages.maps[] | select(.name==\"$map_name\") | .size // empty" "$MANIFEST_FILE" 2>/dev/null || echo "")
            map_sha256=$(jq -r ".packages.maps[] | select(.name==\"$map_name\") | .sha256 // empty" "$MANIFEST_FILE" 2>/dev/null || echo "")
            is_split=$(jq -r ".packages.maps[] | select(.name==\"$map_name\") | .is_split // false" "$MANIFEST_FILE" 2>/dev/null || echo "false")
        fi
        
        # 检查是否已下载
        if [ -f "${DOWNLOAD_DIR}/${map_file}" ]; then
            # 验证已下载文件的完整性
            if verify_file_integrity "${DOWNLOAD_DIR}/${map_file}" "$map_size" "$map_sha256"; then
                log "  ✓ 发现已下载的地图包且完整，直接解压..."
                if extract_tar "${DOWNLOAD_DIR}/${map_file}" "$PAK_DIR"; then
                    log "  ✓ ${map_name} 安装完成"
                    return 0
                else
                    log "  ⚠️  解压失败，尝试重新下载..."
                    rm -f "${DOWNLOAD_DIR}/${map_file}"
                fi
            else
                log "  ⚠️  已下载的地图包完整性验证失败，重新下载..."
                rm -f "${DOWNLOAD_DIR}/${map_file}"
            fi
        fi
        
        # 1. 尝试流式下载完整包（传入大小和 SHA256 进行验证）
        if download_and_extract_stream "$map_url" "$PAK_DIR" "$map_name" "$map_size" "$map_sha256"; then
            log "  ✓ ${map_name} 安装完成"
            return 0
        fi
        
        # 2. 如果流式下载失败，检查是否为分片文件
        if [ "$is_split" = "true" ]; then
            log "  ⚠️  完整包下载失败，尝试分片下载（manifest 标记为分片文件）..."
            local merge_script="${map_file%.tar.gz}.tar.merge.sh"
        local merge_url="${GITHUB_RELEASE_URL}/${merge_script}"
        
            # 尝试下载合并脚本
            if download_file "$merge_url" "$merge_script" 2>/dev/null; then
                # 检查下载的文件是否有效（不是 "Not Found" 或空文件）
                if [ ! -s "$merge_script" ] || head -1 "$merge_script" | grep -q "Not Found"; then
                    log "  ⚠️  合并脚本下载失败或无效，跳过分片下载"
                    rm -f "$merge_script"
                    return 1
                fi
                log "  检测到分片文件，开始下载分片..."
            
            # 下载所有分片
            local part_idx=0
            local download_success=true
            
            while true; do
                local part_ext=$(printf "part%03d" $part_idx)
                local part_file="${map_file%.tar.gz}.tar.${part_ext}"
                local part_url="${GITHUB_RELEASE_URL}/${part_file}"
                
                if download_file "$part_url" "$part_file" 2>/dev/null; then
                    ((part_idx++))
                else
                    if [ $part_idx -eq 0 ]; then
                        log "  ⚠️  无法下载第一个分片: $part_file"
                        download_success=false
                    else
                        log "  分片下载完成 (共 $part_idx 个)"
                    fi
                    break
                fi
            done
            
            if [ "$download_success" = true ] && [ $part_idx -gt 0 ]; then
                # 下载校验和文件（可选）
                local sha_file="${map_file%.tar.gz}.tar.sha256"
                download_file "${GITHUB_RELEASE_URL}/${sha_file}" "$sha_file" 2>/dev/null || true
                
                # 执行合并
                log "  合并分片..."
                chmod +x "$merge_script"
                if ./$merge_script; then
                    log "  ✓ 合并成功"
                    extract_tar "$map_file" "$PAK_DIR"
                    log "  ✓ ${map_name} 安装完成"
                    log "  ✓ 文件保留在: ${DOWNLOAD_DIR}/"
                    return 0
                else
                    log "  ⚠️  合并失败"
                    return 1
                fi
            else
                log "  ⚠️  分片下载不完整"
                return 1
            fi
            else
                log "  ⚠️  合并脚本下载失败，跳过分片下载"
                return 1
            fi
        else
            log "  ⚠️  ${map_name} 下载失败（未标记为分片文件，不尝试分片下载），跳过"
            return 1
        fi
    }

    # 依次下载所有选中的地图包
    for map_name in "${SELECTED_MAPS[@]}"; do
            download_and_install_map "$map_name"
        done
    fi

log_section "[6] 验证安装"
{
    # 使用公共函数验证安装
    verify_installation "$PAK_DIR"
    
    # 验证资源文件是否已安装
    if [ -f "${PROJECT_ROOT}/bin/sim_launcher" ]; then
        launcher_size=$(stat -f%z "${PROJECT_ROOT}/bin/sim_launcher" 2>/dev/null || stat -c%s "${PROJECT_ROOT}/bin/sim_launcher" 2>/dev/null || echo 0)
        if [ "$launcher_size" -gt 1000000 ]; then
            log "✓ 资源文件验证通过: sim_launcher (${launcher_size} 字节)"
        else
            log "⚠️  资源文件可能未正确安装: sim_launcher 文件过小 (${launcher_size} 字节)"
        fi
    fi
}

log_section "[7] 完成"
{
    echo ""
    echo "✅ Chunk包安装完成！"
    echo ""
    echo "已安装的包:"
    if [ -f "${PROJECT_ROOT}/bin/sim_launcher" ]; then
        echo "  - 资源文件包"
    fi
    echo "  - 基础包 (Chunk 0)"
    if [ "$DOWNLOAD_SHARED" = true ] && [ -f "${PAK_DIR}/pakchunk1-Linux.pak" ]; then
        echo "  - 共享资源包 (Chunk 1)"
    fi
    echo "  - 地图包: $(ls -1 "${PAK_DIR}"/pakchunk[1-9][0-9]*-Linux.pak 2>/dev/null | wc -l) 个"
    echo ""
    echo "运行目录: ${TARGET_DIR}"
    echo ""
    echo "现在可以运行模拟器了:"
    echo "  cd ${PROJECT_ROOT}"
    echo "  ./scripts/run_sim.sh 1 0  # XGB机器人，CustomWorld地图"
    echo ""
    echo "提示: 如果需要重新安装或安装其他地图包，可以:"
    echo "  1. 使用本地安装脚本: bash scripts/release_manager/install_chunks_local.sh ${VERSION}"
    echo "  2. 或重新运行此脚本选择其他地图包"
}
