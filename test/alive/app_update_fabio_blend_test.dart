// A tap at any moment of a loop: the payoff must not jump. For every scene, both loops, five moments of each loop and
// both payoffs, Update Now or Maybe later is tapped and the move the tap and the blend add is measured: from the
// loop's last frame to the frame the tap shows (all of it), then from frame to frame through the blend and 3 frames
// past it, how much further each point moves than the payoff itself moves it (the payoff's own pose from a second
// controller playing it alongside at the same clip time). Poses are every part
// that shows, at its pivot and four points 25 pt around it, through the engine's own transforms (each part's delta
// about its pivot, up its chain of parents). It must stay at 1.5 pt a frame or less. The same taps without the blend
// are measured too, for the record: the jump from the loop's last frame to the payoff's first. A tap during the walk in
// glides over 12 frames instead (its own test).
import 'dart:math' as math;
import 'dart:typed_data';

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


Future<AliveController> ready(WidgetTester tester, AppUpdateFabioController c) async {
  final until = DateTime.now().add(const Duration(seconds: 10));
  while ((c.alive == null || c.alive!.status.value == AliveStatus.loading) && DateTime.now().isBefore(until)) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await settle(tester, seconds: .1);
  return c.alive!;
}

/// Where every part that shows is: for each layer, its pivot and four points 25 pt around it in the world, or null
/// when it does not show (its opacity with its parents' under one half).
List<List<double>?> pose(AliveController a) {
  final s = a.scene!, st = a.player!.state, n = s.layerIds.length;
  final world = List<Float64List?>.filled(n, null);
  final m = Float64List(16);
  Float64List worldOf(int i) {
    final w = world[i];
    if (w != null) return w;
    // 2D affine [a, b, c, d, e, f] of the layer's own delta, composed under its parent's
    final own = st.deltaInto(i, s.pivotX[i], s.pivotY[i], m) ? Float64List.fromList([m[0], m[1], m[4], m[5], m[12], m[13]]) : Float64List.fromList([1, 0, 0, 1, 0, 0]);
    final p = s.parent[i];
    if (p < 0) return world[i] = own;
    final q = worldOf(p);
    return world[i] = Float64List.fromList([
      q[0] * own[0] + q[2] * own[1], q[1] * own[0] + q[3] * own[1],
      q[0] * own[2] + q[2] * own[3], q[1] * own[2] + q[3] * own[3],
      q[0] * own[4] + q[2] * own[5] + q[4], q[1] * own[4] + q[3] * own[5] + q[5],
    ]);
  }

  double shown(int i) {
    var o = 1.0;
    for (var j = i; j >= 0; j = s.parent[j]) {
      o *= st.get(j, LayerProp.opacity);
    }
    return o;
  }

  return [
    for (var i = 0; i < n; i++)
      if (shown(i) < .5)
        null
      else
        () {
          final w = worldOf(i), px = s.pivotX[i], py = s.pivotY[i];
          final out = <double>[];
          for (final (dx, dy) in const [(0.0, 0.0), (-25.0, -25.0), (25.0, -25.0), (-25.0, 25.0), (25.0, 25.0)]) {
            final x = px + dx, y = py + dy;
            out..add(w[0] * x + w[2] * y + w[4])..add(w[1] * x + w[3] * y + w[5]);
          }
          return out;
        }(),
  ];
}

/// The largest distance any point of a part that shows in both moved between two poses ([moveLayer]: its layer).
int moveLayer = -1;
double move(List<List<double>?> a, List<List<double>?> b) {
  var most = 0.0;
  for (var i = 0; i < a.length; i++) {
    final p = a[i], q = b[i];
    if (p == null || q == null) continue;
    for (var k = 0; k < p.length; k += 2) {
      final m = math.sqrt(math.pow(p[k] - q[k], 2) + math.pow(p[k + 1] - q[k + 1], 2));
      if (m > most) {
        most = m;
        moveLayer = i;
      }
    }
  }
  return most;
}

/// The pose the payoff itself has at [t] seconds into it, from a second controller on the same scene that plays the
/// payoff with nothing added (the widget's own controller is never touched).
List<List<double>?> designedAt(AliveController ref, double t) {
  ref.seek(t);
  return pose(ref);
}

/// How much further any point moved between two frames than the payoff itself moves it: the blended move minus the
/// payoff's own move, for each point (a flame that flickers 18 pt a frame by design, drawn a few degrees turned while
/// its nozzle eases back, is not a jump; a part that moves where the payoff has it still is). [worstLayer] is the
/// layer of the largest.
int worstLayer = -1;
double added(List<List<double>?> b0, List<List<double>?> d0, List<List<double>?> b1, List<List<double>?> d1) {
  var most = 0.0;
  for (var i = 0; i < b0.length; i++) {
    final p = b0[i], q = d0[i], r = b1[i], t = d1[i];
    if (p == null || q == null || r == null || t == null) continue;
    for (var k = 0; k < p.length; k += 2) {
      final mb = math.sqrt(math.pow(r[k] - p[k], 2) + math.pow(r[k + 1] - p[k + 1], 2));
      final md = math.sqrt(math.pow(t[k] - q[k], 2) + math.pow(t[k + 1] - q[k + 1], 2));
      final m = math.max(0.0, mb - md);
      if (m > most) {
        most = m;
        worstLayer = i;
      }
    }
  }
  return most;
}

