import 'package:dio/dio.dart';

import '../bug_reporter.dart';
import '../diagnostics/breadcrumb_formatter.dart';
import '../diagnostics/dio_client.dart';
import '../models/bug_report_payload.dart';
import 'bug_report_service.dart' show BugReportException;

class GitHubIssueService {
  final Dio _dio;

  GitHubIssueService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<String> createIssue(
    BugReportPayload payload, {
    String? imageUrl,
  }) async {
    final gh = BugReporter.config.github;
    if (gh == null || !gh.isConfigured) {
      throw BugReportException('GitHub repo or token is not configured.');
    }

    try {
      final res = await _dio.post(
        'https://api.github.com/repos/${gh.repo}/issues',
        data: {
          'title': _title(payload),
          'body': _body(payload, imageUrl),
          if (gh.labels.isNotEmpty) 'labels': gh.labels,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${gh.token}',
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
          },
        ),
      );

      final data = res.data;
      final url = data is Map ? data['html_url'] as String? : null;
      if (url == null || url.isEmpty) {
        throw BugReportException('GitHub did not return an issue URL.');
      }
      return url;
    } on DioException catch (e) {
      throw BugReportException(_messageFor(e));
    }
  }

  String _title(BugReportPayload p) {
    final title = p.title.trim();
    return title.isEmpty ? '[BUG] Report from ${p.currentScreen}' : '[BUG] $title';
  }

  String _body(BugReportPayload p, String? imageUrl) {
    final b = StringBuffer()
      ..writeln('### Description of the problem')
      ..writeln()
      ..writeln(p.description.trim())
      ..writeln()
      ..writeln('### Steps to reproduce')
      ..writeln()
      ..writeln('_Reconstructed automatically from the in-app activity trail '
          '(most recent last)._')
      ..writeln()
      ..writeln('<details><summary>Activity trail (${p.breadcrumbs.length})</summary>')
      ..writeln();
    if (p.breadcrumbs.isEmpty) {
      b.writeln('_No activity was recorded._');
    } else {
      for (final c in p.breadcrumbs) {
        b.writeln(
            '- `${c.timestamp.toIso8601String()}` ${BreadcrumbFormatter.describe(c)}');
      }
    }
    b
      ..writeln('</details>')
      ..writeln()
      ..writeln('### Expected results')
      ..writeln()
      ..writeln(_orPlaceholder(p.expectedResults))
      ..writeln()
      ..writeln('### Actual results')
      ..writeln()
      ..writeln(_orPlaceholder(p.actualResults))
      ..writeln()
      ..writeln('### Priority')
      ..writeln()
      ..writeln('P2 - Medium')
      ..writeln()
      ..writeln('### Device')
      ..writeln()
      ..writeln(_device(p.deviceInfo))
      ..writeln()
      ..writeln('### OS')
      ..writeln()
      ..writeln(_os(p.deviceInfo))
      ..writeln()
      ..writeln('### Additional context')
      ..writeln()
      ..writeln('**Screen:** ${p.currentScreen}')
      ..writeln('**Captured:** ${p.capturedAt.toIso8601String()}');
    if (imageUrl != null && imageUrl.isNotEmpty) {
      b
        ..writeln()
        ..writeln('![screenshot]($imageUrl)');
    }
    b
      ..writeln()
      ..writeln('<details><summary>Device info</summary>')
      ..writeln();
    p.deviceInfo.forEach((k, v) => b.writeln('- **$k:** $v'));
    b.writeln('</details>');
    return b.toString();
  }

  String _device(Map<String, dynamic> info) {
    final manufacturer = (info['manufacturer'] ?? '').toString().trim();
    final model = (info['model'] ?? '').toString().trim();
    final joined = [manufacturer, model].where((s) => s.isNotEmpty).join(' ');
    return joined.isEmpty ? 'Unknown' : joined;
  }

  String _orPlaceholder(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty
        ? '_Not provided (filed from the in-app reporter)._'
        : trimmed;
  }

  String _os(Map<String, dynamic> info) {
    final platform = (info['platform'] ?? '').toString().toLowerCase();
    if (platform == 'android') return 'Android';
    if (platform == 'ios') return 'iOS';
    return platform.isEmpty ? 'Unknown' : platform;
  }

  String _messageFor(DioException e) {
    final code = e.response?.statusCode;
    switch (code) {
      case 401:
      case 403:
        return 'GitHub rejected the token (needs Issues: write on the repo).';
      case 404:
        return 'GitHub repo not found (check owner/name and token access).';
      case 422:
        return 'GitHub rejected the issue as invalid.';
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Could not reach GitHub. Check the connection.';
    }
    return 'Failed to create the GitHub issue (${code ?? e.type.name}).';
  }
}
