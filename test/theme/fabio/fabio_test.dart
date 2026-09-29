import 'dart:io';

import 'package:audio_diaries_flutter/theme/fabio/fabio.dart';
import 'package:audio_diaries_flutter/theme/fabio/fabio_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Tests for the procedural Fabio mascot in lib/theme/fabio/.
//
// Fabio Studio (the web dashboard that authors choreographies) runs a JS
// port of the same engine, so a few tests pin down numbers the two must
// agree on, such as the seeded random sequence.

const _size = Size(390, 844);

FabioScript _script(List<Map<String, dynamic>> clips,
        {Map<String, dynamic>? start}) =>
    FabioScript.fromJson({
      'version': 1,
      'name': 'Test',
      'start': start ?? {'x': 0.5, 'y': 0.5},
      'props': {
        'taco': {'kind': 'glyph', 'text': '🌮'},
        'kite': {'paths': [{'d': 'M12 2 22 12 12 22 2 12Z'}]},
      },
      'clips': clips,
    });

void main() {
  group('FabioRandom', () {
    test('matches the Fabio Studio sequence for the same seed', () {
      final r = FabioRandom(7);
      expect(r.next(), closeTo(0.011704753153, 1e-9));
      expect(r.next(), closeTo(0.061958257575, 1e-9));
      expect(r.next(), closeTo(0.976907632779, 1e-9));
    });
  });

  group('FabioScript', () {
    test('every bundled preset parses without dropping clips', () {
      final dir = Directory('assets/fabio/scripts');
      final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'));
      expect(files, isNotEmpty);
      for (final f in files) {
        final source = f.readAsStringSync();
        final script = FabioScript.parse(source);
        final raw = RegExp(r'"track"').allMatches(source).length;
        final parsed = script.motion.length +
            script.face.length +
            script.actions.length +
            script.looks.length +
            script.fx.length +
            script.speech.length +
            script.events.length;
        expect(parsed, raw, reason: '${f.path} has clips the app does not understand');
        expect(script.duration, greaterThan(1), reason: f.path);
      }
    });

    test('ignores unknown tracks and names instead of failing', () {
      final s = _script([
        {'track': 'face', 't': 0, 'expression': 'not_a_face'},
        {'track': 'action', 't': 0, 'gesture': 'moonwalk'},
        {'track': 'lasers', 't': 0},
        {'track': 'face', 't': 100, 'expression': 'happy'},
      ]);
      expect(s.face.single.expression, FabioExpression.happy);
      expect(s.actions, isEmpty);
    });

    test('converts milliseconds to seconds and sorts clips', () {
      final s = _script([
        {'track': 'action', 't': 1500, 'gesture': 'wave'},
        {'track': 'action', 't': 200, 'gesture': 'bounce'},
      ]);
      expect(s.actions.map((a) => a.t), [0.2, 1.5]);
      expect(s.duration, closeTo(1.5 + FabioGesture.wave.duration + 0.4, 1e-9));
    });
  });

  group('custom props', () {
    test('parseSvgPath handles relative, implicit and arc commands', () {
      final square = parseSvgPath('M2 2h10v10h-10z').getBounds();
      expect(square, const Rect.fromLTRB(2, 2, 12, 12));
      final implicit = parseSvgPath('M0 0 10 0 10 5').getBounds();
      expect(implicit, const Rect.fromLTRB(0, 0, 10, 5));
      final circle = parseSvgPath('M2 12a10 10 0 1 0 20 0a10 10 0 1 0-20 0Z').getBounds();
      expect(circle.left, closeTo(2, 0.01));
      expect(circle.right, closeTo(22, 0.01));
      expect(circle.top, closeTo(2, 0.01));
      expect(circle.bottom, closeTo(22, 0.01));
      final compact = parseSvgPath('M1.5.5l2-1.5e1').getBounds();
      expect(compact.top, closeTo(-14.5, 1e-9));
    });

    test('parseSvgPath keeps what it read before malformed data', () {
      final b = parseSvgPath('M0 0L10 10L oops 30 30').getBounds();
      expect(b, const Rect.fromLTRB(0, 0, 10, 10));
    });

    test('parseSvgColor reads CSS hex order', () {
      expect(parseSvgColor('#f00'), const Color(0xFFFF0000));
      expect(parseSvgColor('#11223380'), const Color(0x80112233));
      expect(parseSvgColor('currentColor'), isNull);
      expect(parseSvgColor('none'), isNull);
    });

    test('scripts can define and use vector and glyph props', () {
      final s = FabioScript.fromJson({
        'props': {
          'kite': {
            'kind': 'vector',
            'paths': [{'d': 'M12 2 22 12 12 22 2 12Z', 'fill': 'currentColor'}],
            'physics': 'flutter',
            'color': '#FF6F91',
          },
          'taco': {'kind': 'glyph', 'text': '🌮', 'physics': 'fall'},
          'star': {'kind': 'glyph', 'text': 'x'},
          'empty': {'kind': 'vector', 'paths': []},
        },
        'clips': [
          {'track': 'fx', 't': 0, 'prop': 'kite'},
          {'track': 'fx', 't': 0, 'prop': 'taco'},
          {'track': 'fx', 't': 0, 'prop': 'star'},
          {'track': 'fx', 't': 0, 'prop': 'empty'},
        ],
      });
      expect(s.customProps.keys, ['kite', 'taco']);
      final kite = s.customProps['kite']!.physics;
      expect([kite.gravity, kite.drag, kite.spin, kite.sway],
          [FabioPropPhysics.flutter.gravity, FabioPropPhysics.flutter.drag, FabioPropPhysics.flutter.spin, FabioPropPhysics.flutter.sway]);
      expect(s.customProps['taco']!.isGlyph, isTrue);
      // `star` stays the built-in; `empty` draws nothing so its clip is dropped.
      expect(s.fx.map((c) => c.custom?.name ?? c.prop!.name), ['kite', 'taco', 'star']);
    });

    test('physics overrides apply on top of the preset', () {
      final p = FabioCustomProp.fromJson('x', {'text': 'a', 'physics': 'fall', 'gravity': -10})!;
      expect(p.physics.gravity, -10);
      expect(p.physics.spin, FabioPropPhysics.fall.spin);
    });
  });

  group('FabioTimeline', () {
    test('a fly clip ends exactly on its last path point', () {
      final s = _script([
        {
          'track': 'motion', 'type': 'fly', 't': 0, 'd': 1000,
          'path': [[0.2, 0.2], [0.8, 0.3]],
        },
      ]);
      final tl = FabioTimeline(s, _size);
      final end = tl.motionAt(1).position;
      expect(end.dx, closeTo(0.8 * 390, 0.01));
      expect(end.dy, closeTo(0.3 * 844, 0.01));
      expect(tl.motionAt(-1).position, const Offset(195, 422));
    });

    test('motion clips chain from where the previous one ended', () {
      final s = _script([
        {'track': 'motion', 'type': 'fly', 't': 0, 'd': 500, 'path': [[0.1, 0.1]]},
        {'track': 'motion', 'type': 'hold', 't': 600, 'd': 500},
      ]);
      final tl = FabioTimeline(s, _size);
      expect(tl.motionAt(0.55).position.dx, closeTo(39, 0.01));
      expect(tl.motionAt(0.9).position.dx, closeTo(39, 0.01));
    });

    test('teleport hides Fabio mid-way and adds smoke puffs', () {
      final s = _script([
        {'track': 'motion', 'type': 'teleport', 't': 0, 'd': 1000, 'to': [0.9, 0.2]},
      ]);
      final tl = FabioTimeline(s, _size);
      expect(tl.motionAt(0.5).alpha, 0);
      expect(tl.motionAt(1).alpha, closeTo(1, 1e-9));
      expect(tl.derivedFx.map((f) => f.prop), [FabioProp.puff, FabioProp.puff]);
    });

    test('timed expressions fall back to the last held one', () {
      final s = _script([
        {'track': 'face', 't': 0, 'expression': 'happy'},
        {'track': 'face', 't': 1000, 'd': 500, 'expression': 'surprised'},
      ], start: {'expression': 'sad'});
      final tl = FabioTimeline(s, _size);
      expect(tl.expressionAt(0.5), FabioExpression.happy);
      expect(tl.expressionAt(1.2), FabioExpression.surprised);
      expect(tl.expressionAt(2), FabioExpression.happy);
    });
  });

  group('FabioSim', () {
    test('every gesture plays out and leaves a finite, settled pose', () {
      final sim = FabioSim();
      for (final g in FabioGesture.values) {
        sim.play(g);
        for (var i = 0; i < (g.duration * 60).ceil() + 30; i++) {
          sim.update(1 / 60);
          final p = sim.pose;
          for (final v in [p.rotation, p.offsetX, p.offsetY, p.stretch, p.scale, p.lookX]) {
            expect(v.isFinite, isTrue, reason: '${g.name} produced a non-finite pose');
          }
        }
        expect(sim.isGesturing, isFalse, reason: g.name);
        expect(sim.pose.scale, 1);
        expect(sim.pose.armLeft + sim.pose.armRight, 0, reason: g.name);
      }
    });

    test('moving right leans into the motion and turns the face', () {
      final sim = FabioSim()..face(-1);
      sim.pose.facing = -1;
      sim.velocity = const Offset(4, 0);
      for (var i = 0; i < 60; i++) {
        sim.update(1 / 60);
      }
      expect(sim.pose.facing, greaterThan(0.9));
      expect(sim.pose.dragX, greaterThan(0.5));
    });

    test('flashExpression reverts to the resting expression', () {
      final sim = FabioSim(expression: FabioExpression.sad);
      sim.flashExpression(FabioExpression.joyful, 0.5);
      expect(sim.currentExpression, FabioExpression.joyful);
      for (var i = 0; i < 40; i++) {
        sim.update(1 / 60);
      }
      expect(sim.currentExpression, FabioExpression.sad);
    });
  });

  group('widgets', () {
    testWidgets('Fabio reacts to taps without throwing', (tester) async {
      final controller = FabioController();
      await tester.pumpWidget(MaterialApp(
        home: Center(child: Fabio(size: 120, controller: controller)),
      ));
      await tester.tap(find.byType(Fabio));
      await tester.pump(const Duration(milliseconds: 16));
      expect(controller.sim.isGesturing, isTrue);
      for (var i = 0; i < 120; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(controller.sim.isGesturing, isFalse);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });

    testWidgets('FabioStage plays a script, fires events and finishes', (tester) async {
      final events = <String>[];
      var finished = false;
      final script = _script([
        {'track': 'motion', 'type': 'fly', 't': 0, 'd': 400, 'path': [[1.3, 0.2]]},
        {'track': 'fx', 't': 0, 'prop': 'sparkle', 'count': 4},
        {'track': 'fx', 't': 0, 'prop': 'taco', 'count': 3},
        {'track': 'fx', 't': 0, 'prop': 'kite', 'count': 3},
        {'track': 'speech', 't': 0, 'd': 300, 'text': 'Hi!'},
        {'track': 'event', 't': 200, 'name': 'ping'},
      ]);
      await tester.pumpWidget(MaterialApp(
        home: FabioStage(
          script: script,
          onEvent: events.add,
          onFinished: () => finished = true,
        ),
      ));
      for (var i = 0; i < 300 && !finished; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(events, ['ping']);
      expect(finished, isTrue);
    });
  });
}
