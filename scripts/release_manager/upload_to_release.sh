#!/bin/bash
set -euo pipefail

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

# 函数：显示上传进度
show_upload_progress() {
    local current=$1
    local total=$2
    local filename=$3
    local file_size_mb=$4
    
    local percent=$((current * 100 / total))
    local bar_length=30
    local filled=$((percent * bar_length / 100))
    local empty=$((bar_length - filled))
    
    printf "\r[进度] ["
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' '-'
    printf "] %3d%% (%d/%d) - %s (%dMB)" "$percent" "$current" "$total" "$filename" "$file_size_mb"
}

# 函数：上传文件（带进度显示）
upload_file_with_progress() {
    local file="$1"
    local current_num=$2
    local total_num=$3
    local filename=$(basename "$file")
    local file_size=${file_sizes["$file"]:-0}
    local file_size_mb=$((file_size / 1024 / 1024))
    
    # 显示开始上传
    show_upload_progress "$current_num" "$total_num" "$filename" "$file_size_mb"
    echo ""
    
    # 记录开始时间
    local start_time=$(date +%s)
    
    # 执行上传（在后台运行，同时显示进度）
    local upload_pid
    local temp_output=$(mktemp)
    
    if gh release upload "v${VERSION}" "$file" --repo "$REPO" --clobber > "$temp_output" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local speed_mb=$(echo "scale=2; $file_size_mb / $duration" | bc 2>/dev/null || echo "0")
        
        printf "\r[完成] ✓ %s (%dMB, 耗时: %ds, 速度: %.2fMB/s)\n" "$filename" "$file_size_mb" "$duration" "$speed_mb"
        rm -f "$temp_output"
        return 0
    else
        printf "\r[失败] ⚠️  %s 上传失败\n" "$filename"
        cat "$temp_output" >&2
        rm -f "$temp_output"
        return 1
    fi
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

log_section "检查要上传的文件"

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

# 收集所有需要上传的文件
log "扫描需要上传的文件..."
files_to_upload=()
declare -A file_sizes  # 关联数组存储文件大小

# 基础包和共享包
for file in "${RELEASE_DIR}/base-${VERSION}.tar.gz" "${RELEASE_DIR}/shared-${VERSION}.tar.gz"; do
    if [ -f "$file" ]; then
        files_to_upload+=("$file")
        size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo 0)
        file_sizes["$file"]=$size
    fi
done

