import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../diagnostics/network_diagnostics.dart';
import '../network/upload.dart';

/// Runs a full sweep of the phone's internet connection and returns
/// everything it found as a JSON-friendly map.
///
/// Covers connection type and interfaces, captive portals, the system
/// resolver against public resolvers (DNS-over-HTTPS and plain UDP 53),
/// reachability by IP with no DNS involved, DNS / TLS / HTTPS for the app's
/// own hosts, latency, and optionally download / upload throughput.
///
/// Every section is caught on its own, so a failing check shows up as an
/// `error` entry and never stops the sweep. Like [NetworkDiagnostics], it
/// records hosts, timings and address kinds only, never the device's own IP
/// addresses.
class NetworkSweep {
  /// Hosts the app talks to. Defaults to [submissionHosts].
  final Future<Iterable<String?>> Function() _appHosts;
  final http.Client Function() _httpClient;
  final Future<List<ConnectivityResult>> Function() _connectivity;
  final Future<bool> Function() _hasInternet;
  final Future<List<InternetAddress>> Function(String host) _lookup;
  final Future<List<NetworkInterface>> Function() _interfaces;
  final Future<Socket> Function(Object host, int port, Duration timeout)
      _connect;
  final NetworkDiagnostics _diagnostics;

  /// Public resolvers queried directly, bypassing the phone's DNS.
  static const Map<String, String> udpResolvers = {
    'cloudflare': '1.1.1.1',
    'google': '8.8.8.8',
    'quad9': '9.9.9.9',
  };

  /// DNS-over-HTTPS endpoints, addressed by IP so they work even when the
  /// system resolver does not.
  static const Map<String, String> dohResolvers = {
    'cloudflare': 'https://1.1.1.1/dns-query',
    'google': 'https://8.8.8.8/resolve',
  };

  /// Well-known hosts resolved next to the app's, to tell "DNS is broken"
  /// apart from "our hosts are broken".
  static const List<String> referenceHosts = [
    'www.google.com',
    'www.apple.com',
    'aws.amazon.com',
  ];

  NetworkSweep({
    Future<Iterable<String?>> Function()? appHosts,
    http.Client Function()? httpClient,
    Future<List<ConnectivityResult>> Function()? connectivity,
    Future<bool> Function()? hasInternet,
    Future<List<InternetAddress>> Function(String host)? lookup,
    Future<List<NetworkInterface>> Function()? interfaces,
    Future<Socket> Function(Object host, int port, Duration timeout)? connect,
    NetworkDiagnostics? diagnostics,
  })  : _appHosts = appHosts ?? submissionHosts,
        _httpClient = httpClient ?? http.Client.new,
        _connectivity =
            connectivity ?? (() => Connectivity().checkConnectivity()),
        _hasInternet =
            hasInternet ?? (() => InternetConnection().hasInternetAccess),
        _lookup = lookup ?? InternetAddress.lookup,
        _interfaces = interfaces ??
            (() => NetworkInterface.list(
                includeLoopback: true, includeLinkLocal: true)),
        _connect = connect ??
            ((host, port, timeout) =>
                Socket.connect(host, port, timeout: timeout)),
        _diagnostics = diagnostics ?? NetworkDiagnostics();

