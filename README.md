# Qwen Offline Chat for Android

This repository contains two Flutter applications for running Qwen3.5-0.8B locally on Android devices. Both variants use `llamadart` for on-device inference, download the required GGUF assets on first launch, and support both text prompts and image-assisted prompts.

## Repository Contents

| Project | Model Variant | Approximate Download Size | Intended Use |
| --- | --- | --- | --- |
| `qwen_chat_full` | Q8_0 | 812 MB model + 100 MB vision projector | Higher quality responses on devices with more available memory |
| `qwen_chat_quantized` | Q4_K_M | 528 MB model + 100 MB vision projector | Lower memory footprint for devices with around 8 GB RAM |

## Key Capabilities

- Offline chat after the initial model download
- Image input through camera or gallery selection
- Streaming responses in the chat UI
- Markdown rendering for assistant replies
- Separate first-run download flow with progress feedback

## Project Structure

```text
qwen/
|-- qwen_chat_full/
|   |-- android/
|   |-- lib/
|   `-- test/
|-- qwen_chat_quantized/
|   |-- android/
|   |-- lib/
|   `-- test/
`-- README.md
```

## Technical Notes

- Both applications target Android only.
- The Android builds are configured for `arm64-v8a`.
- Minimum Android SDK version is 26.
- Internet access is required only for the initial model download.
- Downloaded model files are stored on the device and are not part of this repository.

## Requirements

- Flutter 3.29 or newer
- Dart SDK 3.8 or newer
- Android SDK and NDK installed through a standard Flutter Android toolchain
- An Android device or emulator with sufficient storage for the selected model variant

## Running the Applications

From the repository root:

```bash
cd qwen_chat_full
flutter pub get
flutter run --release
```

Or run the quantized variant:

```bash
cd qwen_chat_quantized
flutter pub get
flutter run --release
```

## Release Build Note

Both Android projects currently use the debug signing configuration for release builds. Before distributing APKs outside development or internal testing, configure a proper signing setup for each app.

## Version Control Notes

The root `.gitignore` excludes generated Flutter, Gradle, and Android build output, along with machine-specific files such as `local.properties`, IDE metadata, and signing artifacts. This keeps the repository focused on source code and project configuration.
