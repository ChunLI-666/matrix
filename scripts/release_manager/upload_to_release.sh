#!/bin/bash
set -e

# ============================================================================
# 使用 GitHub CLI 上传文件到 Release
# 需要先安装: sudo apt install gh
# 需要先登录: gh auth login
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$PROJECT_ROOT"

VERSION="${1:-2.0.8}"
REPO="Alphabaijinde/matrix"
RELEASE_DIR="releases"
MAX_SIZE=2147483648  # 2GB in bytes (GitHub Releases limit)

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

# 检查 GitHub CLI
if ! command -v gh &> /dev/null; then
    log "GitHub CLI 未安装"
    log ""
    log "请先安装 GitHub CLI:"
    log "  sudo apt update"
    log "  sudo apt install -y gh"
    log ""
    log "然后登录:"
    log "  gh auth login"
    error_exit "需要先安装并登录 GitHub CLI"
fi

# 检查是否已登录
if ! gh auth status &>/dev/null; then
    log "GitHub CLI 未登录"
    log ""
    log "请先登录:"
    log "  gh auth login"
    error_exit "需要先登录 GitHub CLI"
fi

log "✓ GitHub CLI 已就绪"

log_section "上传文件到 GitHub Release v${VERSION}"

# 检查 Release 目录
if [ ! -d "$RELEASE_DIR" ]; then
    error_exit "Release 目录不存在: $RELEASE_DIR"
fi

# 检查基础包和共享包是否存在
if [ ! -f "${RELEASE_DIR}/base-${VERSION}.tar.gz" ]; then
    error_exit "基础包不存在: ${RELEASE_DIR}/base-${VERSION}.tar.gz"
fi
if [ ! -f "${RELEASE_DIR}/shared-${VERSION}.tar.gz" ]; then
    error_exit "共享资源包不存在: ${RELEASE_DIR}/shared-${VERSION}.tar.gz"
fi

# 检查 Release 是否存在
if ! gh release view "v${VERSION}" --repo "$REPO" &>/dev/null; then
    log "创建 Release v${VERSION}..."
    if [ -f "${RELEASE_DIR}/README.md" ]; then
        gh release create "v${VERSION}" \
            --repo "$REPO" \
            --title "MATRiX v${VERSION} - Modular Chunk Packages" \
            --notes-file "${RELEASE_DIR}/README.md" \
            --draft
    else
        gh release create "v${VERSION}" \
            --repo "$REPO" \
            --title "MATRiX v${VERSION} - Modular Chunk Packages" \
            --notes "MATRiX v${VERSION} - Modular Chunk Packages" \
            --draft
    fi
    log "✓ Release 已创建（草稿状态）"
else
    log "Release v${VERSION} 已存在"
fi

# 上传基础包
log_section "[1] 上传基础包"
if [ -f "${RELEASE_DIR}/base-${VERSION}.tar.gz" ]; then
    file_size=$(stat -c%s "${RELEASE_DIR}/base-${VERSION}.tar.gz" 2>/dev/null || stat -f%z "${RELEASE_DIR}/base-${VERSION}.tar.gz" 2>/dev/null || echo 0)
    file_size_mb=$((file_size / 1024 / 1024))
    
    if [ "$file_size" -gt "$MAX_SIZE" ]; then
        log "⚠️  跳过基础包: base-${VERSION}.tar.gz (${file_size_mb}MB, 超过 2GB 限制)"
        log "   提示: 大文件需要使用其他方式上传（如 Google Drive, Baidu Netdisk）"
    else
        log "上传: base-${VERSION}.tar.gz (${file_size_mb}MB)"
        if gh release upload "v${VERSION}" \
            "${RELEASE_DIR}/base-${VERSION}.tar.gz" \
            --repo "$REPO" \
            --clobber; then
            log "✓ 基础包上传完成"
        else
            log "⚠️  基础包上传失败"
        fi
    fi
else
    log "⚠️  基础包文件不存在，跳过"
fi

