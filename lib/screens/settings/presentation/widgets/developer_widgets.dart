import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/statuses.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';

/// Shared pieces for the developer mode pages.

const TextStyle developerMonospace = TextStyle(
  fontFamily: 'Menlo',
  fontFamilyFallback: ['Courier', 'monospace'],
  fontSize: 11,
  height: 1.4,
  color: CustomColors.textNormalContent,
);

final DateFormat developerDateFormat = DateFormat('EEE d MMM y, HH:mm');

/// The app bar used across the developer pages.
PreferredSizeWidget developerAppBar(BuildContext context, String title,
    {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: CustomColors.fillNormal,
    title: Text(title, style: CustomTypography().titleLarge()),
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.pop(context),
    ),
    actions: actions,
    shape: const Border(
      bottom: BorderSide(color: CustomColors.productBorderNormal, width: 2),
    ),
  );
}

/// A white rounded card, as on the Settings page.
class DeveloperCard extends StatelessWidget {
  final Widget child;
  const DeveloperCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CustomColors.fillWhite,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: CustomColors.productBorderNormal),
      ),
      child: Theme(
        // Removes an ExpansionTile's default top/bottom dividers.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: child,
      ),
    );
  }
}

/// A label and its value on one line.
class DeveloperField extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const DeveloperField(this.label, this.value, {super.key, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: CustomTypography()
                    .bodyMedium(color: CustomColors.textSecondaryContent)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: CustomTypography().bodyMedium(
                  color: valueColor ?? CustomColors.textNormalContent,
                  weight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// A short muted note above a list.
class DeveloperNote extends StatelessWidget {
  final String text;
  const DeveloperNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: CustomTypography()
            .bodyMedium(color: CustomColors.textSecondaryContent));
  }
}

Color diaryStatusColor(DiaryStatus status) => switch (status) {
      DiaryStatus.idle => CustomColors.midGrey,
      DiaryStatus.ongoing => CustomColors.yellowDark,
      DiaryStatus.complete => CustomColors.productNormal,
      DiaryStatus.submitted => CustomColors.darkGreen,
      DiaryStatus.missed => CustomColors.warningActive,
    };

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Copies [text] and confirms with a snack bar.
Future<void> copyWithSnackBar(
    BuildContext context, String text, String message) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
