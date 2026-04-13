# LFM 2.5 Edge

LFM 2.5 Edge is a simple Flutter Android application for offline text and image chat with LiquidAI's `LFM2.5-VL-450M` model.

## What It Does

- text chat on-device
- image question answering on-device
- one-time model download on first launch
- offline use after setup
- simple Android-first UI

## Model Choice

This project is configured for the official LiquidAI GGUF release that prioritizes fast edge inference:

- `LFM2.5-VL-450M-Q4_0.gguf`
- `mmproj-LFM2.5-VL-450m-Q8_0.gguf`

Why this choice:

- LiquidAI's official GGUF page describes `Q4_0/Q8_0` as the fastest inference setup for `llama.cpp`.
- The app keeps memory use lower by default and falls back from acceleration-first loading to smaller CPU profiles when needed.

## Runtime Approach

- Flutter + Dart UI
- `llamadart` for local GGUF inference
- Android `arm64-v8a`
- CPU and Vulkan modules bundled for best effort acceleration
- safe CPU fallback when Vulkan is unavailable or unstable

## Important Constraint

This APK is intended for modern `arm64` Android phones. A 450M multimodal model cannot be guaranteed to load on every Android device, especially older 32-bit phones or very low-RAM devices.

## Build

```bash
flutter pub get
flutter build apk --release
```

Release output:

```text
build/app/outputs/flutter-apk/app-release.apk
```
