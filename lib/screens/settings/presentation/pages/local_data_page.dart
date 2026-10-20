import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/diagnostics/local_data.dart';
import '../../../../core/utils/app_clock.dart';
import '../../../../core/utils/statuses.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';
import '../widgets/developer_widgets.dart';

/// Which diaries the inspector lists.
enum _DiaryFilter {
  today('Today'),
  pending('Pending'),
  all('All');

  final String label;
  const _DiaryFilter(this.label);
}

/// Developer mode page showing what is stored on this device: participant,
/// experiment, protocol, studies and every diary row with its prompts.
///
/// Read-only. Reads through [LocalData], which skips the status sweep, so
/// opening this page never changes a diary.
class LocalDataPage extends StatefulWidget {
  const LocalDataPage({super.key});

  @override
  State<LocalDataPage> createState() => _LocalDataPageState();
}

class _LocalDataPageState extends State<LocalDataPage> {
  late Future<LocalData> _data = LocalData.read();
  _DiaryFilter _filter = _DiaryFilter.today;
  DiaryStatus? _status;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.fillNormal,
      appBar: developerAppBar(context, 'Local data', actions: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: _Badge(
            label: 'Read-only',
            icon: Icons.lock_outline_rounded,
            background: CustomColors.fillWhite,
            foreground: CustomColors.textSecondaryContent,
          ),
        ),
        IconButton(
          key: const Key('refresh_local_data'),
          tooltip: 'Refresh local data',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => setState(() {
            _data = LocalData.read();
          }),
        ),
      ]),
      body: FutureBuilder<LocalData>(
        future: _data,
        builder: (context, snapshot) {
          // A refresh keeps the previous data on screen under the bar.
          final loading = snapshot.connectionState == ConnectionState.waiting;
          return Column(
            children: [
              SizedBox(
                height: 2,
                child: loading
                    ? const LinearProgressIndicator(
                        minHeight: 2,
                        color: CustomColors.productNormal,
                        backgroundColor: CustomColors.productLightBackground,
                      )
                    : null,
              ),
              Expanded(
                child: snapshot.hasError
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Could not read local data:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: CustomTypography()
                                .bodyMedium(color: CustomColors.warningNormal),
                          ),
                        ),
                      )
                    : snapshot.hasData
                        ? _content(snapshot.data!)
                        : const SizedBox.expand(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _content(LocalData data) {
    final diaries = _filtered(data)
      ..sort((a, b) => a.studyID != b.studyID
          ? a.studyID.compareTo(b.studyID)
          : a.start.compareTo(b.start));

    final groups = <int, List<DiarySummary>>{};
    for (final diary in diaries) {
      (groups[diary.studyID] ??= []).add(diary);
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(child: _SummaryCard(data: data)),
        ),
        PinnedHeaderSliver(
          child: _FilterBar(
            filter: _filter,
            status: _status,
            visibleCount: diaries.length,
            totalCount: data.diaries.length,
            onFilterChanged: (filter) => setState(() => _filter = filter),
            onStatusChanged: (status) => setState(() => _status = status),
          ),
        ),
        if (diaries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(
              onShowAll: () => setState(() {
                _filter = _DiaryFilter.all;
                _status = null;
              }),
            ),
          )
        else
          for (final group in groups.entries)
            // The group keeps each study's header pinned only while its own
            // diaries are on screen, instead of stacking them all.
            SliverMainAxisGroup(
              slivers: [
                PinnedHeaderSliver(
                  child: _StudyHeader(
                    name: data.studyName(group.key),
                    studyId: group.key,
                    count: group.value.length,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverList.builder(
                    itemCount: group.value.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DiaryTile(
                        key: Key('local_diary_${group.value[index].id}'),
                        diary: group.value[index],
                      ),
                    ),
                  ),
                ),
              ],
            ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  List<DiarySummary> _filtered(LocalData data) {
    final now = AppClock.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return data.diaries.where((diary) {
      if (_status != null && diary.status != _status) return false;
      return switch (_filter) {
        _DiaryFilter.today =>
          diary.start.isBefore(tomorrow) && diary.due.isAfter(today),
        _DiaryFilter.pending => diary.isPending,
        _DiaryFilter.all => true,
      };
    }).toList();
  }
}

/// [developerMonospace]'s font on top of [style], for IDs, dates and counts.
TextStyle _mono(TextStyle style) => style.copyWith(
      fontFamily: developerMonospace.fontFamily,
      fontFamilyFallback: developerMonospace.fontFamilyFallback,
    );

String _times(List<String> times) {
  if (times.isEmpty) return 'None';
  return times.map((t) {
    final parsed = DateTime.tryParse(t);
    return parsed == null ? t : developerDateFormat.format(parsed);
  }).join('\n');
}

/// A rounded pill: statuses, counts, prompt metadata.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
    this.border,
    this.icon,
    this.mono = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final IconData? icon;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final style = CustomTypography()
        .caption(color: foreground)
        .copyWith(fontWeight: FontWeight.w600);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          if (icon != null) Icon(icon, size: 14, color: foreground),
          Text(label, style: mono ? _mono(style) : style),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);

  final DiaryStatus status;

  @override
  Widget build(BuildContext context) {
    final color = diaryStatusColor(status);
    return _Badge(
      label: status.name,
      background: color.withValues(alpha: 0.12),
      foreground: color,
      border: color.withValues(alpha: 0.35),
    );
  }
}

/// A section title with an icon, used in the summary and expanded diaries.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.icon);

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Icon(icon, size: 18, color: CustomColors.productNormal),
        Text(title,
            style: CustomTypography().bodyLarge(
                color: CustomColors.textNormalContent,
                weight: FontWeight.w600)),
      ],
    );
  }
}

