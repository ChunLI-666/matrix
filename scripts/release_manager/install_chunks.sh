#!/bin/bash
set -e

# ============================================================================
# 安装Chunk包到运行目录
# 自动下载并组织文件到正确的目录结构
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
VERSION="${1:-2.0.8}"
GITHUB_REPO="Alphabaijinde/matrix"
GITHUB_RELEASE_URL="https://github.com/${GITHUB_REPO}/releases/download/v${VERSION}"
TARGET_DIR="${PROJECT_ROOT}/src/UeSim/Linux/jszr_mujoco_ue"
PAK_DIR="${TARGET_DIR}/Content/Paks"

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

log_section() {
    echo ""
    echo "===== $* ====="
    echo "$(printf '=%.0s' {1..60})"
}

error_exit() {
    log "ERROR: $*"
    exit 1
}

# 检查wget或curl
if command -v wget &> /dev/null; then
    DOWNLOAD_CMD="wget -q --show-progress"
elif command -v curl &> /dev/null; then
    DOWNLOAD_CMD="curl -L -O --progress-bar"
else
    error_exit "需要 wget 或 curl 来下载文件"
fi

download_file() {
    local url=$1
    local output=$2
    log "下载: $(basename "$output")"
    
    if command -v wget &> /dev/null; then
        wget -q --show-progress -O "$output" "$url" || return 1
    else
        curl -L --progress-bar -o "$output" "$url" || return 1
    fi
}

extract_tar() {
    local tar_file=$1
    local extract_dir=$2
    log "解压: $(basename "$tar_file")"
    mkdir -p "$extract_dir"
    tar -xzf "$tar_file" -C "$extract_dir" || return 1
}

log_section "MATRiX Chunk包安装器 v${VERSION}"

# 创建下载目录（直接下载到 releases/ 目录）
DOWNLOAD_DIR="${PROJECT_ROOT}/releases"
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

# 确保目标目录存在
mkdir -p "$PAK_DIR"

log_section "[1] 下载基础包 (必需)"
{
    BASE_FILE="base-${VERSION}.tar.gz"
    BASE_URL="${GITHUB_RELEASE_URL}/${BASE_FILE}"
    
    if download_file "$BASE_URL" "$BASE_FILE"; then
        log "✓ 基础包下载完成"
        
        # 解压基础包到目标目录
        log "安装基础包..."
        extract_tar "$BASE_FILE" "$TARGET_DIR"
        
        # 移动chunk文件到Paks目录（如果不在目标位置）
        if [ -d "${TARGET_DIR}/Content/Paks" ]; then
            find "${TARGET_DIR}/Content/Paks" -maxdepth 1 -type f \( -name "*.pak" -o -name "*.ucas" -o -name "*.utoc" \) | while read file; do
                filename=$(basename "$file")
                if [ ! -f "$PAK_DIR/$filename" ]; then
                    mv "$file" "$PAK_DIR/"
                fi
            done
        fi
        
        log "✓ 基础包安装完成"
    else
        error_exit "基础包下载失败，请检查网络连接和版本号"
    fi
}

log_section "[2] 下载共享资源包 (推荐)"
{
    SHARED_FILE="shared-${VERSION}.tar.gz"
    SHARED_URL="${GITHUB_RELEASE_URL}/${SHARED_FILE}"
    
    read -p "是否下载共享资源包? (推荐，多个地图依赖) [Y/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        if download_file "$SHARED_URL" "$SHARED_FILE"; then
            log "✓ 共享资源包下载完成"
            extract_tar "$SHARED_FILE" "$PAK_DIR"
            log "✓ 共享资源包安装完成"
        else
            log "⚠️  共享资源包下载失败，跳过"
        fi
    else
        log "跳过共享资源包"
    fi
}

