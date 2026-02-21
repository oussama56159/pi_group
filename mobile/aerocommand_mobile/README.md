# AeroCommand Mobile (Android)

Simplified Flutter Android app for this repo’s AeroCommand platform.

## Features (MVP)

- Login (JWT) using the same backend as the web dashboard
- Monitor fleet status in real time (WebSocket telemetry stream)
- Receive/view alerts (REST fetch; also listens for WS alert messages if broadcast)
- View telemetry for a selected vehicle
- Assign one or more predefined missions to selected vehicles or an entire fleet

## Backend requirements

- API running (default: `http://localhost:8000/api/v1` on your PC)
- Mobile app talks to the API using emulator/device networking:
  - Android Emulator: `10.0.2.2` maps to your PC `localhost`

## Run (Android Emulator)

From repo root:

```powershell
cd mobile/aerocommand_mobile
flutter pub get

# Use emulator-friendly URLs
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1 --dart-define=WS_BASE_URL=ws://10.0.2.2:8000/api/v1/telemetry/ws
```

## Run (Physical Android device)

Use your PC’s LAN IP instead of `10.0.2.2`, for example:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000/api/v1 --dart-define=WS_BASE_URL=ws://192.168.1.50:8000/api/v1/telemetry/ws
```

## Note about HTTP (dev)

This project enables `android:usesCleartextTraffic="true"` to allow local `http://` during development.
For production you should switch to HTTPS and remove/replace this setting.
# aerocommand_mobile

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
