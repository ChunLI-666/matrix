#!/bin/bash
set -euo pipefail

# ============================================================================
# 分割大文件工具（用于超过 2GB 的文件）
# 将大文件分割为多个小于 2GB 的部分，并提供合并脚本
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$PROJECT_ROOT" || exit 1

MAX_CHUNK_SIZE=2000000000  # 1.86GB (留一些余量，避免正好2GB)

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

error_exit() {
    log "❌ ERROR: $*"
    exit 1
}

split_file() {
    local input_file="$1"
    local output_dir="${2:-$(dirname "$input_file")}"
    local base_name=$(basename "$input_file")
    local base_name_no_ext="${base_name%.*}"
    local ext="${base_name##*.}"
    
    if [[ ! -f "$input_file" ]]; then
        error_exit "文件不存在: $input_file"
    fi
    
    local file_size=$(stat -c%s "$input_file" 2>/dev/null || stat -f%z "$input_file" 2>/dev/null || echo 0)
    local file_size_gb=$(echo "scale=2; $file_size / 1024 / 1024 / 1024" | bc)
    
    log "文件: $input_file"
    log "大小: ${file_size_gb}GB"
    
    if [[ $file_size -le $MAX_CHUNK_SIZE ]]; then
        log "文件小于 2GB，无需分割"
        return 0
    fi
    
    log "开始分割文件..."
    mkdir -p "$output_dir"
    
    # 使用 split 命令分割文件
    # -b: 每个分片的大小（字节）
    # -d: 使用数字后缀
    # -a: 后缀长度
    local chunk_prefix="${output_dir}/${base_name_no_ext}.part"
    split -b "${MAX_CHUNK_SIZE}" -d -a 3 "$input_file" "$chunk_prefix"
    
    # 计算分片数量
    local part_count=$(ls -1 "${chunk_prefix}"* 2>/dev/null | wc -l)
    log "✓ 分割完成，共 ${part_count} 个分片"
    
    # 生成合并脚本
    local merge_script="${output_dir}/${base_name_no_ext}.merge.sh"
    cat > "$merge_script" << 'EOFSCRIPT'
#!/bin/bash
# 自动生成的合并脚本
# 用法: ./merge.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_NAME="BASENAME_PLACEHOLDER"
EXT="EXT_PLACEHOLDER"
OUTPUT_FILE="${SCRIPT_DIR}/${BASE_NAME}.${EXT}"
CHECKSUM_FILE="${SCRIPT_DIR}/${BASE_NAME}.${EXT}.sha256"

echo "合并文件: ${BASE_NAME}.${EXT}"
echo "输出: ${OUTPUT_FILE}"

# 删除已存在的输出文件
if [[ -f "$OUTPUT_FILE" ]]; then
    # 检查校验和是否已匹配，如果匹配则无需覆盖
    if [[ -f "$CHECKSUM_FILE" ]]; then
        EXPECTED_SUM=$(cat "$CHECKSUM_FILE" | awk '{print $1}')
        CURRENT_SUM=$(sha256sum "$OUTPUT_FILE" 2>/dev/null | awk '{print $1}' || echo "none")
        if [[ "$EXPECTED_SUM" == "$CURRENT_SUM" ]]; then
            echo "✓ 文件已存在且校验和匹配，无需操作"
            exit 0
        fi
    fi

    read -p "输出文件已存在，是否覆盖? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "取消合并"
        exit 1
    fi
    rm -f "$OUTPUT_FILE"
fi

# 合并所有分片
echo "正在合并分片..."
cat "${SCRIPT_DIR}/${BASE_NAME}.part"* > "$OUTPUT_FILE"

# 验证校验和
if [[ -f "$CHECKSUM_FILE" ]]; then
    echo "验证校验和..."
    EXPECTED_SUM=$(cat "$CHECKSUM_FILE" | awk '{print $1}')
    CURRENT_SUM=$(sha256sum "$OUTPUT_FILE" | awk '{print $1}')
    
    if [[ "$EXPECTED_SUM" == "$CURRENT_SUM" ]]; then
        echo "✓ 校验和匹配！"
        echo "✓ 合并成功！"
        echo "✓ 可以删除分片文件: rm ${BASE_NAME}.part*"
    else
        echo "❌ 校验和不匹配！"
        echo "  期望: $EXPECTED_SUM"
        echo "  实际: $CURRENT_SUM"
        echo "删除损坏的文件..."
        rm -f "$OUTPUT_FILE"
        exit 1
    fi
else
    # 验证文件大小 (兼容旧逻辑)
    EXPECTED_SIZE="EXPECTED_SIZE_PLACEHOLDER"
    ACTUAL_SIZE=$(stat -c%s "$OUTPUT_FILE" 2>/dev/null || stat -f%z "$OUTPUT_FILE" 2>/dev/null || echo 0)

    if [[ "$ACTUAL_SIZE" == "$EXPECTED_SIZE" ]]; then
        echo "✓ 合并成功！文件大小: $(echo "scale=2; $ACTUAL_SIZE / 1024 / 1024 / 1024" | bc)GB"
        echo "⚠️  注意: 未找到校验和文件，仅验证了文件大小"
        echo "✓ 可以删除分片文件: rm ${BASE_NAME}.part*"
    else
        echo "❌ 文件大小不匹配"
        echo "  期望: ${EXPECTED_SIZE} 字节"
        echo "  实际: ${ACTUAL_SIZE} 字节"
        exit 1
    fi
fi
EOFSCRIPT
    
    # 替换占位符
    sed -i "s/BASENAME_PLACEHOLDER/${base_name_no_ext}/g" "$merge_script"
    sed -i "s/EXT_PLACEHOLDER/${ext}/g" "$merge_script"
    sed -i "s/EXPECTED_SIZE_PLACEHOLDER/${file_size}/g" "$merge_script"
    chmod +x "$merge_script"
    
    log "✓ 合并脚本已生成: $merge_script"
    
    # 生成校验和文件
    local checksum_file="${output_dir}/${base_name_no_ext}.sha256"
    log "计算校验和..."
    sha256sum "$input_file" > "$checksum_file"
    log "✓ 校验和已保存: $checksum_file"
    
    # 列出所有生成的文件
    log ""
    log "生成的文件:"
    ls -lh "${chunk_prefix}"* "$merge_script" "$checksum_file" 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
}

# 主程序
if [[ $# -lt 1 ]]; then
    echo "用法: $0 <文件路径> [输出目录]"
    echo ""
    echo "示例:"
    echo "  $0 releases/chunks/2.0.8/maps/Town10World-2.0.8.tar.gz"
    echo "  $0 releases/chunks/2.0.8/maps/Town10World-2.0.8.tar.gz releases/chunks/2.0.8/maps/split"
    exit 1
fi

split_file "$1" "${2:-}"

