// The app update dialog: each of the four scenes loads in AppUpdateFabio (preloaded first), walks in and upgrades
// (state available), goes on into a loop, and plays Update Now and Maybe later from the controller and from the
// example dialog's buttons, with no error; with reduced motion every state shows its still pose; a scene that cannot
// load shows the fallback.
import 'dart:convert';
import 'dart:io';

import 'package:alive/alive.dart';
import 'package:audio_diaries_flutter/alive/app_update/app_update_fabio.dart'; // where the widget was copied
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// [child] on a phone of 440 x 956 pt, the phone's reduced motion setting as given.
Future<void> pumpPage(WidgetTester tester, Widget child, {bool reduceMotion = false}) async {
  const size = Size(440, 956);
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(size: size).copyWith(disableAnimations: reduceMotion),
      child: Scaffold(body: SafeArea(child: child)),
    ),
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


/// Pumps (with real async time for the asset isolate) until the scene has loaded, at most 10 s of real time.
Future<AliveController> ready(WidgetTester tester, AppUpdateFabioController c) async {
  final until = DateTime.now().add(const Duration(seconds: 10));
  while ((c.alive == null || c.alive!.status.value == AliveStatus.loading) && DateTime.now().isBefore(until)) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await settle(tester, seconds: .1);
  return c.alive!;
}

void main() {
  tearDown(() => AliveCache.shared.releasePreloads());

  for (final scene in AppUpdateFabio.scenes) {
    testWidgets('$scene: preloaded, walks in and upgrades, loops, then Update Now', (tester) async {
      final missing = await tester.runAsync(() => AppUpdateFabio.preload(scene));
      expect(missing, isEmpty, reason: '$scene: $missing');
      final c = AppUpdateFabioController(), errors = <Object>[];
      await pumpPage(tester, AppUpdateFabio(scene: scene, controller: c, onError: errors.add));
      final a = await ready(tester, c);
      expect(a.status.value, AliveStatus.ready, reason: '$scene: ${a.error}');
      expect(a.appState, 'available');
      expect(a.clip, 'enter');
      expect(tester.getSize(find.byType(AppUpdateFabio)).height, AppUpdateFabio.height);
      await settle(tester, seconds: 3.7); // the walk in and the upgrade take 3.3 s
      expect(['loopA', 'loopB'], contains(a.clip));
      final loop = a.clip;
      await settle(tester, seconds: 4.3); // a loop goes round and carries on
      expect(a.clip, loop);
      c.onUpdateNow();
      await settle(tester, seconds: .2);
      expect(a.appState, 'now');
      expect(a.clip, 'now');
      await settle(tester, seconds: 1.0); // under a second
      expect(errors, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$scene: Maybe later from the example dialog', (tester) async {
      var later = 0;
      await pumpPage(tester, Center(child: AppUpdateDialogExample(scene: scene, onLater: () => later++)));
      final c = (tester.state(find.byType(AppUpdateFabio)) as State<AppUpdateFabio>).widget.controller!;
      final a = await ready(tester, c);
      expect(a.status.value, AliveStatus.ready, reason: '$scene: ${a.error}');
      await settle(tester, seconds: 1.0); // he is walking in when the choice comes
      await tester.tap(find.text('Maybe later'));
      await settle(tester, seconds: .2);
      expect(later, 1);
      expect(a.appState, 'later');
      expect(a.clip, 'later');
      await settle(tester, seconds: 2.6); // the goodbye, then he rests
      expect(a.clip, 'later');
      expect(tester.takeException(), isNull);
    });

    testWidgets('$scene: Yes, Update Now from the example dialog', (tester) async {
      var now = 0;
      await pumpPage(tester, Center(child: AppUpdateDialogExample(scene: scene, onUpdateNow: () => now++)));
      final c = (tester.state(find.byType(AppUpdateFabio)) as State<AppUpdateFabio>).widget.controller!;
      final a = await ready(tester, c);
      await settle(tester, seconds: 4.0);
      await tester.tap(find.text('Yes, Update Now'));
      await settle(tester, seconds: .1);
      expect(now, 1); // the store opens in the same tap
      expect(a.clip, 'now');
      await settle(tester, seconds: 1.0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$scene: reduced motion shows the still of every state', (tester) async {
      final c = AppUpdateFabioController();
      await pumpPage(tester, AppUpdateFabio(scene: scene, controller: c), reduceMotion: true);
      final a = await ready(tester, c);
      expect(a.status.value, AliveStatus.ready, reason: '$scene: ${a.error}');
      await settle(tester, seconds: .3);
      expect(a.reducedMotion, isTrue);
      c.onUpdateNow();
      await settle(tester, seconds: .3);
      expect(a.appState, 'now');
      c.onLater();
      await settle(tester, seconds: .3);
      expect(a.appState, 'later');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a scene that cannot load: the fallback shows (the logo), the buttons still work', (tester) async {
    final c = AppUpdateFabioController(), errors = <Object>[];
    await pumpPage(tester, AppUpdateFabio(scene: 'au-missing', controller: c, onError: errors.add, fallback: (_) => const Text('logo')));
    final until = DateTime.now().add(const Duration(seconds: 10));
    while ((c.alive == null || c.alive!.status.value == AliveStatus.loading) && DateTime.now().isBefore(until)) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await settle(tester, seconds: .2);
    expect(c.alive!.status.value, AliveStatus.failed);
    expect(errors, isNotEmpty);
    expect(find.text('logo'), findsOneWidget);
    c.onUpdateNow(); // the dialog's buttons call these whatever happened to the scene
    c.onLater();
    await settle(tester, seconds: .2);
    expect(find.text('logo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('every scene: the dialog\'s states, the two loops as one pool, each clip with its still', () {
    for (final scene in AppUpdateFabio.scenes) {
      final s = jsonDecode(File('assets/alive/$scene/scene.json').readAsStringSync()) as Map<String, dynamic>;
      expect(s['size'], [AppUpdateFabio.designWidth, AppUpdateFabio.height], reason: scene);
      expect(s['initial'], {'state': 'available'}, reason: scene);
      expect(s['states'], {
        'available': {'enter': 'enter', 'idle': 'loop'},
        'now': {'enter': 'now'},
        'later': {'enter': 'later'},
      }, reason: scene);
      expect(s['pools'], {'loop': ['loopA', 'loopB']}, reason: scene);
      final clips = s['clips'] as Map<String, dynamic>;
      expect(clips.keys.toSet(), {'enter', 'loopA', 'loopB', 'now', 'later'}, reason: scene);
      expect(clips['loopA']['loop'], isTrue);
      expect(clips['loopB']['loop'], isTrue);
      expect(clips['now']['duration'], lessThanOrEqualTo(1000), reason: '$scene: Update Now is under a second');
      for (final c in clips.values) {
        expect(c['still'], isA<num>(), reason: '$scene: every clip has its reduced motion still');
      }
    }
  });
}
