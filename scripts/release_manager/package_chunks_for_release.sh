#!/bin/bash
set -e

# ============================================================================
# 将打包好的Chunk文件组织成发布版本
# 压缩包直接放到 releases/ 目录，用于上传到GitHub Releases
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 加载公共函数库
source "${SCRIPT_DIR}/common.sh"

CHUNK_SOURCE="/home/user/work/workspace/jszr_mujoco_ue2/dist/chunks"
VERSION="${1:-0.0.4}"
RELEASE_DIR="${PROJECT_ROOT}/releases"
TEMP_DIR="${PROJECT_ROOT}/releases/.temp_${VERSION}"

# 检查源目录
if [ ! -d "${CHUNK_SOURCE}/${VERSION}" ]; then
    error_exit "找不到源目录: ${CHUNK_SOURCE}/${VERSION}"
fi

log_section "[1] 准备发布目录结构"
{
    mkdir -p "${TEMP_DIR}"/{base,shared,maps}
    mkdir -p "${RELEASE_DIR}"
    log "✓ 创建临时打包目录: ${TEMP_DIR}"
    log "✓ 发布目录: ${RELEASE_DIR} (压缩包将直接放在这里)"
}

log_section "[2] 复制基础包 (Chunk 0)"
{
    BASE_SOURCE="${CHUNK_SOURCE}/${VERSION}/package_base"
    if [ -d "$BASE_SOURCE" ]; then
        log "复制基础包文件..."
        rsync -av --exclude="*.log" "$BASE_SOURCE/" "${TEMP_DIR}/base/"
        
        # 创建基础包压缩文件，直接放到 releases/ 目录
        log "压缩基础包..."
        cd "${TEMP_DIR}"
        tar -czf "${RELEASE_DIR}/base-${VERSION}.tar.gz" -C base .
        log "✓ 基础包: ${RELEASE_DIR}/base-${VERSION}.tar.gz ($(du -sh "${RELEASE_DIR}/base-${VERSION}.tar.gz" | cut -f1))"
    else
        error_exit "找不到基础包目录: $BASE_SOURCE"
    fi
}

log_section "[3] 复制共享资源包 (Chunk 1)"
{
    SHARED_SOURCE="${CHUNK_SOURCE}/${VERSION}/package_shared"
    if [ -d "$SHARED_SOURCE" ]; then
        log "复制共享资源包文件..."
        rsync -av --exclude="*.log" "$SHARED_SOURCE/" "${TEMP_DIR}/shared/"
        
        # 创建共享资源包压缩文件，直接放到 releases/ 目录
        log "压缩共享资源包..."
        cd "${TEMP_DIR}"
        tar -czf "${RELEASE_DIR}/shared-${VERSION}.tar.gz" -C shared .
        log "✓ 共享资源包: ${RELEASE_DIR}/shared-${VERSION}.tar.gz ($(du -sh "${RELEASE_DIR}/shared-${VERSION}.tar.gz" | cut -f1))"
    else
        log "⚠️  共享资源包目录不存在，跳过"
    fi
}