# 上传共享资源包
log_section "[2] 上传共享资源包"
if [ -f "${RELEASE_DIR}/shared-${VERSION}.tar.gz" ]; then
    file_size=$(stat -c%s "${RELEASE_DIR}/shared-${VERSION}.tar.gz" 2>/dev/null || stat -f%z "${RELEASE_DIR}/shared-${VERSION}.tar.gz" 2>/dev/null || echo 0)
    file_size_mb=$((file_size / 1024 / 1024))
    
    if [ "$file_size" -gt "$MAX_SIZE" ]; then
        log "⚠️  跳过共享资源包: shared-${VERSION}.tar.gz (${file_size_mb}MB, 超过 2GB 限制)"
        log "   提示: 大文件需要使用其他方式上传"
    else
        log "上传: shared-${VERSION}.tar.gz (${file_size_mb}MB)"
        if gh release upload "v${VERSION}" \
            "${RELEASE_DIR}/shared-${VERSION}.tar.gz" \
            --repo "$REPO" \
            --clobber; then
            log "✓ 共享资源包上传完成"
        else
            log "⚠️  共享资源包上传失败"
        fi
    fi
else
    log "⚠️  共享资源包文件不存在，跳过"
fi

# 上传地图包
log_section "[3] 上传地图包"
map_count=0
skip_count=0
split_count=0
SPLIT_SCRIPT="${SCRIPT_DIR}/split_large_file.sh"

