$ErrorActionPreference = 'Stop'

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
  Write-Host 'Flutter is not installed or not in PATH.'
  Write-Host 'Install Flutter first, then rerun this script.'
  Write-Host 'Quick Windows option: winget install -e --id Flutter.Flutter'
  Write-Host 'Official guide: https://docs.flutter.dev/get-started/install/windows/mobile'
  exit 1
}

flutter --version | Out-Null

$platforms = 'android'

if ($env:OS -eq 'Windows_NT') {
  # iOS and macOS builds require a Mac host.
  flutter config --enable-windows-desktop | Out-Null
  $platforms = 'android,windows'
} elseif ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)) {
  $platforms = 'android,ios,macos'
} else {
  $platforms = 'android,linux'
}

flutter create --platforms=$platforms .
flutter pub get

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
