# Audio Diaries Flutter

Audio Diaries Flutter is a mobile application that allows users to record audio diaries and store them locally and in a cloud database. 
The application is built using Flutter and Dart, and uses Firebase for cloud storage.

## Table of Contents

- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Pre-commit Hooks](#pre-commit-hooks)
  - [Project Structure](#project-structure)
    - [Architecture](#architecture)
      - [Core](#core)
      - [Data Layer](#data-layer)
      - [Domain Layer](#domain-layer)
      - [Presentation Layer](#presentation-layer)
      - [Services](#services)
- [GitHub Actions](#github-actions)
- [Tests](#tests)

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Visual Studio Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio) or [Xcode](https://developer.apple.com/xcode/)
- [Android Emulator](https://developer.android.com/studio/run/emulator) or [iOS Simulator](https://developer.apple.com/documentation/xcode/running_your_app_in_the_simulator_or_on_a_device)
- [Git](https://git-scm.com/downloads)

### Installation

1. Clone the repository
```bash
git clone
```

2. Install dependencies
```bash
flutter pub get
```

3. Install iOS dependencies (only for iOS)
```bash
cd ios && pod install && cd ..
```

4. Install the database
```bash
dart run build_runner build
```

5. Set up pre-commit hooks (required for all developers)
```bash
dart run scripts/setup-bootstrapper.dart
```

6. Run the application
```bash
flutter run
```

7. Setup amplify project
```bash
amplify pull --appId d1f2k81mx528zu --envName fablapush
```

8. Checkout dev environment
```bash
amplify env checkout fablapush
```

9. Pull amplify project
```bash
amplify pull
```

### Pre-commit Hooks

This project uses automated pre-commit hooks to maintain code quality. Tests run automatically before every commit.

#### Setup (One-time per developer)

After cloning the repository, run:
```bash
dart run scripts/setup-bootstrapper.dart
```

#### How It Works

- **Tests run automatically** on every `git commit`
- **Commit succeeds** only if all tests pass
- **Commit is blocked** if any tests fail

#### Development Workflow

```bash
# Make your changes
flutter pub get
# Edit files...

# Commit changes (tests run automatically)
git add .
git commit -m "your changes"
# Output: Running pre-commit checks...
#         Running tests...
#         All pre-commit checks passed!
```

#### Bypassing Hooks (Emergency Only)

If you need to commit without running tests (use sparingly):
```bash
git commit --no-verify -m "emergency fix"
```

#### Troubleshooting

- **First commit after setup:** May show "Installing hooks" and require retry
- **Hooks not running:** Ensure you ran `dart run scripts/setup-bootstrapper.dart`
- **Tests failing:** Fix the failing tests before committing, or use `--no-verify` for emergencies

### Project Structure

```
lib
├── core
│   ├── error
│   ├── network
│   ├── usecases
│   └── utils
├── screens
│   ├── home
│   │   ├── data
│   │   ├── domain
│   │   │   ├── entities
│   │   │   └── repositories
│   │   └── presentation
│   │       ├── cubit/bloc
│   │       ├── pages
│   │       └── widgets
│   ├── diary
│   └── settings
├── services
└── theme
    └── components
```

### Architecture

The application uses the Clean Architecture pattern, with the following layers:

#### Core

This layer contains the most fundamental elements of the application. It includes common utilities, interfaces, and abstractions that are not specific to any particular feature.

**Error** — Handling and categorizing errors or exceptions.

**Network** — Defining networking-related abstractions.

**Use Cases** — Interfaces for use cases that the domain layer can implement.

#### Data Layer

This is the layer responsible for handling data sources, external services, and data models specific to a screen.

**Data Models** — This layer contains the data models for a screen.

#### Domain Layer

This layer contains the core business logic and entities of the application.

**Entities** — Objects that represent business entities and hold essential data and behavior.

**Repositories** — Interfaces that define the contract for interacting with data sources in the data layer.

#### Presentation Layer

This is the user interface layer responsible for rendering the UI and handling user interactions.

**Cubit/Bloc** — The Cubit/Bloc layer is responsible for handling state management and business logic for a screen.

**Pages** — The Pages layer is responsible for rendering the UI for a screen.

**Widgets** — The Widgets layer is responsible for rendering the UI components for a screen.

#### Services

This layer contains the services that the application uses — for example, the notification service.

## GitHub Actions

Using GitHub Actions to run automatic tests when commits or Pull Requests happen to the main branch. There is a workflow file in the `.github/workflows` folder in `.yml` format. This file will run all tests found in the test folder at the root of the repository.

## Tests

Refer to the [Testing](https://docs.flutter.dev/testing/overview) documentation on the Flutter website for more information on testing.

To run local tests on your machine, you can run the following:

### Widget Test

To run UI tests, run the command. The test cases for the UI are found in the `test/screens` folder in the root folder.
```bash
flutter test test/screens
```

### Unit Test

To run the Unit tests, run the command. The test cases for the Unit tests are found in the `test` folder in the root folder.
```bash
flutter test test/
```

### Integration Test

The test cases for Integration Test are found in the `integration_test` folder in the root folder.

Add the `integration_test` library to the dev_dependencies; this is a native library by Flutter itself:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
```

To run the integration tests on Android, follow the steps below:

1. Install the app on your emulator or physical device
```bash
flutter run
```

2. Stop the app after installing on your emulator or physical device by closing it or by pressing `Ctrl + C` in the terminal running the Flutter app, then typing `y` to terminate.

3. Add the adb path to your environment variables. The `adb` executable can be found in:
   - **Windows:** `AppData/android/sdk/platform-tools`
   - **macOS:** `Android/sdk/platform-tools`

   Add these paths to your environment variable, then run `adb --version` to verify.

4. Create the `grant_permission.sh` script in your root folder with the following code:
```bash
#!/bin/bash

# Exit on any error
set -e

# Replace with your actual package name (check app/build.gradle)
PACKAGE_NAME="actual-package-name"

# Grant required permissions via ADB
adb shell pm grant "$PACKAGE_NAME" android.permission.RECORD_AUDIO
adb shell pm grant "$PACKAGE_NAME" android.permission.CAMERA
adb shell pm grant "$PACKAGE_NAME" android.permission.POST_NOTIFICATIONS
adb shell pm grant "$PACKAGE_NAME" android.permission.ACCESS_FINE_LOCATION

echo "Permissions granted for $PACKAGE_NAME"
```

5. Run the bash script `grant_permission.sh` in the terminal to pre-grant permission to the app
```bash
./grant_permission.sh
```

6. Run the integration test command
```bash
flutter test integration_test/app_test.dart
```

_Note: the test may fail due to the tester missing the button, just rerun it._
