import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../services/developer_mode_service.dart';
import 'debug_trace.dart';

/// Adds a network snapshot of the hosts from [hosts] to the current
/// [DebugTrace]. Only runs in developer mode: traces are not yet kept or sent
/// for participants, so the probes would cost them time and data for nothing.
Future<void> traceNetworkSnapshot(
  Future<Iterable<String?>> Function() hosts, {
  NetworkDiagnostics? diagnostics,
}) async {
  final trace = DebugTrace.current;
  if (trace == null || !DeveloperModeService().isEnabled) return;
  try {
    final names =
        (await hosts()).whereType<String>().where((h) => h.isNotEmpty);
    final snapshot = await (diagnostics ?? NetworkDiagnostics()).collect(names);
    trace.step('network',
        message: 'Network snapshot', data: snapshot.toTraceData());
  } catch (e) {
    trace.step('network', message: 'Network snapshot failed: $e');
  }
}

/// Adds DNS / TLS results for a single [host] to the current [DebugTrace],
/// in developer mode only. For hosts only known mid-submission (S3).
Future<void> traceHostProbe(
  String host, {
  required String step,
  NetworkDiagnostics? diagnostics,
}) async {
  final trace = DebugTrace.current;
  if (trace == null || !DeveloperModeService().isEnabled || host.isEmpty) {
    return;
  }
  final probe = await (diagnostics ?? NetworkDiagnostics()).probeHost(host);
  trace.step(step, message: 'Host check', data: {
    '$host dns': probe.dnsSummary,
    '$host tls': probe.tlsSummary,
  });
}

/// DNS and TLS results for one host.
class HostProbe {
  final String host;
  final Duration? dnsTime;
  final int addressCount;
  final String? dnsError;

  /// TCP connect + TLS handshake time; a proxy for round-trip latency.
  final Duration? tlsTime;
  final String? certificateIssuer;
  final String? tlsError;

  const HostProbe({
    required this.host,
    this.dnsTime,
    this.addressCount = 0,
    this.dnsError,
    this.tlsTime,
    this.certificateIssuer,
    this.tlsError,
  });

  String get dnsSummary => dnsError != null
      ? 'FAILED ${dnsTime?.inMilliseconds ?? '?'}ms: $dnsError'
      : 'ok ${dnsTime!.inMilliseconds}ms, $addressCount '
          '${addressCount == 1 ? 'address' : 'addresses'}';

  String get tlsSummary {
    if (tlsError != null) {
      return 'FAILED ${tlsTime?.inMilliseconds ?? '?'}ms: $tlsError';
    }
    if (tlsTime == null) return 'skipped (DNS failed)';
    return 'ok ${tlsTime!.inMilliseconds}ms'
        '${certificateIssuer != null ? ', issuer: $certificateIssuer' : ''}';
  }
}

/// A picture of the device's network at one moment.
class NetworkSnapshot {
  final List<String> connectionTypes;
  final List<String> vpnInterfaces;
  final bool connectivityReportsVpn;
  final List<HostProbe> hosts;

  const NetworkSnapshot({
    required this.connectionTypes,
    required this.vpnInterfaces,
    required this.connectivityReportsVpn,
    required this.hosts,
  });

  bool get possibleVpn => connectivityReportsVpn || vpnInterfaces.isNotEmpty;

  /// Flattened for [DebugTrace] event data.
  Map<String, String> toTraceData() => {
        'connection':
            connectionTypes.isEmpty ? 'unknown' : connectionTypes.join(', '),
        'possible_vpn': possibleVpn
            ? 'yes (${[
                if (connectivityReportsVpn) 'OS reports VPN',
                ...vpnInterfaces,
              ].join(', ')})'
            : 'no',
        for (final probe in hosts) ...{
          '${probe.host} dns': probe.dnsSummary,
          '${probe.host} tls': probe.tlsSummary,
        },
      };
}

