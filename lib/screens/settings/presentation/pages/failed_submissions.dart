import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/diagnostics/trace_log.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';

/// Developer mode page listing recent failed submissions recorded by
/// [TraceLog], newest first, each with its full trace and a copy button.
class FailedSubmissionsPage extends StatefulWidget {
  const FailedSubmissionsPage({super.key});

  @override
  State<FailedSubmissionsPage> createState() => _FailedSubmissionsPageState();
}

class _FailedSubmissionsPageState extends State<FailedSubmissionsPage> {
  final TraceLog _log = TraceLog();
  late Future<List<TraceRecord>> _records = _log.load();

  static const _monospace = TextStyle(
    fontFamily: 'Menlo',
    fontFamilyFallback: ['Courier', 'monospace'],
    fontSize: 11,
    height: 1.4,
    color: CustomColors.textNormalContent,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.fillNormal,
      appBar: AppBar(
        backgroundColor: CustomColors.fillNormal,
        title: Text(
          'Failed submissions',
          style: CustomTypography().titleLarge(),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            key: const Key('clear_failed_submissions'),
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _confirmClear,
          ),
        ],
        shape: const Border(
          bottom: BorderSide(
            color: CustomColors.productBorderNormal,
            width: 2,
          ),
        ),
      ),
      body: FutureBuilder<List<TraceRecord>>(
        future: _records,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                  color: CustomColors.productNormalActive),
            );
          }
          final records = snapshot.data ?? const [];
          if (records.isEmpty) return _empty();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: records.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => index == 0
                ? Text(
                    'The last ${TraceLog.maxRecords} failures on this device, '
                    'newest first. Kept even when developer mode is off.',
                    style: CustomTypography()
                        .bodyMedium(color: CustomColors.textSecondaryContent),
                  )
                : _recordCard(records[index - 1]),
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
          'No failed submissions recorded on this device.',
          style: CustomTypography()
              .bodyLarge(color: CustomColors.textSecondaryContent),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _recordCard(TraceRecord record) {
    return Material(
      key: Key('failed_submission_${record.time.toIso8601String()}'),
      color: CustomColors.fillWhite,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: CustomColors.productBorderNormal),
      ),
      child: Theme(
        // Removes the ExpansionTile's default top/bottom dividers.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(
            record.simulated
                ? Icons.science_outlined
                : Icons.bug_report_rounded,
            color: record.simulated
                ? CustomColors.productNormal
                : CustomColors.warningActive,
          ),
          title: Text(
            DateFormat('EEE d MMM y, HH:mm:ss').format(record.time.toLocal()),
            style: CustomTypography().bodyLarge(
                color: CustomColors.textNormalContent, weight: FontWeight.w500),
          ),
          subtitle: Text(
            [
              if (record.diary != null) record.diary!,
              'Failed at: ${record.step}',
              record.reason,
              if (record.simulated) 'Simulated',
            ].join('\n'),
            style: CustomTypography()
                .bodyMedium(color: CustomColors.textSecondaryContent),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 320),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CustomColors.fillNormal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(record.report, style: _monospace),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _copy(record),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy'),
                style: TextButton.styleFrom(
                    foregroundColor: CustomColors.productNormal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(TraceRecord record) async {
    await Clipboard.setData(ClipboardData(text: record.report));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          const SnackBar(content: Text('Debug details copied to clipboard')));
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear failed submissions?'),
        content:
            const Text('This removes the recorded traces from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirm_clear_failed_submissions'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _log.clear();
    if (!mounted) return;
    setState(() {
      _records = _log.load();
    });
  }
}
