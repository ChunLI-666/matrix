# Git LFS 使用指南

本项目使用 Git LFS (Large File Storage) 来管理大文件（如 3D 模型、二进制库、可执行文件）。

## 1. 初始设置

在使用本仓库之前，请确保已安装 Git LFS：

```bash
# Ubuntu
sudo apt-get install git-lfs

# 初始化
git lfs install
```

## 2. 克隆仓库

克隆时，Git LFS 会自动下载大文件。

```bash
git clone <repository-url>
```

如果下载速度慢，可以尝试仅拉取 LFS 指针，然后按需下载：

```bash
GIT_LFS_SKIP_SMUDGE=1 git clone <repository-url>
cd matrix
git lfs pull
```

## 3. 添加大文件

`.gitattributes` 已经配置了常见的大文件类型（如 `*.so`, `*.dll`, `*.STL`, `*.onnx` 等）。

当你添加新的大文件时：

1. 确保文件类型已在 `.gitattributes` 中定义。如果没有，请添加：
   ```bash
   git lfs track "*.myext"
   ```

2. 正常提交：
   ```bash
   git add my_large_file.myext
   git commit -m "Add large file"
   git push
   ```

## 4. 常见问题

### 错误：`invalid ELF header` 或文件大小只有几百字节
这是因为 LFS 文件没有被正确下载，只下载了指针文件。
**解决办法**：运行 `git lfs pull`。

### 错误：`batch response: Post ...: status 403`
可能是 LFS 带宽或存储超限（GitHub 免费额度为 1GB）。
**解决办法**：
- 升级 GitHub 套餐
- 或将超大文件（如地图包）移至 GitHub Releases 管理

## 5. 当前配置的文件类型

- **3D 模型**: `.STL`, `.obj`, `.dae`, `.fbx`, `.blend`
- **库文件**: `.so`, `.dll`, `.a`, `.lib`, `.dylib`
- **可执行文件**: `.exe`, `.bin`, 及其它特定二进制
- **UE5 资源**: `.uasset`, `.umap`, `.ucas`, `.utoc`, `.pak`
- **图像**: `.png`, `.jpg`, `.psd`, `.tga`
- **AI 模型**: `.onnx`, `.pth`, `.pt`
