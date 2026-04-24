$ErrorActionPreference = 'Stop'

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

& $flutterBat build appbundle --release

$bundlePath = Join-Path $PSScriptRoot "build\app\outputs\bundle\release\app-release.aab"
if (Test-Path $bundlePath) {
  Write-Host ""
  Write-Host "SUCCESS: Play Store bundle generated:"
  Write-Host $bundlePath
} else {
  throw "Build completed but app-release.aab was not found at expected path."
}
