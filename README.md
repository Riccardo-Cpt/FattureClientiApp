# Spese Cliente App

A Flutter Android app for tracking materials purchased per client. For each
client you can add, edit, and delete material entries (name, quantity, unit
price); the app computes a running total per client and shows it in the
client list. Data is stored locally in SQLite via `sqflite` — there is no
backend or cloud sync.

See [`docs/superpowers/specs/2026-07-22-client-material-tracker-design.md`](docs/superpowers/specs/2026-07-22-client-material-tracker-design.md)
for the full design and [`docs/superpowers/plans/2026-07-22-client-material-tracker.md`](docs/superpowers/plans/2026-07-22-client-material-tracker.md)
for the implementation plan.

## Prerequisites

- Flutter SDK (this project was built against Flutter 3.44.1 / Dart ^3.12.1).
- An Android SDK with at least one platform + build-tools installed and
  licenses accepted (`flutter doctor` should show the Android toolchain as
  `[✓]`).
- A way to see an Android device or emulator from wherever you run `flutter`
  (see **Simulating Android behavior** below if you're on WSL2 without
  `/dev/kvm`, which is the case for the environment this app was built in).

If the `flutter` command isn't on your `PATH`, use its full path instead,
e.g. on this project's dev machine:
`/home/luser/snap/flutter/common/flutter/bin/flutter`.

## Setup

```bash
cd spese_cliente_app
flutter pub get
```

## Running the test suite

```bash
cd spese_cliente_app
flutter test
flutter analyze
```

Tests run against an in-memory SQLite database (`sqflite_common_ffi`), so
they don't need an Android device or emulator.

## Simulating Android behavior in development

Flutter's own Android emulator needs hardware virtualization
(`/dev/kvm`). **WSL2 does not expose this by default**, so
`flutter emulators` / AVD-based emulators won't work there. In that case,
run against a real Android device instead — this exercises actual Android
behavior (permissions, storage paths, back button, lifecycle) more
faithfully than an emulator would anyway:

1. On the phone: enable Developer Options, then enable **USB debugging**
   (Settings → About phone → tap Build number 7 times → Developer options).
2. Connect the phone to the dev machine:
   - **Native Linux/macOS/Windows:** plug in via USB.
   - **WSL2:** USB devices aren't visible to WSL2 by default. Either:
     - Use **wireless debugging** instead (Android 11+): on the phone, enable
       "Wireless debugging" and pair it, then from WSL2 run
       `adb connect <phone-ip>:<port>` (the phone shows the IP/port to pair
       with); or
     - Forward the USB device into WSL2 with
       [`usbipd-win`](https://github.com/dorssel/usbipd-win) from a Windows
       admin PowerShell (`usbipd bind`/`usbipd attach --wsl`), then `adb
       devices` should list it inside WSL2.
3. Verify the device is visible:
   ```bash
   adb devices
   flutter devices
   ```
4. Run the app with hot reload:
   ```bash
   cd spese_cliente_app
   flutter run
   ```
   Press `r` for hot reload, `R` for hot restart, `q` to quit.

If you don't have a physical device handy and just want to iterate on UI
logic quickly (not real Android behavior — no platform channels, no real
back-gesture, etc.), you can instead run the Linux desktop target for fast
iteration:

```bash
flutter run -d linux
```

## Building a release APK

```bash
cd spese_cliente_app
flutter build apk --release
```

The APK is written to `spese_cliente_app/build/app/outputs/flutter-apk/app-release.apk`.
Install it on a connected device with:

```bash
adb install spese_cliente_app/build/app/outputs/flutter-apk/app-release.apk
```

or copy the file to the phone and open it directly (allow "install from
unknown sources" if prompted).
