import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../bug_reporter.dart';
import '../diagnostics/breadcrumb.dart';
import '../diagnostics/breadcrumbs.dart';
import '../models/bug_report_payload.dart';
import '../services/bug_report_service.dart';
import '../services/github_issue_service.dart';
import '../services/image_upload_service.dart';
import 'breadcrumb_list.dart';

class BugReportScreen extends StatefulWidget {
  final BugReportDraft draft;

  const BugReportScreen({super.key, required this.draft});

  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _expectedController = TextEditingController();
  final _actualController = TextEditingController();
  final _service = BugReportService();
  final _imageService = ImageUploadService();
  final _githubService = GitHubIssueService();
  String? _titleError;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _expectedController.dispose();
    _actualController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final expected = _expectedController.text.trim();
    final actual = _actualController.text.trim();
    if (title.isEmpty || description.isEmpty) {
      setState(() {
        _titleError = title.isEmpty ? 'Please add a short title.' : null;
        _error =
            description.isEmpty ? 'Please describe what went wrong.' : null;
      });
      return;
    }
    setState(() {
      _titleError = null;
      _error = null;
      _saving = true;
    });

    String? screenshotKey;
    if (BugReporter.config.isBackendConfigured) {
      screenshotKey = await _service.uploadScreenshot(widget.draft.screenshot);
      if (!mounted) return;
    }

    final payload = BugReportPayload.fromDraft(
      widget.draft,
      description,
      title: title,
      expectedResults: expected,
      actualResults: actual,
      screenshotKey: screenshotKey,
    );
    final json = const JsonEncoder.withIndent('  ').convert(payload.toJson());

    debugPrint('==== Bug Report Payload ====');
    debugPrint(json);
    debugPrint('==== End Bug Report ====');

    try {
      final savedPath = await _saveLocally(json);
      debugPrint('Bug report saved to: $savedPath');
    } catch (e) {
      debugPrint('Failed to save bug report locally: $e');
    }

    if (BugReporter.config.isBackendConfigured) {
      try {
        final issueUrl = await _service.submit(payload);
        Breadcrumbs.instance.custom('bug_report_submitted', data: {'issue': issueUrl});
        if (!mounted) return;
        Navigator.of(context).pop();
      } on BugReportException catch (e) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
      return;
    }

    if (BugReporter.config.github?.isConfigured ?? false) {
      try {
        String? imageUrl;
        if (BugReporter.config.imageUpload?.isConfigured ?? false) {
          imageUrl = await _imageService.upload(widget.draft.screenshot);
          if (!mounted) return;
          debugPrint('[bug_reporter] image upload -> ${imageUrl ?? 'FAILED (issue will file without image)'}');
        }
        final issueUrl =
            await _githubService.createIssue(payload, imageUrl: imageUrl);
        debugPrint('[bug_reporter] GitHub issue created: $issueUrl');
        Breadcrumbs.instance.custom('bug_report_submitted', data: {'issue': issueUrl});
        if (!mounted) return;
        Navigator.of(context).pop();
      } on BugReportException catch (e) {
        debugPrint('[bug_reporter] GitHub submit failed: ${e.message}');
        if (!mounted) return;
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
      return;
    }

    Breadcrumbs.instance.custom('bug_report_captured_local');
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
    BugReporter.config.messengerKey?.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Captured locally (no backend or GitHub configured).'),
      ),
    );
  }

  Future<String> _saveLocally(String json) async {
    final dir = await getApplicationDocumentsDirectory();
    final stamp = widget.draft.capturedAt.millisecondsSinceEpoch;
    final folder = Directory(p.join(dir.path, 'bug_reports', '$stamp'));
    await folder.create(recursive: true);
    await File(p.join(folder.path, 'screenshot.png'))
        .writeAsBytes(widget.draft.screenshot);
    await File(p.join(folder.path, 'report.json')).writeAsString(json);
    return folder.path;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = widget.draft;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Report a Bug'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScreenshotPreview(theme, draft),
            const SizedBox(height: 12),
            Text(
              'Screen: ${draft.currentScreen}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            Text('Issue title', style: _labelStyle(theme)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'A short summary of the problem',
                errorText: _titleError,
              ),
            ),
            const SizedBox(height: 24),
            Text('What happened?', style: _labelStyle(theme)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Describe the bug and how to reproduce it',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 24),
            Text('Expected results', style: _labelStyle(theme)),
            const SizedBox(height: 8),
            TextField(
              controller: _expectedController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'What did you expect to happen?',
              ),
            ),
            const SizedBox(height: 24),
            Text('Actual results', style: _labelStyle(theme)),
            const SizedBox(height: 8),
            TextField(
              controller: _actualController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'What actually happened?',
              ),
            ),
            const SizedBox(height: 24),
            _buildBreadcrumbSection(theme, draft.breadcrumbs),
            const SizedBox(height: 20),
            _buildDeviceSection(theme, draft.deviceInfo),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle? _labelStyle(ThemeData theme) =>
      theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600);

  Widget _buildScreenshotPreview(ThemeData theme, BugReportDraft draft) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 280),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.memory(draft.screenshot, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbSection(ThemeData theme, List<Breadcrumb> breadcrumbs) {
    return Material(
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(12),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(Icons.timeline, color: theme.colorScheme.primary),
          title: Text(
            'Breadcrumbs (${breadcrumbs.length})',
            style: theme.textTheme.bodyMedium,
          ),
          children: [
            BreadcrumbList(breadcrumbs: breadcrumbs),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceSection(ThemeData theme, Map<String, dynamic> info) {
    final entries = info.entries.toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Device info', style: _labelStyle(theme)),
          const SizedBox(height: 12),
          ...entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(e.key, style: theme.textTheme.bodySmall),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${e.value}',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
