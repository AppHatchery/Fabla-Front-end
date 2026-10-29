import 'dart:async';

import 'package:audio_diaries_flutter/core/diagnostics/debug_trace.dart';
import 'package:audio_diaries_flutter/core/diagnostics/trace_watchers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late StreamController<List<ConnectivityResult>> connectivity;
  late StreamController<AppLifecycleState> lifecycle;

  setUp(() {
    connectivity = StreamController.broadcast();
    lifecycle = StreamController.broadcast();
  });

  tearDown(() async {
    await connectivity.close();
    await lifecycle.close();
  });

  Future<T> watch<T>(DebugTrace trace, Future<T> Function() body) =>
      watchDuring(trace, body,
          connectivityChanges: connectivity.stream,
          lifecycleChanges: lifecycle.stream);

  test('records connectivity changes, skipping repeats', () async {
    final trace = DebugTrace('test');

    await watch(trace, () async {
      connectivity.add([ConnectivityResult.wifi]);
      connectivity.add([ConnectivityResult.wifi]);
      connectivity.add([ConnectivityResult.none]);
      connectivity.add([ConnectivityResult.mobile]);
      await Future<void>.delayed(Duration.zero);
    });

    expect(trace.events.map((e) => e.message), [
      'Connectivity: wifi',
      'Connectivity changed: wifi → none',
      'Connectivity changed: none → mobile',
    ]);
  });

  test('records the app going to the background and back', () async {
    final trace = DebugTrace('test');

    await watch(trace, () async {
      lifecycle.add(AppLifecycleState.inactive);
      lifecycle.add(AppLifecycleState.paused);
      lifecycle.add(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
    });

    expect(trace.events.map((e) => e.message),
        ['App inactive', 'App paused', 'App resumed']);
    expect(trace.events.every((e) => e.isNote), isTrue);
  });

  test('stops listening once the body completes', () async {
    final trace = DebugTrace('test');

    await watch(trace, () async {});
    expect(connectivity.hasListener, isFalse);
    expect(lifecycle.hasListener, isFalse);
  });

  test('stops listening and rethrows when the body throws', () async {
    final trace = DebugTrace('test');

    await expectLater(
        watch(trace, () async => throw StateError('boom')), throwsStateError);
    expect(connectivity.hasListener, isFalse);
  });

  test('returns the body result', () async {
    expect(await watch(DebugTrace('test'), () async => 42), 42);
  });
}
