$ErrorActionPreference = 'Stop'

function Assert-LastExitCode([string]$step) {
  if ($LASTEXITCODE -ne 0) {
    throw "$step failed with exit code $LASTEXITCODE."
  }
}

function Read-Secret([string]$Prompt) {
  $secure = Read-Host -Prompt $Prompt -AsSecureString
  $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  } finally {
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }
}

Set-Location $PSScriptRoot

$pubspecPath = Join-Path $PSScriptRoot "pubspec.yaml"
if (-not (Test-Path $pubspecPath)) {
  throw "pubspec.yaml not found at '$pubspecPath'."
}

$versionLine = Get-Content $pubspecPath | Where-Object { $_ -match '^\s*version:\s*' } | Select-Object -First 1
if (-not $versionLine) {
  throw "Could not find a 'version:' entry in pubspec.yaml."
}

$versionToken = ($versionLine -replace '^\s*version:\s*', '').Trim()
$versionParts = $versionToken -split '\+'
$buildName = $versionParts[0].Trim()
$buildNumber = if ($versionParts.Count -gt 1 -and -not [string]::IsNullOrWhiteSpace($versionParts[1])) {
  $versionParts[1].Trim()
} else {
  "1"
}

$flutterBat = Join-Path $HOME ".puro\envs\stable\flutter\bin\flutter.bat"
if (-not (Test-Path $flutterBat)) {
  throw "Flutter not found at '$flutterBat'. Install Flutter or update this script."
}

$keytool = "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
if (-not (Test-Path $keytool)) {
  throw "keytool not found at '$keytool'. Install Android Studio JBR."
}

$sdkManager = Join-Path $env:LOCALAPPDATA "Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat"
if (-not (Test-Path $sdkManager)) {
  throw "Android cmdline-tools are missing. In Android Studio install: SDK Tools > Android SDK Command-line Tools (latest)."
}

& $flutterBat doctor --android-licenses
Assert-LastExitCode "flutter doctor --android-licenses"

$keystorePath = Join-Path $PSScriptRoot "android\upload-keystore.jks"
if (-not (Test-Path $keystorePath)) {
  Write-Host "Creating upload keystore at $keystorePath"
  & $keytool -genkeypair `
    -v `
    -keystore $keystorePath `
    -alias upload `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -dname "CN=Yeti Sports Pingu Throw, OU=Apps, O=GarKeName, L=Zurich, S=ZH, C=CH"
}

$storePassword = Read-Secret "Enter keystore password for android/key.properties"
$keyPassword = Read-Secret "Enter key password for android/key.properties (usually same as keystore)"

$keyPropertiesPath = Join-Path $PSScriptRoot "android\key.properties"
@"
storePassword=$storePassword
keyPassword=$keyPassword
keyAlias=upload
storeFile=upload-keystore.jks
"@ | Set-Content -Path $keyPropertiesPath -Encoding ascii

$bundlePath = Join-Path $PSScriptRoot "build\app\outputs\bundle\release\app-release.aab"
if (Test-Path $bundlePath) {
  Remove-Item $bundlePath -Force
}

Write-Host "Building release bundle with versionName=$buildName and versionCode=$buildNumber"
& $flutterBat build appbundle --release --build-name $buildName --build-number $buildNumber
Assert-LastExitCode "flutter build appbundle"

if (Test-Path $bundlePath) {
  $versionedBundlePath = Join-Path $PSScriptRoot ("build\app\outputs\bundle\release\app-release-vc{0}.aab" -f $buildNumber)
  Copy-Item $bundlePath $versionedBundlePath -Force

  Write-Host ""
  Write-Host "SUCCESS: Play Store bundle generated:"
  Write-Host $bundlePath
  Write-Host "Versioned copy:"
  Write-Host $versionedBundlePath
} else {
  throw "Build completed but app-release.aab was not found at expected path."
}
