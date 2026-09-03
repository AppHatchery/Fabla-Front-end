import 'dart:math';

import 'package:audio_diaries_flutter/core/background/upload_execution_lock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

void main() {
  late MockSharedPreferencesAsync preferences;
  String? storedValue;

  setUp(() {
    preferences = MockSharedPreferencesAsync();
    storedValue = null;

    when(() => preferences.getString(any()))
        .thenAnswer((_) async => storedValue);
    when(() => preferences.setString(any(), any()))
        .thenAnswer((invocation) async {
      storedValue = invocation.positionalArguments[1] as String;
    });
    when(() => preferences.remove(any())).thenAnswer((_) async {
      storedValue = null;
    });
  });

  test('blocks a second upload until the owner releases the lock', () async {
    final now = DateTime(2026, 8, 19, 10);
    final first = UploadExecutionLock(
      preferences: preferences,
      now: () => now,
      random: Random(1),
    );
    final second = UploadExecutionLock(
      preferences: preferences,
      now: () => now,
      random: Random(2),
    );

    final firstToken = await first.acquire();

    expect(firstToken, isNotNull);
    expect(await second.acquire(), isNull);

    await first.release(firstToken!);
    expect(await second.acquire(), isNotNull);
  });

  test('allows recovery after a lock expires', () async {
    var now = DateTime(2026, 8, 19, 10);
    final lock = UploadExecutionLock(
      preferences: preferences,
      now: () => now,
      random: Random(1),
    );

    expect(await lock.acquire(), isNotNull);

    now = now.add(const Duration(minutes: 16));
    expect(await lock.acquire(), isNotNull);
  });
}
