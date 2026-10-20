import 'dart:convert';
import 'dart:io';

import 'package:audio_diaries_flutter/core/diagnostics/network_diagnostics.dart';
import 'package:audio_diaries_flutter/core/usecases/network_sweep.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

class MockSocket extends Mock implements Socket {}

class MockSecureSocket extends Mock implements SecureSocket {}

class MockNetworkInterface extends Mock implements NetworkInterface {}

NetworkInterface fakeInterface(String name, List<InternetAddress> addresses) {
  final interface = MockNetworkInterface();
  when(() => interface.name).thenReturn(name);
  when(() => interface.addresses).thenReturn(addresses);
  return interface;
}

/// Answers the captive portal checks, DoH and HTTPS like a healthy network
/// unless overridden.
http.Response defaultResponse(http.Request request,
    {List<String> dohAnswer = const ['52.1.2.3']}) {
  final url = request.url.toString();
  if (url.contains('captive.apple.com')) {
    return http.Response('<HTML>Success</HTML>', 200);
  }
  if (url.contains('generate_204')) return http.Response('', 204);
  if (url.contains('1.1.1.1') || url.contains('8.8.8.8')) {
    return http.Response(
        jsonEncode({
          'Status': 0,
          'Answer': [
            for (final ip in dohAnswer) {'type': 1, 'data': ip}
          ],
        }),
        200);
  }
  return http.Response('', 200, headers: {'server': 'test'});
}

NetworkSweep sweep({
  http.Response Function(http.Request)? respond,
  Future<List<InternetAddress>> Function(String host)? lookup,
  List<NetworkInterface>? interfaces,
  List<ConnectivityResult> connectivity = const [ConnectivityResult.wifi],
}) {
  final systemLookup =
      lookup ?? (String _) async => [InternetAddress('52.1.2.3')];
  return NetworkSweep(
    appHosts: () async => ['api.example.com', null, ''],
    httpClient: () =>
        MockClient((request) async => (respond ?? defaultResponse)(request)),
    connectivity: () async => connectivity,
    hasInternet: () async => true,
    lookup: systemLookup,
    interfaces: () async =>
        interfaces ??
        [
          fakeInterface('en0', [InternetAddress('192.168.1.20')])
        ],
    connect: (host, port, timeout) async {
      final socket = MockSocket();
      when(() => socket.destroy()).thenReturn(null);
      return socket;
    },
    diagnostics: NetworkDiagnostics(
      connectivity: () async => connectivity,
      lookup: systemLookup,
      secureConnect: (_, __) async {
        final socket = MockSecureSocket();
        when(() => socket.peerCertificate).thenReturn(null);
        when(() => socket.destroy()).thenReturn(null);
        return socket;
      },
      interfaces: () async => [],
    ),
  );
}

Future<Map<String, dynamic>> run(NetworkSweep sweep) => sweep.run(
      measureThroughput: false,
      latencySamples: 2,
      timeout: const Duration(milliseconds: 300),
    );

void main() {
  group('NetworkSweep', () {
    test('a healthy network reports every section', () async {
      final result = await run(sweep());

      expect(result['app_hosts'], ['api.example.com']);
      expect(result['connection']['types'], ['wifi']);
      expect(result['connection']['internet_access'], true);
      expect(result['connection']['ipv4_available'], true);
      expect(result['connection']['vpn']['tunnel_interfaces'], isEmpty);
      expect(result['captive_portal']['likely_captive_portal'], false);
      expect(result['dns']['system']['api.example.com']['ipv4'], ['52.1.2.3']);
      expect(result['dns']['doh']['cloudflare']['api.example.com']['ipv4'],
          ['52.1.2.3']);
      expect(result['dns']['consistency']['api.example.com'], 'match');
      expect(result['reachability_by_ip']['1.1.1.1:443']['ok'], true);
      expect(result['hosts']['api.example.com']['dns'], startsWith('ok'));
      expect(result['hosts']['api.example.com']['https']['status'], 200);
      expect(result['latency']['failures'], 0);
      expect(result['throughput'], {'skipped': true});
    });

    test('never includes the device\'s own addresses', () async {
      final result = await run(sweep());

      expect(jsonEncode(result), isNot(contains('192.168.1.20')));
      expect(result['connection']['interfaces'][0]['ipv4'], ['private']);
    });

    test('flags a captive portal when the check page is replaced', () async {
      final result = await run(sweep(respond: (request) {
        if (request.url.host == 'captive.apple.com') {
          return http.Response('<html>Log in to Wi-Fi</html>', 200);
        }
        return defaultResponse(request);
      }));

      expect(result['captive_portal']['apple']['expected_response'], false);
      expect(result['captive_portal']['likely_captive_portal'], true);
    });

    test('reports when only the system resolver fails', () async {
      final result = await run(sweep(
          lookup: (_) async =>
              throw const SocketException('Failed host lookup')));

      expect(result['dns']['system']['api.example.com']['error'],
          contains('Failed host lookup'));
      expect(result['dns']['consistency']['api.example.com'],
          'system DNS failed but DoH resolved it');
    });

    test('flags a public host resolving to a private address', () async {
      final result =
          await run(sweep(lookup: (_) async => [InternetAddress('10.0.0.1')]));

      expect(
          result['dns']['system']['api.example.com']['private_answer'], true);
      expect(result['dns']['consistency']['api.example.com'],
          'system returned private IP');
    });

    test('spots a VPN tunnel interface', () async {
      final result = await run(sweep(
        connectivity: [ConnectivityResult.wifi, ConnectivityResult.vpn],
        interfaces: [
          fakeInterface('utun3', [InternetAddress('10.8.0.2')]),
        ],
      ));

      expect(result['connection']['vpn']['os_reports_vpn'], true);
      expect(result['connection']['vpn']['tunnel_interfaces'], ['utun3']);
    });

    test('a failing check becomes an error entry, not a thrown error',
        () async {
      final result = await run(NetworkSweep(
        appHosts: () async => throw StateError('no credentials'),
        httpClient: () => MockClient((_) async => http.Response('', 200)),
        connectivity: () async => throw StateError('plugin missing'),
        hasInternet: () async => false,
        lookup: (_) async => [InternetAddress('52.1.2.3')],
        interfaces: () async => [],
        connect: (host, port, timeout) async =>
            throw const SocketException('Connection refused'),
      ));

      expect(result['app_hosts'], {'error': contains('no credentials')});
      expect(
          result['connection']['types'], {'error': contains('plugin missing')});
      expect(result['reachability_by_ip']['8.8.8.8:443']['ok'], false);
      expect(result['latency']['failures'], 2);
    });
  });
}