log_section "[4] 复制地图包 (Chunk 11-24)"
{
    MAPS_SOURCE="${CHUNK_SOURCE}/${VERSION}/package_maps"
    if [ -d "$MAPS_SOURCE" ]; then
        log "复制地图包文件..."
        
        for map_dir in "$MAPS_SOURCE"/*/; do
            if [ -d "$map_dir" ]; then
                map_name=$(basename "$map_dir")
                if [ -n "$(ls -A "$map_dir" 2>/dev/null)" ]; then
                    log "  处理地图: $map_name"
                    
                    # 复制到临时目录
                    temp_map_dir="${TEMP_DIR}/maps/${map_name}"
                    mkdir -p "$temp_map_dir"
                    rsync -av "$map_dir" "$temp_map_dir/"
                    
                    # 为每个地图创建压缩文件，直接放到 releases/ 目录
                    cd "${TEMP_DIR}/maps"
                    tar -czf "${RELEASE_DIR}/${map_name}-${VERSION}.tar.gz" -C "${map_name}" .
                    map_size=$(du -sh "${RELEASE_DIR}/${map_name}-${VERSION}.tar.gz" | cut -f1)
                    log "    ✓ ${map_name}-${VERSION}.tar.gz ($map_size)"
                fi
            fi
        done
        
        log "✓ 所有地图包已复制并压缩"
    else
        log "⚠️  地图包目录不存在，跳过"
    fi
}

log_section "[5] 生成 SHA256 校验和"
{
    cd "${RELEASE_DIR}"
    
    # 为所有 tar.gz 文件生成 SHA256 校验和
    log "计算 SHA256 校验和..."
    for tar_file in *-${VERSION}.tar.gz; do
        if [ -f "$tar_file" ]; then
            sha256_file="${tar_file}.sha256"
            if [ ! -f "$sha256_file" ] || [ "$tar_file" -nt "$sha256_file" ]; then
                log "  计算: $tar_file"
                sha256sum "$tar_file" > "$sha256_file"
            fi
        fi
    done
    
    log "✓ SHA256 校验和已生成"
}

log_section "[6] 生成清单文件"
{
    cd "${RELEASE_DIR}"
    
    # 辅助函数：获取文件的 SHA256 校验和
    get_sha256() {
        local file="$1"
        local sha256_file="${file}.sha256"
        
        # 首先尝试查找 filename.sha256
        if [ -f "$sha256_file" ]; then
            awk '{print $1}' "$sha256_file"
        else
            # 如果文件被分片，可能校验和文件是 filename.tar.sha256
            local base_name="${file%.tar.gz}"
            local tar_sha256_file="${base_name}.tar.sha256"
            if [ -f "$tar_sha256_file" ]; then
                # 从校验和文件中提取（格式：hash  filename）
                awk '{print $1}' "$tar_sha256_file"
            elif [ -f "$file" ]; then
                # 如果文件存在，计算 SHA256
                sha256sum "$file" 2>/dev/null | awk '{print $1}'
            else
                echo "null"
            fi
        fi
    }
    
    # 辅助函数：检查是否为分片文件
    check_is_split() {
        local base_name="$1"
        if ls "${base_name}".tar.part* 1>/dev/null 2>&1; then
            echo "true"
        else
            echo "false"
        fi
    }
    
    # 辅助函数：获取分片文件列表（返回 JSON 数组字符串）
    get_parts() {
        local base_name="$1"
        local parts=()
        for part_file in "${base_name}".tar.part*; do
            if [ -f "$part_file" ]; then
                parts+=("$(basename "$part_file")")
            fi
        done
        # 按文件名排序
        IFS=$'\n' sorted_parts=($(printf '%s\n' "${parts[@]}" | sort))
        unset IFS
        
        # 生成 JSON 数组
        if [ ${#sorted_parts[@]} -eq 0 ]; then
            echo "[]"
        else
            echo -n "["
            local first=true
            for part in "${sorted_parts[@]}"; do
                if [ "$first" = true ]; then
                    first=false
                else
                    echo -n ","
                fi
                echo -n "\"${part}\""
            done
            echo -n "]"
        fi
    }
    
    # 获取 base 包的 SHA256
    BASE_SHA256=$(get_sha256 "base-${VERSION}.tar.gz")
    BASE_SIZE=$(stat -f%z "base-${VERSION}.tar.gz" 2>/dev/null || stat -c%s "base-${VERSION}.tar.gz" 2>/dev/null || echo 0)
    
    # 获取 shared 包的 SHA256 和分片信息
    SHARED_SHA256=$(get_sha256 "shared-${VERSION}.tar.gz")
    SHARED_SIZE=$(stat -f%z "shared-${VERSION}.tar.gz" 2>/dev/null || stat -c%s "shared-${VERSION}.tar.gz" 2>/dev/null || echo 0)
    SHARED_IS_SPLIT=$(check_is_split "shared-${VERSION}")
    
    cat > "manifest-${VERSION}.json" << EOF
{
  "version": "${VERSION}",
  "release_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "packages": {
    "base": {
      "file": "base-${VERSION}.tar.gz",
      "required": true,
      "description": "基础包 (Chunk 0) - 包含EmptyWorld和核心蓝图",
      "size": ${BASE_SIZE},
      "sha256": "${BASE_SHA256}"
    },
    "shared": {
      "file": "shared-${VERSION}.tar.gz",
      "required": false,
      "description": "共享资源包 (Chunk 1) - 包含Fab/Warehouse和StarterContent共享资源",
      "size": ${SHARED_SIZE},
      "sha256": "${SHARED_SHA256}"
EOF

    # 如果 shared 是分片文件，添加分片信息
    if [ "$SHARED_IS_SPLIT" = "true" ]; then
        SHARED_PARTS=$(get_parts "shared-${VERSION}")
        SHARED_MERGE_SCRIPT="shared-${VERSION}.tar.merge.sh"
        SHARED_CHECKSUM_FILE="shared-${VERSION}.tar.sha256"
        cat >> "manifest-${VERSION}.json" << EOF
,
      "is_split": true,
      "parts": ${SHARED_PARTS},
      "merge_script": "${SHARED_MERGE_SCRIPT}",
      "checksum_file": "${SHARED_CHECKSUM_FILE}"
EOF
    fi
    
    cat >> "manifest-${VERSION}.json" << EOF
    },
    "maps": [
EOF

    # 添加地图包信息
    cd "${RELEASE_DIR}"
    first=true
    for map_tar in *-${VERSION}.tar.gz; do
        # 跳过 base 和 shared
        if [[ "$map_tar" == base-* ]] || [[ "$map_tar" == shared-* ]]; then
            continue
        fi
        if [ -f "$map_tar" ]; then
            map_name=$(echo "$map_tar" | sed "s/-${VERSION}.tar.gz//")
            map_size=$(stat -f%z "$map_tar" 2>/dev/null || stat -c%s "$map_tar" 2>/dev/null || echo 0)
            map_sha256=$(get_sha256 "$map_tar")
            map_is_split=$(check_is_split "${map_name}-${VERSION}")
            
            if [ "$first" = true ]; then
                first=false
            else
                echo "," >> "manifest-${VERSION}.json"
            fi
            
            cat >> "manifest-${VERSION}.json" << EOF
      {
        "name": "${map_name}",
        "file": "${map_tar}",
        "required": false,
        "description": "地图包 - ${map_name}",
        "size": ${map_size},
        "sha256": "${map_sha256}"
EOF
            
            # 如果是分片文件，添加分片信息
            if [ "$map_is_split" = "true" ]; then
                map_parts=$(get_parts "${map_name}-${VERSION}")
                map_merge_script="${map_name}-${VERSION}.tar.merge.sh"
                map_checksum_file="${map_name}-${VERSION}.tar.sha256"
                cat >> "manifest-${VERSION}.json" << EOF
,
        "is_split": true,
        "parts": ${map_parts},
        "merge_script": "${map_merge_script}",
        "checksum_file": "${map_checksum_file}"
EOF
            fi
            
            cat >> "manifest-${VERSION}.json" << EOF
      }
EOF
        fi
    done
    
    cd "${RELEASE_DIR}"
    cat >> "manifest-${VERSION}.json" << EOF
    ]
  }
}
EOF

    log "✓ 清单文件已生成: manifest-${VERSION}.json"
    log "  - 包含 SHA256 校验和"
    log "  - 包含分片文件信息（如果存在）"
}

log_section "[7] 清理临时文件"
{
    if [ -d "$TEMP_DIR" ]; then
        log "清理临时目录..."
        rm -rf "$TEMP_DIR"
        log "✓ 临时目录已清理"
    fi
}

log_section "[8] 总结"
{
    cd "${RELEASE_DIR}"
    echo ""
    echo "✅ 发布包准备完成！"
    echo ""
    echo "📦 包文件 (在 releases/ 目录):"
    echo "  - 基础包: base-${VERSION}.tar.gz ($(du -sh "base-${VERSION}.tar.gz" | cut -f1))"
    if [ -f "shared-${VERSION}.tar.gz" ]; then
        echo "  - 共享资源包: shared-${VERSION}.tar.gz ($(du -sh "shared-${VERSION}.tar.gz" | cut -f1))"
    fi
    map_count=$(ls -1 *-${VERSION}.tar.gz 2>/dev/null | grep -v "^base-" | grep -v "^shared-" | wc -l)
    echo "  - 地图包数量: ${map_count}"
    echo ""
    echo "📁 发布目录: ${RELEASE_DIR}"
    echo ""
    echo "下一步:"
    echo "1. 检查发布文件: ls -lh ${RELEASE_DIR}/*.tar.gz"
    echo "2. 上传到 GitHub Releases: ./scripts/release_manager/upload_to_release.sh ${VERSION}"
    echo "3. Git 提交时 releases/ 目录保持为空（只有 .gitkeep）"
}
