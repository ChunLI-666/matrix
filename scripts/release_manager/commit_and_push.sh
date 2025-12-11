#!/bin/bash
set -e

# ============================================================================
# 提交并推送 Chunk Packages 相关更改
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 加载公共函数库
source "${SCRIPT_DIR}/common.sh"
cd "$PROJECT_ROOT"

BRANCH="feature/chunk-packages-release"
VERSION="${1:-0.0.4}"  # 可以通过参数传入版本号，默认 0.0.4

# 检查当前分支
current_branch=$(git branch --show-current)
if [ "$current_branch" != "$BRANCH" ]; then
    log "当前分支: $current_branch"
    read -p "是否切换到分支 $BRANCH? [Y/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        git checkout "$BRANCH" || git checkout -b "$BRANCH"
    else
        log "使用当前分支: $current_branch"
        BRANCH="$current_branch"
    fi
fi

log_section "[1] 检查 Git 状态"
{
    git status --short
    echo ""
    read -p "确认提交这些更改? [Y/n]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log "取消提交"
        exit 0
    fi
}

log_section "[2] 添加文件"
{
    # 确保不包含 .tar.gz 文件
    git add .gitignore
    git add .gitattributes
    
    # 添加文档文件（如果存在）
    [ -f "docs/CHUNK_PACKAGES_GUIDE.md" ] && git add docs/CHUNK_PACKAGES_GUIDE.md
    [ -f "docs/GIT_LFS_GUIDE.md" ] && git add docs/GIT_LFS_GUIDE.md
    [ -f "docs/README_1.md" ] && git add docs/README_1.md
    [ -f "docs/README_2.md" ] && git add docs/README_2.md
    [ -f "docs/README_CN.md" ] && git add docs/README_CN.md
    [ -f "README.md" ] && git add README.md
    
    # 添加 releases 目录下的清单文件（如果存在）
    [ -f "releases/manifest-${VERSION}.json" ] && git add "releases/manifest-${VERSION}.json"
    [ -f "releases/RELEASE_NOTES-${VERSION}.md" ] && git add "releases/RELEASE_NOTES-${VERSION}.md"
    [ -f "releases/checksums-${VERSION}.sha256" ] && git add "releases/checksums-${VERSION}.sha256"
    
    # 添加脚本目录
    git add scripts/release_manager/
    
    log "✓ 文件已添加到暂存区"
    
    # 检查是否有 .tar.gz 文件被意外添加
    if git diff --cached --name-only | grep -q "\.tar\.gz$"; then
        log "⚠️  警告: 发现 .tar.gz 文件在暂存区，正在移除..."
        git reset HEAD $(git diff --cached --name-only | grep "\.tar\.gz$")
        log "✓ 已移除 .tar.gz 文件"
    fi
}

log_section "[3] 提交更改"
{
    COMMIT_MSG="Add chunk packages v${VERSION} with modular download support

- Add documentation and guides (CHUNK_PACKAGES_GUIDE.md, GIT_LFS_GUIDE.md, etc.)
- Add automatic installer scripts (install_chunks.sh, install_chunks_local.sh)
- Add release packaging scripts (package_chunks_for_release.sh)
- Add upload script for GitHub Releases (upload_to_release.sh)
- Add manifest.json for package metadata
- Package files (.tar.gz) will be uploaded to GitHub Releases (not in Git repo)
- Configure .gitignore to exclude large package files"

    git commit -m "$COMMIT_MSG"
    log "✓ 提交完成"
}

log_section "[4] 推送到远程仓库"
{
    read -p "推送到 origin $BRANCH? [Y/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        git push origin "$BRANCH"
        log "✓ 推送完成"
    else
        log "跳过推送，可以稍后手动执行: git push origin $BRANCH"
    fi
}

log_section "[5] 完成"
{
    echo ""
    echo "✅ 提交完成！"
    echo ""
    echo "📝 下一步:"
    echo "1. 上传 .tar.gz 文件到 GitHub Releases:"
    echo "   bash scripts/release_manager/upload_to_release.sh ${VERSION}"
    echo ""
    echo "   或使用 Web 界面:"
    echo "   https://github.com/Alphabaijinde/matrix/releases/new"
    echo ""
    echo "2. 在 GitHub 上创建 Release v${VERSION}"
    echo "3. 上传所有 .tar.gz 文件从 releases/ 目录"
}

