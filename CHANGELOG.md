# Changelog

## 1.1.0

### Added

- Cache folders are now discovered by name under the known NVIDIA roots instead of being hard coded, so new driver layouts such as `PerDriverVersion` are found without a code change.
- `%APPDATA%\NVIDIA\ComputeCache`, `OptixCache`, the `SysWOW64` system profile, and the `ServiceProfiles` accounts are now covered. These were being missed.
- `%__GL_SHADER_DISK_CACHE_PATH%\GLCache` is cleared when that NVIDIA variable has been used to move the OpenGL cache.
- `-AllUsers` clears every local user profile, not just the current one.
- `-IncludeD3DSCache` (on by default) to control whether the Windows DirectX cache is cleared.
- `-SkipServices` to run without touching any Windows service.
- `-LogPath` writes a full transcript of the run.
- `-WhatIf` and `-Confirm` support.
- Exit codes: `0` cleared, `1` partly cleared, `2` fatal error or declined elevation.
- A GitHub Actions workflow that runs PSScriptAnalyzer on every push.

### Fixed

- Stopped services are now restarted from a `finally` block, so a failure part way through can no longer leave the machine with the display service stopped.
- Services that were stopped as dependencies are recorded and started again in reverse order. Previously only the one named service came back.
- `NvContainerLocalSystem` and `NvContainerNetworkService` are handled, not just `NVDisplay.ContainerLocalSystem`.
- Space freed is measured as the size before minus the size after, so files that stayed locked are no longer counted as freed.
- The launcher passes its arguments through to the script, quotes paths that contain spaces, and returns the script's exit code.
- Elevation waits for the elevated run and returns its exit code instead of exiting immediately.

## 1.0.0

- First release.
