#!/bin/bash
# ============================================================================
# 公共函数库 - Release Manager Scripts
# 所有 release_manager 脚本共享的公共函数和变量
# ============================================================================

# 获取脚本目录和项目根目录
# 注意：如果脚本已经设置了这些变量，则不会覆盖
if [ -z "${SCRIPT_DIR:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -z "${PROJECT_ROOT:-}" ]; then
    # release_manager 目录下的脚本需要向上两级到达项目根目录
    PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
fi

# 日志函数
log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

# 日志章节函数
log_section() {
    echo ""
    echo "===== $* ====="
    echo "$(printf '=%.0s' {1..60})"
}

# 错误退出函数
error_exit() {
    log "ERROR: $*"
    exit 1
}

# 解压 tar.gz 文件到指定目录
# 用法: extract_tar <tar_file> <extract_dir>
extract_tar() {
    local tar_file="$1"
    local extract_dir="$2"
    
    if [ ! -f "$tar_file" ]; then
        error_exit "文件不存在: $tar_file"
    fi
    
    log "解压: $(basename "$tar_file")"
    mkdir -p "$extract_dir"
    
    if tar -xzf "$tar_file" -C "$extract_dir" 2>/dev/null; then
        return 0
    else
        log "⚠️  解压失败: $tar_file"
        return 1
    fi
}

# 移动 chunk 文件到 Paks 目录
# 用法: move_chunk_files_to_paks <source_dir> <paks_dir>
move_chunk_files_to_paks() {
    local source_dir="$1"
    local paks_dir="$2"
    
    if [ ! -d "$source_dir" ]; then
        return 0  # 源目录不存在，无需移动
    fi
    
    mkdir -p "$paks_dir"
    
    # 移动所有 .pak, .ucas, .utoc 文件
    find "$source_dir" -maxdepth 1 -type f \( -name "*.pak" -o -name "*.ucas" -o -name "*.utoc" \) 2>/dev/null | while read file; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            if [ ! -f "$paks_dir/$filename" ]; then
                mv "$file" "$paks_dir/"
            fi
        fi
    done
}

# 验证安装（检查基础包是否存在）
# 用法: verify_installation <paks_dir>
verify_installation() {
    local paks_dir="$1"
    
    if [ -f "${paks_dir}/pakchunk0-Linux.pak" ]; then
        log "✓ 基础包验证通过"
        local chunk_count=$(ls -1 "${paks_dir}"/pakchunk*.pak 2>/dev/null | wc -l)
        log "✓ 已安装 ${chunk_count} 个chunk文件"
        return 0
    else
        error_exit "基础包验证失败: ${paks_dir}/pakchunk0-Linux.pak 不存在"
    fi
}

# Chunk ID 到地图名的映射
# 用法: get_map_name_by_chunk_id <chunk_id>
get_map_name_by_chunk_id() {
    local chunk_id="$1"
    
    declare -A CHUNK_TO_MAP=(
        ["0"]="EmptyWorld"
        ["1"]="Shared"
        ["11"]="SceneWorld"
        ["12"]="Town10World"
        ["13"]="YardWorld"
        ["14"]="CrowdWorld"
        ["15"]="VeniceWorld"
        ["16"]="RunningWorld"
        ["17"]="HouseWorld"
        ["18"]="IROSFlatWorld"
        ["19"]="IROSSlopedWorld"
        ["20"]="Town10Zombie"
        ["21"]="IROSFlatWorld2025"
        ["22"]="IROSSloppedWorld2025"
        ["23"]="OfficeWorld"
        ["24"]="CustomWorld"
        ["25"]="3DGSWorld"
        ["26"]="MoonWorld"
    )
    
    echo "${CHUNK_TO_MAP[$chunk_id]:-(未知地图)}"
}

