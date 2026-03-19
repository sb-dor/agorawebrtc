## Rename the project (optional)

```bash
dart run tool/dart/rename_project.dart --name="project" --organization="dev.flutter" --description="My project description"
```

# Agora Call — Flutter Video & Audio Calling App

A multi-party video and audio calling app built with Flutter and
the [Agora RTC Engine](https://pub.dev/packages/agora_rtc_engine).

---

## Prerequisites

- Flutter SDK ≥ 3.x
- An [Agora account](https://console.agora.io) with an App ID
- CocoaPods (for iOS / macOS builds)

---

## 1. Get your Agora credentials

1. Log in to the [Agora Console](https://console.agora.io).
2. Create a new project (or open an existing one).
3. Copy the **App ID** from the project settings page.
4. To test without a token server, go to **Temporary Token** in the console, enter any channel name,
   and generate a **Temp Token**. Temp tokens expire after 24 hours.

---

## 2. Configure the app

Open the config file for the environment you want to run:

| Environment | File                      |
|-------------|---------------------------|
| Development | `config/development.json` |
| Production  | `config/production.json`  |

Fill in your credentials:

```json
{
  "AGORA_APP_ID": "<your-app-id>",
  "AGORA_TEMP_TOKEN": "<your-temp-token-or-empty-string>"
}
```

> **Note:** If you leave `AGORA_TEMP_TOKEN` empty the app will join with no token, which works for
> Agora projects that have **App ID only** authentication enabled (the default for new projects in
> testing mode). If your project requires token authentication you must supply a valid temp token.

---

## 3. Install dependencies

```bash
flutter pub get
```

For iOS / macOS, install native pods:

```bash
cd ios && pod install && cd ..
# or for macOS
cd macos && pod install && cd ..
```

---

## 4. Run the app

Pass the config file with `--dart-define-from-file`:

```bash
# Development
flutter run --dart-define-from-file=config/development.json

# Production
flutter run --dart-define-from-file=config/production.json
```

To target a specific device add `-d <device-id>` (e.g. `-d macos`, `-d chrome`,
`-d <ios-device-id>`).

---

## 5. Using the app

1. **Enter your display name** on the welcome screen and tap **Continue**.
2. On the lobby screen, **type a channel name** (any string, e.g. `my-room`).
3. Tap **Audio Call** or **Video Call** to join.
4. Share the same channel name with anyone else — they open the app, enter the same channel name,
   and tap the same call type to join your call.
5. Up to 6 participants are shown in the grid simultaneously. Empty slots display a placeholder
   until someone joins.

---

## 6. In-call controls

| Button | Action                                            |
|--------|---------------------------------------------------|
| Mic    | Mute / unmute your microphone                     |
| Camera | Turn camera on / off (video calls only)           |
| Flip   | Switch between front and rear camera (video only) |
| End    | Leave the call and return to the lobby            |

---

## Platform permissions

Permissions are already configured in the project. For reference:

- **Android** — `CAMERA`, `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`, `INTERNET` declared in
  `AndroidManifest.xml`.
- **iOS** — `NSCameraUsageDescription` and `NSMicrophoneUsageDescription` in
  `ios/Runner/Info.plist`.
- **macOS** — Camera and microphone sandbox entitlements in `macos/Runner/*.entitlements`.

---