import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../screens/diary/domain/entities/recording.dart';
import '../utils/statuses.dart';

/// Decides which of a prompt's recordings can actually serve as an answer, and
/// clears the ones that cannot.
///
/// Shared by the diary flow and the edit screen because they must agree. The
/// incident this guards against was caused by two layers deciding "is this an
/// answer" independently and diverging on files that exist but will not
/// decode, which let a participant submit a diary whose audio was never
/// uploaded.
///
/// A recording is unusable when its file is absent, empty, or reported
/// undecodable by the card that tried to load it. Any of those would fail S3
/// upload or arrive as silence, so the row is discarded and the participant is
/// asked to record again.
class RecordingAnswerChecker {
  RecordingAnswerChecker({required this.discard});

  /// Removes the recording row at the given path.
  final void Function(String path) discard;

  /// Recordings known to be unusable, keyed by path.
  ///
  /// Exposed so the prompt can explain what happened. Treat as read-only —
  /// mutate through [report] and [countUsable] so discards stay paired with
  /// the status that caused them.
  final Map<String, AudioStatus> unplayable = {};

  /// Records a card's verdict for [path].
  ///
  /// Returns whether anything changed, so the caller can skip a rebuild and a
  /// re-evaluation when it did not.
  bool report(String path, AudioStatus status) {
    if (status == AudioStatus.available) {
      // A working recording supersedes every outstanding explanation. Clearing
      // by path alone would not do: a replacement is saved under a new
      // filename, so the discarded recording's notice would never be matched
      // and would sit on screen next to the new answer.
      if (unplayable.isEmpty) return false;

      unplayable.clear();
      return true;
    }

    if (unplayable[path] == status) return false;

    unplayable[path] = status;
    discard(path);
    return true;
  }

  /// Counts the recordings that can serve as an answer, discarding any whose
  /// file is missing or empty along the way.
  ///
  /// The sweep matters for prompts no card ever rendered — a resumed diary, or
  /// an optional prompt that never gates navigation. O(n) stat calls.
  Future<int> countUsable(List<Recording> recordings) async {
    if (recordings.isEmpty) return 0;

    final dir = await getApplicationDocumentsDirectory();

    var usable = 0;
    for (final recording in recordings) {
      // Already known bad; it has been discarded once already.
      if (unplayable.containsKey(recording.path)) continue;

      final file = File(p.join(dir.path, recording.path));
      final exists = await file.exists();

      if (exists && await file.length() > 0) {
        usable++;
        continue;
      }

      report(
        recording.path,
        exists ? AudioStatus.noAudioLength : AudioStatus.fileNotFound,
      );
    }
    return usable;
  }
}