# 地图包
for file in "${RELEASE_DIR}"/*-${VERSION}.tar.gz; do
    if [ -f "$file" ] && [[ "$file" != *"base-${VERSION}.tar.gz" ]] && [[ "$file" != *"shared-${VERSION}.tar.gz" ]]; then
        filename=$(basename "$file")
        base_name="${filename%.tar.gz}"
        # 如果文件超过2GB，检查是否有分片文件
        size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo 0)
        if [ "$size" -gt "$MAX_SIZE" ] && { [ -f "${RELEASE_DIR}/${base_name}.part000" ] || [ -f "${RELEASE_DIR}/${base_name}.tar.part000" ]; }; then
            # 已分割，添加分片文件而不是原始文件
            # 尝试两种命名模式
            if [ -f "${RELEASE_DIR}/${base_name}.part000" ]; then
                pattern="${RELEASE_DIR}/${base_name}"
            else
                pattern="${RELEASE_DIR}/${base_name}.tar"
            fi
            
            for part_file in "${pattern}.part"* "${pattern}.merge.sh" "${pattern}.sha256"; do
                if [ -f "$part_file" ]; then
                    files_to_upload+=("$part_file")
                    part_size=$(stat -c%s "$part_file" 2>/dev/null || stat -f%z "$part_file" 2>/dev/null || echo 0)
                    file_sizes["$part_file"]=$part_size
                fi
            done
        else
            # 未分割或小于2GB，添加原始文件
            files_to_upload+=("$file")
            file_sizes["$file"]=$size
        fi
    fi
done

# 清单文件
if [ -f "${RELEASE_DIR}/manifest-${VERSION}.json" ]; then
    files_to_upload+=("${RELEASE_DIR}/manifest-${VERSION}.json")
    size=$(stat -c%s "${RELEASE_DIR}/manifest-${VERSION}.json" 2>/dev/null || stat -f%z "${RELEASE_DIR}/manifest-${VERSION}.json" 2>/dev/null || echo 0)
    file_sizes["${RELEASE_DIR}/manifest-${VERSION}.json"]=$size
fi

total_files=${#files_to_upload[@]}
total_size=0
for file in "${files_to_upload[@]}"; do
    total_size=$((total_size + ${file_sizes["$file"]:-0}))
done
total_size_gb=$(echo "scale=2; $total_size / 1024 / 1024 / 1024" | bc)

log "✓ 找到 ${total_files} 个文件需要上传，总大小: ${total_size_gb}GB"

# 检查 Release 是否存在，如果存在则检查已上传的文件
uploaded_files_info=""
if gh release view "v${VERSION}" --repo "$REPO" &>/dev/null; then
    log "检查已上传的文件..."
    uploaded_files_info=$(gh release view "v${VERSION}" --repo "$REPO" --json assets --jq '.assets[] | "\(.name)|\(.size)"' 2>/dev/null || echo "")
    if [ -n "$uploaded_files_info" ]; then
        uploaded_count=$(echo "$uploaded_files_info" | wc -l)
        log "✓ Release 已存在，已上传 ${uploaded_count} 个文件"
    fi
fi

log_section "上传文件到 GitHub Release v${VERSION}"

# 检查 Release 是否存在，不存在则创建
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
    # 重新获取已上传文件信息（应该为空）
    uploaded_files_info=""
fi

# 函数：刷新已上传文件信息
refresh_uploaded_files() {
    uploaded_files_info=$(gh release view "v${VERSION}" --repo "$REPO" --json assets --jq '.assets[] | "\(.name)|\(.size)"' 2>/dev/null || echo "")
}

# 函数：检查文件是否已上传且完整
check_file_uploaded() {
    local file="$1"
    local filename=$(basename "$file")
    local local_size=${file_sizes["$file"]:-0}
    
    # 如果已上传文件信息为空，先刷新
    if [ -z "$uploaded_files_info" ]; then
        refresh_uploaded_files || true
    fi
    
    if [ -z "$uploaded_files_info" ]; then
        return 1  # 未上传
    fi
    
    # 检查文件名和大小是否匹配
    while IFS='|' read -r name size || [ -n "$name" ]; do
        if [ "$name" == "$filename" ] && [ "$size" == "$local_size" ]; then
            return 0  # 已上传且完整
        fi
    done <<< "$uploaded_files_info"
    
    return 1  # 未上传或不完整
}

# 上传基础包
log_section "[1] 上传基础包"
base_file="${RELEASE_DIR}/base-${VERSION}.tar.gz"
if [ -f "$base_file" ]; then
    file_size=${file_sizes["$base_file"]:-0}
    file_size_mb=$((file_size / 1024 / 1024))
    
    if check_file_uploaded "$base_file"; then
        log "✓ 基础包已上传且完整，跳过: base-${VERSION}.tar.gz (${file_size_mb}MB)"
    elif [ "$file_size" -gt "$MAX_SIZE" ]; then
        log "⚠️  跳过基础包: base-${VERSION}.tar.gz (${file_size_mb}MB, 超过 2GB 限制)"
        log "   提示: 大文件需要使用其他方式上传（如 Google Drive, Baidu Netdisk）"
    else
        ((current_upload_num++))
        if upload_file_with_progress "$base_file" "$current_upload_num" "$files_to_upload_count"; then
            refresh_uploaded_files  # 刷新已上传文件列表
        fi
    fi
else
    log "⚠️  基础包文件不存在，跳过"
fi

# 上传共享资源包
log_section "[2] 上传共享资源包"
shared_file="${RELEASE_DIR}/shared-${VERSION}.tar.gz"
if [ -f "$shared_file" ]; then
    file_size=${file_sizes["$shared_file"]:-0}
    file_size_mb=$((file_size / 1024 / 1024))
    
    if check_file_uploaded "$shared_file"; then
        log "✓ 共享资源包已上传且完整，跳过: shared-${VERSION}.tar.gz (${file_size_mb}MB)"
    elif [ "$file_size" -gt "$MAX_SIZE" ]; then
        log "⚠️  跳过共享资源包: shared-${VERSION}.tar.gz (${file_size_mb}MB, 超过 2GB 限制)"
        log "   提示: 大文件需要使用其他方式上传"
    else
        ((current_upload_num++))
        if upload_file_with_progress "$shared_file" "$current_upload_num" "$files_to_upload_count"; then
            refresh_uploaded_files  # 刷新已上传文件列表
        fi
    fi
else
    log "⚠️  共享资源包文件不存在，跳过"
fi

# 上传地图包和其他文件
log_section "[3] 上传地图包和其他文件"
map_count=0
skip_count=0
split_count=0
skipped_count=0
SPLIT_SCRIPT="${SCRIPT_DIR}/split_large_file.sh"

# 计算需要上传的文件总数（排除已上传的）
files_to_upload_count=0
for file in "${files_to_upload[@]}"; do
    if [ -f "$file" ]; then
        if ! check_file_uploaded "$file" 2>/dev/null || true; then
            # 如果 check_file_uploaded 返回 1（未上传），则计数
            if ! check_file_uploaded "$file" 2>/dev/null; then
                ((files_to_upload_count++)) || true
            fi
        fi
    fi
done

if [ "$files_to_upload_count" -gt 0 ]; then
    log "需要上传 ${files_to_upload_count} 个文件"
else
    log "所有文件已上传，无需上传新文件"
fi

current_upload_num=0

# 遍历所有需要上传的文件
log "开始遍历文件数组，共 ${#files_to_upload[@]} 个文件"
for file in "${files_to_upload[@]}"; do
    if [ ! -f "$file" ]; then
        continue
    fi
    
    filename=$(basename "$file")
    
    # 跳过基础包和共享包（已在前面处理）
    if [[ "$filename" == "base-${VERSION}.tar.gz" ]] || [[ "$filename" == "shared-${VERSION}.tar.gz" ]] || [[ "$filename" == "manifest-${VERSION}.json" ]]; then
        continue
    fi
    
    # 检查是否已上传且完整
    if check_file_uploaded "$file" 2>/dev/null; then
        file_size=${file_sizes["$file"]:-0}
        file_size_mb=$((file_size / 1024 / 1024))
        log "✓ 已上传且完整，跳过: $filename (${file_size_mb}MB)"
            skipped_count=$((skipped_count + 1))
        continue
    fi
    
    file_size=${file_sizes["$file"]:-0}
    file_size_mb=$((file_size / 1024 / 1024))
    file_size_gb=$(echo "scale=2; $file_size / 1024 / 1024 / 1024" | bc)
    
    # 处理分片文件
    if [[ "$filename" == *.part* ]]; then
        if check_file_uploaded "$file" 2>/dev/null; then
            log "✓ 已上传且完整，跳过: $filename (${file_size_mb}MB)"
        else
            current_upload_num=$((current_upload_num + 1))
            if upload_file_with_progress "$file" "$current_upload_num" "$files_to_upload_count"; then
                refresh_uploaded_files  # 刷新已上传文件列表
            fi
        fi
        continue
    fi
    
    # 处理合并脚本和校验和
    if [[ "$filename" == *.merge.sh ]] || [[ "$filename" == *.sha256 ]]; then
        if check_file_uploaded "$file" 2>/dev/null; then
            log "✓ 已上传且完整，跳过: $filename"
        else
            current_upload_num=$((current_upload_num + 1))
            if upload_file_with_progress "$file" "$current_upload_num" "$files_to_upload_count"; then
                refresh_uploaded_files  # 刷新已上传文件列表
            fi
        fi
        continue
    fi
    
    # 处理普通地图包
    if [[ "$filename" == *-${VERSION}.tar.gz ]]; then
        if check_file_uploaded "$file" 2>/dev/null; then
            log "✓ 已上传且完整，跳过: $filename (${file_size_mb}MB)"
            map_count=$((map_count + 1))
        elif [ "$file_size" -gt "$MAX_SIZE" ]; then
            log "⚠️  大文件: $filename (${file_size_gb}GB, 超过 2GB 限制)"
            map_base="${filename%.tar.gz}"
            # 检查 releases/ 目录下是否有分片文件
            if [ -f "${RELEASE_DIR}/${map_base}.part000" ] || [ -f "${RELEASE_DIR}/${map_base}.tar.part000" ]; then
                log "  检测到已分割的文件，分片将在后续处理"
                split_count=$((split_count + 1))
            else
                log "  提示: 运行以下命令分割文件："
                log "    $SPLIT_SCRIPT \"$file\""
                log "  或者使用其他方式上传（如 Google Drive, Baidu Netdisk）"
                skip_count=$((skip_count + 1))
            fi
        else
            current_upload_num=$((current_upload_num + 1))
            if upload_file_with_progress "$file" "$current_upload_num" "$files_to_upload_count"; then
                map_count=$((map_count + 1))
                refresh_uploaded_files  # 刷新已上传文件列表
            fi
        fi
    fi
done

log "✓ 已上传 ${map_count} 个地图包"
if [ "$split_count" -gt 0 ]; then
    log "✓ 已处理 ${split_count} 个大文件的分片"
fi
if [ "$skipped_count" -gt 0 ]; then
    log "✓ 已跳过 ${skipped_count} 个已上传且完整的文件"
fi
if [ "$skip_count" -gt 0 ]; then
    log "⚠️  跳过 ${skip_count} 个超过 2GB 的文件（未分割）"
fi

# 上传清单文件
log_section "[4] 上传清单文件"
manifest_file="${RELEASE_DIR}/manifest-${VERSION}.json"
if [ -f "$manifest_file" ]; then
    if check_file_uploaded "$manifest_file" 2>/dev/null; then
        log "✓ 清单文件已上传且完整，跳过: manifest-${VERSION}.json"
    else
        current_upload_num=$((current_upload_num + 1))
        if upload_file_with_progress "$manifest_file" "$current_upload_num" "$files_to_upload_count"; then
            refresh_uploaded_files  # 刷新已上传文件列表
        fi
    fi
else
    log "⚠️  清单文件不存在，跳过"
fi

# 最终验证上传完整性
log_section "[5] 最终验证上传完整性"
log "重新获取已上传文件列表..."
refresh_uploaded_files

if [ -z "$uploaded_files_info" ]; then
    log "⚠️  无法获取已上传文件列表，跳过验证"
else
    missing_count=0
    incomplete_count=0
    uploaded_missing=0
    
    log "检查所有文件的完整性..."
    for file in "${files_to_upload[@]}"; do
        if [ ! -f "$file" ]; then
            continue
        fi
        
        filename=$(basename "$file")
        local_size=${file_sizes["$file"]:-0}
        
        # 检查文件是否已上传
        found=false
        remote_size=0
        while IFS='|' read -r name size; do
            if [ "$name" == "$filename" ]; then
                found=true
                remote_size=$size
                break
            fi
        done <<< "$uploaded_files_info"
        
        if [ "$found" == false ]; then
            log "⚠️  缺失: $filename"
            ((missing_count++))
            
            # 尝试上传缺失的文件
            file_size_mb=$((local_size / 1024 / 1024))
            if [ "$local_size" -gt "$MAX_SIZE" ]; then
                log "  跳过（超过 2GB 限制）"
            else
                ((current_upload_num++))
                if upload_file_with_progress "$file" "$current_upload_num" "$files_to_upload_count"; then
                    ((uploaded_missing++))
                    refresh_uploaded_files  # 刷新已上传文件列表
                fi
            fi
        elif [ "$remote_size" != "$local_size" ]; then
            log "⚠️  文件大小不匹配: $filename (本地: ${local_size}, 远程: ${remote_size})"
            ((incomplete_count++))
            # 重新上传
            file_size_mb=$((local_size / 1024 / 1024))
            ((current_upload_num++))
            if upload_file_with_progress "$file" "$current_upload_num" "$files_to_upload_count"; then
                ((uploaded_missing++))
                refresh_uploaded_files  # 刷新已上传文件列表
            fi
        fi
    done
    
    if [ "$missing_count" -eq 0 ] && [ "$incomplete_count" -eq 0 ]; then
        log "✓ 所有文件已上传且完整"
    elif [ "$uploaded_missing" -gt 0 ]; then
        log "✓ 已补上传 ${uploaded_missing} 个缺失或不完整的文件"
        if [ "$uploaded_missing" -lt $((missing_count + incomplete_count)) ]; then
            log "⚠️  仍有 $((missing_count + incomplete_count - uploaded_missing)) 个文件缺失或不完整"
        fi
    else
        log "⚠️  仍有 ${missing_count} 个文件缺失，${incomplete_count} 个文件不完整"
    fi
fi

log_section "[6] 完成"
echo ""
echo "✅ 文件上传完成！"
echo ""
echo "📊 上传统计:"
total_uploaded=$(gh release view "v${VERSION}" --repo "$REPO" --json assets -q '.assets | length' 2>/dev/null || echo "0")
echo "  - 总文件数: ${total_uploaded}"
echo "  - 基础包: $(if [ -f "${RELEASE_DIR}/base-${VERSION}.tar.gz" ]; then file_size=$(stat -c%s "${RELEASE_DIR}/base-${VERSION}.tar.gz" 2>/dev/null || echo 0); if [ "$file_size" -le "$MAX_SIZE" ]; then echo "已上传"; else echo "已跳过（超过2GB）"; fi; else echo "不存在"; fi)"
echo "  - 共享资源包: $(if [ -f "${RELEASE_DIR}/shared-${VERSION}.tar.gz" ]; then file_size=$(stat -c%s "${RELEASE_DIR}/shared-${VERSION}.tar.gz" 2>/dev/null || echo 0); if [ "$file_size" -le "$MAX_SIZE" ]; then echo "已上传"; else echo "已跳过（超过2GB）"; fi; else echo "不存在"; fi)"
echo "  - 地图包: ${map_count} 个已上传"
if [ "$split_count" -gt 0 ]; then
    echo "  - 分割文件: ${split_count} 个大文件已分割上传"
fi
if [ "$skip_count" -gt 0 ]; then
    echo "  - 跳过: ${skip_count} 个超过 2GB 的文件（未分割）"
fi
echo ""
if [ "$skip_count" -gt 0 ]; then
    echo "⚠️  注意: 有 ${skip_count} 个文件超过 GitHub Releases 的 2GB 限制"
    echo "   这些文件需要上传到其他存储（如 Google Drive, Baidu Netdisk）"
    echo ""
fi
# 检查 Release 是否为草稿状态
is_draft=$(gh release view "v${VERSION}" --repo "$REPO" --json isDraft -q '.isDraft' 2>/dev/null || echo "false")

if [ "$is_draft" == "true" ]; then
    read -p "是否发布 Release? (从草稿状态发布) [Y/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        log "发布 Release..."
        # 使用 GitHub API 发布 Release（某些版本的 gh CLI 不支持 release edit 命令）
        release_id=$(gh release view "v${VERSION}" --repo "$REPO" --json id -q '.id' 2>/dev/null)
        if [ -n "$release_id" ]; then
            if gh api "repos/${REPO}/releases/${release_id}" -X PATCH -f draft=false 2>/dev/null; then
                log "✓ Release 已发布！"
            else
                log "⚠️  发布失败，请手动发布:"
                log "  release_id=\$(gh release view v${VERSION} --repo ${REPO} --json id -q '.id')"
                log "  gh api repos/${REPO}/releases/\${release_id} -X PATCH -f draft=false"
            fi
        else
            log "⚠️  无法获取 Release ID，请手动发布"
        fi
        echo ""
        echo "🔗 Release 链接:"
        echo "  https://github.com/${REPO}/releases/tag/v${VERSION}"
    else
        log "保持草稿状态"
        echo ""
        echo "稍后可以手动发布:"
        echo "  release_id=\$(gh release view v${VERSION} --repo ${REPO} --json id -q '.id')"
        echo "  gh api repos/${REPO}/releases/\${release_id} -X PATCH -f draft=false"
    fi
else
    log "✓ Release 已经是发布状态"
    echo ""
    echo "🔗 Release 链接:"
    echo "  https://github.com/${REPO}/releases/tag/v${VERSION}"
fi
