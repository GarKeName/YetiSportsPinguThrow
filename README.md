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

## Art Generation
All included art was generated with the built-in Images tool (`image_gen`, images 2.0 workflow) and copied into `assets/images`:
- `yeti_idle.png`
- `yeti_swing.png`
- `penguin.png`
- `cliff.png`
- `ui_panel.png`
- `arctic_bg.png`

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

Optional Windows desktop test:

```bash
flutter run -d windows
```

For iPhone builds, run from macOS with Xcode installed (cannot be built from Windows):

```bash
flutter run -d ios
```

## Notes
- This is an original implementation inspired by the classic timing-and-distance mechanic.
- No external game engine package is required; the game loop and physics are in pure Flutter.
