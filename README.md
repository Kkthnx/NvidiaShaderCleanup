<div align="center">

<img src="assets/logo.png" alt="NVIDIA Shader Cache Cleanup logo" width="220" />

# NVIDIA Shader Cache Cleanup

[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D6)](#requirements)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE)](#requirements)
[![License: MIT](https://img.shields.io/badge/License-MIT-76B900)](LICENSE)

</div>

A small Windows utility that clears the **NVIDIA** and **Windows DirectX/OpenGL shader caches** in one click.

Use it **after installing a new GPU driver**, or whenever games start **crashing on launch, stuttering, flickering, or showing visual artifacts**. The driver and Windows rebuild these caches automatically the next time you launch each game.

---

## What is the shader cache?

When you run a game, your GPU driver compiles the game's shaders into binaries that match your exact GPU and driver version, then stores them on disk. On later launches the driver reuses those cached binaries so games load faster and stutter less.

These cache files can become **stale or corrupted** after a driver update or game patch. When that happens you may see crashes, hitching, or graphical glitches. Deleting the cache forces the driver to rebuild clean copies. Nothing important is lost — saves, settings, and accounts are untouched. (Source: [NVIDIA Support — Deleting NVIDIA Shader Cache files](https://nvidia.custhelp.com/app/answers/detail/a_id/5735/).)

> **First launch after cleanup is expected to be slower** while shaders recompile. This is normal and one-time per game.

---

## What it does

1. Stops NVIDIA background apps (NVIDIA App, overlay, ShadowPlay/Share, Broadcast, helpers) so they release file locks.
2. Temporarily stops the **NVIDIA Display Container** service so the system-profile caches can be cleared, then restarts it. *(Your screen may flicker once — this is expected.)*
3. Deletes the **contents** of every known shader-cache folder (the folders themselves are kept so the driver refills them in place).
4. Reports how much disk space was freed.

It does **not** touch your games, drivers, saves, or settings, and it skips any cache folder that does not exist.

---

## Cache locations cleared

All paths below are documented NVIDIA or Windows shader-cache locations. Missing folders are skipped automatically.

| Location | Notes |
| --- | --- |
| `%LOCALAPPDATA%\NVIDIA\DXCache` | DirectX shader cache (DX10/11/12 games) |
| `%LOCALAPPDATA%\NVIDIA\GLCache` | OpenGL shader cache (e.g. Minecraft, CAD) |
| `%LOCALAPPDATA%\NVIDIA\ComputeCache` | CUDA / compute cache |
| `%LOCALAPPDATA%Low\NVIDIA\PerDriverVersion\DXCache` | Per-driver cache (driver **545.xx and newer**) |
| `%LOCALAPPDATA%Low\NVIDIA\PerDriverVersion\GLCache` | Per-driver OpenGL cache |
| `%LOCALAPPDATA%Low\NVIDIA\DXCache` | Newer driver location |
| `%ProgramData%\NVIDIA Corporation\NV_Cache` | Legacy cache |
| `%LOCALAPPDATA%\NVIDIA Corporation\NV_Cache` | Legacy cache |
| `...\systemprofile\AppData\LocalLow\NVIDIA\...` | Caches used by the driver **service** |
| `%LOCALAPPDATA%\D3DSCache` | Windows DirectX Shader Cache (any GPU) |
| `%LOCALAPPDATA%\Microsoft\D3DSCache` | Windows DirectX Shader Cache (alternate path) |

---

## How to use

### Option A — Download and run (recommended)

1. Go to the repository, click **Code → Download ZIP**, and extract it.
2. Open the `NvidiaShaderCleanup` folder.
3. Double-click **`NvidiaShaderCleanup.bat`**.
4. Approve the **User Account Control (UAC)** prompt — admin rights are required to clear the system-profile caches.
5. Wait for `Cleanup Complete`, then press **Enter** to close.

### Option B — Clone with Git

```bash
git clone https://github.com/Kkthnx/NvidiaShaderCleanup.git
cd NvidiaShaderCleanup/NvidiaShaderCleanup
```

Then double-click `NvidiaShaderCleanup.bat`.

> **Before running**, close your games (and ideally the NVIDIA App). The tool stops NVIDIA background processes for you, but actively running games can keep cache files locked.

### Advanced options (PowerShell)

You can run the script directly with optional flags:

```powershell
# Preview only — shows what would be cleared and how much space it would free, deletes nothing
.\NvidiaShaderCleanup.ps1 -DryRun

# Run without waiting for a key press (useful for automation / scripting)
.\NvidiaShaderCleanup.ps1 -NoPause
```

| Flag | Description |
| --- | --- |
| `-DryRun` | Preview mode. Reports what would be cleared without stopping anything or deleting files. |
| `-NoPause` | Skips the "Press Enter to exit" prompt at the end. |

The script self-elevates (prompts for admin) if you run it without administrator rights.

---

## Requirements

- Windows 10 or Windows 11
- An NVIDIA GPU + driver
- Windows PowerShell 5.1 (built in) or PowerShell 7+
- Administrator rights (the launcher requests these automatically)

---

## Files

| File | Purpose |
| --- | --- |
| `NvidiaShaderCleanup/NvidiaShaderCleanup.bat` | Launcher. Requests admin rights and runs the script. Double-click this. |
| `NvidiaShaderCleanup/NvidiaShaderCleanup.ps1` | The PowerShell script that does the cleanup. Can also be run directly (it self-elevates). |

---

## FAQ

**Is it safe?**
Yes. It only deletes regenerable cache files. Windows and the NVIDIA driver rebuild them on demand. Your games, saves, settings, and drivers are not modified.

**Why does my screen flicker during the run?**
Restarting the NVIDIA Display Container service briefly resets the display. It comes back on its own.

**Why does a game stutter or load slowly right after I run this?**
The shaders are being recompiled and re-cached. This happens once per game after a cleanup and then goes away.

**Do I need to disable the shader cache in the NVIDIA Control Panel first?**
No. Because the tool stops the NVIDIA processes/service before deleting, manually disabling the cache is not required. If you prefer NVIDIA's official manual steps, see their support article linked above.

**It says some files are "in use."**
A game or background app still had them open. Close all games and the NVIDIA App, then run it again.

---

## License

[MIT](LICENSE) © Kkthnx
