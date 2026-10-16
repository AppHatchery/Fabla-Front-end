import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/usecases/time_travel.dart';
import '../../../../core/utils/app_clock.dart';
import '../../../../services/developer_mode_service.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';
import '../../../../theme/dialogs/pop_ups.dart';
import '../../../home/presentation/cubit/cubit/home_cubit.dart';
import '../widgets/developer_widgets.dart';

/// Developer mode page for shifting the app's date ([AppClock]) to test
/// diary windows, goals, incentives and the calendar on other days.
///
/// Travel is "full": statuses the app saves while travelling stick. Back in
/// the present, the repair section lists the `missed` and `submitted`
/// statuses travelling caused and resets them (see [planStatusRepairs]).
class TimeTravelPage extends StatefulWidget {
  const TimeTravelPage({super.key});

  @override
  State<TimeTravelPage> createState() => _TimeTravelPageState();
}

class _TimeTravelPageState extends State<TimeTravelPage> {
  final TimeTravel _timeTravel = TimeTravel();
  final DeveloperModeService _developerMode = DeveloperModeService();
  late Future<List<StatusRepair>> _repairs = _timeTravel.pendingRepairs();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.fillNormal,
      appBar: developerAppBar(context, 'Time travel'),
      body: ValueListenableBuilder<Duration>(
        valueListenable: _developerMode.timeTravel,
        builder: (context, offset, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ClockCard(offset: offset),
            const SizedBox(height: 16),
            _JumpControls(
              offset: offset,
              busy: _busy,
              onJump: (by) => _travel(offset + by),
              onPick: _pick,
              onReturnToPresent: _returnToPresent,
            ),
            if (offset == Duration.zero) _repairSection(),
            const SizedBox(height: 24),
            const _HowItWorks(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _repairSection() {
    return FutureBuilder<List<StatusRepair>>(
      future: _repairs,
      builder: (context, snapshot) {
        final repairs = snapshot.data ?? const [];
        if (repairs.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: _RepairSection(
            repairs: repairs,
            busy: _busy,
            onRepair: () => _repair(repairs.length),
          ),
        );
      },
    );
  }

  Future<void> _pick() async {
    final now = AppClock.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365 * 3)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (time == null) return;
    final target =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    // Whole minutes, as stored.
    await _travel(
        Duration(minutes: target.difference(DateTime.now()).inMinutes));
  }

  Future<void> _travel(Duration offset) async {
    if (offset.inMinutes == 0) return _returnToPresent();
    if (!_developerMode.isTimeTravelling && !await _confirmTravel()) return;
    await _run(() => _timeTravel.travel(offset));
  }

  Future<void> _returnToPresent() async {
    await _run(_timeTravel.returnToPresent);
  }

  Future<void> _repair(int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeletePopUp(
        title: 'Repair $count ${count == 1 ? 'diary' : 'diaries'}?',
        subheader: 'Their statuses are set back as listed, and '
            'notifications are rescheduled.',
        confirmText: 'Repair',
        confirmKey: const Key('confirm_time_travel_repair'),
      ),
    );
    if (confirmed != true) return;
    int fixed = 0;
    await _run(() async => fixed = await _timeTravel.repair());
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Repaired $fixed diaries')));
  }

  Future<bool> _confirmTravel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const DeletePopUp(
        title: 'Start time travel?',
        subheader: 'The load-time check can save past-due diaries as missed '
            'or submitted, and those changes persist after you return. '
            'Entries submitted while travelling use the app date as their '
            'timestamp. Back in the present, use Repair to reset the listed '
            'statuses.',
        confirmText: 'Travel',
        confirmKey: Key('confirm_time_travel'),
      ),
    );
    return confirmed == true;
  }

  /// Runs [change], then reloads the home page and the repair list.
  Future<void> _run(Future<void> Function() change) async {
    setState(() => _busy = true);
    try {
      await change();
      if (!mounted) return;
      try {
        await context.read<HomeCubit>().loadDiaries();
      } catch (_) {
        // No HomeCubit above this page (e.g. in tests).
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _repairs = _timeTravel.pendingRepairs();
        });
      }
    }
  }
}