class _DetailValue {
  final String label;
  final String value;

  const _DetailValue(this.label, this.value);
}

/// A label on the left and its value right-aligned, with an optional
/// badge under the value.
class _SummaryValueRow extends StatelessWidget {
  const _SummaryValueRow(this.label, this.value, {this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Expanded(
          child: Text(label,
              style: CustomTypography()
                  .bodyMedium(color: CustomColors.textSecondaryContent)),
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SelectableText(
                value,
                textAlign: TextAlign.right,
                style: _mono(CustomTypography().bodyMedium(
                    color: CustomColors.textNormalContent,
                    weight: FontWeight.w600)),
              ),
              if (trailing != null) ...[
                const SizedBox(height: 6),
                trailing!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_DetailValue> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        _SectionTitle(title, icon),
        const SizedBox(height: 2),
        for (final row in rows) _SummaryValueRow(row.label, row.value),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final LocalData data;

  @override
  Widget build(BuildContext context) {
    final experiment = data.experiment;
    final protocol = data.protocol;

    final experimentSection = experiment == null
        ? null
        : _DetailSection(
            title: 'Experiment',
            icon: Icons.science_outlined,
            rows: [
              _DetailValue('Name', '${experiment['name']}'),
              _DetailValue('Login code', '${experiment['login']}'),
              _DetailValue('Version', '${experiment['version']}'),
            ],
          );

    final protocolSection = _DetailSection(
      title: 'Protocol',
      icon: Icons.account_tree_outlined,
      rows: protocol == null
          ? const [_DetailValue('Version', 'None')]
          : [
              _DetailValue('Version', '${protocol['version']}'),
              _DetailValue('Daily goal', '${protocol['daily_goal']}'),
              _DetailValue('Weekly goal', '${protocol['weekly_goal']}'),
              _DetailValue('Blueprints', '${protocol['blueprints']}'),
            ],
    );

    const divider = Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Divider(height: 1, color: CustomColors.productBorderNormal),
    );

    return DeveloperCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Participant',
                style: CustomTypography()
                    .caption(color: CustomColors.textSecondaryContent)),
            const SizedBox(height: 4),
            SelectableText(
              data.participantId ?? 'None',
              style: _mono(CustomTypography()
                  .titleLarge(color: CustomColors.textNormalContent)),
            ),
            divider,
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 560 && experimentSection != null) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16,
                    children: [
                      Expanded(child: experimentSection),
                      Expanded(child: protocolSection),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    if (experimentSection != null) experimentSection,
                    protocolSection,
                  ],
                );
              },
            ),
            divider,
            _SummaryValueRow('Studies', '${data.studies.length}'),
            const SizedBox(height: 8),
            _SummaryValueRow(
              'App date',
              developerDateFormat.format(AppClock.now()),
              trailing: AppClock.isShifted
                  ? const _Badge(
                      label: 'Time-shifted',
                      icon: Icons.schedule_rounded,
                      background: CustomColors.orangeLight,
                      foreground: CustomColors.warningNormal,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text('Diary statuses',
                style: CustomTypography()
                    .caption(color: CustomColors.textSecondaryContent)),
            const SizedBox(height: 8),
            _StatusTiles(counts: data.statusCounts),
          ],
        ),
      ),
    );
  }
}

class _StatusTiles extends StatelessWidget {
  const _StatusTiles({required this.counts});

