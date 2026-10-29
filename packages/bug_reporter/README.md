# bug_reporter

In-app bug reporting for Flutter. A floating report button captures a screenshot, the last ~50 breadcrumbs (navigation, taps, network, lifecycle), and device info, then files a GitHub issue with everything attached.

## Install

Depend on it by path from within this repo:

```yaml
dependencies:
  bug_reporter:
    path: packages/bug_reporter
```

## Use

Create a navigator key and a scaffold-messenger key, hand them to your app and to the reporter, initialize the config before `runApp`, then wrap your app in `BugReportScope`.

```dart
import 'package:bug_reporter/bug_reporter.dart';
import 'package:flutter/material.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  BugReporter.init(BugReporterConfig(
    navigatorKey: navigatorKey,
    messengerKey: messengerKey,
    routeNames: {'/Hub': 'Home', '/NewDiaryPage': 'New Diary'},
    github: GitHubConfig(
      repo: 'owner/repo',
      token: 'your-github-token',
      labels: ['bug', 'in-app'],
    ),
    imageUpload: ImageUploadConfig(
      url: 'https://your-upload-endpoint',
      apiKey: 'your-upload-key',
    ),
    // showReportButton defaults to kDebugMode; set true to show it to testers.
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      builder: (context, child) =>
          BugReportScope(child: child ?? const SizedBox.shrink()),
      home: const HomePage(),
    );
  }
}
```

Submitting a report creates a GitHub issue in `repo`, structured to match the repository's bug report issue form. The screenshot is uploaded through `imageUpload` and linked in the issue.

Using `go_router`? Pass the same `navigatorKey` to `GoRouter(navigatorKey: ...)` instead of `MaterialApp`.

## Optional add-ons

- Richer navigation breadcrumbs: add `BreadcrumbNavigatorObserver()` to your router's `observers`.
- Network breadcrumbs: add `BreadcrumbDioInterceptor()` to your Dio instance (or use the preconfigured `DioClient.instance`).
- Manual breadcrumbs anywhere: `Breadcrumbs.instance.custom('checkout_started')`.
- Redact sensitive data before it leaves the device with the `scrub` hook on `BugReporterConfig`.

## Configuration

| Field | Purpose |
| --- | --- |
| `github` | Repo, token and labels used to file the issue. |
| `imageUpload` | Endpoint and key used to upload the screenshot and get its link. |
| `showReportButton` | Whether the floating button is visible. Defaults to `kDebugMode`. |
| `navigatorKey` | Navigator used to open the report screen. Required for the button to work. |
| `messengerKey` | Scaffold messenger used for post-submit snackbars. |
| `routeNames` | Map of route path to friendly name for breadcrumbs. |
| `iconNames` | Map of icon code point to label, for naming icon-only taps. |
| `scrub` | Callback to redact the payload JSON before submit. |

## Status

Pre-1.0 and evolving. Currently exercised on Android.
