#!/bin/bash
set -e

# ============================================================================
# 从本地打包文件安装Chunk包到运行目录
# 直接从 releases/chunks/VERSION 目录解压并组织文件
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
VERSION="${1:-2.0.10}"
RELEASE_DIR="${PROJECT_ROOT}/releases"
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

# 检查发布目录
if [ ! -d "$RELEASE_DIR" ]; then
    error_exit "找不到发布目录: $RELEASE_DIR"
fi

log_section "MATRiX Chunk包本地安装器 v${VERSION}"

# 确保目标目录存在
mkdir -p "$PAK_DIR"
mkdir -p "$TARGET_DIR/Content/model"

log_section "[1] 安装基础包 (必需)"
{
    BASE_FILE="${RELEASE_DIR}/base-${VERSION}.tar.gz"
    if [ ! -f "$BASE_FILE" ]; then
        error_exit "找不到基础包: $BASE_FILE (请先下载到 releases/ 目录)"
    fi
    
    log "解压基础包..."
    tar -xzf "$BASE_FILE" -C "$TARGET_DIR"
    
    # 移动chunk文件到Paks目录（如果不在目标位置）
    if [ -d "${TARGET_DIR}/Content/Paks" ]; then
        # 确保 Paks 目录存在
        mkdir -p "$PAK_DIR"
        # 移动所有 .pak, .ucas, .utoc 文件（只移动不在目标位置的）
        find "${TARGET_DIR}/Content/Paks" -maxdepth 1 -type f \( -name "*.pak" -o -name "*.ucas" -o -name "*.utoc" \) | while read file; do
            filename=$(basename "$file")
            if [ ! -f "$PAK_DIR/$filename" ]; then
                mv "$file" "$PAK_DIR/"
            fi
        done
    fi
    
    log "✓ 基础包安装完成"
}

log_section "[2] 安装共享资源包 (推荐)"
{
    SHARED_FILE="${RELEASE_DIR}/shared-${VERSION}.tar.gz"
    if [ -f "$SHARED_FILE" ]; then
        log "解压共享资源包..."
        tar -xzf "$SHARED_FILE" -C "$PAK_DIR"
        log "✓ 共享资源包安装完成"
    else
        log "⚠️  共享资源包不存在，跳过"
    fi
}

log_section "[3] 安装地图包 (可选)"
{
    # 检查并合并分片文件
    for merge_script in "${RELEASE_DIR}"/*.merge.sh; do
        if [ -f "$merge_script" ]; then
            # 获取目标文件名（从 merge script 文件名推断，去掉 .merge.sh 后缀）
            target_file="${merge_script%.merge.sh}"
            # 如果合并后的文件不存在，则执行合并
            if [ ! -f "$target_file" ]; then
                log "发现分片文件，正在合并: $(basename "$target_file")"
                # 赋予执行权限并运行
                chmod +x "$merge_script"
                # 在 RELEASE_DIR 中执行，确保路径正确
                (cd "$RELEASE_DIR" && ./$(basename "$merge_script")) || log "⚠️  合并失败: $(basename "$merge_script")"
            else
                log "分片文件已合并: $(basename "$target_file")"
            fi
        fi
    done

    map_count=0
    for map_tar in "${RELEASE_DIR}"/*-${VERSION}.tar.gz; do
        # 跳过 base 和 shared
        if [[ "$(basename "$map_tar")" == base-* ]] || [[ "$(basename "$map_tar")" == shared-* ]]; then
            continue
        fi
        if [ -f "$map_tar" ]; then
            map_name=$(basename "$map_tar" | sed "s/-${VERSION}.tar.gz//")
            log "安装地图包: $map_name"
            tar -xzf "$map_tar" -C "$PAK_DIR"
            ((map_count++))
        fi
    done
    if [ $map_count -gt 0 ]; then
        log "✓ 已安装 ${map_count} 个地图包"
    else
        log "⚠️  未找到地图包，跳过"
    fi
}

log_section "[4] 验证安装"
{
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
    map_count=$(ls -1 "${PAK_DIR}"/pakchunk[1-9][0-9]*-Linux.pak 2>/dev/null | wc -l)
    echo "  - 地图包: ${map_count} 个"
    echo ""
    echo "运行目录: ${TARGET_DIR}"
    echo ""
    echo "注意:"
    echo "  - Engine/ 目录和 jszr_mujoco_ue.sh 脚本已保留在仓库中"
    echo "  - jszr_mujoco_ue/ 目录内容通过 releases 下载填充"
    echo ""
    echo "现在可以运行模拟器了:"
    echo "  cd ${PROJECT_ROOT}"
    echo "  ./scripts/run_sim.sh 1 1  # 运行XGB机器人，Warehouse地图"
}

