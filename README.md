# Fabla — Mobile Research Data Collection Tool

Fabla is an open-source Flutter mobile app for collecting qualitative and quantitative research data from study participants. It supports two common research methodologies: **Daily Diary** (one recurring entry per time period) and **Ecological Momentary Assessment / EMA** (multiple in-the-moment captures per day). The app is designed to be researcher-friendly, participant-friendly, and pluggable — you bring your own backend.

---

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Environment Variables](#environment-variables)
  - [Installation](#installation)
  - [Code Generation](#code-generation)
  - [Running the App](#running-the-app)
- [Backend Integration](#backend-integration)
  - [Credentials Flow](#credentials-flow)
  - [Study Protocol JSON Format](#study-protocol-json-format)
  - [Notification Scheduling](#notification-scheduling)
- [Project Structure](#project-structure)
- [Testing](#testing)
  - [Unit & Widget Tests](#unit--widget-tests)
  - [Integration Tests](#integration-tests)
- [CI/CD](#cicd)
- [Pre-commit Hooks](#pre-commit-hooks)
- [Contributing](#contributing)

---

## Features

- **Audio & Video Recording** — Participants record spoken diary entries or video responses directly in-app
- **Survey Prompts** — Rich question types: multiple choice, sliding scales, checkboxes, free text, and more
- **Study Protocols** — Driven by a JSON-based protocol definition fetched from your backend; no app update required to change a study
- **Push Notifications** — Firebase Cloud Messaging (FCM) with image-rich local notifications to remind participants of upcoming entries
- **Scheduled & Windowed Entries** — Configurable notification windows, entry deadlines, and recurrence rules
- **Local-First Database** — All participant data is persisted locally via ObjectBox before being uploaded
- **Onboarding Flow** — Animated onboarding with participant ID login and study setup
- **Offline Support** — Entries are queued locally and synced when connectivity is restored
- **Analytics Integration** — Pluggable analytics (default: Pendo SDK) for monitoring participant activity
- **Crash Reporting** — Firebase Crashlytics

---

## Tech Stack

| Category | Library |
|---|---|
| Framework | Flutter (Dart) |
| State Management | flutter_bloc / cubit |
| Local Database | ObjectBox |
| Audio | flutter_sound, audioplayers |
| Video | camera, video_player, video_compress |
| Push Notifications | firebase_messaging, flutter_local_notifications |
| Animation | Rive, Lottie |
| Analytics | Pendo SDK |
| Crash Reporting | Firebase Crashlytics |
| HTTP | http |
| Storage | flutter_secure_storage, shared_preferences |
| Permissions | permission_handler |

---

## Architecture

The project follows **Clean Architecture**, organized per feature screen:

```
Feature (e.g. diary)
├── data/          # Data models, local DB entities, API response mappers
├── domain/        # Business entities, repository interfaces, use cases
└── presentation/  # Cubit/Bloc, pages, widgets
```

**Cross-cutting layers:**

| Layer | Purpose |
|---|---|
| `core/` | Network abstractions, error types, shared use case interfaces, utilities |
| `services/` | Singleton services (notifications, routing, preferences, analytics, crash reporting) |
| `theme/` | Design system — colors, typography, reusable components, dialogs |

Data flows: **Backend API → Repository → Cubit/Bloc → UI**. All persistence goes through ObjectBox; uploads happen via the network layer when connectivity is available.

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) — see `pubspec.yaml` for the required version (`>=3.0.2`)
- Dart (bundled with Flutter)
- [Xcode](https://developer.apple.com/xcode/) (macOS, for iOS builds)
- [Android Studio](https://developer.android.com/studio) or another Android toolchain
- [CocoaPods](https://cocoapods.org/) (macOS, for iOS)
- A Firebase project (see [Backend Integration](#backend-integration))

### Environment Variables

The app reads credentials from a `.env` file at the project root. The file is not to be committed to version control.

1. Copy the example env file:

```bash
cp .env.example .env
```

2. Fill in your values:

```
APIKEY=your_backend_api_key
PENDOKEY=your_pendo_integration_key   # optional — remove if not using Pendo
```

3. Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from your Firebase project to the respective platform directories.

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/AppHatchery/Fabla-Front-end.git
cd Fabla-Front-end

# 2. Install Flutter dependencies
flutter pub get

# 3. iOS only — install CocoaPods dependencies
cd ios && pod install && cd ..

# 4. Set up pre-commit hooks (one-time, required for contributors)
dart run scripts/setup-bootstrapper.dart
```

### Code Generation

The local database (ObjectBox) requires generated binding code. Run this after cloning and after any changes to `@Entity` annotated classes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Running the App

```bash
flutter run
```

---

## Backend Integration

Fabla is designed so the study protocol and participant data flow through **your own backend**. Out of the box the app expects:

| Concern | What the app needs |
|---|---|
| Study protocol | A JSON endpoint that returns the study configuration (questions, schedule, etc.) |
| Participant auth | An API endpoint that accepts a participant ID and returns study credentials |
| Data upload | An endpoint (or cloud storage presigned URL) to receive audio, video, and survey responses |
| Push notifications | An FCM server key to send push notifications via Firebase Cloud Messaging |

The key files to touch when wiring up your own backend are:

**`lib/core/network/request.dart`** — The central HTTP client. Replace the `devURL` and `prodURL` constants at the top with your own API host. The `base()` function returns the dev URL in debug mode and the prod URL in release mode. All GET and POST calls flow through the `get()` and `post()` helpers in this file, making it the single place to swap the base URL.

**`lib/core/network/upload.dart`** — Handles uploading completed diary entries (survey responses, audio, images, and video) to a backend store. The current implementation targets AWS S3 (presigned URLs) and a DynamoDB-backed endpoint. Replace the upload functions here to route data to your own storage and database.

**`lib/core/network/secrets_handler.dart`** — Manages the upload credentials that the app fetches during onboarding. See [Credentials Flow](#credentials-flow) below.

Additional integration points:

- `lib/screens/*/data/` — Per-feature data sources and models
- `lib/screens/*/domain/repositories/` — Repository interfaces (implement these against your backend)

### Credentials Flow

When a participant logs in with their study code, the app calls a credentials endpoint (currently a Lambda function) to exchange the study code for upload credentials. Those credentials are persisted to encrypted on-device storage (`flutter_secure_storage`) and read back automatically on every diary submission — the participant never sees them.

```
Participant enters study code
        │
        ▼
SecureSave.postData(studyCode)
        │  POST { StudyCode: "…" }
        ▼
Credentials endpoint
        │  { "message": { "Authorization": "…", "x-api-key": "…",
        │                  "dynamo_url": "…", "presigned_url": "…" } }
        ▼
SecureSave.save()  →  encrypted device storage
        │
        ▼
upload.dart reads credentials on each submission
```

**To replace with your own backend:**

1. In `lib/core/network/secrets_handler.dart`, replace the Lambda URL inside `SecureSave.postData()` with your own credentials endpoint.
2. Your endpoint must accept a `StudyCode` form field and return a JSON body with a `message` object containing these four keys:

| Key | Used by |
|---|---|
| `Authorization` | Auth header on every upload request |
| `x-api-key` | API key header on every upload request |
| `dynamo_url` | Endpoint that receives survey response JSON |
| `presigned_url` | Endpoint that returns presigned URLs for file (audio/video/image) uploads |

3. If your backend uses a different credential shape, update `CredentialsModel` in the same file and adjust how `upload.dart` reads those values.

### Study Protocol JSON Format

The study protocol endpoint must return a JSON response with the following top-level shape:

```json
{
  "status": "success",
  "data": {
    "studies": [ /* array of study objects */ ]
  }
}
```

#### Study object

| Field | Type | Description |
|---|---|---|
| `id` | integer | Unique study identifier |
| `name` | string | Display name shown to participants |
| `goal` | object | `{ "daily": N, "weekly": N }` — target entry counts |
| `incentive` | object | `{ "amount": "5.00", "bonus": "20.00", "currency": "$", "threshold": 80 }` |
| `diaries` | array | One or more diary objects (see below) |

#### Diary object

| Field | Type | Description |
|---|---|---|
| `name` | string | Display name for this diary |
| `start_time` | ISO 8601 datetime | When the diary window opens |
| `end_time` | ISO 8601 datetime | When the diary window closes |
| `entries` | integer | Maximum number of entries allowed |
| `active_days` | array \| null | Days of the week this diary is active, or `null` for one day diaries |
| `questions` | array | Ordered list of question objects (see below) |
| `notifications` | array | Push notification schedules for this diary |

> **Day boundary — 4 AM shift:** The app defines a calendar day as **4:00 AM to 3:59 AM** the following morning, and a week as **Monday 4:00 AM to Sunday 3:59 AM**. This means a diary with `start_time` of `2025-06-16T00:00:00` belongs to the previous calendar day from the participant's perspective. When scheduling diaries and setting `start_time`/`end_time`, treat 4:00 AM as midnight. Daily and weekly goal counts (`goal.daily`, `goal.weekly`) are also tallied against these shifted boundaries.
>
> To change the boundary, edit `_getWeekBoundaries()` in `lib/screens/home/presentation/cubit/cubit/home_cubit.dart` — adjust the hour value in the two `DateTime(…, hour, …)` constructors (currently `4` for the week start and `3` / minute `59` for the week end).

#### Question objects

All question objects share these common fields:

| Field | Type | Description |
|---|---|---|
| `question_id` | integer | Unique question identifier |
| `type` | string | One of the types listed below |
| `title` | string | Question prompt shown to the participant |
| `subtitle` | string | Optional secondary prompt text |
| `required` | boolean | Whether the participant must answer before continuing |
| `question_number` | integer | Display order within the diary |

Type-specific fields:

| `type` | Extra fields | Description |
|---|---|---|
| `text` | — | Free-text response |
| `audio` | — | Voice recording |
| `textaudio` | — | Free-text combined with a voice recording |
| `slider` | `min`, `max`, `step`, `minLabel`, `maxLabel` | Numeric sliding scale |
| `multiple` | `options: ["Option A", "Option B", …]` | Multi-select list of string choices |
| `radio` | `options: ["Option A", "Option B", …]` | Single-select radio list of string choices |
| `timer` | `duration` (seconds) | Countdown timer the participant must complete |
| `timePicker` | — | Time-of-day picker |
| `instruction` | — | Non-interactive instructional slide |
| `webview` | `link` | Embedded web page (e.g. REDCap survey) |
| `visualResponse-imageVideo` | `media_type` | Photo or video capture response |

#### Notification objects

Each object in a diary's `notifications` array schedules a local push notification for that diary window:

| Field | Type | Description |
|---|---|---|
| `title` | string | Notification title |
| `content` | string | Notification body text |
| `time` | ISO 8601 datetime | When the notification fires |

The app reads `content` (not `body`) as the notification body — match that key exactly. Multiple objects in the array schedule multiple notifications for the same diary.

#### Minimal example

```json
{
  "status": "success",
  "data": {
    "studies": [
      {
        "id": 1,
        "name": "My Study",
        "goal": { "daily": 2, "weekly": 14 },
        "incentive": { "amount": "5.00", "bonus": "20.00", "currency": "$", "threshold": 80 },
        "diaries": [
          {
            "name": "Daily Check-in",
            "start_time": "2025-06-16T08:00:00",
            "end_time": "2025-06-16T22:00:00",
            "entries": 1,
            "active_days": null,
            "questions": [
              {
                "question_id": 1,
                "type": "audio",
                "title": "How was your day?",
                "subtitle": "",
                "required": true,
                "question_number": 1
              },
              {
                "question_id": 2,
                "type": "slider",
                "title": "Rate your mood",
                "subtitle": "",
                "required": true,
                "question_number": 2,
                "min": 1,
                "max": 10,
                "step": 1,
                "minLabel": "Very low",
                "maxLabel": "Very high"
              }
            ],
            "notifications": []
          }
        ]
      }
    ]
  }
}
```

### Notification Scheduling

The app runs three parallel notification tracks. Understanding them matters if you're changing the study protocol or the reminder UX.

#### 1. Protocol notifications (from your backend)

Each diary object in the study protocol can include a `notifications` array. These are loaded into the local database at onboarding and scheduled as local device notifications by `NotificationManager` (`lib/core/usecases/notification_manager.dart`).

**OS notification cap:** iOS allows at most 64 scheduled local notifications; the app self-limits to **50** (`threshold` constant in `notification_manager.dart`). Because a long study can have more than 50 future notification slots, the app uses a two-step strategy:

- `scheduleLimit()` — called once after the protocol is loaded during onboarding. Clears all existing notifications and fills the device queue up to 50, ordered by diary start date.
- `scheduleAdditional()` — called every time the app returns to the foreground. Checks how many notifications are currently queued and tops up to 50 without duplicating already-scheduled ones.

For **weekly diaries** (those with `active_days` set), the manager expands each notification time across every active weekday between the diary's `start_time` and `end_time`, so a single protocol notification entry fans out into one device notification per active day.

#### 2. User reminder notifications (participant-set)

Participants set their preferred reminder times from the **Settings page**. These are stored in the `reminder_times` preference and scheduled by `createNotifications()` in `setup_repository.dart`. The scheduling logic:

- One notification per diary per chosen time.
- If the latest chosen time is at or after 7 PM and adding 3 hours doesn't cross midnight, an automatic **late reminder** fires 3 hours after that last time.
- If the participant chose no late-evening time, a fixed **9 PM fallback** reminder is always added.
- A **"study starts tomorrow"** notification fires the day before the first diary at the participant's first chosen time (or 5 PM if none set).

Each time the participant saves new reminder times in Settings, `reScheduleAllNotifications()` is called and the full schedule is replaced.

#### 3. Automatic in-session notifications

These fire based on participant behaviour and require no backend configuration:

| Type | Trigger | Time |
|---|---|---|
| **Continue** | Participant opens but doesn't finish a diary | 30 minutes later (only before 7 PM) |
| **Submit** | Participant completes all questions but hasn't submitted | 10 minutes later (only before 7 PM, requires internet) |
| **Daily goal** | Participant hasn't met their `goal.daily` target | Between 3 PM and 7 PM, up to once per hour |

---

## Project Structure

```
fabla-flutter/
├── lib/
│   ├── main.dart
│   ├── core/                  # Shared infrastructure
│   │   ├── database/          # ObjectBox DAOs
│   │   ├── network/           # HTTP client and request helpers
│   │   ├── notifications/     # Notification controller
│   │   ├── secrets/           # keys.dart (gitignored)
│   │   └── utils/             # Extensions, formatters, type helpers
│   ├── screens/               # Feature modules (Clean Architecture)
│   │   ├── home/              # Study home screen
│   │   ├── diary/             # Diary entry flow
│   │   ├── onboarding/        # Login and study setup
│   │   ├── settings/          # App and study settings
│   │   └── hub/               # Study hub / overview
│   ├── services/              # Singleton services
│   │   ├── notification_service.dart
│   │   ├── preference_service.dart
│   │   ├── route_service.dart
│   │   ├── crashlytics_service.dart
│   │   └── pendo_service.dart
│   └── theme/                 # Design system
│       ├── custom_colors.dart
│       ├── custom_typography.dart
│       ├── components/        # Reusable UI components
│       └── dialogs/           # Modals and pop-ups
├── test/                      # Unit and widget tests
├── integration_test/          # End-to-end tests
├── android/                   # Android native project
├── ios/                       # iOS native project
├── assets/                    # Images, fonts, Rive/Lottie animations, audio
├── scripts/                   # Developer tooling
└── .github/workflows/         # GitHub Actions CI
```

---

## Testing

### Unit & Widget Tests

```bash
# Run all tests
flutter test test/

# Run only widget tests
flutter test test/screens/
```

Tests live in `test/` mirroring the `lib/` structure. Mocking is done with [mocktail](https://pub.dev/packages/mocktail).

Firebase dependencies are mocked in `test/firebase_mock.dart`. CI requires a dummy `.env` and `lib/core/secrets/keys.dart` — the workflow creates them automatically.

### Integration Tests

Integration tests live in `integration_test/`. They require a connected device or emulator.

1. Install the app on your device/emulator:

```bash
flutter run
```

2. Stop the app (`Ctrl+C`, then `y`).

3. Pre-grant permissions (Android) — edit `grant_permission.sh` with your package name, then:

```bash
./grant_permission.sh
```

4. Run the integration tests:

```bash
flutter test integration_test/app_test.dart
```

> **Note:** Tests may occasionally miss a button tap due to timing. Re-running usually resolves it.

---

## CI/CD

GitHub Actions runs on every pull request targeting `main` or `Dev`.

**Workflow: `.github/workflows/UnitAndWidgetTesting.yml`**

| Job | What it does |
|---|---|
| `test` | Runs the full test suite using repository secrets (for branches with access) |


---

## Pre-commit Hooks

This project uses automated pre-commit hooks to catch test failures before they reach CI.

**Setup (one-time):**

```bash
dart run scripts/setup-bootstrapper.dart
```

**How it works:**

- Tests run automatically on every `git commit`
- The commit is blocked if any tests fail
- Use `git commit --no-verify` only in genuine emergencies

---

## Contributing

Contributions are welcome. To get started:

1. Fork the repository and create a feature branch off `main`
2. Follow the existing Clean Architecture conventions — new features should have `data/`, `domain/`, and `presentation/` layers
3. Write tests for new logic — aim to cover repository implementations and cubits
4. Run `dart format .` and `flutter analyze` before opening a PR
5. Open a pull request against `main`; CI must pass before review

For larger changes, open an issue first to discuss the approach.
