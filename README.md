# Arctic Slugger (Pingu Throw Style)

A one-tap arcade launcher game inspired by classic Yeti-style penguin-throw gameplay, rebuilt for modern mobile targets.

## Targets
- Android phones
- iPhone (iOS, built from macOS)
- macOS desktop (optional test target)

## Gameplay
- Tap once to drop the penguin.
- Tap again while it passes the hit zone to swing.
- Better timing gives higher launch power.
- The penguin flies, bounces, then slides.
- Distance in meters is your score.

## Project Layout
- `lib/main.dart`: Full game loop, physics, rendering, UI.
- `assets/images/`: AI-generated game art assets.
- `assets/images/v2/`: Current "classic look" stage, flight, yeti, and penguin assets used by the app.

## Art Generation
All included art was generated with the built-in Images tool (`image_gen`, images 2.0 workflow) and copied into `assets/images`:
- `yeti_idle.png`
- `yeti_swing.png`
- `penguin.png`
- `cliff.png`
- `ui_panel.png`
- `arctic_bg.png`

Current in-game art is loaded from `assets/images/v2/`:
- `stage_bg_classic.png`
- `flight_bg_classic.png`
- `yeti_idle.png`
- `yeti_swing_lr.png`
- `penguin.png`

## Run Locally

1. Install Flutter SDK (stable channel).
On Windows, one reliable option is:

```powershell
winget install -e --id pingbird.Puro
puro create stable stable
puro use -g stable
```

Then open a new terminal and run:

```powershell
flutter --version
```

If `flutter` is still not recognized in the same PowerShell window, refresh PATH once:

```powershell
$env:Path = [Environment]::GetEnvironmentVariable("Path","User") + ";" + [Environment]::GetEnvironmentVariable("Path","Machine")
flutter --version
```

2. On Windows, install Android Studio (for Android SDK/emulator).
3. In this folder, generate platform scaffolding if needed:

```bash
flutter create --platforms=android,windows .
```

Or use the included script:

```powershell
./setup.ps1
```

Important: run `setup.ps1` (PowerShell script), not `setup.ps`.
If your machine blocks PowerShell scripts, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1
```

Or use the included batch launcher:

```bat
setup.cmd
```

4. Fetch dependencies:

```bash
flutter pub get
```

5. Run:

```bash
flutter run -d android
```

## Run On Android Emulator (Windows)

1. Install Android Studio:

```powershell
winget install -e --id Google.AndroidStudio
```

2. Open Android Studio once and complete setup:
- Install Android SDK, Android SDK Platform-Tools, and Android Emulator.
- Create an AVD in `Tools > Device Manager`.

3. Point Flutter to SDK (if needed) and verify:

```powershell
flutter config --android-sdk "$env:LOCALAPPDATA\Android\Sdk"
flutter doctor
flutter emulators
```

4. Start emulator and run game:

```powershell
flutter emulators --launch <EMULATOR_ID>
flutter devices
flutter run -d <EMULATOR_ID>
```

If `flutter` is not recognized in your current terminal, use the direct executable path:

```powershell
& "$HOME\.puro\envs\stable\flutter\bin\flutter.bat" emulators
& "$HOME\.puro\envs\stable\flutter\bin\flutter.bat" emulators --launch <EMULATOR_ID>
& "$HOME\.puro\envs\stable\flutter\bin\flutter.bat" run -d <EMULATOR_ID>
```

Optional Windows desktop test:

```bash
flutter run -d windows
```

For iPhone builds, run from macOS with Xcode installed (cannot be built from Windows):

```bash
flutter run -d ios
```

## Deploy To Google Play (Android)

1. Set a unique app id before first release.
In `android/app/build.gradle.kts`, change:
- `namespace = "com.example.pingu_throw_mobile"`
- `applicationId = "com.example.pingu_throw_mobile"`
to your own reverse-domain id, for example `com.yourcompany.yetisportspingu`.

2. Create an upload keystore (one time):

```powershell
keytool -genkey -v -keystore android/upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

3. Create `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

The project is already configured to use this file for release signing.

4. Build the Play Store bundle (`.aab`):

```powershell
flutter build appbundle --release
```

Output file:
- `build/app/outputs/bundle/release/app-release.aab`

5. Upload in Play Console:
- Open Google Play Console.
- Create app (once).
- Go to `Testing > Internal testing` (recommended first).
- Create release and upload `app-release.aab`.
- Complete Store Listing + Content Rating + Data safety.
- Roll out to internal testers, then promote to production.

## Notes
- This is an original implementation inspired by the classic timing-and-distance mechanic.
- No external game engine package is required; the game loop and physics are in pure Flutter.
