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
2. In this folder, generate platform scaffolding if needed:

```bash
flutter create --platforms=android,ios,macos .
```

3. Fetch dependencies:

```bash
flutter pub get
```

4. Run:

```bash
flutter run -d android
```

For iPhone builds, run from macOS with Xcode installed:

```bash
flutter run -d ios
```

Optional desktop test on macOS:

```bash
flutter run -d macos
```

## Notes
- This is an original implementation inspired by the classic timing-and-distance mechanic.
- No external game engine package is required; the game loop and physics are in pure Flutter.