/// [offset] without its sign, as "2d 3h"; "0m" when there is none.
String _offsetParts(Duration offset) {
  final total = offset.abs();
  final parts = [
    if (total.inDays > 0) '${total.inDays}d',
    if (total.inHours % 24 > 0) '${total.inHours % 24}h',
    if (total.inMinutes % 60 > 0) '${total.inMinutes % 60}m',
  ];
  return parts.isEmpty ? '0m' : parts.join(' ');
}

/// A rounded badge, for the shifted marker, the offset and statuses.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
    this.border,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          if (icon != null) Icon(icon, size: 16, color: foreground),
          Text(label,
              style: CustomTypography()
                  .bodyMedium(color: foreground, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ClockCard extends StatelessWidget {
  const _ClockCard({required this.offset});

  final Duration offset;

  @override
  Widget build(BuildContext context) {
    final shifted = offset != Duration.zero;
    final appNow = AppClock.now();
    const secondaryText = CustomColors.textSecondaryContent;

    return Material(
      color: shifted ? CustomColors.orangeLight : CustomColors.fillWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: shifted
              ? CustomColors.warningActive
              : CustomColors.productBorderNormal,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (shifted) ...[
              const _Pill(
                label: 'Time-shifted',
                icon: Icons.schedule_rounded,
                background: CustomColors.warningActive,
                foreground: CustomColors.textWhite,
              ),
              const SizedBox(height: 16),
            ],
            Semantics(
              label: 'App date ${developerDateFormat.format(appNow)}',
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  DateFormat('d MMM y').format(appNow),
                  key: const Key('time_travel_app_date'),
                  style: CustomTypography().headlineLarge(
                      color: shifted
                          ? CustomColors.warningNormal
                          : CustomColors.textNormalContent),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE · HH:mm').format(appNow),
              style: CustomTypography().titleMedium(color: secondaryText),
            ),
            const SizedBox(height: 16),
            if (shifted) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _Pill(
                    label: '${offset.isNegative ? '−' : '+'}'
                        '${_offsetParts(offset)}',
                    background: CustomColors.fillWhite,
                    foreground: CustomColors.textNormalContent,
                    border: CustomColors.productBorderNormal,
                  ),
                  Text(
                    offset.isNegative
                        ? 'behind the device'
                        : 'ahead of the device',
                    style: CustomTypography().bodyMedium(color: secondaryText),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Device: ${developerDateFormat.format(DateTime.now())}',
                style: CustomTypography().caption(color: secondaryText),
              ),
            ] else
              Text(
                'App date matches the device',
                style: CustomTypography().bodyMedium(color: secondaryText),
              ),
          ],
        ),
      ),
    );
  }
}

class _JumpControls extends StatelessWidget {
  const _JumpControls({
    required this.offset,
    required this.busy,
    required this.onJump,
    required this.onPick,
    required this.onReturnToPresent,
  });

  final Duration offset;
  final bool busy;
  final ValueChanged<Duration> onJump;
  final VoidCallback onPick;
  final VoidCallback onReturnToPresent;

