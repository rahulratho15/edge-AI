# Edge AI

This repository contains `Lightweight Baby`, a Flutter Android application for fully offline text chat and image understanding on mobile devices using LiquidAI's `LFM2-VL-450M` GGUF model.

## Download APK

The latest test build is available directly from the repository root:

- [lightweightbaby.apk](./lightweightbaby.apk)

## Main Project

- [`lightweightbaby/`](./lightweightbaby) is the current Android app source.

## What The App Does

- Runs text-to-text and image-to-text prompts locally on Android
- Downloads the GGUF model and projector once, then works offline
- Supports image input from camera or gallery
- Streams responses inside a simple chat interface
- Includes light and dark theme support

## Model Setup

The application is configured for these files from the LiquidAI Hugging Face GGUF repository:

- `LFM2-VL-450M-Q4_0.gguf`
- `mmproj-LFM2-VL-450M-Q8_0.gguf`

These files are not stored in the repository. The app downloads them on first launch and saves them on the device.

## Device Notes

- Android only
- `arm64-v8a` build
- Android 8.0 or newer
- 4 GB RAM or more is recommended

The runtime has been tuned for safer startup on a wider range of Android phones by using a compact baseline CPU bundle and a manual model-load step after launch.

## Build From Source

```bash
cd lightweightbaby
flutter pub get
flutter build apk --release
```

The generated APK will be placed in:

```text
lightweightbaby/build/app/outputs/flutter-apk/app-release.apk
```

## Repository Notes

This repository may also contain earlier experiments and reference folders from previous on-device LLM builds. `lightweightbaby` is the current project intended for direct testing and sharing.
