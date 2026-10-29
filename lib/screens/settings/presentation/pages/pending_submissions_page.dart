import 'package:flutter/material.dart';

import '../../../../core/diagnostics/local_data.dart';
import '../../../../core/diagnostics/submission_trace.dart';
import '../../../../core/diagnostics/trace_log.dart';
import '../../../../core/utils/statuses.dart';
import '../../../../services/preference_service.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';
import '../../../diary/domain/repository/diary_repository.dart';
import '../../../diary/domain/repository/summary_repository.dart';
import '../widgets/developer_widgets.dart';

typedef _Queue = ({LocalData data, List<TraceRecord> failures});

/// Developer mode page listing entries completed but not uploaded (the
/// pending submissions card), with their recordings and recent failures,
/// and a way to retry each one now.
///
/// A retry submits like the summary page does, under a trace that lands in
/// Failed submissions if it fails.
class PendingSubmissionsPage extends StatefulWidget {
  const PendingSubmissionsPage({super.key});

  @override
  State<PendingSubmissionsPage> createState() => _PendingSubmissionsPageState();
}

class _PendingSubmissionsPageState extends State<PendingSubmissionsPage> {
  late Future<_Queue> _queue = _load();

  /// Diaries being retried right now.
  final Set<int> _retrying = {};

  static Future<LocalData> _readPending() =>
      LocalData.read(where: (d) => d.status == DiaryStatus.complete);

  static Future<_Queue> _load() async =>
      (data: await _readPending(), failures: await TraceLog().load());

  void _reload() => setState(() {
        _queue = _load();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.fillNormal,
      appBar: developerAppBar(context, 'Pending submissions', actions: [
        IconButton(
          key: const Key('refresh_pending_submissions'),
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _retrying.isEmpty ? _reload : null,
        ),
      ]),
      body: FutureBuilder<_Queue>(
        future: _queue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Could not read the queue:\n${snapshot.error}',
                    textAlign: TextAlign.center),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                  color: CustomColors.productNormalActive),
            );
          }
          final queue = snapshot.data!;
          final pending = queue.data.pending;
          if (pending.isEmpty) return _empty();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const DeveloperNote(
                  'Entries completed on this device but not uploaded yet, '
                  'oldest first. Failures are from the Failed submissions log.'),
              const SizedBox(height: 12),
              for (final diary in pending) ...[
                _entryCard(queue, diary),
                const SizedBox(height: 12),
              ],
              if (pending.length > 1)
                OutlinedButton.icon(
                  key: const Key('retry_all_pending'),
                  onPressed: _retrying.isEmpty ? () => _retry(pending) : null,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text('Retry all ${pending.length}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CustomColors.productNormal,
                    side: const BorderSide(color: CustomColors.productNormal),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Nothing waiting to submit on this device.',
          style: CustomTypography()
              .bodyLarge(color: CustomColors.textSecondaryContent),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _entryCard(_Queue queue, DiarySummary diary) {
    final failures =
        queue.failures.where((f) => f.diaryId == diary.id).toList();
    final last = failures.firstOrNull;
    final completed = diary.completions.elementAtOrNull(diary.currentEntry);
    final retrying = _retrying.contains(diary.id);

    return DeveloperCard(
      key: Key('pending_${diary.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              diary.name,
              style: CustomTypography().bodyLarge(
                  color: CustomColors.textNormalContent,
                  weight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            DeveloperField('Study', queue.data.studyName(diary.studyID)),
            DeveloperField('Diary ID', '${diary.id}'),
            DeveloperField(
                'Entry', '${diary.currentEntry + 1} of ${diary.entries}'),
            DeveloperField('Due', developerDateFormat.format(diary.due)),
            DeveloperField(
                'Completed',
                completed == null
                    ? 'Unknown'
                    : developerDateFormat
                        .format(DateTime.tryParse(completed) ?? diary.due)),
            DeveloperField('Answered',
                '${diary.answeredCurrent} of ${diary.prompts.length} prompts'),
            DeveloperField(
              'Recordings',
              diary.recordings.isEmpty
                  ? 'None'
                  : '${diary.recordings.length} · '
                      '${formatBytes(diary.recordingBytes)}'
                      '${diary.missingRecordings > 0 ? ' · ${diary.missingRecordings} missing on disk' : ''}',
              valueColor: diary.missingRecordings > 0
                  ? CustomColors.warningActive
                  : null,
            ),
            DeveloperField(
              'Recent failures',
              last == null
                  ? 'None logged'
                  : '${failures.length} · last '
                      '${developerDateFormat.format(last.time.toLocal())}\n'
                      'at ${last.step}: ${last.reason}',
              valueColor: last == null ? null : CustomColors.warningActive,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: Key('retry_pending_${diary.id}'),
                onPressed: _retrying.isEmpty ? () => _retry([diary]) : null,
                icon: retrying
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cloud_upload_outlined, size: 18),
                label: Text(retrying ? 'Submitting…' : 'Retry now'),
                style: TextButton.styleFrom(
                    foregroundColor: CustomColors.productNormal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Submits each of [diaries] in turn, then reports how it went.
  Future<void> _retry(List<DiarySummary> diaries) async {
    final diaryRepository = DiaryRepository();
    final summaryRepository = SummaryRepository();
    var sent = 0, failed = 0, offline = 0;

    for (final summary in diaries) {
      setState(() => _retrying.add(summary.id));
      final stored = diaryRepository.getDiaryByID(summary.id);
      if (stored == null) {
        failed++;
      } else {
        final diary = await summaryRepository.loadSummary(stored);
        final outcome =
            await submitWithTrace(diary, repository: summaryRepository);
        switch (outcome.result) {
          case true:
            sent++;
          case false:
            failed++;
          case null:
            offline++;
        }
      }
      if (!mounted) return;
      setState(() => _retrying.remove(summary.id));
    }

    await _updateNetworkErrorFlag(offline > 0);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text([
          if (sent > 0) '$sent sent',
          if (failed > 0) '$failed failed (see Failed submissions)',
          if (offline > 0) '$offline not sent: no internet',
        ].join(' · ')),
      ));
    _reload();
  }

  /// Keeps the home page's pending card in step, as the summary page and
  /// bulk submission do: shown after an offline attempt, hidden once the
  /// queue is empty.
  Future<void> _updateNetworkErrorFlag(bool wentOffline) async {
    final preferences = PreferenceService();
    if (wentOffline) {
      await preferences.setBoolPreference(key: 'network_error', value: true);
    } else if ((await _readPending()).pending.isEmpty) {
      await preferences.setBoolPreference(key: 'network_error', value: false);
    }
  }
}