/// Plays [loop], waits until [at] seconds into it, taps ([now]: Update Now, else Maybe later). With the blend: the
/// largest move the tap and the blend add, from the loop's last frame to the frame the tap shows and then frame by
/// frame through the blend and 3 frames past it, beyond the payoff's own motion; also the payoff's own largest move a
/// frame over those frames. Without: the move from the loop's last frame to the payoff's first.
String worstAt = '';
Future<(double, double)> tapAt(WidgetTester tester, String scene, String loop, double at, bool now, {required bool blend}) async {
  final c = AppUpdateFabioController();
  await pumpPage(tester, AppUpdateFabio(scene: scene, controller: c, blend: blend));
  final a = await ready(tester, c);
  expect(a.status.value, AliveStatus.ready);
  a.play(loop);
  await tester.pump(const Duration(microseconds: 33333));
  while (a.clipTime < at) {
    await tester.pump(const Duration(microseconds: 33333));
  }
  expect(a.clip, loop);
  final last = pose(a);
  if (now) {
    c.onUpdateNow();
  } else {
    c.onLater();
  }
  var most = 0.0, own = 0.0;
  if (!blend) {
    most = move(last, pose(a));
  } else {
    final ref = AliveController(vsync: const TestVSync(), scene: scene);
    await tester.runAsync(() => ref.ready);
    ref.appState = now ? 'now' : 'later';
    var b = pose(a), d = designedAt(ref, a.clipTime);
    most = move(last, b); // the frame the tap shows
    worstAt = 'tap frame, ${a.scene!.layerIds[math.max(0, moveLayer)]}';
    for (var f = 1; f < 9; f++) {
      await tester.pump(const Duration(microseconds: 33333));
      final b1 = pose(a), d1 = designedAt(ref, a.clipTime);
      final m = added(b, d, b1, d1);
      if (m > most) {
        most = m;
        worstAt = '${a.scene!.layerIds[worstLayer]} frame $f';
      }
      own = math.max(own, move(d, d1));
      b = b1;
      d = d1;
    }
    ref.dispose();
  }
  expect(a.clip, now ? 'now' : 'later');
  await tester.pumpWidget(const SizedBox()); // the next tap starts on a fresh dialog
  return (most, own);
}

void main() {
  tearDown(() => AliveCache.shared.releasePreloads());

  // A tap while he is still walking in: the payoff's pose is far from his (he is near the dialog's edge), so the glide
  // takes 12 frames: no jump on the tap, his own place over the payoff's for 11 frames, then the payoff's own.
  for (final scene in AppUpdateFabio.scenes) {
    testWidgets('$scene: a tap during the walk in glides over 12 frames', (tester) async {
      final c = AppUpdateFabioController();
      await pumpPage(tester, AppUpdateFabio(scene: scene, controller: c));
      final a = await ready(tester, c);
      await settle(tester, seconds: .8); // walking in
      expect(a.clip, 'enter');
      final last = pose(a);
      c.onUpdateNow();
      expect(a.clip, 'now');
      final ref = AliveController(vsync: const TestVSync(), scene: scene);
      await tester.runAsync(() => ref.ready);
      ref.appState = 'now';
      expect(move(last, pose(a)), lessThanOrEqualTo(1.5), reason: 'the frame the tap shows is where he was');
      // how far his pose is from the payoff's own, frame by frame
      final gap = <double>[];
      for (var f = 1; f <= 13; f++) {
        await tester.pump(const Duration(microseconds: 33333));
        gap.add(move(pose(a), designedAt(ref, a.clipTime)));
      }
      ref.dispose();
      expect(gap[10], greaterThan(.05), reason: 'still gliding on frame 11 of 12: $gap');
      expect(gap[12], lessThan(.01), reason: 'the payoff\'s own pose once the glide is over: $gap');
      for (var f = 1; f < 11; f++) {
        expect(gap[f], lessThan(gap[f - 1]), reason: 'the gap closes every frame: $gap');
      }
      expect(tester.takeException(), isNull);
    });
  }
  const moments = [0.4, 1.1, 1.9, 2.6, 3.4];
  for (final scene in AppUpdateFabio.scenes) {
    for (final now in [true, false]) {
      testWidgets('$scene: ${now ? 'Update Now' : 'Maybe later'} tapped at any moment of a loop moves him 1.5 pt a frame or less', (tester) async {
        final rows = <String>[];
        var worst = 0.0, worstOff = 0.0, ownMost = 0.0;
        for (final loop in ['loopA', 'loopB']) {
          for (final at in moments) {
            final (m, own) = await tapAt(tester, scene, loop, at, now, blend: true);
            final (off, _) = await tapAt(tester, scene, loop, at, now, blend: false);
            rows.add('$loop ${at.toStringAsFixed(1)} s: ${m.toStringAsFixed(2)} pt a frame [$worstAt] (a ${off.toStringAsFixed(2)} pt jump without the blend)');
            worst = math.max(worst, m);
            worstOff = math.max(worstOff, off);
            ownMost = math.max(ownMost, own);
          }
        }
        // ignore: avoid_print
        print('$scene ${now ? 'now' : 'later'}: the tap and the blend move him ${worst.toStringAsFixed(2)} pt a frame at most '
            '(without the blend a jump of up to ${worstOff.toStringAsFixed(2)} pt; the payoff itself moves up to ${ownMost.toStringAsFixed(2)} pt a frame over the same frames)\n  ${rows.join('\n  ')}');
        expect(worst, lessThanOrEqualTo(1.5), reason: rows.join('; '));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