  /// Runs the sweep. Each network check gives up after [timeout].
  ///
  /// [throughputBytes] is how much is downloaded and uploaded for the speed
  /// test; set [measureThroughput] to false to skip it and save data.
  Future<Map<String, dynamic>> run({
    Duration timeout = const Duration(seconds: 5),
    bool measureThroughput = true,
    int throughputBytes = 1000000,
    int latencySamples = 5,
  }) async {
    final started = DateTime.now();
    final watch = Stopwatch()..start();
    final client = _httpClient();
    try {
      final appHosts = await _section(() async => (await _appHosts())
          .whereType<String>()
          .where((h) => h.isNotEmpty)
          .toSet()
          .toList());
      final hosts = appHosts is List<String> ? appHosts : <String>[];

      final results = await Future.wait([
        _section(() => _connection(timeout)),
        _section(() => _captivePortal(client, timeout)),
        _section(() => _dns([...hosts, ...referenceHosts], client, timeout)),
        _section(() => _reachabilityByIp(timeout)),
        _section(() => _hosts(hosts, client, timeout)),
      ]);

      // After the parallel checks, so they don't skew the timings.
      final latency = await _section(() => _latency(
          hosts.isNotEmpty ? hosts.first : referenceHosts.first,
          latencySamples,
          timeout));
      final throughput = measureThroughput
          ? await _section(() => _throughput(client, throughputBytes))
          : {'skipped': true};

      return {
        'started_at': started.toIso8601String(),
        'duration_ms': watch.elapsedMilliseconds,
        'platform': Platform.operatingSystem,
        'os_version': Platform.operatingSystemVersion,
        'app_hosts': appHosts,
        'connection': results[0],
        'captive_portal': results[1],
        'dns': results[2],
        'reachability_by_ip': results[3],
        'hosts': results[4],
        'latency': latency,
        'throughput': throughput,
      };
    } finally {
      client.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Connection

  Future<Map<String, dynamic>> _connection(Duration timeout) async {
    final results = await Future.wait([
      _section(() async =>
          (await _connectivity().timeout(timeout)).map((r) => r.name).toList()),
      _section(() => _hasInternet().timeout(timeout * 2)),
      _section(_interfaceSummary),
    ]);
    final types = results[0];
    final interfaces = results[2];
    final interfaceList =
        interfaces is List ? interfaces.cast<Map<String, dynamic>>() : [];
    final tunnels = interfaceList
        .where((i) => i['possible_vpn'] == true)
        .map((i) => i['name'])
        .toList();

    return {
      'types': types,
      'internet_access': results[1],
      'vpn': {
        'os_reports_vpn':
            types is List && types.contains(ConnectivityResult.vpn.name),
        'tunnel_interfaces': tunnels,
      },
      'ipv4_available': interfaceList.any((i) =>
          (i['ipv4'] as List).any((k) => k == 'private' || k == 'public')),
      'ipv6_available': interfaceList
          .any((i) => (i['ipv6'] as List).any((k) => k == 'global')),
      'proxy': _proxyEnvironment(),
      'interfaces': interfaces,
    };
  }

  static final RegExp _tunnelInterface =
      RegExp(r'^(tun|tap|ppp|ipsec|utun|wg)\d*', caseSensitive: false);

  /// Interfaces with the kind of each address rather than the address.
  Future<List<Map<String, dynamic>>> _interfaceSummary() async {
    final interfaces = await _interfaces();
    return [
      for (final i in interfaces)
        {
          'name': i.name,
          'ipv4': [
            for (final a in i.addresses)
              if (a.type == InternetAddressType.IPv4) _ipv4Kind(a),
          ],
          'ipv6': [
            for (final a in i.addresses)
              if (a.type == InternetAddressType.IPv6) _ipv6Kind(a),
          ],
          'possible_vpn': _tunnelInterface.hasMatch(i.name) &&
              i.addresses.any(
                  (a) => a.type == InternetAddressType.IPv4 && !a.isLinkLocal),
        },
    ];
  }

  Map<String, String> _proxyEnvironment() {
    final env = Platform.environment;
    return {
      for (final key in const [
        'http_proxy',
        'https_proxy',
        'HTTP_PROXY',
        'HTTPS_PROXY',
        'no_proxy'
      ])
        if (env[key] != null) key: env[key]!,
    };
  }

  // ---------------------------------------------------------------------------
  // Captive portal

  /// Asks Apple's and Google's portal-check URLs for their known answers. A
  /// different answer usually means a login page (hotel / campus Wi-Fi).
  Future<Map<String, dynamic>> _captivePortal(
      http.Client client, Duration timeout) async {
    Future<Map<String, dynamic>> check(
        String url, bool Function(http.Response) expected) async {
      final watch = Stopwatch()..start();
      try {
        final response = await client.get(Uri.parse(url)).timeout(timeout);
        return {
          'status': response.statusCode,
          'ms': watch.elapsedMilliseconds,
          'expected_response': expected(response),
        };
      } catch (e) {
        return {'error': _describe(e), 'ms': watch.elapsedMilliseconds};
      }
    }

    final results = await Future.wait([
      check('http://captive.apple.com/hotspot-detect.html',
          (r) => r.statusCode == 200 && r.body.contains('Success')),
      check('http://connectivitycheck.gstatic.com/generate_204',
          (r) => r.statusCode == 204),
    ]);
    return {
      'apple': results[0],
      'google': results[1],
      'likely_captive_portal':
          results.any((r) => r['expected_response'] == false),
    };
  }

  // ---------------------------------------------------------------------------
  // DNS

  Future<Map<String, dynamic>> _dns(
      List<String> hosts, http.Client client, Duration timeout) async {
    final system = Map.fromEntries(await Future.wait(hosts.map((host) async =>
        MapEntry(host, await _section(() => _systemLookup(host, timeout))))));

    final doh = {
      for (final entry in dohResolvers.entries)
        entry.key: Map.fromEntries(await Future.wait(hosts.map((host) async =>
            MapEntry(
                host,
                await _section(
                    () => _dohLookup(client, entry.value, host, timeout)))))),
    };

    final probeHost = hosts.isNotEmpty ? hosts.first : referenceHosts.first;
    final udp = Map.fromEntries(await Future.wait(udpResolvers.entries.map(
        (entry) async => MapEntry(
            '${entry.key} (${entry.value})',
            await _section(
                () => _udpLookup(entry.value, probeHost, timeout))))));

    return {
      'system': system,
      'doh': doh,
      'udp_53': {'query': probeHost, ...udp},
      'consistency': {
        for (final host in hosts) host: _consistency(system[host], doh, host),
      },
    };
  }

  Future<Map<String, dynamic>> _systemLookup(
      String host, Duration timeout) async {
    final watch = Stopwatch()..start();
    try {
      final addresses = await _lookup(host).timeout(timeout);
      final ipv4 = addresses
          .where((a) => a.type == InternetAddressType.IPv4)
          .map((a) => a.address)
          .toList();
      final ipv6 = addresses
          .where((a) => a.type == InternetAddressType.IPv6)
          .map((a) => a.address)
          .toList();
      return {
        'ms': watch.elapsedMilliseconds,
        'ipv4': ipv4,
        'ipv6': ipv6,
        // A public host resolving to a private address points at DNS
        // hijacking or a filtering network.
        'private_answer': addresses.any((a) =>
            a.type == InternetAddressType.IPv4 && _ipv4Kind(a) != 'public'),
      };
    } catch (e) {
      return {'ms': watch.elapsedMilliseconds, 'error': _describe(e)};
    }
  }

  Future<Map<String, dynamic>> _dohLookup(http.Client client, String endpoint,
      String host, Duration timeout) async {
    final watch = Stopwatch()..start();
    try {
      final response = await client.get(
          Uri.parse(endpoint).replace(queryParameters: {
            'name': host,
            'type': 'A',
          }),
          headers: {'accept': 'application/dns-json'}).timeout(timeout);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final answers = (json['Answer'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .where((a) => a['type'] == 1)
          .map((a) => a['data'] as String)
          .toList();
      return {
        'ms': watch.elapsedMilliseconds,
        'status': response.statusCode,
        'rcode': json['Status'],
        'ipv4': answers,
      };
    } catch (e) {
      return {'ms': watch.elapsedMilliseconds, 'error': _describe(e)};
    }
  }

  /// Sends a plain DNS query for [host] to [resolver] on UDP 53. Fails when
  /// the network blocks or intercepts outside DNS.
  Future<Map<String, dynamic>> _udpLookup(
      String resolver, String host, Duration timeout) async {
    final watch = Stopwatch()..start();
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    try {
      final id = Random().nextInt(0xFFFF);
      final completer = Completer<Uint8List>();
      final subscription = socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = socket.receive();
        if (datagram == null || datagram.data.length < 12) return;
        final responseId = (datagram.data[0] << 8) | datagram.data[1];
        if (responseId == id && !completer.isCompleted) {
          completer.complete(datagram.data);
        }
      });
      socket.send(_dnsQuery(id, host), InternetAddress(resolver), 53);
      try {
        final response = await completer.future.timeout(timeout);
        return {
          'ms': watch.elapsedMilliseconds,
          ..._parseDnsResponse(response),
        };
      } finally {
        await subscription.cancel();
      }
    } catch (e) {
      return {'ms': watch.elapsedMilliseconds, 'error': _describe(e)};
    } finally {
      socket.close();
    }
  }

  static Uint8List _dnsQuery(int id, String host) {
    final bytes = BytesBuilder()
      ..add([id >> 8, id & 0xFF, 0x01, 0x00, 0, 1, 0, 0, 0, 0, 0, 0]);
    for (final label in host.split('.')) {
      final encoded = utf8.encode(label);
      bytes
        ..addByte(encoded.length)
        ..add(encoded);
    }
    bytes.add([0, 0, 1, 0, 1]); // root, type A, class IN
    return bytes.toBytes();
  }

  static const _rcodes = {
    0: 'NOERROR',
    1: 'FORMERR',
    2: 'SERVFAIL',
    3: 'NXDOMAIN',
    4: 'NOTIMP',
    5: 'REFUSED',
  };

  static Map<String, dynamic> _parseDnsResponse(Uint8List data) {
    final rcode = data[3] & 0x0F;
    final questions = (data[4] << 8) | data[5];
    final answers = (data[6] << 8) | data[7];
    var offset = 12;

    int skipName(int at) {
      while (at < data.length) {
        final length = data[at];
        if (length == 0) return at + 1;
        if (length & 0xC0 == 0xC0) return at + 2; // compression pointer
        at += length + 1;
      }
      return at;
    }

    for (var i = 0; i < questions; i++) {
      offset = skipName(offset) + 4;
    }
    final ipv4 = <String>[];
    for (var i = 0; i < answers && offset < data.length; i++) {
      offset = skipName(offset);
      if (offset + 10 > data.length) break;
      final type = (data[offset] << 8) | data[offset + 1];
      final length = (data[offset + 8] << 8) | data[offset + 9];
      offset += 10;
      if (type == 1 && length == 4 && offset + 4 <= data.length) {
        ipv4.add(data.sublist(offset, offset + 4).join('.'));
      }
      offset += length;
    }
    return {
      'rcode': _rcodes[rcode] ?? rcode,
      'answer_count': answers,
      'ipv4': ipv4,
    };
  }

  /// Compares the system resolver's IPv4 answers with the DoH resolvers'.
  /// CDNs can legitimately hand out different addresses, so a mismatch is a
  /// hint, not proof.
  static String _consistency(
      Object? system, Map<String, Map<String, Object?>> doh, String host) {
    if (system is! Map || system['error'] != null) {
      final dohWorked = doh.values.any((r) {
        final result = r[host];
        return result is Map && (result['ipv4'] as List?)?.isNotEmpty == true;
      });
      return dohWorked
          ? 'system DNS failed but DoH resolved it'
          : 'unresolved everywhere';
    }
    final systemIps = Set<String>.from(system['ipv4'] as List);
    if (system['private_answer'] == true) return 'system returned private IP';
    final dohIps = <String>{
      for (final r in doh.values)
        if (r[host] case {'ipv4': final List ips}) ...ips.cast<String>(),
    };
    if (dohIps.isEmpty) return 'DoH unavailable';
    if (systemIps.intersection(dohIps).isNotEmpty) return 'match';
    return 'different addresses (may be CDN)';
  }

  // ---------------------------------------------------------------------------
  // Reachability without DNS

  Future<Map<String, dynamic>> _reachabilityByIp(Duration timeout) async {
    const targets = {
      '1.1.1.1:443': ('1.1.1.1', 443),
      '8.8.8.8:443': ('8.8.8.8', 443),
      '1.1.1.1:53 (tcp)': ('1.1.1.1', 53),
      '[2606:4700:4700::1111]:443': ('2606:4700:4700::1111', 443),
    };
    return Map.fromEntries(await Future.wait(targets.entries.map((entry) async {
      final (host, port) = entry.value;
      return MapEntry(
          entry.key, await _tcpConnect(InternetAddress(host), port, timeout));
    })));
  }

  Future<Map<String, dynamic>> _tcpConnect(
      Object host, int port, Duration timeout) async {
    final watch = Stopwatch()..start();
    try {
      final socket = await _connect(host, port, timeout).timeout(timeout);
      final ms = watch.elapsedMilliseconds;
      socket.destroy();
      return {'ok': true, 'ms': ms};
    } catch (e) {
      return {
        'ok': false,
        'ms': watch.elapsedMilliseconds,
        'error': _describe(e)
      };
    }
  }

  // ---------------------------------------------------------------------------
  // App hosts

  Future<Map<String, dynamic>> _hosts(
      List<String> hosts, http.Client client, Duration timeout) async {
    return Map.fromEntries(await Future.wait(hosts.map((host) async {
      final results = await Future.wait([
        _section(() async {
          final probe = await _diagnostics.probeHost(host, timeout: timeout);
          return {
            'dns': probe.dnsSummary,
            'tls': probe.tlsSummary,
          };
        }),
        _section(() => _httpsRequest(client, host, timeout)),
      ]);
      return MapEntry(host, {
        ...(results[0] is Map ? results[0] as Map<String, dynamic> : {}),
        'https': results[1],
      });
    })));
  }

  /// Any HTTP status counts as reachable; only a transport error does not.
  Future<Map<String, dynamic>> _httpsRequest(
      http.Client client, String host, Duration timeout) async {
    final watch = Stopwatch()..start();
    try {
      final response = await client
          .send(http.Request('HEAD', Uri.https(host)))
          .timeout(timeout);
      await response.stream.drain<void>();
      return {
        'status': response.statusCode,
        'ms': watch.elapsedMilliseconds,
        if (response.headers['server'] != null)
          'server': response.headers['server'],
      };
    } catch (e) {
      return {'ms': watch.elapsedMilliseconds, 'error': _describe(e)};
    }
  }

  // ---------------------------------------------------------------------------
  // Latency

  /// Repeated TCP connects to [host]:443 (DNS resolved once, up front).
  Future<Map<String, dynamic>> _latency(
      String host, int samples, Duration timeout) async {
    final addresses = await _lookup(host).timeout(timeout);
    final target = addresses.first;
    final times = <int>[];
    var failures = 0;
    for (var i = 0; i < samples; i++) {
      final result = await _tcpConnect(target, 443, timeout);
      if (result['ok'] == true) {
        times.add(result['ms'] as int);
      } else {
        failures++;
      }
    }
    if (times.isEmpty) {
      return {'host': host, 'samples': samples, 'failures': failures};
    }
    final avg = times.reduce((a, b) => a + b) / times.length;
    var jitter = 0.0;
    for (var i = 1; i < times.length; i++) {
      jitter += (times[i] - times[i - 1]).abs();
    }
    if (times.length > 1) jitter /= times.length - 1;
    return {
      'host': host,
      'samples': samples,
      'failures': failures,
      'min_ms': times.reduce(min),
      'avg_ms': double.parse(avg.toStringAsFixed(1)),
      'max_ms': times.reduce(max),
      'jitter_ms': double.parse(jitter.toStringAsFixed(1)),
    };
  }

  // ---------------------------------------------------------------------------
  // Throughput

  Future<Map<String, dynamic>> _throughput(
      http.Client client, int bytes) async {
    const timeout = Duration(seconds: 30);

    final download = await _section(() async {
      final watch = Stopwatch()..start();
      final response = await client
          .send(http.Request('GET',
              Uri.parse('https://speed.cloudflare.com/__down?bytes=$bytes')))
          .timeout(timeout);
      var received = 0;
      await response.stream
          .forEach((chunk) => received += chunk.length)
          .timeout(timeout);
      return _rate(received, watch.elapsed);
    });

    final upload = await _section(() async {
      final watch = Stopwatch()..start();
      final response = await client
          .post(Uri.parse('https://speed.cloudflare.com/__up'),
              body: Uint8List(bytes))
          .timeout(timeout);
      return {'status': response.statusCode, ..._rate(bytes, watch.elapsed)};
    });

    return {'download': download, 'upload': upload};
  }

  static Map<String, dynamic> _rate(int bytes, Duration elapsed) => {
        'bytes': bytes,
        'ms': elapsed.inMilliseconds,
        'mbps': elapsed.inMicroseconds == 0
            ? null
            : double.parse(
                (bytes * 8 / elapsed.inMicroseconds).toStringAsFixed(2)),
      };

  // ---------------------------------------------------------------------------
  // Helpers

  /// Runs [check], turning a throw into an `error` entry.
  static Future<Object?> _section(Future<Object?> Function() check) async {
    try {
      return await check();
    } catch (e) {
      return {'error': _describe(e)};
    }
  }

  static String _ipv4Kind(InternetAddress address) {
    final b = address.rawAddress;
    if (b[0] == 127) return 'loopback';
    if (b[0] == 169 && b[1] == 254) return 'link-local';
    if (b[0] == 10 ||
        (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
        (b[0] == 192 && b[1] == 168)) {
      return 'private';
    }
    if (b[0] == 100 && b[1] >= 64 && b[1] <= 127) return 'carrier-nat';
    if (b[0] == 0) return 'unspecified';
    return 'public';
  }

  static String _ipv6Kind(InternetAddress address) {
    if (address.isLoopback) return 'loopback';
    if (address.isLinkLocal) return 'link-local';
    final first = address.rawAddress[0];
    if (first & 0xFE == 0xFC) return 'unique-local';
    return 'global';
  }

  static String _describe(Object error) => switch (error) {
        TimeoutException() => 'timed out',
        HandshakeException(:final message) => 'TLS handshake: $message',
        SocketException(:final message, :final osError) =>
          osError != null ? '$message (${osError.message})' : message,
        _ => '${error.runtimeType}: $error',
      };
}
