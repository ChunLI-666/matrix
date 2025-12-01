# MATRiX Chunk Packages 使用指南

## 📦 什么是Chunk Packages?

MATRiX现在支持模块化打包，将模拟器内容分为：
- **基础包**: 必需的核心文件和EmptyWorld地图
- **共享资源包**: 多个地图共享的资源（推荐安装）
- **地图包**: 各个独立的地图，可按需下载

这种设计让用户可以：
- ✅ 只下载需要的内容，节省存储空间
- ✅ 快速开始（只需下载基础包）
- ✅ 按需扩展（需要哪个地图再下载）

## 🚀 快速安装

### 自动安装（推荐）

**从 GitHub Releases 下载并安装：**
```bash
bash scripts/release_manager/install_chunks.sh 0.0.4
```

脚本会：
- 自动下载基础包（必需）
- 提示是否下载共享资源包（推荐）
- 交互式选择要下载的地图包
- 自动处理分片文件的下载和合并（对于超过2GB的大文件）
- **所有下载的文件保存在 `releases/` 目录**，方便后续使用

**从本地 releases/ 目录安装：**
```bash
# 如果文件已经下载到 releases/ 目录
bash scripts/release_manager/install_chunks_local.sh 0.0.4
```

### 手动安装

1. **下载基础包**（必需）
   ```bash
   wget https://github.com/Alphabaijinde/matrix/releases/download/v0.0.4/base-0.0.4.tar.gz
   ```

2. **下载共享资源包**（推荐）
   ```bash
   wget https://github.com/Alphabaijinde/matrix/releases/download/v0.0.4/shared-0.0.4.tar.gz
   ```

3. **下载地图包**（按需）
   ```bash
   wget https://github.com/Alphabaijinde/matrix/releases/download/v0.0.4/SceneWorld-0.0.4.tar.gz
   ```

4. **解压到运行目录**
   ```bash
   cd src/UeSim/Linux/jszr_mujoco_ue
   tar -xzf ../../../../releases/base-0.0.4.tar.gz
   cd Content/Paks
   tar -xzf ../../../../releases/shared-0.0.4.tar.gz
   tar -xzf ../../../../releases/SceneWorld-0.0.4.tar.gz
   ```

> **注意：** 建议将下载的文件放在 `releases/` 目录，这样可以使用 `install_chunks_local.sh` 脚本进行后续安装。

## 📋 包说明

### 基础包 (base-0.0.4.tar.gz) - 必需
- **大小**: ~920MB
- **内容**: 
  - EmptyWorld地图
  - 核心蓝图和系统文件
  - Chunk 0 (pakchunk0)
- **必需**: ✅ 是
- **下载位置**: `releases/base-0.0.4.tar.gz`

### 共享资源包 (shared-0.0.4.tar.gz) - 推荐
- **大小**: ~182MB
- **内容**: 
  - Fab/Warehouse共享资源
  - StarterContent共享资源
  - Chunk 1 (pakchunk1)
- **必需**: ⚠️ 否，但多个地图依赖，强烈建议安装
- **下载位置**: `releases/shared-0.0.4.tar.gz`

### 地图包 - 可选

| 地图包 | 大小 | Chunk ID | 说明 | 备注 |
|--------|------|----------|------|------|
| SceneWorld | ~277MB | 11 | 仓库场景 | |
| Town10World | ~3.6GB | 12 | 城镇场景 | ⚠️ 大文件，已分割为多个分片 |
| YardWorld | ~694MB | 13 | 庭院场景 | |
| CrowdWorld | ~406MB | 14 | 人群场景 | |
| VeniceWorld | ~327MB | 15 | 威尼斯场景 | |
| RunningWorld | ~36MB | 16 | 跑步场景 | |
| HouseWorld | ~327MB | 17 | 房屋场景 | |
| IROSFlatWorld | ~177MB | 18 | IROS平地场景 | |
| IROSSlopedWorld | ~419MB | 19 | IROS斜坡场景 | |
| Town10Zombie | ~3.5GB | 20 | 僵尸场景 | ⚠️ 大文件，已分割为多个分片 |
| IROSFlatWorld2025 | ~114MB | 21 | IROS 2025平地场景 | |
| IROSSloppedWorld2025 | ~114MB | 22 | IROS 2025斜坡场景 | |
| OfficeWorld | ~379MB | 23 | 办公室场景 | |
| Custom | ~48MB | 24 | 自定义场景 | |

> **注意：** 
> - 所有地图包下载后保存在 `releases/` 目录
> - 超过2GB的大文件（Town10World, Town10Zombie）会被分割为多个分片文件
> - 安装脚本会自动处理分片文件的下载、合并和校验

## 🔍 验证安装

安装后检查：

```bash
cd src/UeSim/Linux/jszr_mujoco_ue/Content/Paks
ls -lh pakchunk*.pak
```

