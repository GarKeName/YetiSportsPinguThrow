$ErrorActionPreference = 'Stop'

flutter --version | Out-Null

flutter create --platforms=android,ios,macos .
flutter pub get

Write-Host 'Setup complete. Run one of:'
Write-Host '  flutter run -d android'
Write-Host '  flutter run -d ios'
Write-Host '  flutter run -d macos'
