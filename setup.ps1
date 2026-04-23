$ErrorActionPreference = 'Stop'

function Invoke-Checked {
  param(
    [string]$Executable,
    [string[]]$Arguments
  )

  & $Executable @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed: $Executable $($Arguments -join ' ')"
  }
}

# Ensure git is callable for flutter/puro-managed SDKs.
$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git -and (Test-Path 'C:\Program Files\Git\cmd\git.exe')) {
  $env:PATH = 'C:\Program Files\Git\cmd;' + $env:PATH
}

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
$flutterExe = $null

if ($flutter) {
  $flutterExe = $flutter.Source
} else {
  $puroFlutter = Join-Path $HOME '.puro\envs\stable\flutter\bin\flutter.bat'
  if (Test-Path $puroFlutter) {
    $flutterExe = $puroFlutter
    $env:PATH = (Split-Path -Parent $puroFlutter) + ';' + $env:PATH
  }
}

if (-not $flutterExe) {
  Write-Host 'Flutter is not installed or not in PATH.'
  Write-Host 'Install Flutter first, then rerun this script.'
  Write-Host 'Quick Windows option:'
  Write-Host '  winget install -e --id pingbird.Puro'
  Write-Host '  puro create stable stable'
  Write-Host '  puro use -g stable'
  Write-Host 'Official guide: https://docs.flutter.dev/get-started/install/windows/mobile'
  exit 1
}

Invoke-Checked -Executable $flutterExe -Arguments @('--version')

$platforms = 'android'

if ($env:OS -eq 'Windows_NT') {
  # iOS and macOS builds require a Mac host.
  Invoke-Checked -Executable $flutterExe -Arguments @('config', '--enable-windows-desktop')
  $platforms = 'android,windows'
} elseif ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)) {
  $platforms = 'android,ios,macos'
} else {
  $platforms = 'android,linux'
}

Invoke-Checked -Executable $flutterExe -Arguments @('create', "--platforms=$platforms", '.')
Invoke-Checked -Executable $flutterExe -Arguments @('pub', 'get')

Write-Host 'Setup complete. Run one of:'
Write-Host '  flutter run -d android'

if ($env:OS -eq 'Windows_NT') {
  Write-Host '  flutter run -d windows'
  Write-Host 'iOS/macOS builds are only available when building on macOS.'
} elseif ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)) {
  Write-Host '  flutter run -d ios'
  Write-Host '  flutter run -d macos'
} else {
  Write-Host '  flutter run -d linux'
}
