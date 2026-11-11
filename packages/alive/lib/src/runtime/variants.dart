// "Fresh every run": a pool picks a new variant each time it plays, never the one it played last. The last pick is
// remembered through a store the app provides (shared_preferences in the Fabla app), so it holds across sessions.
import 'dart:async';
import 'dart:math' as math;

import '../schema/errors.dart';
import '../schema/scene_def.dart';

/// Where the last pick of each pool is remembered. Implement it over shared_preferences (see the integration guide).
abstract class AliveStore {
  /// The value stored under [key], or null.
  Future<String?> read(String key);

  /// Store [value] under [key].
  Future<void> write(String key, String value);
}

/// A store that lives as long as the app process (the default).
class AliveMemoryStore implements AliveStore {
  /// An empty store.
  AliveMemoryStore();

  /// What it holds.
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;
}

/// What a run is: the diary, the day and the question. Given, the picks are reproducible (a test can replay a run);
/// without it they are random.
class AliveRunContext {
  /// A run context.
  const AliveRunContext({this.diary, this.day, this.question, this.seed = 0});

  /// Diary id.
  final String? diary;

  /// Day (any stable text, e.g. 2026-10-22).
  final String? day;

  /// Question id or index.
  final Object? question;

  /// Extra seed.
  final int seed;
}

/// FNV-1a, 32 bit, over the UTF-16 code units (the old engine's runSeed hash). Exact on every platform: on the web an
/// int is a JavaScript number, exact only to 2^53, so the multiply goes in 16-bit halves ([mul32]).
int fnv1a(String s) {
  var h = 0x811c9dc5;
  for (var i = 0; i < s.length; i++) {
    h = (h ^ s.codeUnitAt(i)) & 0xFFFFFFFF;
    h = mul32(h, 0x01000193);
  }
  return h;
}

/// The low 32 bits of [a] x [b] for 32-bit [a] and [b] (JavaScript's Math.imul, unsigned), exact on the web too: every
/// step stays under 2^34.
int mul32(int a, int b) {
  final ah = (a ~/ 65536) & 0xFFFF, al = a & 0xFFFF;
  final bh = (b ~/ 65536) & 0xFFFF, bl = b & 0xFFFF;
  return (al * bl + ((ah * bl + al * bh) & 0xFFFF) * 65536) & 0xFFFFFFFF;
}

/// [a] shifted right by [k] for a 32-bit unsigned [a], the same on the web (whose >> is signed 32-bit).
int _shr(int a, int k) => a ~/ (1 << k);

/// mulberry32, the old engine's seeded generator: a value in [0, 1). The same numbers on the VM and on the web.
class Mulberry32 {
  /// A generator seeded with [seed].
  Mulberry32(int seed) : _s = seed & 0xFFFFFFFF;
  int _s;

  /// The next value in [0, 1).
  double next() {
    _s = (_s + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _s;
    t = mul32((t ^ _shr(t, 15)) & 0xFFFFFFFF, t | 1);
    t = (t ^ ((t + mul32((t ^ _shr(t, 7)) & 0xFFFFFFFF, t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF;
    return ((t ^ _shr(t, 14)) & 0xFFFFFFFF) / 4294967296;
  }
}

/// Picks pool variants for one scene and remembers the last one per pool.
class VariantPicker {
  /// A picker for scene [scope].
  VariantPicker(this.scope, {this.store, this.run, math.Random? random, this.onError}) : _random = random ?? math.Random();

  /// The scene id (part of the store key).
  final String scope;

  /// Where last picks are remembered, if anywhere.
  final AliveStore? store;

  /// The run, for reproducible picks.
  final AliveRunContext? run;

  /// Store failures are reported here (picks keep working).
  final void Function(AliveError error)? onError;

  final math.Random _random;
  final Map<String, String?> _last = {};
  final Map<String, int> _count = {};

  /// The store key for a pool.
  String keyOf(String pool) => 'alive.last.$scope.$pool';

  /// Read the last picks of [pools] from the store (once, when the scene loads).
  Future<void> preload(Iterable<String> pools) async {
    final s = store;
    if (s == null) return;
    for (final p in pools) {
      try {
        _last[p] = await s.read(keyOf(p));
      } catch (e) {
        onError?.call(AliveStoreError('could not read the last pick of "$p"', e));
      }
    }
  }

  /// The last pick of a pool (its variant key), if known.
  String? lastOf(String pool) => _last[pool];

  /// Pick a variant of [pool]: never the last one when there is another.
  Variant pick(PoolDef pool) {
    final all = pool.variants;
    final last = _last[pool.id];
    var candidates = all.where((v) => v.key != last).toList();
    if (candidates.isEmpty) candidates = all;
    final n = (_count[pool.id] ?? 0);
    _count[pool.id] = n + 1;
    final int index;
    final r = run;
    if (candidates.length == 1) {
      index = 0;
    } else if (r != null) {
      final seed = fnv1a('$scope/${pool.id}|${r.diary ?? ''}|${r.day ?? ''}|${r.question ?? ''}|$n|${r.seed}');
      index = (Mulberry32(seed).next() * candidates.length).floor() % candidates.length;
    } else {
      index = _random.nextInt(candidates.length);
    }
    final v = candidates[index];
    _last[pool.id] = v.key;
    final s = store;
    if (s != null) {
      unawaited(s.write(keyOf(pool.id), v.key).catchError((Object e) {
        onError?.call(AliveStoreError('could not remember the pick of "${pool.id}"', e));
      }));
    }
    return v;
  }
}