/// Collects connection type, VPN hints, and DNS / TLS results per host so a
/// failed submission shows what the network looked like.
///
/// Records hosts, timings and certificate issuers only — never the device's
/// own IP addresses.
class NetworkDiagnostics {
  /// Interfaces that usually mean a VPN tunnel. iOS keeps idle `utun`
  /// interfaces for system services, so only ones with a routable IPv4
  /// address count.
  static final RegExp _tunnelInterface =
      RegExp(r'^(tun|tap|ppp|ipsec|utun|wg)\d*', caseSensitive: false);

  final Future<List<ConnectivityResult>> Function() _connectivity;
  final Future<List<InternetAddress>> Function(String host) _lookup;
  final Future<SecureSocket> Function(String host, Duration timeout)
      _secureConnect;
  final Future<List<NetworkInterface>> Function() _interfaces;

  NetworkDiagnostics({
    Future<List<ConnectivityResult>> Function()? connectivity,
    Future<List<InternetAddress>> Function(String host)? lookup,
    Future<SecureSocket> Function(String host, Duration timeout)? secureConnect,
    Future<List<NetworkInterface>> Function()? interfaces,
  })  : _connectivity =
            connectivity ?? (() => Connectivity().checkConnectivity()),
        _lookup = lookup ?? InternetAddress.lookup,
        _secureConnect = secureConnect ??
            ((host, timeout) =>
                SecureSocket.connect(host, 443, timeout: timeout)),
        _interfaces = interfaces ?? NetworkInterface.list;

  /// Probes [hosts] in parallel; each check gives up after [timeout].
  Future<NetworkSnapshot> collect(
    Iterable<String> hosts, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final results = await Future.wait([
      _connectionTypes(timeout),
      _vpnInterfaces(),
      Future.wait(hosts.toSet().map((h) => probeHost(h, timeout: timeout))),
    ]);
    final types = results[0] as List<String>;
    return NetworkSnapshot(
      connectionTypes: types,
      connectivityReportsVpn: types.contains(ConnectivityResult.vpn.name),
      vpnInterfaces: results[1] as List<String>,
      hosts: results[2] as List<HostProbe>,
    );
  }

  /// Resolves [host] and opens a TLS connection to it on port 443.
  Future<HostProbe> probeHost(String host,
      {Duration timeout = const Duration(seconds: 5)}) async {
    final dnsWatch = Stopwatch()..start();
    final List<InternetAddress> addresses;
    try {
      addresses = await _lookup(host).timeout(timeout);
    } catch (e) {
      return HostProbe(
          host: host, dnsTime: dnsWatch.elapsed, dnsError: _describe(e));
    }
    final dnsTime = dnsWatch.elapsed;

    final tlsWatch = Stopwatch()..start();
    try {
      final socket = await _secureConnect(host, timeout).timeout(timeout);
      final tlsTime = tlsWatch.elapsed;
      final issuer = socket.peerCertificate?.issuer;
      socket.destroy();
      return HostProbe(
        host: host,
        dnsTime: dnsTime,
        addressCount: addresses.length,
        tlsTime: tlsTime,
        certificateIssuer: issuer,
      );
    } catch (e) {
      return HostProbe(
        host: host,
        dnsTime: dnsTime,
        addressCount: addresses.length,
        tlsTime: tlsWatch.elapsed,
        tlsError: _describe(e),
      );
    }
  }

  Future<List<String>> _connectionTypes(Duration timeout) async {
    try {
      final results = await _connectivity().timeout(timeout);
      return results.map((r) => r.name).toList();
    } catch (e) {
      return ['unknown (${_describe(e)})'];
    }
  }

  Future<List<String>> _vpnInterfaces() async {
    try {
      final interfaces = await _interfaces();
      return interfaces
          .where((i) =>
              _tunnelInterface.hasMatch(i.name) &&
              i.addresses.any(
                  (a) => a.type == InternetAddressType.IPv4 && !a.isLinkLocal))
          .map((i) => i.name)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String _describe(Object error) => switch (error) {
        TimeoutException() => 'timed out',
        HandshakeException(:final message) => 'TLS handshake: $message',
        SocketException(:final message, :final osError) =>
          osError != null ? '$message (${osError.message})' : message,
        _ => '${error.runtimeType}: $error',
      };
}