log_section "[3] 下载地图包 (可选)"
{
    # 尝试从 manifest 读取可用地图列表
    MANIFEST_FILE="manifest-${VERSION}.json"
    MANIFEST_URL="${GITHUB_RELEASE_URL}/${MANIFEST_FILE}"
    
    # 下载 manifest 文件（如果不存在）
    if [ ! -f "$MANIFEST_FILE" ]; then
        log "下载 manifest 文件以获取可用地图列表..."
        download_file "$MANIFEST_URL" "$MANIFEST_FILE" || log "⚠️  无法下载 manifest，使用默认地图列表"
    fi
    
    # 从 manifest 读取地图列表（如果可用）
    if [ -f "$MANIFEST_FILE" ] && command -v jq &> /dev/null; then
        log "从 manifest 读取可用地图包..."
        echo ""
        echo "可用地图包:"
        map_index=1
        map_names=()
        while IFS= read -r map_name; do
            if [ -n "$map_name" ]; then
                map_size=$(jq -r ".packages.maps[] | select(.name==\"$map_name\") | .size" "$MANIFEST_FILE" 2>/dev/null || echo "未知")
                map_desc=$(jq -r ".packages.maps[] | select(.name==\"$map_name\") | .description" "$MANIFEST_FILE" 2>/dev/null || echo "")
                if [ "$map_size" != "null" ] && [ "$map_size" != "" ]; then
                    size_mb=$(echo "scale=1; $map_size / 1024 / 1024" | bc)
                    printf "  %2d. %-25s (%6.1f MB) %s\n" "$map_index" "$map_name" "$size_mb" "$map_desc"
                else
                    printf "  %2d. %-25s\n" "$map_index" "$map_name"
                fi
                map_names+=("$map_name")
                ((map_index++))
            fi
        done < <(jq -r '.packages.maps[].name' "$MANIFEST_FILE" 2>/dev/null)
        
        if [ ${#map_names[@]} -eq 0 ]; then
            # 如果 jq 解析失败，使用默认列表
            log "⚠️  无法解析 manifest，使用默认地图列表"
            map_names=("SceneWorld" "Town10World" "YardWorld" "CrowdWorld" "VeniceWorld" "RunningWorld" "HouseWorld" "IROSFlatWorld" "IROSSlopedWorld" "Town10Zombie" "IROSFlatWorld2025" "IROSSloppedWorld2025" "OfficeWorld" "Custom")
            for map_name in "${map_names[@]}"; do
                printf "  %2d. %s\n" "$map_index" "$map_name"
                ((map_index++))
            done
        fi
    else
        # 如果没有 manifest 或 jq，使用默认列表
        echo "可用地图包:"
        map_names=("SceneWorld" "Town10World" "YardWorld" "CrowdWorld" "VeniceWorld" "RunningWorld" "HouseWorld" "IROSFlatWorld" "IROSSlopedWorld" "Town10Zombie" "IROSFlatWorld2025" "IROSSloppedWorld2025" "OfficeWorld" "Custom")
        map_index=1
        for map_name in "${map_names[@]}"; do
            printf "  %2d. %s\n" "$map_index" "$map_name"
            ((map_index++))
        done
    fi
    
    echo ""
    echo "输入要下载的地图名称（用空格分隔，或输入 'all' 下载全部，直接回车跳过）:"
    read -r maps_input
    
    # 函数：下载并安装单个地图包（支持分片）
    download_and_install_map() {
        local map_name=$1
        local map_file="${map_name}-${VERSION}.tar.gz"
        local map_url="${GITHUB_RELEASE_URL}/${map_file}"
        
        # 1. 尝试直接下载完整包
        if download_file "$map_url" "$map_file"; then
            extract_tar "$map_file" "$PAK_DIR"
            log "  ✓ ${map_name} 安装完成 (文件保留在: ${DOWNLOAD_DIR}/${map_file})"
            # 保留下载的文件在 releases/ 目录，不删除
            return 0
        fi
        
        # 2. 如果直接下载失败，尝试检查是否存在分片合并脚本
        local merge_script="${map_file%.gz}.merge.sh" # 注意：这里假设 split 脚本生成的 merge 脚本名为 .tar.merge.sh
        # 如果文件名是 Town10World-0.0.4.tar.gz，merge 脚本是 Town10World-0.0.4.tar.merge.sh
        # 但我们在 upload_to_release.sh 看到的命名似乎是 Town10World-0.0.4.tar.merge.sh
        
        local merge_url="${GITHUB_RELEASE_URL}/${merge_script}"
        
        log "尝试下载分片合并脚本: $merge_script"
        if download_file "$merge_url" "$merge_script"; then
            log "检测到分片文件，开始下载分片..."
            
            # 下载分片 part000, part001, ...
            local part_idx=0
            local download_success=true
            
            while true; do
                local part_ext=$(printf "part%03d" $part_idx)
                local part_file="${map_file%.gz}.${part_ext}" # Town10World-0.0.4.tar.part000
                local part_url="${GITHUB_RELEASE_URL}/${part_file}"
                
                # 尝试下载分片，如果失败（404），假设分片结束
                # 注意：wget/curl 在 404 时可能不会返回错误代码，取决于具体参数，这里假设 download_file 处理了
                # 但为了保险，我们先检查 part000，后续失败则停止
                
                if download_file "$part_url" "$part_file"; then
                    ((part_idx++))
                else
                    if [ $part_idx -eq 0 ]; then
                        log "⚠️  无法下载第一个分片: $part_file"
                        download_success=false
                    else
                        log "分片下载结束 (共 $part_idx 个)"
                    fi
                    break
                fi
            done
            
            if [ "$download_success" = true ] && [ $part_idx -gt 0 ]; then
                # 下载校验和文件（可选）
                local sha_file="${map_file%.gz}.sha256"
                download_file "${GITHUB_RELEASE_URL}/${sha_file}" "$sha_file" || true
                
                # 执行合并
                log "合并分片..."
                chmod +x "$merge_script"
                if ./$merge_script; then
                    log "✓ 合并成功"
                    extract_tar "$map_file" "$PAK_DIR"
                    log "  ✓ ${map_name} 安装完成"
                    log "  ✓ 文件保留在: ${DOWNLOAD_DIR}/${map_file}"
                    log "  ✓ 分片文件保留在: ${DOWNLOAD_DIR}/"
                    # 保留所有文件（分片、合并脚本、校验和、合并后的文件）在 releases/ 目录，不删除
                    return 0
                else
                    log "⚠️  合并失败"
                    return 1
                fi
            else
                log "⚠️  分片下载不完整"
                return 1
            fi
        else
            log "  ⚠️  ${map_name} 下载失败 (未找到完整包或分片信息)，跳过"
            return 1
        fi
    }

    if [ -z "$maps_input" ]; then
        log "跳过地图包下载"
    elif [ "$maps_input" = "all" ]; then
        log "下载所有地图包..."
        # 如果 map_names 数组未定义，使用默认列表
        if [ ${#map_names[@]} -eq 0 ]; then
            map_names=("SceneWorld" "Town10World" "YardWorld" "CrowdWorld" "VeniceWorld" "RunningWorld" "HouseWorld" "IROSFlatWorld" "IROSSlopedWorld" "Town10Zombie" "IROSFlatWorld2025" "IROSSloppedWorld2025" "OfficeWorld" "Custom")
        fi
        for map_name in "${map_names[@]}"; do
            download_and_install_map "$map_name"
        done
    else
        for map_name in $maps_input; do
            download_and_install_map "$map_name"
        done
    fi
}

log_section "[4] 验证安装"
{
    # 保留所有下载的文件在 releases/ 目录，不清理
    log "✓ 所有文件已保存到: ${DOWNLOAD_DIR}/"
    
    # 验证安装
    log "验证安装..."
    if [ -f "${PAK_DIR}/pakchunk0-Linux.pak" ]; then
        log "✓ 基础包验证通过"
    else
        error_exit "基础包验证失败"
    fi
    
    chunk_count=$(ls -1 "${PAK_DIR}"/pakchunk*.pak 2>/dev/null | wc -l)
    log "✓ 已安装 ${chunk_count} 个chunk文件"
}

log_section "[5] 完成"
{
    echo ""
    echo "✅ Chunk包安装完成！"
    echo ""
    echo "已安装的包:"
    echo "  - 基础包 (Chunk 0)"
    if [ -f "${PAK_DIR}/pakchunk1-Linux.pak" ]; then
        echo "  - 共享资源包 (Chunk 1)"
    fi
    echo "  - 地图包: $(ls -1 "${PAK_DIR}"/pakchunk[1-9][0-9]*-Linux.pak 2>/dev/null | wc -l) 个"
    echo ""
    echo "下载的文件保存在: ${DOWNLOAD_DIR}/"
    echo "  - 基础包: ${DOWNLOAD_DIR}/base-${VERSION}.tar.gz"
    if [ -f "${DOWNLOAD_DIR}/shared-${VERSION}.tar.gz" ]; then
        echo "  - 共享资源包: ${DOWNLOAD_DIR}/shared-${VERSION}.tar.gz"
    fi
    echo "  - 地图包: ${DOWNLOAD_DIR}/*-${VERSION}.tar.gz"
    echo ""
    echo "运行目录: ${TARGET_DIR}"
    echo ""
    echo "现在可以运行模拟器了:"
    echo "  cd ${PROJECT_ROOT}"
    echo "  ./scripts/run_sim.sh 0 0  # 运行EmptyWorld"
    echo ""
    echo "提示: 如果需要重新安装或安装其他地图包，可以:"
    echo "  1. 使用本地安装脚本: bash scripts/release_manager/install_chunks_local.sh ${VERSION}"
    echo "  2. 或重新运行此脚本选择其他地图包"
}

