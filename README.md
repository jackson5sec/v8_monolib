# V8 12.9.202 — Windows x64 Static Build

Automated GitHub Actions pipeline that builds **V8 12.9.202** as a monolithic static library (`v8_monolith.lib`) for Windows x64 in both **Release** and **Debug** configurations.

## Artifacts

| File | Description |
|------|-------------|
| `v8_monolith.lib` | Static library (link this into your project) |
| `include/` | V8 public headers |
| `*.pdb` | Debug symbols (both configs) |

## Build Configuration

Both configurations share these flags (see `gn_args/`):

| Flag | Value | Reason |
|------|-------|--------|
| `is_component_build` | false | Monolithic output |
| `v8_monolithic` | true | Single `.lib` output |
| `v8_static_library` | true | Static linking |
| `v8_enable_i18n_support` | false | No ICU dependency |
| `use_custom_libcxx` | false | Use MSVC stdlib |
| `v8_enable_webassembly` | false | Strips WASM |
| `v8_enable_inspector` | false | No DevTools protocol |
| `v8_enable_sandbox` | false | Simplified build |
| `v8_enable_pointer_compression` | false | Compatibility |
| `v8_use_snapshot` | false | No snapshot binary |
| `target_cpu` | x64 | 64-bit |

The **Debug** build additionally sets `is_debug = true`, `symbol_level = 2`, `v8_enable_backtrace = true`, and `v8_enable_verify_heap = true`.

## Triggering a Build

### Automatic
- Every push to `main` triggers both Release and Debug builds.
- Pushing a tag (e.g. `git tag v1.0.0 && git push --tags`) triggers a full build **and** creates a GitHub Release with both zipped artifacts attached.

### Manual
Go to **Actions → Build V8 12.9.202 → Run workflow** and choose `both`, `release`, or `debug`.

## Local Build (Windows)

Requirements: Visual Studio 2022 with C++ workload, Windows SDK, Python 3, Git.

```powershell
# Release
.\scripts\build.ps1 -BuildType release

# Debug
.\scripts\build.ps1 -BuildType debug
```

Artifacts are placed in `artifacts\release\` and `artifacts\debug\`.

## Linking in Your Project (CMake example)

```cmake
add_library(v8_monolith STATIC IMPORTED)
set_target_properties(v8_monolith PROPERTIES
    IMPORTED_LOCATION     "${V8_LIB_DIR}/v8_monolith.lib"
    INTERFACE_INCLUDE_DIRECTORIES "${V8_LIB_DIR}/include"
)

target_link_libraries(your_target PRIVATE v8_monolith winmm dbghelp)
```

> **Note:** V8 requires `winmm.lib` and `dbghelp.lib` from the Windows SDK.

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── build.yml          # CI/CD pipeline
├── gn_args/
│   ├── release.gn             # GN args – Release
│   └── debug.gn               # GN args – Debug
├── scripts/
│   └── build.ps1              # Local build helper
└── README.md
```