  final Map<DiaryStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520
            ? 5
            : constraints.maxWidth >= 280
                ? 3
                : 2;
        final width = (constraints.maxWidth - (columns - 1) * 8) / columns;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final status in DiaryStatus.values)
              Container(
                width: width,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: CustomColors.fillWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CustomColors.productBorderNormal),
                ),
                child: Column(
                  children: [
                    Container(height: 4, color: diaryStatusColor(status)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                      child: Column(
                        spacing: 2,
                        children: [
                          Text('${counts[status] ?? 0}',
                              style: _mono(CustomTypography().titleLarge(
                                  color: CustomColors.textNormalContent))),
                          Text(
                            status.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: CustomTypography().caption(
                                color: CustomColors.textSecondaryContent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.status,
    required this.visibleCount,
    required this.totalCount,
    required this.onFilterChanged,
    required this.onStatusChanged,
  });

  final _DiaryFilter filter;
  final DiaryStatus? status;
  final int visibleCount;
  final int totalCount;
  final ValueChanged<_DiaryFilter> onFilterChanged;
  final ValueChanged<DiaryStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: const BoxDecoration(
        color: CustomColors.fillNormal,
        border:
            Border(bottom: BorderSide(color: CustomColors.productBorderNormal)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final item in _DiaryFilter.values)
                ChoiceChip(
                  key: Key('local_data_filter_${item.name}'),
                  label: Text(item.label),
                  selected: filter == item,
                  showCheckmark: false,
                  onSelected: (_) => onFilterChanged(item),
                  backgroundColor: CustomColors.fillWhite,
                  selectedColor: CustomColors.productLightBackground,
                  labelStyle: CustomTypography().bodyMedium(
                      color: filter == item
                          ? CustomColors.productDark
                          : CustomColors.textSecondaryContent,
                      weight: FontWeight.w600),
                  side: BorderSide(
                      color: filter == item
                          ? CustomColors.productNormal
                          : CustomColors.productBorderNormal),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: CustomColors.fillWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CustomColors.productBorderNormal),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DiaryStatus?>(
                    key: const Key('local_data_status_filter'),
                    value: status,
                    hint: const Text('Any status'),
                    style: CustomTypography()
                        .bodyMedium(color: CustomColors.textNormalContent),
                    icon: const Icon(Icons.arrow_drop_down_rounded,
                        color: CustomColors.textSecondaryContent),
                    dropdownColor: CustomColors.fillWhite,
                    items: [
                      const DropdownMenuItem<DiaryStatus?>(
                          value: null, child: Text('Any status')),
                      for (final item in DiaryStatus.values)
                        DropdownMenuItem<DiaryStatus?>(
                            value: item, child: Text(item.name)),
                    ],
                    onChanged: onStatusChanged,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('$visibleCount of $totalCount diary rows',
              style: CustomTypography()
                  .caption(color: CustomColors.textSecondaryContent)),
        ],
      ),
    );
  }
}

class _StudyHeader extends StatelessWidget {
  const _StudyHeader({
    required this.name,
    required this.studyId,
    required this.count,
  });

  final String name;
  final int studyId;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: CustomColors.fillNormal,
        border:
            Border(bottom: BorderSide(color: CustomColors.productBorderNormal)),
      ),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: Text(
              '$name (study $studyId)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CustomTypography()
                  .titleMedium(color: CustomColors.textNormalContent),
            ),
          ),
          _Badge(
            label: '$count',
            mono: true,
            background: CustomColors.fillWhite,
            foreground: CustomColors.textSecondaryContent,
            border: CustomColors.productBorderNormal,
          ),
        ],
      ),
    );
  }
}

/// Values laid out in one column, or two on wide screens.
class _ValueGrid extends StatelessWidget {
  const _ValueGrid(this.values);

