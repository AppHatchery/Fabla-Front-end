import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/core/utils/recording_answer_gate.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Covers `RecordingAnswerGate` — the half of a diary page that decides whether
// its prompt still has an answer, shared by the diary flow and the edit screen.
//
// ------------------------------------------------------------------
// What is driven here
// ------------------------------------------------------------------
// The mixin needs a State to live on, so the tests below mount a bare host
// widget that supplies the three things a page owes it and records what it was
// asked to do.
//
// All three can be implemented for real, which is the point of
// `discardRecording` being one hook rather than the cubit, diary and prompt it
// takes to build that call. Asking for those meant the host could only stub
// them, so tests had to avoid the path that deletes a recording.
// ------------------------------------------------------------------

class _GateHost extends StatefulWidget {
  const _GateHost({required this.onReevaluate});

  final Future<void> Function() onReevaluate;

  @override
  State<_GateHost> createState() => _GateHostState();
}

class _GateHostState extends State<_GateHost>
    with RecordingAnswerGate<_GateHost> {
  int reevaluations = 0;
  int builds = 0;

  /// Rows the gate asked the page to delete, in order.
  final List<String> discarded = [];

  @override
  void discardRecording(String path) => discarded.add(path);

  @override
  bool get gatedPromptIsSingleAnswer => true;

  @override
  Future<void> reevaluateAnswers() {
    reevaluations++;
    return widget.onReevaluate();
  }

  @override
  Widget build(BuildContext context) {
    builds++;
    return const SizedBox.shrink();
  }
}

void main() {
  Future<_GateHostState> pumpHost(
    WidgetTester tester, {
    required Future<void> Function() onReevaluate,
  }) async {
    await tester.pumpWidget(_GateHost(onReevaluate: onReevaluate));
    return tester.state<_GateHostState>(find.byType(_GateHost));
  }

  group('re-running the gate', () {
    testWidgets('a card verdict rebuilds the page and re-runs the gate',
        (tester) async {
      final state = await pumpHost(tester, onReevaluate: () async {});
      final buildsBefore = state.builds;

      state.onPlaybackResolved('audios/a.aac', AudioStatus.canNotPlay);
      await tester.pump();

      expect(state.reevaluations, 1);
      expect(state.builds, greaterThan(buildsBefore));
      expect(state.answers.unplayable['audios/a.aac'], AudioStatus.canNotPlay);
    });

    // Nothing changed, so nothing should happen: report() says the verdict was
    // already held, and rebuilding on it would be a rebuild per resolved card.
    testWidgets('a verdict already held does not re-run anything',
        (tester) async {
      final state = await pumpHost(tester, onReevaluate: () async {});

      state.onPlaybackResolved('audios/a.aac', AudioStatus.canNotPlay);
      await tester.pump();
      final buildsAfterFirst = state.builds;

      state.onPlaybackResolved('audios/a.aac', AudioStatus.canNotPlay);
      await tester.pump();

      expect(state.reevaluations, 1);
      expect(state.builds, buildsAfterFirst);
    });

    // The gate is fired and not awaited, and the sweep behind it touches every
    // recording on the prompt. On a device with a full or unmounted volume that
    // throws, and an escaping error would be logged as a *fatal*.
    //
    // There is no "did not crash" assertion: an uncaught async error fails a
    // testWidgets case by itself, so this passing IS the check.
    testWidgets('a gate that throws is reported, not left to become a crash',
        (tester) async {
      final state = await pumpHost(
        tester,
        onReevaluate: () async => throw StateError('the volume is gone'),
      );

      state.onPlaybackResolved('audios/a.aac', AudioStatus.canNotPlay);
      await tester.pump();

      expect(state.reevaluations, 1, reason: 'the gate was still attempted');
      expect(state.answers.unplayable['audios/a.aac'], AudioStatus.canNotPlay,
          reason: 'and the notice it was told about survives the failure');
    });

    // A throw leaves the page on whatever it had decided before, rather than
    // half-applying. The next verdict runs the gate again on state nothing
    // has quietly changed.
    testWidgets('a gate that throws can still be re-run', (tester) async {
      var shouldThrow = true;
      final state = await pumpHost(
        tester,
        onReevaluate: () async {
          if (shouldThrow) throw StateError('the volume is gone');
        },
      );

      state.onPlaybackResolved('audios/a.aac', AudioStatus.canNotPlay);
      await tester.pump();

      shouldThrow = false;
      state.onPlaybackResolved('audios/b.aac', AudioStatus.canNotPlay);
      await tester.pump();

      expect(state.reevaluations, 2);
      expect(state.answers.unplayable, hasLength(2));
    });
  });

  // ------------------------------------------------------------------
  // Deleting a row
  // ------------------------------------------------------------------
  //
  // The path that destroys a participant's recording. It could not be reached
  // from here while the mixin demanded a cubit, a diary and a prompt.
  // ------------------------------------------------------------------
  group('deleting a row', () {
    testWidgets('a dismissal deletes the row and re-runs the gate',
        (tester) async {
      final state = await pumpHost(tester, onReevaluate: () async {});

      // The status report() refuses to delete on: a decoder's word is not
      // enough, so nothing is gone until the participant says so.
      state.onPlaybackResolved('audios/a.aac', AudioStatus.canNotPlay);
      await tester.pump();
      expect(state.discarded, isEmpty);

      state.onDismissRecording('audios/a.aac');
      await tester.pump();

      expect(state.discarded, ['audios/a.aac']);
      expect(state.answers.unplayable, isEmpty,
          reason: 'the explanation goes with the row');
      expect(state.answers.isUsable('audios/a.aac'), isFalse,
          reason: 'and it must not count while the cubit catches up');
      expect(state.reevaluations, 2,
          reason: 'it can be the last row on the prompt');
    });

    // The file being missing is proof enough on its own, so this one deletes
    // without being asked.
    testWidgets('a verdict the checker acts on deletes without a dismissal',
        (tester) async {
      final state = await pumpHost(tester, onReevaluate: () async {});

      state.onPlaybackResolved('audios/a.aac', AudioStatus.fileNotFound);
      await tester.pump();

      expect(state.discarded, ['audios/a.aac']);
    });

    testWidgets('dismissing twice deletes once', (tester) async {
      final state = await pumpHost(tester, onReevaluate: () async {});

      state.onDismissRecording('audios/a.aac');
      state.onDismissRecording('audios/a.aac');
      await tester.pump();

      expect(state.discarded, ['audios/a.aac']);
    });
  });
}
