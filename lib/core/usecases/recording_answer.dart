import 'dart:collection';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../screens/diary/domain/entities/recording.dart';
import '../utils/statuses.dart';

class UsableAnswerCount {
  const UsableAnswerCount(this.usable) : checked = true;

  /// A sweep that could not read the disk at all.
  ///
  /// [usable] is 0 because nothing was proved either way, so the gate stays
  /// shut. That is the safe direction.
  const UsableAnswerCount.unchecked()
      : usable = 0,
        checked = false;

  final int usable;

  final bool checked;
}

abstract interface class RecordingAnswerView {
  bool isUsable(String path);

  Map<String, AudioStatus> get unplayable;
}

/// Decides which of a prompt's recordings can serve as an answer, and clears
/// the ones that cannot.
///
/// Shared by the diary flow and the edit screen so they always agree. They used
/// to decide separately and disagreed about files that exist but will not play,
/// which let a diary be submitted with audio that was never uploaded.
class RecordingAnswerChecker implements RecordingAnswerView {
  RecordingAnswerChecker({
    required this.discard,
    required this.singleAnswer,
    this.onError,
  });

  /// Removes the recording row at the given path.
  final void Function(String path) discard;

  final void Function(Object error, StackTrace stackTrace, String reason)?
      onError;

  final bool singleAnswer;

  final Map<String, AudioStatus> _unplayable = {};

  @override
  Map<String, AudioStatus> get unplayable => UnmodifiableMapView(_unplayable);

  final Set<String> _discarded = {};

  static const _deletable = {
    AudioStatus.fileNotFound,
    AudioStatus.noAudioLength,
  };

  void _report(Object error, StackTrace stackTrace, String reason) {
    try {
      onError?.call(error, stackTrace, reason);
    } catch (_) {}
  }

  bool report(String path, AudioStatus status) {
    if (status == AudioStatus.available) {
      return _unplayable.remove(path) != null;
    }

    final changed = _unplayable[path] != status;

    _unplayable[path] = status;

    if (_deletable.contains(status) && !_discarded.contains(path)) {
      try {
        discard(path);
        _discarded.add(path);
      } catch (e, s) {
        _report(e, s, 'Discarding an unusable recording failed');
      }
    }

    return changed;
  }

  @override
  bool isUsable(String path) =>
      !_unplayable.containsKey(path) && !_discarded.contains(path);

  /// Clears the notice for [path] because the participant asked, deleting the
  /// row behind it if one is still there.
  void dismiss(String path) {
    _unplayable.remove(path);

    if (!_discarded.contains(path)) {
      try {
        discard(path);
        _discarded.add(path);
      } catch (e, s) {
        _report(e, s, 'Dismissing a recording failed');
      }
    }
  }

  /// Counts the recordings that can serve as an answer, deleting any whose file
  /// is missing or empty as it goes.
  Future<UsableAnswerCount> countUsable(List<Recording> recordings) async {
    if (recordings.isEmpty) return const UsableAnswerCount(0);

    final Directory dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (e, s) {
      _report(e, s, 'Locating the documents directory failed');

      // Nothing was checked, so nothing is claimed. The caller is told which
      // kind of zero this is, so it can explain itself instead of quietly
      // disabling its button.
      return const UsableAnswerCount.unchecked();
    }

    var usable = 0;

    for (final recording in List.of(recordings)) {
      if (_discarded.contains(recording.path)) continue;

      final file = File(p.join(dir.path, recording.path));

      try {
        final exists = await file.exists();

        if (!(exists && await file.length() > 0)) {
          report(
            recording.path,
            exists ? AudioStatus.noAudioLength : AudioStatus.fileNotFound,
          );
          continue;
        }

        if (isUsable(recording.path)) usable++;
      } catch (e, s) {
        _report(e, s, 'Checking a recording on disk failed');
        continue;
      }
    }

    if (usable > 0) _retireDiscardedNotices();

    return UsableAnswerCount(usable);
  }

  void _retireDiscardedNotices() {
    if (!singleAnswer) return;

    _unplayable.removeWhere(
      (path, status) =>
          _deletable.contains(status) && _discarded.contains(path),
    );
  }
}
