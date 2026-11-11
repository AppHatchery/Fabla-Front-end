// The example dialog (AppUpdateDialogExample: the dev team's dialog of 3 Nov, their words, buttons and sizes) with
// Fabio where their art was: their copy; Fabio at their Fabio's size (AppUpdateFabio.dialogScale, the band 136 x 110 / 83
// pt tall); Yes, Update Now plays the payoff and calls onUpdateNow in the same tap; Maybe later plays the goodbye, then
// the same dialog turns into the reminder with Fabio still there, resting in the goodbye's last pose (the same scene, no
// new walk in), and its X calls onClose; after a choice the buttons take no more taps.
import 'package:alive/alive.dart';
import 'package:audio_diaries_flutter/alive/app_update/app_update_fabio.dart'; // where the widget was copied
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// [child] on a phone of 440 x 956 pt.
Future<void> pumpPage(WidgetTester tester, Widget child) async {
  const size = Size(440, 956);
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(data: const MediaQueryData(size: size), child: Scaffold(body: SafeArea(child: child))),
  ));
}

/// Lets real async work finish (scene files decode in an isolate), then pumps [seconds] of 30 fps frames, giving real
/// async time every few frames.
Future<void> settle(WidgetTester tester, {double seconds = 1}) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
  for (var i = 0; i < (seconds * 30).round(); i++) {
    if (i % 6 == 5) await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 33));
  }
}

/// Pumps (with real async time for the asset isolate) until his scene has left loading, at most 10 s of real time.
Future<AliveController?> loaded(WidgetTester tester) async {
  final until = DateTime.now().add(const Duration(seconds: 10));
  AliveController? a() => find.byType(AppUpdateFabio).evaluate().isEmpty
      ? null
      : tester.widget<AppUpdateFabio>(find.byType(AppUpdateFabio)).controller?.alive;
  while ((a() == null || a()!.status.value == AliveStatus.loading) && DateTime.now().isBefore(until)) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await settle(tester, seconds: .1);
  return a();
}

void main() {
  tearDown(() => AliveCache.shared.releasePreloads());

  for (final scene in AppUpdateFabio.scenes) {
    testWidgets('$scene: their copy, Fabio at their size; Yes, Update Now plays the payoff and opens the store at once',
        (tester) async {
      var store = 0;
      await pumpPage(tester, AppUpdateDialogExample(scene: scene, onUpdateNow: () => store++));
      final a = await loaded(tester);
      expect(a?.status.value, AliveStatus.ready, reason: '$scene: ${a?.error}');
      for (final t in [
        AppUpdateDialogExample.title,
        AppUpdateDialogExample.updateNow,
        AppUpdateDialogExample.later,
        AppUpdateDialogExample.doNotShow,
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(tester.widget<AppUpdateFabio>(find.byType(AppUpdateFabio)).scale, AppUpdateFabio.dialogScale);
      expect(tester.getSize(find.byType(AppUpdateFabio)).height, closeTo(AppUpdateFabio.height * AppUpdateFabio.dialogScale, .5),
          reason: 'the band is 136 x 110 / 83 pt tall');
      await settle(tester, seconds: 4.2); // the walk in and the upgrade, then the loop
      expect(['loopA', 'loopB'], contains(a!.clip));
      await tester.tap(find.text(AppUpdateDialogExample.updateNow));
      await settle(tester, seconds: .5);
      expect(store, 1, reason: 'the store opens in the same tap');
      expect(a.clip, 'now');
      await tester.tap(find.text(AppUpdateDialogExample.later), warnIfMissed: false);
      await settle(tester, seconds: .3);
      expect(a.clip, 'now', reason: 'after a choice the buttons take no more taps');
      expect(find.text(AppUpdateDialogExample.stillTitle), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$scene: Maybe later plays the goodbye, then the reminder with him resting; its X closes', (tester) async {
      var later = 0, closed = 0;
      await pumpPage(tester, AppUpdateDialogExample(scene: scene, onLater: () => later++, onClose: () => closed++));
      final b = await loaded(tester);
      expect(b?.status.value, AliveStatus.ready, reason: '$scene: ${b?.error}');
      await settle(tester, seconds: 1.0); // during the walk in
      await tester.tap(find.text(AppUpdateDialogExample.later));
      await settle(tester, seconds: 1.5);
      expect(later, 1);
      expect(b!.clip, 'later');
      expect(find.text(AppUpdateDialogExample.stillTitle), findsNothing, reason: 'the goodbye first');
      await settle(tester, seconds: 2.5); // the goodbye (at most 2.5 s), then the reminder
      expect(find.text(AppUpdateDialogExample.stillTitle), findsOneWidget);
      expect(find.text(AppUpdateDialogExample.stillBody), findsOneWidget);
      expect(find.text(AppUpdateDialogExample.title), findsNothing);
      expect(tester.widget<AppUpdateFabio>(find.byType(AppUpdateFabio)).controller?.alive, same(b),
          reason: 'the same scene, no new walk in');
      expect(b.clip, 'later', reason: 'he rests in the goodbye\'s last pose');
      await tester.tap(find.byIcon(Icons.close));
      await settle(tester, seconds: .3);
      expect(closed, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
