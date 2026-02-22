param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("release", "debug")]
    [string]$BuildType,

    [string]$V8Version = "12.9.202",
    [string]$OutputDir = "$PSScriptRoot\..\artifacts"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$OutDir = "$OutputDir\$BuildType"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Write-Host "=== V8 $V8Version Windows x64 $BuildType Build ===" -ForegroundColor Cyan

# ── 1. Fetch depot_tools ──────────────────────────────────────────────────────
Write-Host "[1/5] Fetching depot_tools..." -ForegroundColor Yellow
if (-not (Test-Path "$env:USERPROFILE\depot_tools")) {
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "$env:USERPROFILE\depot_tools"
}
$env:PATH = "$env:USERPROFILE\depot_tools;$env:PATH"
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = "0"

# ── 2. Fetch V8 source ────────────────────────────────────────────────────────
Write-Host "[2/5] Fetching V8 source at tag $V8Version..." -ForegroundColor Yellow
$V8Root = "$env:TEMP\v8_$V8Version"
if (-not (Test-Path $V8Root)) {
    New-Item -ItemType Directory -Force -Path $V8Root | Out-Null
    Push-Location $V8Root
    fetch v8
    Pop-Location
}
Push-Location "$V8Root\v8"
git fetch --tags
git checkout refs/tags/$V8Version
gclient sync --with_branch_heads --with_tags
Pop-Location

# ── 3. Generate build files ───────────────────────────────────────────────────
Write-Host "[3/5] Generating GN build files ($BuildType)..." -ForegroundColor Yellow
$GnArgs = Get-Content "$PSScriptRoot\..\gn_args\$BuildType.gn" -Raw
$GnArgs = $GnArgs -replace "`r`n", " " -replace "`n", " "
$BuildDir = "$V8Root\v8\out\$BuildType"

Push-Location "$V8Root\v8"
gn gen $BuildDir --args="$GnArgs"

# ── 4. Build ──────────────────────────────────────────────────────────────────
Write-Host "[4/5] Building v8_monolith (this will take a while)..." -ForegroundColor Yellow
ninja -C $BuildDir v8_monolith
Pop-Location

# ── 5. Collect artifacts ──────────────────────────────────────────────────────
Write-Host "[5/5] Collecting artifacts..." -ForegroundColor Yellow

# Static library
Copy-Item "$BuildDir\obj\v8_monolith.lib" "$OutDir\v8_monolith.lib" -Force

# Public headers
$HeaderDest = "$OutDir\include"
if (Test-Path $HeaderDest) { Remove-Item $HeaderDest -Recurse -Force }
Copy-Item "$V8Root\v8\include" $HeaderDest -Recurse -Force

# PDB (debug symbols) – present in both configs at different depths
$PdbFiles = Get-ChildItem "$BuildDir" -Filter "*.pdb" -Recurse -ErrorAction SilentlyContinue
foreach ($pdb in $PdbFiles) {
    Copy-Item $pdb.FullName "$OutDir\" -Force
}

Write-Host "=== Build complete: $OutDir ===" -ForegroundColor Green
Get-ChildItem $OutDir | Format-Table Name, Length, LastWriteTime
