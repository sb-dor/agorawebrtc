# Agora Call — Flutter Video & Audio Calling App

A multi-party video and audio calling app built with Flutter and
the [Agora RTC Engine](https://pub.dev/packages/agora_rtc_engine).
Works like Google Meet — create a meeting, share the code, anyone with
the code can join.

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
4. *(Optional)* To test without a token server, go to **Temporary Token** in the console,
   enter a channel name, and generate a **Temp Token**. Temp tokens expire after 24 hours.

---

## 2. Configure the app

Open `config/production.json` and fill in your credentials:

```json
{
  "AGORA_APP_ID": "<your-app-id>",
  "AGORA_APP_CERTIFICATE": "<your-primary-certificate-or-empty>",
  "AGORA_TEMP_TOKEN": "<your-temp-token-or-empty>"
}
```

| Field | Purpose |
|---|---|
| `AGORA_APP_ID` | Required. Your Agora project App ID. |
| `AGORA_APP_CERTIFICATE` | Optional. Enables client-side token generation. Leave empty for App ID–only mode. |
| `AGORA_TEMP_TOKEN` | Optional. A pre-generated token for quick testing. Takes priority over certificate generation. |

> **Note:** New Agora projects default to **App ID–only** mode. If you leave both
> `AGORA_APP_CERTIFICATE` and `AGORA_TEMP_TOKEN` empty the app joins without a token,
> which works for projects in testing mode.

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
# Default device
flutter run --dart-define-from-file=config/production.json

# Specific platform
flutter run -d macos --dart-define-from-file=config/production.json
flutter run -d <ios-device-id> --dart-define-from-file=config/production.json

# Web (must use localhost for camera/mic access)
flutter run -d chrome --web-hostname localhost --web-port 8080 --dart-define-from-file=config/production.json
```

Or use the pre-configured VSCode launch configurations in `.vscode/launch.json`.

---

## 5. Meeting flow (Google Meet-style)

### Creating a meeting

1. Enter your display name and tap **Continue**.
2. Tap **New Meeting** — the app generates a random code like `abc-defg-hij`.
3. Tap the **copy icon** to copy the code and share it.
4. Tap **Audio** or **Video** to start the call.

### Joining a meeting

1. Enter your display name and tap **Continue**.
2. Paste the code you received into the **Meeting Code** field.
3. Tap **Audio** or **Video** to join.

> The meeting code is the Agora **channel name**. Anyone who enters the same code joins
> the same channel. No backend is required — Agora handles the routing.

---

## 6. In-call controls

| Button | Action |
|--------|--------|
| Mic    | Mute / unmute your microphone |
| Camera | Turn camera on / off (video calls only) |
| Flip   | Switch between front and rear camera (native only) |
| End    | Leave the call and return to the lobby |

---

## 7. Token authentication

### How it works

When you tap **Audio** or **Video**, `MeetingController` resolves the token using this priority:

```
1. AGORA_TEMP_TOKEN (config)         ← non-empty → use it directly (quick testing)
         ↓ empty
2. AGORA_APP_CERTIFICATE (config)    ← non-empty → generate a fresh token client-side
         ↓ empty
3. null                              ← App ID–only mode (no token)
```

The generated token is scoped to the channel name and user ID, and is valid for **1 hour**.

### Setup — client-side token generation

1. In the [Agora Console](https://console.agora.io), go to **Project Management → your project → Edit**.
2. Under **Security**, enable **App Certificate** and copy the **Primary Certificate**.
3. Add it to `config/production.json`:

```json
{
  "AGORA_APP_ID": "<your-app-id>",
  "AGORA_APP_CERTIFICATE": "<your-primary-certificate>",
  "AGORA_TEMP_TOKEN": ""
}
```

> ⚠️ Once you enable the App Certificate, **App ID–only** joins stop working — every client
> must supply a valid token.

> ⚠️ Embedding the App Certificate in the app binary means anyone who decompiles
> the app can extract it. This is acceptable for internal tools and demos. For a public
> production app, generate tokens on a server instead and keep the certificate there.

### Option B — Server-side token generation

Deploy Agora's official token service:

```
https://github.com/AgoraIO-Community/agora-token-service
```

Set `APP_ID` and `APP_CERTIFICATE` on the server. It exposes:

```
GET /rtc/:channelName/:uid/publisher/uid/:tokenExpiry/
→ { "rtcToken": "007eJx..." }
```

Then implement `ITokenRepository` to fetch the token from your server and inject it
into `MeetingController` in `MeetingScreen`.

---

## Platform permissions

Permissions are pre-configured for all supported platforms:

| Platform | Configuration |
|----------|--------------|
| Android  | `CAMERA`, `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`, `INTERNET` in `AndroidManifest.xml` |
| iOS      | `NSCameraUsageDescription`, `NSMicrophoneUsageDescription` in `ios/Runner/Info.plist` |
| macOS    | Camera + microphone sandbox entitlements in `macos/Runner/*.entitlements` and `Info.plist` |
| Web      | Browser prompts natively when media is first accessed. Must run on `localhost` or `https://` |
| Linux / Windows | Granted at OS level — no runtime request required |

---

## Rename the project (optional)

```bash
dart run tool/dart/rename_project.dart --name="project" --organization="dev.flutter" --description="My project description"
```


## Mobile Screenshots
<p float="left">
  <img src="https://raw.githubusercontent.com/sb-dor/agorawebrtc/refs/heads/main/github_assets/Screenshot_1774091275.png" alt="Screenshot 1" width="200" />
</p>


## Web Screenshots
<p float="left">
  <img src="https://raw.githubusercontent.com/sb-dor/agorawebrtc/refs/heads/main/github_assets/%D0%A1%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA%20%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0%202026-03-21%20%D0%B2%2016.08.12.png" alt="Screenshot WEB 1" width="820" />
</p>

<p float="left">
  <img src="https://raw.githubusercontent.com/sb-dor/simple_pos/refs/heads/main/app_pics/web_2.png" alt="Screenshot WEB 2" width="820" />
</p>