import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/diagnostics/debug_trace.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';

/// Developer mode panel shown on the submission error page: what failed,
/// where, why, and the full submission timeline, with a copy button for bug
/// reports.
class SubmissionDebugPanel extends StatelessWidget {
  final DebugTrace trace;

  const SubmissionDebugPanel({super.key, required this.trace});

  static const _monospace = TextStyle(
    fontFamily: 'Menlo',
    fontFamilyFallback: ['Courier', 'monospace'],
    fontSize: 11,
    height: 1.4,
    color: CustomColors.textNormalContent,
  );

  @override
  Widget build(BuildContext context) {
    final root = trace.rootFailure;

    return Material(
      key: const Key('submission_debug_panel'),
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
          leading: const Icon(Icons.bug_report_rounded,
              color: CustomColors.warningActive),
          title: Text(
            "Debug details",
            style: CustomTypography().bodyLarge(
                color: CustomColors.textNormalContent, weight: FontWeight.w500),
          ),
          subtitle: root == null
              ? null
              : Text(
                  "Failed at: ${root.step}",
                  style: CustomTypography()
                      .bodyMedium(color: CustomColors.textSecondaryContent),
                ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (root != null) ...[
              _row("What happened", root.message ?? "Unknown"),
              _row("Where", root.step),
              ...root.data.entries.map((e) => _row(e.key, e.value)),
              const SizedBox(height: 12),
            ],
            Container(
              constraints: const BoxConstraints(maxHeight: 240),
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CustomColors.fillNormal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(trace.toReport(), style: _monospace),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const Key('copy_debug_details'),
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text("Copy"),
                style: TextButton.styleFrom(
                    foregroundColor: CustomColors.productNormal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          text: "$label: ",
          style: CustomTypography().bodyMedium(
              color: CustomColors.textNormalContent, weight: FontWeight.w600),
          children: [
            TextSpan(
              text: value,
              style: CustomTypography()
                  .bodyMedium(color: CustomColors.textSecondaryContent),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: trace.toReport()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          const SnackBar(content: Text("Debug details copied to clipboard")));
  }
}
