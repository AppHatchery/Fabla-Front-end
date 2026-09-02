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
/// undecodable by the card that tried to load it. None of them can serve as an
/// answer, so none of them count towards the gate — but only the first two get
/// the row deleted. See [_deletable].
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

  /// Paths present on the previous [countUsable] sweep.
  ///
  /// A usable recording missing from this set is new — the participant has
  /// re-recorded — which is what retires the outstanding notices. Siblings
  /// that were healthy all along are in the set, so they cannot.
  Set<String>? _previousSweep;

  /// Statuses that prove the file cannot be uploaded, and so justify deleting
  /// the row.
  ///
  /// [AudioStatus.canNotPlay] is deliberately absent. It means a decoder
  /// declined the file, which can be transient — a first `getDuration()` on a
  /// perfectly good AAC comes back null on some devices — and [discard] is
  /// irreversible: it deletes the audio and its row. A file that exists and
  /// holds bytes still uploads, so it is kept rather than destroyed on a
  /// player's word. It is still never counted as an answer, so the gate stays
  /// shut until a recording that does play replaces it.
  static const _deletable = {
    AudioStatus.fileNotFound,
    AudioStatus.noAudioLength,
  };

  /// Records a card's verdict for [path].
  ///
  /// Returns whether anything changed, so the caller can skip a rebuild and a
  /// re-evaluation when it did not.
  bool report(String path, AudioStatus status) {
    if (status == AudioStatus.available) {
      // This recording's own notice only. Clearing every notice let a healthy
      // sibling on a multiple-answer prompt erase the explanation for a
      // different recording that had been discarded, so that answer
      // disappeared from the list with nothing on screen to say why —
      // whichever card happened to resolve last decided it. Retiring notices
      // once a replacement arrives is countUsable()'s job instead.
      return unplayable.remove(path) != null;
    }

    if (unplayable[path] == status) return false;

    unplayable[path] = status;
    if (_deletable.contains(status)) discard(path);
    return true;
  }

  /// Counts the recordings that can serve as an answer, discarding any whose
  /// file is missing or empty along the way.
  ///
  /// The sweep matters for prompts no card ever rendered — a resumed diary, or
  /// an optional prompt that never gates navigation. O(n) stat calls.
  Future<int> countUsable(List<Recording> recordings) async {
    final previous = _previousSweep;
    _previousSweep = {for (final recording in recordings) recording.path};

    if (recordings.isEmpty) return 0;

    final dir = await getApplicationDocumentsDirectory();

    var usable = 0;
    // Iterated over a copy: [discard] removes the row it is told about, and
    // the list handed in is the live `Answer.recordings` relation, so walking
    // it directly throws ConcurrentModificationError the moment a recording
    // turns out to be unusable — the one case this sweep exists for.
    for (final recording in List.of(recordings)) {
      // Already known bad; it has been discarded once already.
      if (unplayable.containsKey(recording.path)) continue;

      final file = File(p.join(dir.path, recording.path));
      final exists = await file.exists();

      if (exists && await file.length() > 0) {
        usable++;

        // Absent last sweep, so this is the replacement the notices were
        // asking for: they have served their purpose and must not sit on
        // screen beside the new answer. On the first sweep there is nothing
        // to compare against, and nothing has been discarded yet either.
        if (previous != null && !previous.contains(recording.path)) {
          unplayable.clear();
        }

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