  final List<_DetailValue> values;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 480
            ? (constraints.maxWidth - 8) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              Container(
                width: width,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CustomColors.fillNormal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(value.label,
                        style: CustomTypography()
                            .caption(color: CustomColors.textSecondaryContent)),
                    SelectableText(value.value,
                        style: _mono(CustomTypography().bodyMedium(
                            color: CustomColors.textNormalContent,
                            weight: FontWeight.w500))),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DiaryTile extends StatelessWidget {
  const _DiaryTile({super.key, required this.diary});

  final DiarySummary diary;

  @override
  Widget build(BuildContext context) {
    return DeveloperCard(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Expanded(
              child: Text(diary.name,
                  style: CustomTypography().bodyLarge(
                      color: CustomColors.textNormalContent,
                      weight: FontWeight.w600)),
            ),
            _StatusBadge(diary.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${developerDateFormat.format(diary.start)} · '
            'entry ${diary.currentEntry}/${diary.entries}',
            style: _mono(CustomTypography()
                .caption(color: CustomColors.textSecondaryContent)),
          ),
        ),
        children: [
          const Divider(height: 1, color: CustomColors.productBorderNormal),
          const SizedBox(height: 16),
          const _SectionTitle('Schedule', Icons.schedule_outlined),
          const SizedBox(height: 8),
          _ValueGrid([
            _DetailValue('ID', '${diary.id}'),
            _DetailValue('Start', developerDateFormat.format(diary.start)),
            _DetailValue('End', developerDateFormat.format(diary.end)),
            _DetailValue('Due', developerDateFormat.format(diary.due)),
            _DetailValue('Active days', diary.activeDays?.join(', ') ?? 'All'),
            _DetailValue('Notifications', '${diary.notifications}'),
          ]),
          const SizedBox(height: 16),
          const _SectionTitle('Activity', Icons.timeline_outlined),
          const SizedBox(height: 8),
          _ValueGrid([
            _DetailValue('Completions', _times(diary.completions)),
            _DetailValue('Submissions', _times(diary.submissions)),
          ]),
          if (diary.recordings.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionTitle('Recordings', Icons.mic_none_rounded),
            const SizedBox(height: 8),
            _ValueGrid([
              _DetailValue('Count', '${diary.recordings.length}'),
              _DetailValue('Total size', formatBytes(diary.recordingBytes)),
            ]),
            if (diary.missingRecordings > 0) ...[
              const SizedBox(height: 8),
              _MissingFilesBanner(diary.missingRecordings),
            ],
          ],
          const SizedBox(height: 16),
          const _SectionTitle('Prompts', Icons.quiz_outlined),
          const SizedBox(height: 4),
          for (var i = 0; i < diary.prompts.length; i++) ...[
            _PromptRow(diary.prompts[i]),
            if (i != diary.prompts.length - 1)
              const Divider(
                  height: 16, color: CustomColors.productBorderNormal),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => copyWithSnackBar(
                  context,
                  const JsonEncoder.withIndent('  ').convert(diary.toJson()),
                  'Diary row copied to clipboard'),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy JSON'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: CustomColors.productLightBackground,
                foregroundColor: CustomColors.productDark,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingFilesBanner extends StatelessWidget {
  const _MissingFilesBanner(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CustomColors.orangeLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CustomColors.warningFill),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 18, color: CustomColors.warningNormal),
          Expanded(
            child: Text(
              '$count ${count == 1 ? 'file is' : 'files are'} missing on disk',
              style: CustomTypography().bodyMedium(
                  color: CustomColors.warningNormal, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptRow extends StatelessWidget {
  const _PromptRow(this.prompt);

  final PromptSummary prompt;

  @override
  Widget build(BuildContext context) {
    final missing = prompt.recordings.where((r) => !r.exists).length;

    Widget chip(String label, {bool warning = false}) => _Badge(
          label: label,
          background:
              warning ? CustomColors.orangeLight : CustomColors.fillNormal,
          foreground: warning
              ? CustomColors.warningNormal
              : CustomColors.textSecondaryContent,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Icon(
            prompt.answeredCurrent
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: prompt.answeredCurrent
                ? CustomColors.darkGreen
                : CustomColors.midGrey,
            semanticLabel: prompt.answeredCurrent ? 'Answered' : 'Not answered',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q${prompt.questionNumber} · ${prompt.question}',
                  style: CustomTypography().bodyMedium(
                      color: CustomColors.textNormalContent,
                      weight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    chip(prompt.type),
                    if (prompt.required) chip('required'),
                    chip('${prompt.answerCount} answers'),
                    if (prompt.recordings.isNotEmpty)
                      chip('${prompt.recordings.length} files'),
                    if (missing > 0) chip('$missing missing', warning: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onShowAll});

  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_alt_off_outlined,
                size: 40, color: CustomColors.midGrey),
            const SizedBox(height: 16),
            Text(
              'No diaries match these filters',
              textAlign: TextAlign.center,
              style: CustomTypography()
                  .titleMedium(color: CustomColors.textNormalContent),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('local_data_show_all'),
              onPressed: onShowAll,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: CustomColors.productNormal,
              ),
              child: const Text('Show all'),
            ),
          ],
        ),
      ),
    );
  }
}
