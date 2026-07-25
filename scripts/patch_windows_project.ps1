# Scaffolds the Flutter Windows runner project (windows/ folder) that
# `flutter create` normally generates, and patches in our custom WIA
# scanner platform channel. Safe to re-run (checks before patching).
#
# This exists because the repo ships lib/, pubspec.yaml, assets/, and
# windows/runner/scanner_channel.{h,cpp} but NOT the rest of the
# `windows/` folder (CMakeLists.txt, flutter_window.cpp, etc.) - those
# are Flutter-version-specific boilerplate that `flutter create` must
# generate fresh. Run this locally too if you're not using CI.

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

Write-Host "== Scaffolding a fresh Flutter Windows project for boilerplate =="
$scaffoldDir = Join-Path $env:TEMP "flutter_scaffold_$([guid]::NewGuid().ToString('N'))"
flutter create --platforms=windows --org com.rangu --project-name aadhaar_verifier $scaffoldDir
if ($LASTEXITCODE -ne 0) { throw "flutter create failed" }

Write-Host "== Copying generated windows/ boilerplate into the repo (without overwriting our scanner_channel files) =="
$destWindows = Join-Path $repoRoot "windows"
if (-not (Test-Path $destWindows)) {
    New-Item -ItemType Directory -Path $destWindows | Out-Null
}
Copy-Item -Path (Join-Path $scaffoldDir "windows\*") -Destination $destWindows -Recurse -Force -Exclude "scanner_channel.h", "scanner_channel.cpp"

$scannerH = Join-Path $repoRoot "windows\runner\scanner_channel.h"
$scannerCpp = Join-Path $repoRoot "windows\runner\scanner_channel.cpp"
if (-not (Test-Path $scannerH) -or -not (Test-Path $scannerCpp)) {
    throw "scanner_channel.h/.cpp missing from windows/runner - did the repo checkout include them?"
}

Write-Host "== Patching CMakeLists.txt to compile scanner_channel.cpp =="
$cmakePath = Join-Path $repoRoot "windows\runner\CMakeLists.txt"
$cmakeContent = Get-Content $cmakePath -Raw
if ($cmakeContent -notmatch "scanner_channel\.cpp") {
    $cmakeContent = $cmakeContent -replace '("flutter_window\.cpp")', "`$1`n  `"scanner_channel.cpp`""
    Set-Content -Path $cmakePath -Value $cmakeContent -NoNewline
    Write-Host "  Added scanner_channel.cpp to CMakeLists.txt"
} else {
    Write-Host "  Already patched, skipping"
}

Write-Host "== Patching flutter_window.cpp to register the scanner channel =="
$fwPath = Join-Path $repoRoot "windows\runner\flutter_window.cpp"
$fwContent = Get-Content $fwPath -Raw
if ($fwContent -notmatch "RegisterScannerChannel") {
    # Add the include near the top, right after the existing flutter_window.h include.
    $fwContent = $fwContent -replace '(#include "flutter_window\.h"\s*\n)', "`$1#include `"scanner_channel.h`"`n"
    # Register the channel right after RegisterPlugins(...) is called in OnCreate().
    $fwContent = $fwContent -replace '(RegisterPlugins\(flutter_controller_->engine\(\)\);\s*\n)', "`$1  RegisterScannerChannel(flutter_controller_->engine());`n"
    Set-Content -Path $fwPath -Value $fwContent -NoNewline
    Write-Host "  Added #include and RegisterScannerChannel(...) call"
} else {
    Write-Host "  Already patched, skipping"
}

Write-Host "== Cleaning up scaffold temp dir =="
Remove-Item -Path $scaffoldDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "== Verifying the patches actually applied =="
$cmakeCheck = Get-Content $cmakePath -Raw
$fwCheck = Get-Content $fwPath -Raw
$ok = $true
if ($cmakeCheck -notmatch "scanner_channel\.cpp") {
    Write-Warning "CMakeLists.txt does NOT mention scanner_channel.cpp - the auto-patch regex probably didn't match this Flutter version's generated file. Open windows/runner/CMakeLists.txt manually and add `"scanner_channel.cpp`" next to `"flutter_window.cpp`" in the add_executable(...) file list."
    $ok = $false
}
if ($fwCheck -notmatch "RegisterScannerChannel") {
    Write-Warning "flutter_window.cpp does NOT call RegisterScannerChannel - the auto-patch regex probably didn't match. Open windows/runner/flutter_window.cpp manually: add #include `"scanner_channel.h`" near the top, and add RegisterScannerChannel(flutter_controller_->engine()); right after the existing RegisterPlugins(flutter_controller_->engine()); line inside OnCreate()."
    $ok = $false
}
if ($ok) {
    Write-Host "== Done. windows/ is ready for 'flutter pub get' + 'flutter build windows' =="
} else {
    Write-Host "== Done with warnings above - the app will still build and run without the scanner feature until you fix these manually (ScannerService on the Dart side fails gracefully to 'no scanner found' if the channel isn't registered). =="
}
