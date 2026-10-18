# spese_cliente_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Building the Android APK

Prerequisites: Flutter SDK and the Android SDK installed (check with `flutter doctor`).

```bash
# Install dependencies
flutter pub get

# Generate localization files (if not already generated)
flutter gen-l10n

# Build a release APK
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`
(a SHA-1 checksum is next to it in `app-release.apk.sha1`).

Useful variants:

```bash
# Smaller APKs, one per CPU architecture
flutter build apk --release --split-per-abi

# Debug APK
flutter build apk --debug
```

To install on a connected device:

```bash
flutter install
# or
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

> **Note:** the release build is currently signed with the debug key
> (see `android/app/build.gradle.kts`). To publish on the Play Store, configure
> a proper release keystore first.
