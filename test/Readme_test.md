# Automated Testing Plan for Flutter App

##  Objectives

- Automate all unit tests (domain, data, utils, services).
- Validate presentation logic using Cubit/Bloc tests.
- Enforce code correctness with pre-merge test runs.
- Generate test coverage reports for visibility.

---

##  Testing Layers and Responsibilities


| Layer        | Area / Responsibility                       | Testing Focus                                   | Type            | Tools / Mocks                                 |
|--------------|----------------------------------------------|--------------------------------------------------|------------------|-----------------------------------------------|
| Core         | `core/utils` – formatters, enums             | Helpers: formatting, mapping                     | Unit             | `flutter test`                                |
| Core         | `core/usecases` – logic branches             | Permission states, incentive math, timers        | Unit             | `flutter test`, `mocktail` (`location`)       |
| Core         | `core/network` – upload                      | Header JSON, list creation, error paths          | Unit             | `flutter test`, `mocktail` (`http.Client`)    |
| Core         | `core/dao` – database access                 | CRUD ops, filtering                              | Unit             | `objectbox_test`                              |

| Domain       | `domain/repositories`                        | Uploads, status flows, incentives, triggers      | Unit             | `flutter test`, `mocktail`                    |
| Domain       | `domain/entities`                            | Equality, `copyWith`, factory helpers            | Unit             | `flutter test`                                |
| Data         | `data/models`                                | JSON ↔ Map conversion                            | Unit             | `flutter test`                                |
| Presentation | `presentation/cubit/`                        | State transitions (load, save, submit)           | Unit (Bloc)      | `bloc_test`, `mocktail`                       |
| Services     | `preference_service.dart`                    | Read/write preferences                           | Unit             | `flutter test`, `shared_preferences` (fake)   |
| Services     | `route_service.dart`                         | Routing logic, navigation helpers                | Unit             | `flutter test`, `mocktail`                    |
| Services     | `notification_service.dart`                  | Trigger notifications, handle callbacks          | Unit             | `flutter test`, `mocktail`, `AwesomeNotifications` |

---

##  Test File Organization

```
test/
├── core/
│   └── utils/
├── screens/
│   └── home/
│       ├── data/
│       │   └── models/
│       ├── domain/
│       │   └── usecases/
│       └── presentation/
│           ├── cubit/
│           └── widgets/
├── services/
└── main_test.dart
```

---

## Automation Plan: Local + CI

### 1. Local Development Automation

**a. Run all tests**
```bash
flutter test
```

**b. Run tests on file change**
```bash
flutter test --watch
```

**c. Generate coverage report**
```bash
flutter test --coverage
```

**d. View coverage as HTML**
```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**e. Run code generation (if applicable)**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### 2. CI/CD Automation (GitHub Actions)

Create `.github/workflows/flutter_test.yml`:

```yaml
name: Flutter CI - Tests

on: [push, pull_request]

jobs:
    test:
        runs-on: ubuntu-latest

        steps:
            - uses: actions/checkout@v3

            - name: Set up Flutter
                uses: subosito/flutter-action@v2
                with:
                    flutter-version: '3.19.0'

            - name: Install dependencies
                run: flutter pub get

            - name: Generate code (if needed)
                run: flutter pub run build_runner build --delete-conflicting-outputs

            - name: Run unit and widget tests
                run: flutter test --coverage

            - name: Upload coverage to Codecov
                uses: codecov/codecov-action@v3
                with:
                    files: coverage/lcov.info
                    flags: flutter
```

*Optional: Integrate with Codecov.io or Coveralls.io to monitor test coverage over time.*

---

### 3. Enforce Pre-commit Testing ?????

Use pre-commit or a simple Git hook:

Create `.git/hooks/pre-commit`:

```bash
#!/bin/sh
flutter test || exit 1
```

Make it executable:

```bash
chmod +x .git/hooks/pre-commit
```

---

##  Test Coverage Expectations

| Layer         | Target Coverage         |
|---------------|------------------------|
| Use Cases     |  100%                |
| Repositories  |  90%+                |
| Models (to/from JSON) |  100%        |
| Cubit/Bloc    |  100% of transitions |
| UI Widgets    | Optional (prioritize logic) |
| Services      |  80–100%             |

---

## Dev Dependencies

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
    flutter_test:
        sdk: flutter
    mocktail: ^1.0.0
    bloc_test: ^9.1.0
    build_runner: ^2.3.3
    json_serializable: ^6.6.2
    freezed: ^2.3.2
```

---

## Tips for Long-Term Maintainability

- Follow consistent naming: `*_test.dart`
- Use mocks only for boundaries (repo, API, DB)
- Group tests by feature/screen
- Integrate code coverage into PR review
- Avoid over-testing Flutter widgets (test logic instead)

---

##  Summary

| Feature                        | Implemented? |
|---------------------------------|:-----------:|
| Unit test automation (local)    |           |
| CI automation (GitHub Actions)  |           |
| Code generation automation      |           |
| Coverage reporting              |           |
| Organized test structure        |           |
| Cubit/Bloc test automation      |           |
| Pre-commit test hook            |           |
