import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const String kBugReportRouteName = '/bug-report';

const int kBugReportSchemaVersion = 1;

typedef BugReportScrubber = Map<String, dynamic> Function(
  Map<String, dynamic> json,
);

class BugReporterConfig {
  final String backendBaseUrl;
  final String apiKey;
  final bool showReportButton;
  final GlobalKey<NavigatorState>? navigatorKey;
  final GlobalKey<ScaffoldMessengerState>? messengerKey;
  final Map<String, String> routeNames;
  final Map<int, String> iconNames;
  final BugReportScrubber? scrub;
  final GitHubConfig? github;
  final ImageUploadConfig? imageUpload;

  const BugReporterConfig({
    this.backendBaseUrl = '',
    this.apiKey = '',
    this.showReportButton = kDebugMode,
    this.navigatorKey,
    this.messengerKey,
    this.routeNames = const {},
    this.iconNames = const {},
    this.scrub,
    this.github,
    this.imageUpload,
  });

  bool get isBackendConfigured =>
      backendBaseUrl.isNotEmpty && apiKey.isNotEmpty;
}

class GitHubConfig {
  final String repo;
  final String token;
  final List<String> labels;

  const GitHubConfig({
    required this.repo,
    required this.token,
    this.labels = const ['bug'],
  });

  bool get isConfigured => repo.isNotEmpty && token.isNotEmpty;
}

class ImageUploadConfig {
  final String url;
  final String apiKey;
  final String keyPrefix;
  final String publicBaseUrl;

  const ImageUploadConfig({
    required this.url,
    this.apiKey = '',
    this.keyPrefix = 'bug-reports',
    this.publicBaseUrl = '',
  });

  bool get isConfigured => url.isNotEmpty;
}

class BugReporter {
  BugReporter._();

  static BugReporterConfig _config = const BugReporterConfig();

  static BugReporterConfig get config => _config;

  static void init(BugReporterConfig config) {
    _config = config;
  }
}