应该看到：
- `pakchunk0-Linux.pak` - 基础包（必需）
- `pakchunk1-Linux.pak` - 共享资源包（如果已安装）
- `pakchunk11-Linux.pak` 等 - 地图包（如果已安装）

## 🎮 使用

安装完成后，运行模拟器：

```bash
# 已在 matrix 根目录
./scripts/run_sim.sh 0 0  # 运行EmptyWorld（只需要基础包）
./scripts/run_sim.sh 1 1  # 切换到SceneWorld（需要SceneWorld地图包）
```

## 💾 文件管理

### 下载文件位置

所有通过 `install_chunks.sh` 下载的文件都保存在 `releases/` 目录：

```
releases/
├── base-0.0.4.tar.gz              # 基础包
├── shared-0.0.4.tar.gz            # 共享资源包
├── SceneWorld-0.0.4.tar.gz        # 地图包
├── Town10World-0.0.4.tar.gz       # 大文件（合并后）
├── Town10World-0.0.4.tar.part000  # 分片文件
├── Town10World-0.0.4.tar.part001  # 分片文件
├── Town10World-0.0.4.tar.merge.sh # 合并脚本
├── Town10World-0.0.4.tar.sha256   # 校验和文件
└── manifest-0.0.4.json            # 包清单文件
```

### 后续安装

如果已经下载了文件到 `releases/` 目录，可以使用本地安装脚本：

```bash
# 安装其他地图包（无需重新下载）
bash scripts/release_manager/install_chunks_local.sh 0.0.4
```

这样可以：
- ✅ 避免重复下载
- ✅ 离线安装
- ✅ 快速添加新地图

## 🔧 脚本选择指南

### `install_chunks.sh` vs `install_chunks_local.sh`

| 特性 | install_chunks.sh | install_chunks_local.sh |
|------|------------------|------------------------|
| **数据源** | GitHub Releases | 本地 releases/ 目录 |
| **网络需求** | ✅ 需要 | ❌ 不需要 |
| **交互选择** | ✅ 支持（可选择地图） | ❌ 自动安装所有 |
| **下载功能** | ✅ 自动下载 | ❌ 不下载 |
| **安装功能** | ✅ 下载+安装 | ✅ 仅安装 |
| **使用场景** | 首次安装/更新 | 离线安装/重新安装 |
| **速度** | 较慢（需下载） | 快速（仅解压） |

### 何时使用哪个脚本？

**使用 `install_chunks.sh` 当：**
- 🌐 首次安装，需要从 GitHub 下载
- 🆕 需要获取最新版本
- 🎯 只想下载特定的地图包
- 📥 需要下载功能

**使用 `install_chunks_local.sh` 当：**
- 💾 文件已下载到 releases/ 目录
- 🔌 没有网络连接（离线环境）
- ⚡ 需要快速重新安装
- 📦 想安装 releases/ 目录下所有可用包

### 典型工作流程

```bash
# 步骤 1: 首次安装（有网络）
bash scripts/release_manager/install_chunks.sh 0.0.4
# → 下载到 releases/ + 安装到运行目录

# 步骤 2: 后续安装（离线或重新安装）
bash scripts/release_manager/install_chunks_local.sh 0.0.4
# → 从 releases/ 安装到运行目录（不下载）
```

## ❓ 常见问题

**Q: 我只想运行EmptyWorld，需要下载哪些包？**  
A: 只需要基础包（base包）即可。

**Q: 为什么共享资源包是推荐的？**  
A: 因为多个地图都依赖共享资源包中的资源，如果不安装，这些地图可能无法正常加载。

**Q: 我可以只下载部分地图包吗？**  
A: 可以！你可以根据需要只下载要使用的地图包。

**Q: 如何更新到新版本？**  
A: 下载新版本的包，解压覆盖旧文件即可。建议先备份。

**Q: 下载的文件保存在哪里？**  
A: 所有下载的文件都保存在 `releases/` 目录，包括基础包、共享资源包、地图包、分片文件等。

**Q: 我可以删除 releases/ 目录下的文件吗？**  
A: 可以，但建议保留。如果删除后需要重新安装，需要重新下载。保留文件可以使用 `install_chunks_local.sh` 快速安装。

**Q: 大文件（Town10World, Town10Zombie）如何下载？**  
A: 这些文件超过2GB，会被分割为多个分片文件。`install_chunks.sh` 脚本会自动下载所有分片、合并脚本和校验和文件，然后自动合并并验证。

**Q: `install_chunks.sh` 和 `install_chunks_local.sh` 有什么区别？**  
A: `install_chunks.sh` 从 GitHub 下载并安装（需要网络），`install_chunks_local.sh` 从本地 releases/ 目录安装（无需网络）。两者都会安装到运行目录，区别在于数据源。

## 📚 更多信息

- [主 README](../README.md) - 项目主文档
- [中文文档](README_CN.md) - 中文使用指南
