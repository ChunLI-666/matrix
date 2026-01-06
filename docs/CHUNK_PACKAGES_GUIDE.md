# MATRiX Chunk Packages Guide

## 📦 What are Chunk Packages?

MATRiX now supports modular packaging, splitting simulator content into:
- **Assets Package**: Contains simulator launcher and core binaries (Required).
- **Base Package**: Essential core files and EmptyWorld map (Required).
- **Shared Resources Package**: Resources shared across multiple maps (Recommended).
- **Map Packages**: Individual maps that can be downloaded on demand.

This design allows users to:
- ✅ Download only what is needed, saving storage space.
- ✅ Quick start (only Assets and Base Packages required).
- ✅ Expand on demand (download specific maps as needed).

## 🚀 Quick Installation

### Automatic Installation (Recommended)

```bash
bash scripts/release_manager/install_chunks.sh 0.1.1
```

### Manual Installation

1. **Prepare Directory**

   Enter `releases` directory in the project root:
   ```bash
   cd releases
   ```

2. **Download Packages to releases Directory**

   - **Download Assets Package** (Required)
     ```bash
     wget https://github.com/zsibot/matrix/releases/download/v0.1.1/assets-0.1.1.tar.gz
     ```

   - **Download Base Package** (Required)
     ```bash
     wget https://github.com/zsibot/matrix/releases/download/v0.1.1/base-0.1.1.tar.gz
     ```

   - **Download Shared Resources Package** (Recommended)
     ```bash
     wget https://github.com/zsibot/matrix/releases/download/v0.1.1/shared-0.1.1.tar.gz
     ```

   - **Download Map Packages** (On Demand)
     ```bash
     wget https://github.com/zsibot/matrix/releases/download/v0.1.1/SceneWorld-0.1.1.tar.gz
     ```

3. **Run Local Installation Script**

   Return to the project root and run the installation script:
   ```bash
   cd ..
   bash scripts/release_manager/install_chunks_local.sh 0.1.1
   ```

## 📋 Package Description

### Assets Package (assets-0.1.1.tar.gz) - Required
- **Contents**:
  - `bin/sim_launcher`: Simulator launcher
  - Core binary dependencies
- **Required**: ✅ Yes

### Base Package (base-0.1.1.tar.gz) - Required
- **Size**: ~950MB
- **Contents**:
  - EmptyWorld Map
  - Core Blueprints and System Files
  - Chunk 0 (pakchunk0)
- **Required**: ✅ Yes

### Shared Resources Package (shared-0.1.1.tar.gz) - Recommended
- **Size**: ~3.2GB
- **Contents**:
  - Fab/Carla Shared Resources
  - Blueprints and Resources shared by multiple maps
  - Chunk 1 (pakchunk1)
- **Required**: ⚠️ No, but many maps depend on it. Strongly recommended.

### Map Packages - Optional

| Package Name | Size | Chunk ID | Description |
|--------------|------|----------|-------------|
| SceneWorld | ~423MB | 11 | Warehouse Scene |
| Town10World | ~1.1GB | 12 | Large Town Scene |
| YardWorld | ~695MB | 13 | Courtyard Scene |
| CrowdWorld | ~60MB | 14 | Crowd Scene |
| VeniceWorld | ~328MB | 15 | Venice Scene |
| RunningWorld | ~36MB | 16 | Running Game Scene |
| HouseWorld | ~265MB | 17 | House Scene |
| IROSFlatWorld | ~300KB | 18 | IROS Flat Terrain |
| IROSSlopedWorld | ~250MB | 19 | IROS Sloped Terrain |
| Town10Zombie | ~628MB | 20 | Zombie Scene (Large) |
| IROSFlatWorld2025 | ~148KB | 21 | IROS 2025 Flat Terrain |
| IROSSloppedWorld2025 | ~149KB | 22 | IROS 2025 Sloped Terrain |
| OfficeWorld | ~418MB | 23 | Office Scene |
| CustomWorld | ~22MB | 24 | Custom Scene |
| 3DGSWorld | ~206MB | 25 | 3D Gaussian Splatting Map |
| MoonWorld | ~603MB | 26 | Moon Environment |

## 🔍 Verify Installation

After installation, check:

```bash
# 1. Check Assets (Should exist and >1MB)
ls -lh bin/sim_launcher

# 2. Check PAK files
cd src/UeSim/Linux/zsibot_mujoco_ue/Content/Paks
ls -lh pakchunk*.pak
```

You should see:
- `pakchunk0-Linux.pak` - Base Package (Required)
- `pakchunk1-Linux.pak` - Shared Resources Package (if installed)
- `pakchunk11-Linux.pak` etc. - Map Packages (if installed)

## 🎮 Usage

After installation, run the simulator:

```bash
# In matrix root directory
./scripts/run_sim.sh 1 0  # XGB Robot, CustomWorld Map
./scripts/run_sim.sh 1 1  # XGB Robot, Warehouse Map (Requires SceneWorld package)
```

## ❓ FAQ

**Q: I only want to run EmptyWorld. Which packages do I need?**
A: You need the Assets Package (assets) and the Base Package (base).

**Q: Why is the Shared Resources Package recommended?**
A: Because many maps depend on assets in the Shared Resources Package. Without it, those maps may not load correctly.

**Q: Can I download only specific map packages?**
A: Yes! You can download only the map packages you need.

**Q: How do I update to a new version?**
A: Download the new version packages and extract them, overwriting the old files. It is recommended to backup first.

## 📚 More Information

- [Main README](../README.md) - Project Main Documentation
- [Chinese Documentation](README_CN.md) - User Guide in Chinese