if ls "${RELEASE_DIR}"/*-${VERSION}.tar.gz 1> /dev/null 2>&1; then
    for map_tar in "${RELEASE_DIR}"/*-${VERSION}.tar.gz; do
        if [ -f "$map_tar" ]; then
            # Skip base and shared packages (already uploaded)
            if [[ "$map_tar" == *"base-${VERSION}.tar.gz" ]] || [[ "$map_tar" == *"shared-${VERSION}.tar.gz" ]]; then
                continue
            fi
            map_name=$(basename "$map_tar")
            file_size=$(stat -c%s "$map_tar" 2>/dev/null || stat -f%z "$map_tar" 2>/dev/null || echo 0)
            file_size_mb=$((file_size / 1024 / 1024))
            file_size_gb=$(echo "scale=2; $file_size / 1024 / 1024 / 1024" | bc)
            
            if [ "$file_size" -gt "$MAX_SIZE" ]; then
                log "⚠️  大文件: $map_name (${file_size_gb}GB, 超过 2GB 限制)"
                
                # 检查是否已分割
                map_base="${map_name%.tar.gz}"
                split_dir="${RELEASE_DIR}/maps/split"
                if [ -f "${split_dir}/${map_base}.part000" ]; then
                    log "  检测到已分割的文件，上传分片..."
                    part_count=$(ls -1 "${split_dir}/${map_base}.part"* 2>/dev/null | wc -l)
                    log "  分片数量: ${part_count}"
                    
                    # 上传所有分片
                    upload_success=true
                    for part_file in "${split_dir}/${map_base}.part"*; do
                        if [ -f "$part_file" ]; then
                            part_name=$(basename "$part_file")
                            part_size=$(stat -c%s "$part_file" 2>/dev/null || stat -f%z "$part_file" 2>/dev/null || echo 0)
                            part_size_mb=$((part_size / 1024 / 1024))
                            log "  上传分片: $part_name (${part_size_mb}MB)"
                            if ! gh release upload "v${VERSION}" \
                                "$part_file" \
                                --repo "$REPO" \
                                --clobber; then
                                log "    ⚠️  分片上传失败: $part_name"
                                upload_success=false
                            fi
                        fi
                    done
                    
                    # 上传合并脚本和校验和
                    if [ -f "${split_dir}/${map_base}.merge.sh" ]; then
                        log "  上传合并脚本: ${map_base}.merge.sh"
                        gh release upload "v${VERSION}" \
                            "${split_dir}/${map_base}.merge.sh" \
                            --repo "$REPO" \
                            --clobber || upload_success=false
                    fi
                    
                    if [ -f "${split_dir}/${map_base}.sha256" ]; then
                        log "  上传校验和: ${map_base}.sha256"
                        gh release upload "v${VERSION}" \
                            "${split_dir}/${map_base}.sha256" \
                            --repo "$REPO" \
                            --clobber || upload_success=false
                    fi
                    
                    if [ "$upload_success" == true ]; then
                        log "  ✓ 分片上传成功"
                        ((split_count++))
                    else
                        log "  ⚠️  部分分片上传失败"
                    fi
                else
                    log "  提示: 运行以下命令分割文件："
                    log "    $SPLIT_SCRIPT \"$map_tar\""
                    log "  或者使用其他方式上传（如 Google Drive, Baidu Netdisk）"
                    ((skip_count++))
                fi
            else
                log "上传: $map_name (${file_size_mb}MB)"
                if gh release upload "v${VERSION}" \
                    "$map_tar" \
                    --repo "$REPO" \
                    --clobber; then
                    log "  ✓ 上传成功"
                    ((map_count++))
                else
                    log "  ⚠️  上传失败"
                fi
            fi
        fi
    done
    log "✓ 已上传 ${map_count} 个地图包"
    if [ "$split_count" -gt 0 ]; then
        log "✓ 已上传 ${split_count} 个大文件的分片"
    fi
    if [ "$skip_count" -gt 0 ]; then
        log "⚠️  跳过 ${skip_count} 个超过 2GB 的文件（未分割）"
    fi
else
    log "⚠️  地图包目录不存在，跳过"
fi

# 上传清单文件
log_section "[4] 上传清单文件"
if [ -f "${RELEASE_DIR}/manifest-${VERSION}.json" ]; then
    log "上传: manifest-${VERSION}.json"
    if gh release upload "v${VERSION}" \
        "${RELEASE_DIR}/manifest-${VERSION}.json" \
        --repo "$REPO" \
        --clobber; then
        log "✓ 清单文件上传完成"
    else
        log "⚠️  清单文件上传失败"
    fi
else
    log "⚠️  清单文件不存在，跳过"
fi

log_section "[5] 完成"
echo ""
echo "✅ 文件上传完成！"
echo ""
echo "📊 上传统计:"
echo "  - 基础包: $(if [ -f "${RELEASE_DIR}/base-${VERSION}.tar.gz" ]; then file_size=$(stat -c%s "${RELEASE_DIR}/base-${VERSION}.tar.gz" 2>/dev/null || echo 0); if [ "$file_size" -le "$MAX_SIZE" ]; then echo "已上传"; else echo "已跳过（超过2GB）"; fi; else echo "不存在"; fi)"
echo "  - 共享资源包: $(if [ -f "${RELEASE_DIR}/shared-${VERSION}.tar.gz" ]; then file_size=$(stat -c%s "${RELEASE_DIR}/shared-${VERSION}.tar.gz" 2>/dev/null || echo 0); if [ "$file_size" -le "$MAX_SIZE" ]; then echo "已上传"; else echo "已跳过（超过2GB）"; fi; else echo "不存在"; fi)"
echo "  - 地图包: ${map_count} 个已上传"
if [ "$skip_count" -gt 0 ]; then
    echo "  - 跳过: ${skip_count} 个超过 2GB 的文件"
fi
echo ""
if [ "$skip_count" -gt 0 ]; then
    echo "⚠️  注意: 有 ${skip_count} 个文件超过 GitHub Releases 的 2GB 限制"
    echo "   这些文件需要上传到其他存储（如 Google Drive, Baidu Netdisk）"
    echo ""
fi
read -p "是否发布 Release? (从草稿状态发布) [Y/n]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    log "发布 Release..."
    gh release edit "v${VERSION}" --repo "$REPO" --draft=false
    log "✓ Release 已发布！"
    echo ""
    echo "🔗 Release 链接:"
    echo "  https://github.com/${REPO}/releases/tag/v${VERSION}"
else
    log "保持草稿状态"
    echo ""
    echo "稍后可以手动发布:"
    echo "  gh release edit v${VERSION} --repo ${REPO} --draft=false"
fi
