import 'dart:async';
import 'dart:io';

import 'package:audio_diaries_flutter/core/utils/audio_processor.dart';
import 'package:audio_diaries_flutter/core/utils/audioPlayer.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/recording.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/prompt/prompt_cubit.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/theme/components/cards.dart' show RecordingIssueCard;
import 'package:audio_diaries_flutter/theme/components/static_waveform.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:audio_diaries_flutter/theme/dialogs/bottom_modals.dart';
import 'package:audio_diaries_flutter/theme/dialogs/pop_ups.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Bottom modal for editing an already-saved recording — trim, replace from a
/// point onward, or resume recording onto the end — mirroring iOS Voice
/// Memos' edit screen.
class BottomAudioEditModal extends StatefulWidget {
  final DiaryModel diary;
  final PromptModel prompt;
  final Recording recording;

  const BottomAudioEditModal({
    super.key,
    required this.diary,
    required this.prompt,
    required this.recording,
  });

  @override
  State<BottomAudioEditModal> createState() => _BottomAudioEditModalState();
}

class _BottomAudioEditModalState extends State<BottomAudioEditModal>
    with AudioPlaybackMixin<BottomAudioEditModal> {
  List<double>? _peaks;
  bool _waveformFailed = false;

  double _trimStart = 0;
  double _trimEnd = 1;

  bool _busy = false;

  String? _absolutePath;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    disposeAudio();
    super.dispose();
  }

  Future<void> _load() async {
    await initAudio(widget.recording.path);
    if (!mounted) return;

    final dir = await getApplicationDocumentsDirectory();
    final absolutePath = p.join(dir.path, widget.recording.path);
    if (!mounted) return;
    setState(() => _absolutePath = absolutePath);

    try {
      final peaks = await const AudioProcessor().extractWaveform(absolutePath);
      if (!mounted) return;
      setState(() => _peaks = peaks);
    } catch (e, s) {
      CrashlyticsService()
          .recordError(e, s, reason: 'Waveform extraction failed');
      if (!mounted) return;
      setState(() => _waveformFailed = true);
    }
  }

  double get _playheadFraction {
    final total = maxDuration.inMilliseconds;
    if (total <= 0) return 0;
    return (currentSliderPosition / total).clamp(0.0, 1.0);
  }

  /// The smallest gap kept between the two trim handles — roughly a second,
  /// so a drag can't collapse the selection to nothing.
  double get _minTrimGap {
    final total = maxDuration.inMilliseconds;
    if (total <= 0) return 0.05;
    return (1000 / total).clamp(0.01, 0.5);
  }

  bool get _canTrim => _trimStart > 0.001 || _trimEnd < 0.999;

  String _newFileName() =>
      'audio_prompt_${widget.prompt.id + 1}_'
      '${DateTime.now().microsecondsSinceEpoch}.m4a';

  Future<void> _deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {
        // Best-effort cleanup — an orphaned file costs storage, not
        // correctness, and is not worth failing the edit over.
      }
    }
  }

  /// Points [widget.recording] at [relativePath], then retires the file it
  /// used to point at, if any.
  Future<void> _persist(String relativePath,
      {String? deleteOldAbsolutePath}) async {
    await context.read<PromptCubit>().updateRecording(
          diary: widget.diary,
          prompt: widget.prompt,
          recording: widget.recording,
          newPath: relativePath,
        );

    if (deleteOldAbsolutePath != null) {
      await _deleteIfExists(deleteOldAbsolutePath);
    }
  }

  /// Opens the existing recording modal in resume mode, reporting whether a
  /// take was actually saved.
  Future<bool> _openRecordingModal({
    String? resumeFromPath,
    required Duration resumeElapsed,
    String? deleteOnSave,
  }) async {
    var saved = false;

    await showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      elevation: 0,
      useSafeArea: true,
      routeSettings: const RouteSettings(name: "/RecordingModal"),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 1,
        minChildSize: 1,
        snap: true,
        builder: (context, scrollController) {
          final hint = widget.prompt.subtitle?.replaceAll(r'\\n', '\n');

          return BottomRecordingModal(
            promptId: widget.prompt.id,
            question: widget.prompt.question,
            subtitle: widget.prompt.subtitle,
            hint: hint,
            limit: widget.prompt.option?.maxLength,
            suggested: widget.prompt.option?.suggestedLength,
            resumeFromPath: resumeFromPath,
            resumeElapsed: resumeElapsed,
            onSave: (value) {
              saved = true;
              unawaited(_persist(value!, deleteOldAbsolutePath: deleteOnSave));
            },
          );
        },
      ),
    );

    return saved;
  }

  Future<void> _handleTrim() async {
    if (_busy || !_canTrim || _absolutePath == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const DeletePopUp(
        title: "Trim recording?",
        subheader:
            "Audio outside the selected range will be permanently deleted.",
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);

    final originalPath = _absolutePath!;
    try {
      final totalMs = maxDuration.inMilliseconds;
      final start = Duration(milliseconds: (_trimStart * totalMs).round());
      final end = Duration(milliseconds: (_trimEnd * totalMs).round());

      final outputPath = p.join(p.dirname(originalPath), _newFileName());
      final output = await const AudioProcessor().trim(
        inputPath: originalPath,
        outputPath: outputPath,
        start: start,
        end: end,
      );

      await _persist(basePath(output.path),
          deleteOldAbsolutePath: originalPath);

      if (mounted) Navigator.pop(context);
    } catch (e, s) {
      CrashlyticsService().recordError(e, s, reason: 'Trim failed');
      if (mounted) {
        setState(() => _busy = false);
        _showErrorSnack("Couldn't trim this recording. Please try again.");
      }
    }
  }

  Future<void> _handleReplace() async {
    if (_busy || _absolutePath == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const DeletePopUp(
        title: "Replace from here?",
        subheader:
            "Everything after this point will be replaced by your new recording.",
      ),
    );
    if (confirmed != true || !mounted) return;

    final originalPath = _absolutePath!;
    final playhead = Duration(milliseconds: currentSliderPosition.round());

    setState(() => _busy = true);

    String? headPath;
    try {
      if (playhead > Duration.zero) {
        headPath = p.join(p.dirname(originalPath), _newFileName());
        await const AudioProcessor().trim(
          inputPath: originalPath,
          outputPath: headPath,
          start: Duration.zero,
          end: playhead,
        );
      }

      if (!mounted) return;
      setState(() => _busy = false);

      final saved = await _openRecordingModal(
        resumeFromPath: headPath,
        resumeElapsed: playhead,
        deleteOnSave: originalPath,
      );

      if (saved) {
        if (mounted) Navigator.pop(context);
      } else if (headPath != null) {
        await _deleteIfExists(headPath);
      }
    } catch (e, s) {
      CrashlyticsService().recordError(e, s, reason: 'Replace failed');
      if (headPath != null) await _deleteIfExists(headPath);
      if (mounted) {
        setState(() => _busy = false);
        _showErrorSnack("Couldn't replace this recording. Please try again.");
      }
    }
  }

  Future<void> _handleResume() async {
    if (_busy || _absolutePath == null) return;

    final saved = await _openRecordingModal(
      resumeFromPath: _absolutePath,
      resumeElapsed: maxDuration,
    );

    if (saved && mounted) Navigator.pop(context);
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: width,
        height: MediaQuery.of(context).size.height * .75,
        decoration: const BoxDecoration(
          color: Color(0xFFF3F3F3),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Edit Recording",
                      style: CustomTypography().titleLarge()),
                  GestureDetector(
                    onTap: _busy ? null : () => Navigator.pop(context),
                    child: Icon(
                      CupertinoIcons.clear_circled_solid,
                      size: 32,
                      color: _busy
                          ? CustomColors.textTertiaryContent
                          : CustomColors.textSecondaryContent,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (audioStatus == AudioStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!canPlay) {
      return Center(child: RecordingIssueCard(status: audioStatus));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: _peaks == null
                  ? (_waveformFailed
                      ? Text("Couldn't load waveform",
                          style: CustomTypography().bodyMedium())
                      : const CircularProgressIndicator())
                  : SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: StaticWaveform(
                        peaks: _peaks!,
                        playheadFraction: _playheadFraction,
                        trimStartFraction: _trimStart,
                        trimEndFraction: _trimEnd,
                        onSeek: (fraction) =>
                            seek(fraction * maxSliderPosition),
                        onTrimStartChanged: (fraction) => setState(() {
                          _trimStart =
                              fraction.clamp(0.0, _trimEnd - _minTrimGap);
                        }),
                        onTrimEndChanged: (fraction) => setState(() {
                          _trimEnd =
                              fraction.clamp(_trimStart + _minTrimGap, 1.0);
                        }),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${formatDuration(currentSliderPosition.toInt())} / "
            "${formatDuration(maxDuration.inMilliseconds)}",
            style: CustomTypography().bodyMedium(),
          ),
          const SizedBox(height: 12),
          IconButton(
            onPressed: _busy ? null : play,
            icon: Icon(isPlaying
                ? CupertinoIcons.pause_circle_fill
                : CupertinoIcons.play_circle_fill),
            iconSize: 44,
            color: CustomColors.productNormalActive,
          ),
          const SizedBox(height: 16),
          _actionRow(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _actionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(
          icon: CupertinoIcons.scissors,
          label: "Trim",
          enabled: _canTrim && !_busy,
          onPressed: _handleTrim,
        ),
        _actionButton(
          icon: CupertinoIcons.arrow_2_circlepath,
          label: "Replace",
          enabled: !_busy,
          onPressed: _handleReplace,
        ),
        _actionButton(
          icon: CupertinoIcons.mic,
          label: "Resume",
          enabled: !_busy,
          onPressed: _handleResume,
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    final color = enabled
        ? CustomColors.productNormalActive
        : CustomColors.textTertiaryContent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: enabled ? onPressed : null,
          icon: Icon(icon),
          color: color,
          iconSize: 28,
        ),
        Text(label, style: CustomTypography().caption(color: color)),
      ],
    );
  }
}
