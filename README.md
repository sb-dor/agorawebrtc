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

> **Note:** If you leave `AGORA_TEMP_TOKEN` empty the app joins with no token, which works for
> Agora projects that have **App ID only** authentication enabled (the default for new projects
> in testing mode). See [Section 7](#7-production-token-authentication) for production setup.

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

To target a specific device add `-d <device-id>` (e.g. `-d macos`, `-d <ios-device-id>`).

---

## 5. Meeting flow (Google Meet-style)

The lobby works exactly like Google Meet:

### Creating a meeting

1. Enter your display name and tap **Continue**.
2. Tap **New Meeting** — the app generates a random code like `abc-defg-hij`.
3. Tap the **copy icon** (or the **Copy** button in the hint below the field) to copy the code.
4. Send the code to anyone you want to invite (via WhatsApp, Telegram, iMessage, etc.).
5. Tap **Audio** or **Video** to start the call.

### Joining a meeting

1. Enter your display name and tap **Continue**.
2. Paste the code you received into the **Meeting Code** field.
3. Tap **Audio** or **Video** to join.

> The meeting code is the Agora **channel name**. Anyone who enters the same code joins
> the same channel. No backend is required for this — Agora handles the routing.

---

## 6. In-call controls

| Button | Action                                            |
|--------|---------------------------------------------------|
| Mic    | Mute / unmute your microphone                     |
| Camera | Turn camera on / off (video calls only)           |
| Flip   | Switch between front and rear camera (video only) |
| End    | Leave the call and return to the lobby            |

---

## 7. Token authentication

### How it works in this app

The app uses the [`agora_token_generator`](https://pub.dev/packages/agora_token_generator)
package to generate Agora RTC tokens **directly on the device** — no backend server required.

#### Files involved

| File | Role |
|---|---|
| `lib/src/feature/call/data/token_repository.dart` | `ITokenRepository` interface + `TokenRepositoryImpl` (generates tokens) + `TokenRepositoryNoop` (returns null when no certificate) |
| `lib/src/feature/call/widgets/call_config_widget.dart` | Creates the right repository at startup based on whether `AGORA_APP_CERTIFICATE` is set |
| `lib/src/feature/call/controller/call_controller.dart` | Resolves the final token inside `join()` before connecting |
| `lib/src/common/constant/config.dart` | Exposes `Config.agoraAppCertificate` from the config JSON |
| `config/development.json` / `config/production.json` | Where you put the certificate value |

#### Token resolution — automatic, no code changes needed

Every time someone taps **Audio** or **Video**, `CallController.join()` picks the token using this priority:

```
1. AGORA_TEMP_TOKEN (config)      ← set → use it as-is (quick testing)
         ↓ empty
2. TokenRepositoryImpl.generateToken()  ← AGORA_APP_CERTIFICATE set → generate fresh token
         ↓ no certificate
3. null                            ← App ID-only mode (Agora default for new projects)
```

The generated token is scoped to the specific channel name and user ID, and is valid for **1 hour**.

---

### Setup — enable client-side token generation

#### Step 1 — Enable App Certificate in Agora Console

1. Log in to the [Agora Console](https://console.agora.io).
2. Go to **Project Management → your project → Edit**.
3. Under **Security**, click **Enable** next to **App Certificate**.
4. Copy the **Primary Certificate** string.

> ⚠️ Once you enable the App Certificate for a project, **App ID-only** joins stop working.
> Every client must supply a valid token from that point on.

#### Step 2 — Add the certificate to your config file

Open `config/production.json` (or `development.json`) and fill in:

```json
{
  "AGORA_APP_ID": "<your-app-id>",
  "AGORA_APP_CERTIFICATE": "<your-primary-certificate>",
  "AGORA_TEMP_TOKEN": ""
}
```

Leave `AGORA_TEMP_TOKEN` empty — the app will generate a fresh token automatically on every join.

#### Step 3 — Run the app

```bash
flutter run --dart-define-from-file=config/production.json
```

That's it. No server, no extra code. Every call join automatically gets a valid signed token.

---

### Security trade-off

> ⚠️ Embedding the App Certificate in the app binary means anyone who decompiles
> the app can extract it and generate their own tokens for your Agora project.
>
> This is acceptable for **internal tools, demos, and personal projects**.
> For a **public production app** you should generate tokens on a server instead
> (see Option B below) so the certificate never leaves your backend.

---

### Option B — Server-side token generation (public production apps)

If you need to keep the App Certificate secret, generate tokens on a backend.

#### 1. Enable App Certificate (same as Step 1 above)

#### 2. Deploy a token server

Use Agora's official one-click deployable token service:

```
https://github.com/AgoraIO-Community/agora-token-service
```

Set these environment variables on the server:

```
APP_ID=<your-agora-app-id>
APP_CERTIFICATE=<your-primary-certificate>
```

The server exposes:

```
GET /rtc/:channelName/:uid/publisher/uid/:tokenExpiry/
→ { "rtcToken": "007eJx..." }
```

#### 3. Leave `AGORA_APP_CERTIFICATE` empty in config

```json
{
  "AGORA_APP_ID": "<your-app-id>",
  "AGORA_APP_CERTIFICATE": "",
  "AGORA_TEMP_TOKEN": ""
}
```

#### 4. Fetch the token in `_startCall()` before joining

In `lib/src/feature/call/widgets/lobby/call_lobby_widget.dart`, update `_startCall()`:

```dart
void _startCall(CallType callType) async {
  final channelName = _channelController.text.trim();
  if (channelName.isEmpty) return;
  final user = AuthenticationScope.userOf(context);
  if (user == null) return;

  final response = await http.get(
    Uri.parse('https://<your-server>/rtc/$channelName/${user.id}/publisher/uid/3600/'),
  );
  final token = jsonDecode(response.body)['rtcToken'] as String;

  _callDataController.setLastChannelName(channelName);
  _callController.join(
    channelName: channelName,
    callType: callType,
    uid: user.id,
    token: token, // controller will use this directly (priority 1)
  );
}
```

---

## Platform permissions

Permissions are already configured in the project. For reference:

- **Android** — `CAMERA`, `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`, `INTERNET` declared in
  `AndroidManifest.xml`.
- **iOS** — `NSCameraUsageDescription` and `NSMicrophoneUsageDescription` in
  `ios/Runner/Info.plist`.
- **macOS** — Camera and microphone sandbox entitlements in `macos/Runner/*.entitlements`.

---

## Rename the project (optional)

```bash
dart run tool/dart/rename_project.dart --name="project" --organization="dev.flutter" --description="My project description"
```