  static final _shape =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  @override
  Widget build(BuildContext context) {
    // Past jumps are amber, future ones blue, so direction reads at a glance.
    Widget jump({
      required String label,
      required IconData icon,
      required Duration by,
      required String key,
      bool past = false,
    }) {
      return Expanded(
        child: FilledButton.icon(
          key: Key(key),
          onPressed: busy ? null : () => onJump(by),
          icon: Icon(icon),
          label: Text(label),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 56),
            backgroundColor: past
                ? CustomColors.yellowLight
                : CustomColors.productLightBackground,
            foregroundColor:
                past ? CustomColors.pumpkinOrange : CustomColors.productDark,
            textStyle: CustomTypography().bodyMedium(weight: FontWeight.w600),
            shape: _shape,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Quick jumps',
            style: CustomTypography()
                .titleMedium(color: CustomColors.textNormalContent)),
        const SizedBox(height: 8),
        Row(
          spacing: 8,
          children: [
            jump(
              label: '−1 day',
              icon: Icons.history_rounded,
              by: const Duration(days: -1),
              key: 'time_travel_minus_day',
              past: true,
            ),
            jump(
              label: '+1 hour',
              icon: Icons.add_alarm_rounded,
              by: const Duration(hours: 1),
              key: 'time_travel_plus_hour',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          spacing: 8,
          children: [
            jump(
              label: '+1 day',
              icon: Icons.today_rounded,
              by: const Duration(days: 1),
              key: 'time_travel_plus_day',
            ),
            jump(
              label: '+1 week',
              icon: Icons.date_range_rounded,
              by: const Duration(days: 7),
              key: 'time_travel_plus_week',
            ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const Key('time_travel_pick'),
          onPressed: busy ? null : onPick,
          icon: const Icon(Icons.calendar_month_rounded),
          label: const Text('Pick a date and time'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: CustomColors.productNormal,
            side: const BorderSide(color: CustomColors.productNormal),
            shape: _shape,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: offset == Duration.zero
                ? const SizedBox.shrink(key: ValueKey('present_hidden'))
                : SizedBox(
                    key: const ValueKey('present_visible'),
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('time_travel_present'),
                      onPressed: busy ? null : onReturnToPresent,
                      icon: const Icon(Icons.restore_rounded),
                      label: const Text('Back to the present'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: CustomColors.productNormal,
                        foregroundColor: CustomColors.textWhite,
                        shape: _shape,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _RepairSection extends StatelessWidget {
  const _RepairSection({
    required this.repairs,
    required this.busy,
    required this.onRepair,
  });

  final List<StatusRepair> repairs;
  final bool busy;
  final VoidCallback onRepair;

  /// Rows listed before "…and N more".
  static const int _shown = 50;

  @override
  Widget build(BuildContext context) {
    final visible = repairs.take(_shown).toList(growable: false);

    Widget repairRow(StatusRepair repair) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(repair.diary.name,
              style: CustomTypography().bodyLarge(
                  color: CustomColors.textNormalContent,
                  weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(developerDateFormat.format(repair.diary.start),
              style: CustomTypography()
                  .caption(color: CustomColors.textSecondaryContent)),
          const SizedBox(height: 4),
          Text(repair.reason,
              style: CustomTypography()
                  .caption(color: CustomColors.textSecondaryContent)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Pill(
                label: repair.from.name,
                background: CustomColors.fillWhite,
                foreground: diaryStatusColor(repair.from),
                border: CustomColors.productBorderNormal,
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: CustomColors.textSecondaryContent,
                semanticLabel: 'changes to',
              ),
              _Pill(
                label: repair.to.name,
                background: CustomColors.productLightBackground,
                foreground: CustomColors.productDark,
                border: CustomColors.productNormal,
              ),
            ],
          ),
        ],
      );
    }

    return DeveloperCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Repair diary statuses',
                          style: CustomTypography().titleMedium(
                              color: CustomColors.textNormalContent)),
                      const SizedBox(height: 8),
                      const DeveloperNote(
                          'These statuses look like they were saved while '
                          'travelling. Repairing sets them back; nothing is '
                          'sent to the server.'),
                    ],
                  ),
                ),
                _Pill(
                  label: '${repairs.length}',
                  background: CustomColors.productLightBackground,
                  foreground: CustomColors.productDark,
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < visible.length; i++) ...[
              repairRow(visible[i]),
              if (i != visible.length - 1) const Divider(height: 24),
            ],
            if (repairs.length > _shown) ...[
              const SizedBox(height: 8),
              DeveloperNote('…and ${repairs.length - _shown} more'),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('time_travel_repair'),
              onPressed: busy ? null : onRepair,
              icon: const Icon(Icons.build_rounded),
              label: Text('Repair ${repairs.length} '
                  '${repairs.length == 1 ? 'diary' : 'diaries'}'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: CustomColors.productNormal,
                foregroundColor: CustomColors.textWhite,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    Widget bullet(String value) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text('•',
                style: CustomTypography().bodyMedium(
                    color: CustomColors.productNormal,
                    weight: FontWeight.w700)),
            Expanded(child: DeveloperNote(value)),
          ],
        ),
      );
    }

    return DeveloperCard(
      child: ExpansionTile(
        leading: const Icon(Icons.info_outline_rounded,
            color: CustomColors.productNormal),
        title: Text('How it works',
            style: CustomTypography()
                .titleMedium(color: CustomColors.textNormalContent)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bullet('The app reads the date through a fixed AppClock offset. '
              'Logs and traces keep real time.'),
          bullet('The first trip snapshots every diary status, so changes '
              'caused by time travel can be told apart.'),
          bullet('Repair only resets the listed missed and submitted '
              'statuses, then reschedules notifications.'),
          bullet('Timezone changes are not simulated, and this page itself '
              'sends nothing to the server.'),
        ],
      ),
    );
  }
}
