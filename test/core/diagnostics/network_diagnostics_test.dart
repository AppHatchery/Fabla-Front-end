import 'dart:async';
import 'dart:io';

import 'package:audio_diaries_flutter/core/diagnostics/debug_trace.dart';
import 'package:audio_diaries_flutter/core/diagnostics/network_diagnostics.dart';
import 'package:audio_diaries_flutter/services/developer_mode_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSecureSocket extends Mock implements SecureSocket {}

class MockCertificate extends Mock implements X509Certificate {}

class MockNetworkInterface extends Mock implements NetworkInterface {}

NetworkInterface fakeInterface(String name, List<InternetAddress> addresses) {
  final interface = MockNetworkInterface();
  when(() => interface.name).thenReturn(name);
  when(() => interface.addresses).thenReturn(addresses);
  return interface;
}

SecureSocket fakeSocket({String issuer = 'CN=Amazon RSA 2048 M02'}) {
  final certificate = MockCertificate();
  when(() => certificate.issuer).thenReturn(issuer);
  final socket = MockSecureSocket();
  when(() => socket.peerCertificate).thenReturn(certificate);
  when(() => socket.destroy()).thenReturn(null);
  return socket;
}

NetworkDiagnostics diagnostics({
  List<ConnectivityResult> connectivity = const [ConnectivityResult.wifi],
  Future<List<InternetAddress>> Function(String host)? lookup,
  Future<SecureSocket> Function(String host, Duration timeout)? connect,
  List<NetworkInterface> interfaces = const [],
}) =>
    NetworkDiagnostics(
      connectivity: () async => connectivity,
      lookup: lookup ?? (_) async => [InternetAddress('52.1.2.3')],
      secureConnect: connect ?? (_, __) async => fakeSocket(),
      interfaces: () async => interfaces,
    );

void main() {
  group('NetworkDiagnostics', () {
    test('a healthy host reports DNS and TLS success with the issuer',
        () async {
      final snapshot = await diagnostics().collect(['api.example.com']);

      final data = snapshot.toTraceData();
      expect(data['connection'], 'wifi');
      expect(data['possible_vpn'], 'no');
      expect(data['api.example.com dns'], matches(r'^ok \d+ms, 1 address$'));
      expect(data['api.example.com tls'],
          matches(r'^ok \d+ms, issuer: CN=Amazon RSA 2048 M02$'));
    });

    test('a DNS failure is reported and TLS is skipped', () async {
      var connected = false;
      final snapshot = await diagnostics(
        lookup: (_) async => throw const SocketException('Failed host lookup',
            osError: OSError('nodename nor servname provided', 8)),
        connect: (_, __) async {
          connected = true;
          return fakeSocket();
        },
      ).collect(['api.example.com']);

      final probe = snapshot.hosts.single;
      expect(probe.dnsSummary,
          contains('Failed host lookup (nodename nor servname provided)'));
      expect(probe.tlsSummary, 'skipped (DNS failed)');
      expect(connected, isFalse);
    });

    test('a TLS handshake failure is reported', () async {
      final snapshot = await diagnostics(
        connect: (_, __) async =>
            throw const HandshakeException('CERTIFICATE_VERIFY_FAILED'),
      ).collect(['api.example.com']);

      expect(snapshot.hosts.single.tlsSummary,
          contains('TLS handshake: CERTIFICATE_VERIFY_FAILED'));
    });

    test('a hanging host times out instead of blocking', () async {
      final snapshot = await diagnostics(
        connect: (_, __) => Completer<SecureSocket>().future,
      ).collect(['slow.example.com'],
          timeout: const Duration(milliseconds: 50));

      expect(snapshot.hosts.single.tlsSummary, contains('timed out'));
    });

    test('hosts are probed once each, in parallel', () async {
      final looked = <String>[];
      final snapshot = await diagnostics(lookup: (host) async {
        looked.add(host);
        return [InternetAddress('52.1.2.3')];
      }).collect(['a.example.com', 'b.example.com', 'a.example.com']);

      expect(looked..sort(), ['a.example.com', 'b.example.com']);
      expect(snapshot.hosts, hasLength(2));
    });

    test('cellular with an OS-reported VPN is flagged', () async {
      final snapshot = await diagnostics(connectivity: [
        ConnectivityResult.mobile,
        ConnectivityResult.vpn,
      ]).collect([]);

      final data = snapshot.toTraceData();
      expect(data['connection'], 'mobile, vpn');
      expect(data['possible_vpn'], 'yes (OS reports VPN)');
    });

    test('a tunnel interface with a routable IPv4 address suggests a VPN',
        () async {
      final snapshot = await diagnostics(interfaces: [
        fakeInterface('en0', [InternetAddress('192.168.1.20')]),
        fakeInterface('utun4', [InternetAddress('10.8.0.2')]),
      ]).collect([]);

      expect(snapshot.toTraceData()['possible_vpn'], 'yes (utun4)');
    });

    test('idle iOS utun interfaces with only link-local IPv6 are ignored',
        () async {
      final snapshot = await diagnostics(interfaces: [
        fakeInterface('utun0', [InternetAddress('fe80::1')]),
        fakeInterface('utun1', [InternetAddress('fe80::2')]),
      ]).collect([]);

      expect(snapshot.possibleVpn, isFalse);
    });
  });

  group('traceNetworkSnapshot', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await DeveloperModeService().load();
    });

    test('does nothing outside developer mode', () async {
      var asked = false;
      final trace = DebugTrace('test');

      await trace.run(() => traceNetworkSnapshot(() async {
            asked = true;
            return ['api.example.com'];
          }, diagnostics: diagnostics()));

      expect(asked, isFalse);
      expect(trace.events, isEmpty);
    });

    test('does nothing outside a trace', () async {
      await DeveloperModeService().enable();
      addTearDown(DeveloperModeService().disable);
      var asked = false;

      await traceNetworkSnapshot(() async {
        asked = true;
        return ['api.example.com'];
      }, diagnostics: diagnostics());

      expect(asked, isFalse);
    });

    test('records a network step in developer mode, skipping empty hosts',
        () async {
      await DeveloperModeService().enable();
      addTearDown(DeveloperModeService().disable);
      final trace = DebugTrace('test');

      await trace.run(() => traceNetworkSnapshot(
          () async => ['api.example.com', null, ''],
          diagnostics: diagnostics()));

      final event = trace.events.single;
      expect(event.step, 'network');
      expect(event.data.keys,
          containsAll(['connection', 'possible_vpn', 'api.example.com dns']));
      expect(event.data.keys.where((k) => k.endsWith(' dns')), hasLength(1));
    });
  });
}
