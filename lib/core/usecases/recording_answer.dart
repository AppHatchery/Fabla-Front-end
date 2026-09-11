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
  RecordingAnswerChecker({
    required this.discard,
    required this.singleAnswer,
  });

  /// Removes the recording row at the given path.
  final void Function(String path) discard;

  /// Whether this prompt accepts exactly one answer.
  ///
  /// Decides when a notice for a deleted row can come down. One slot means any
  /// usable recording is the replacement the notice asked for. With several
  /// slots there is no such link — a re-recording is saved under a new
  /// filename, so nothing says which lost take it replaces — and guessing is
  /// what let one healthy recording erase another's explanation.
  final bool singleAnswer;

  /// Recordings known to be unusable, keyed by path.
  ///
  /// Exposed so the prompt can explain what happened. Treat as read-only —
  /// mutate through [report] and [countUsable] so discards stay paired with
  /// the status that caused them.
  ///
  /// These are the notices, not a record of what was deleted — entries leave
  /// once the explanation has been read. See [_discarded].
  final Map<String, AudioStatus> unplayable = {};

  /// Paths already handed to [discard].
  ///
  /// Separate from [unplayable] because it has to last longer: a notice comes
  /// down once the participant has an answer again, but "this row is gone"
  /// stays true. Sharing one set let a retired notice trigger a second
  /// [discard] of a row that no longer exists.
  final Set<String> _discarded = {};

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
    if (_deletable.contains(status) && _discarded.add(path)) discard(path);
    return true;
  }

  /// Whether anything known disqualifies [path] as an answer.
  ///
  /// The single definition of "this recording counts", and the reason this
  /// class exists: the incident in the class doc came from two layers deciding
  /// it independently. Both halves matter — a notice means a card found the
  /// file unusable, and [_discarded] means the row has been deleted, which
  /// outlives the notice. A caller that checks only [unplayable] treats a
  /// deleted row it has not been rebuilt without yet as a perfectly good
  /// answer.
  ///
  /// `true` is the absence of a verdict, not proof the file is good —
  /// [countUsable] still stats it.
  bool isUsable(String path) =>
      !unplayable.containsKey(path) && !_discarded.contains(path);

  /// Takes down the notice for [path] at the participant's request, deleting
  /// the row behind it if one is still there.
  ///
  /// The deletion is the point. An [AudioStatus.canNotPlay] row is kept by
  /// [report] precisely because a decoder's verdict can be wrong, so it sits
  /// in the answer list unplayable, uncountable, and — since the card shows a
  /// notice in place of its controls — with no delete button of its own. This
  /// is the way out. The difference from [report] is who decided: a player's
  /// word is not enough to destroy audio, a participant's is.
  ///
  /// Idempotent, and safe for a notice whose row [report] already discarded:
  /// that one just loses the notice.
  void dismiss(String path) {
    unplayable.remove(path);

    // The same guard report() relies on, and the reason this cannot delete a
    // row twice.
    if (_discarded.add(path)) discard(path);
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
    // Iterated over a copy: [discard] removes the row it is told about, and
    // the list handed in is the live `Answer.recordings` relation, so walking
    // it directly throws ConcurrentModificationError the moment a recording
    // turns out to be unusable — the one case this sweep exists for.
    for (final recording in List.of(recordings)) {
      // Already handled: either still carrying a notice, or a row deleted once
      // already that must not be deleted again.
      if (!isUsable(recording.path)) continue;

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

    if (usable > 0) _retireDiscardedNotices();

    return usable;
  }

  /// Takes down the notices for rows [discard] deleted, once the prompt has a
  /// usable answer again. Single-answer prompts only — see [singleAnswer].
  ///
  /// Only the deleted ones. An [AudioStatus.canNotPlay] row is still in
  /// `answer.recordings`, so dropping its key would hand it back as a playable
  /// answer and let it open the gate — the exact thing this class exists to
  /// prevent.
  void _retireDiscardedNotices() {
    if (!singleAnswer) return;

    unplayable.removeWhere((_, status) => _deletable.contains(status));
  }
}
