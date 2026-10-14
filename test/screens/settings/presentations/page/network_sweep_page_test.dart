import 'package:audio_diaries_flutter/core/usecases/network_sweep.dart';
import 'package:audio_diaries_flutter/screens/settings/presentation/pages/network_sweep_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns a canned report and records how it was called.
class FakeNetworkSweep extends NetworkSweep {
  bool? measuredThroughput;

  @override
  Future<Map<String, dynamic>> run({
    Duration timeout = const Duration(seconds: 5),
    bool measureThroughput = true,
    int throughputBytes = 1000000,
    int latencySamples = 5,
  }) async {
    measuredThroughput = measureThroughput;
    return {
      'connection': {
        'types': ['wifi']
      },
      'throughput': measureThroughput ? {'download': {}} : {'skipped': true},
    };
  }
}

void main() {
  late FakeNetworkSweep sweep;
  String? clipboard;

  setUp(() {
    sweep = FakeNetworkSweep();
    clipboard = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
  });

  Future<void> pumpPage(WidgetTester tester) {
    // Phone-sized, so the run button is on screen.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(home: NetworkSweepPage(sweep: sweep)),
    ));
  }

  testWidgets('runs the sweep and shows the report as JSON', (tester) async {
    await pumpPage(tester);
    expect(find.byKey(const Key('network_sweep_result')), findsNothing);

    await tester.tap(find.byKey(const Key('run_network_sweep')));
    await tester.pumpAndSettle();

    expect(sweep.measuredThroughput, isTrue);
    final result = tester
        .widget<SelectableText>(find.byKey(const Key('network_sweep_result')));
    expect(result.data, contains('"types": [\n      "wifi"'));
    expect(find.text('Run again'), findsOneWidget);
  });

  testWidgets('the speed test can be switched off', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('network_sweep_throughput_switch')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('run_network_sweep')));
    await tester.pumpAndSettle();

    expect(sweep.measuredThroughput, isFalse);
    expect(find.textContaining('"skipped": true'), findsOneWidget);
  });

  testWidgets('copy puts the JSON on the clipboard', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const Key('run_network_sweep')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('copy_network_sweep')));
    await tester.pumpAndSettle();

    expect(clipboard, contains('"connection"'));
    expect(find.text('Network sweep copied to clipboard'), findsOneWidget);
  });

  testWidgets('shows the headline facts above the JSON', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byKey(const Key('run_network_sweep')));
    await tester.pumpAndSettle();

    final facts = find.byKey(const Key('network_sweep_facts'));
    expect(facts, findsOneWidget);
    expect(find.descendant(of: facts, matching: find.text('wifi')),
        findsOneWidget);
    expect(
        tester.getTopLeft(facts).dy,
        lessThan(tester
            .getTopLeft(find.byKey(const Key('network_sweep_result')))
            .dy));
  });

  group('sweepFacts', () {
    Map<String, dynamic> report({
      bool internet = true,
      bool captivePortal = false,
      String consistency = 'match',
      bool hostReachable = true,
      bool vpn = false,
      List<String> tunnels = const [],
    }) =>
        {
          'app_hosts': ['api.example.com'],
          'connection': {
            'types': ['wifi', if (vpn) 'vpn'],
            'internet_access': internet,
            'vpn': {'os_reports_vpn': vpn, 'tunnel_interfaces': tunnels},
            'ipv6_available': false,
          },
          'captive_portal': {'likely_captive_portal': captivePortal},
          'dns': {
            'consistency': {
              'api.example.com': consistency,
              'www.google.com': 'unresolved everywhere',
            },
          },
          'hosts': {
            'api.example.com': {
              'https': hostReachable
                  ? {'status': 200, 'ms': 90}
                  : {'error': 'timed out', 'ms': 5000},
            },
          },
          'latency': {'avg_ms': 41.4, 'jitter_ms': 5.5},
          'throughput': {
            'download': {'mbps': 5.02},
            'upload': {'mbps': 3.63},
          },
        };

    Map<String, SweepFact> byLabel(Map<String, dynamic> report) =>
        {for (final f in sweepFacts(report)) f.label: f};

    test('a healthy report has no failing facts', () {
      final facts = byLabel(report());

      expect(facts.values.where((f) => f.ok == false), isEmpty);
      expect(facts['Connection']!.value, 'wifi');
      expect(facts['DNS']!.value, 'OK');
      expect(facts['Our servers']!.value, '1/1 reachable');
      expect(facts['Latency']!.value, '41.4 ms avg, 5.5 ms jitter');
      expect(facts['Speed']!.value, '↓ 5.02 Mbps · ↑ 3.63 Mbps');
    });

    test('DNS only judges our hosts, not the reference hosts', () {
      final facts =
          byLabel(report(consistency: 'system DNS failed but DoH resolved it'));

      expect(facts['DNS']!.ok, isFalse);
      expect(facts['DNS']!.value,
          'api.example.com: system DNS failed but DoH resolved it');
    });

    test('flags no internet, a captive portal and unreachable servers', () {
      final facts = byLabel(
          report(internet: false, captivePortal: true, hostReachable: false));

      expect(facts['Internet']!.ok, isFalse);
      expect(facts['Captive portal']!.value, 'Detected');
      expect(facts['Our servers']!.value, '0/1 reachable');
    });

    test('notes a VPN on the connection line once', () {
      expect(
          byLabel(report(vpn: true, tunnels: ['utun3']))['Connection']!.value,
          'wifi, vpn');
      expect(byLabel(report(tunnels: ['utun3']))['Connection']!.value,
          'wifi · VPN tunnel');
    });

    test('a report of errors still produces facts', () {
      final facts = byLabel({
        'connection': {'error': 'plugin missing'},
        'throughput': {'skipped': true},
      });

      expect(facts['Connection']!.value, 'unknown');
      expect(facts['Internet']!.value, 'No');
      expect(facts.containsKey('Speed'), isFalse);
    });
  });
}
