import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/usecases/network_sweep.dart';
import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';

/// One headline finding from a sweep report. [ok] is null when the fact is
/// neither good nor bad, just information.
typedef SweepFact = ({String label, String value, bool? ok});

/// The headline findings of a [NetworkSweep] report, for a glance before the
/// full JSON. Tolerates missing or errored sections.
List<SweepFact> sweepFacts(Map<String, dynamic> report) {
  final connection = _map(report['connection']);
  final vpn = _map(connection['vpn']);
  final onVpn = vpn['os_reports_vpn'] == true ||
      (vpn['tunnel_interfaces'] as List?)?.isNotEmpty == true;
  final types = connection['types'];

  final consistency = _map(_map(report['dns'])['consistency']);
  final appHosts = (report['app_hosts'] as List?)?.cast<String>() ?? const [];
  const healthyDns = {'match', 'different addresses (may be CDN)'};
  final dnsIssues = [
    for (final host in appHosts)
      if (consistency[host] is String &&
          !healthyDns.contains(consistency[host]))
        '$host: ${consistency[host]}',
  ];

  final hosts = _map(report['hosts']);
  final reachable = hosts.values
      .where((h) => _map(_map(h)['https']).containsKey('status'))
      .length;

  final latency = _map(report['latency']);
  final throughput = _map(report['throughput']);
  String mbps(Object? section) => '${_map(section)['mbps'] ?? '–'} Mbps';

  return [
    (
      label: 'Connection',
      value: [
        if (types is List && types.isNotEmpty) types.join(', ') else 'unknown',
        // Tunnel found but the OS didn't list `vpn` itself.
        if (onVpn && !(types is List && types.contains('vpn'))) 'VPN tunnel',
      ].join(' · '),
      ok: types is List && !types.contains('none') ? null : false,
    ),
    (
      label: 'Internet',
      value: connection['internet_access'] == true ? 'Yes' : 'No',
      ok: connection['internet_access'] == true,
    ),
    if (_map(report['captive_portal']).containsKey('likely_captive_portal'))
      (
        label: 'Captive portal',
        value: report['captive_portal']['likely_captive_portal'] == true
            ? 'Detected'
            : 'None',
        ok: report['captive_portal']['likely_captive_portal'] != true,
      ),
    if (appHosts.isNotEmpty)
      (
        label: 'DNS',
        value: dnsIssues.isEmpty ? 'OK' : dnsIssues.join('\n'),
        ok: dnsIssues.isEmpty,
      ),
    if (hosts.isNotEmpty)
      (
        label: 'Our servers',
        value: '$reachable/${hosts.length} reachable',
        ok: reachable == hosts.length,
      ),
    if (latency['avg_ms'] != null)
      (
        label: 'Latency',
        value: '${latency['avg_ms']} ms avg, ${latency['jitter_ms']} ms jitter',
        ok: null,
      )
    else if (latency.isNotEmpty)
      (label: 'Latency', value: 'Failed', ok: false),
    if (throughput['skipped'] != true && throughput.isNotEmpty)
      (
        label: 'Speed',
        value: '↓ ${mbps(throughput['download'])} · '
            '↑ ${mbps(throughput['upload'])}',
        ok: null,
      ),
    (
      label: 'IPv6',
      value: connection['ipv6_available'] == true ? 'Yes' : 'No',
      ok: null,
    ),
  ];
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? value.cast<String, dynamic>() : const {};

/// Developer mode page that runs a [NetworkSweep] and shows its headline
/// facts and the full report as JSON, with a copy button. See
/// docs/network_sweep.md for the keys.
class NetworkSweepPage extends StatefulWidget {
  /// Injected in tests; defaults to a real [NetworkSweep].
  final NetworkSweep? sweep;

  const NetworkSweepPage({super.key, this.sweep});

  @override
  State<NetworkSweepPage> createState() => _NetworkSweepPageState();
}

class _NetworkSweepPageState extends State<NetworkSweepPage> {
  late final NetworkSweep _sweep = widget.sweep ?? NetworkSweep();
  bool _measureThroughput = true;
  bool _running = false;
  String? _json;
  List<SweepFact> _facts = const [];

  static const _monospace = TextStyle(
    fontFamily: 'Menlo',
    fontFamilyFallback: ['Courier', 'monospace'],
    fontSize: 11,
    height: 1.4,
    color: CustomColors.textNormalContent,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.fillNormal,
      appBar: AppBar(
        backgroundColor: CustomColors.fillNormal,
        title: Text(
          'Network sweep',
          style: CustomTypography().titleLarge(),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_json != null)
            IconButton(
              key: const Key('copy_network_sweep'),
              tooltip: 'Copy',
              icon: const Icon(Icons.copy_rounded,
                  color: CustomColors.productNormal),
              onPressed: _copy,
            ),
        ],
        shape: const Border(
          bottom: BorderSide(
            color: CustomColors.productBorderNormal,
            width: 2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Checks connection type, captive portals, DNS (system, '
            'DNS-over-HTTPS and direct resolvers), reachability, our servers, '
            'latency and speed. Never records this device\'s IP addresses.',
            style: CustomTypography()
                .bodyMedium(color: CustomColors.textSecondaryContent),
          ),
          const SizedBox(height: 12),
          Material(
            color: CustomColors.fillWhite,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: CustomColors.productBorderNormal),
            ),
            child: SwitchListTile.adaptive(
              key: const Key('network_sweep_throughput_switch'),
              value: _measureThroughput,
              activeTrackColor: CustomColors.productNormal,
              onChanged: _running
                  ? null
                  : (value) => setState(() => _measureThroughput = value),
              title: Text(
                'Include speed test',
                style: CustomTypography().bodyLarge(
                    color: CustomColors.productNormal, weight: FontWeight.w500),
              ),
              subtitle: Text(
                'Uses about 2 MB of data.',
                style: CustomTypography()
                    .bodyMedium(color: CustomColors.textSecondaryContent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          CustomElevatedButton(
            key: const Key('run_network_sweep'),
            onClick: _running ? null : _run,
            isDisabled: _running,
            text: _json == null ? 'Run sweep' : 'Run again',
          ),
          const SizedBox(height: 16),
          if (_running)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                    color: CustomColors.productNormalActive),
              ),
            )
          else if (_json != null)
            _result(_json!),
        ],
      ),
    );
  }

  Widget _result(String json) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_facts.isNotEmpty) ...[
          _factsCard(),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CustomColors.fillWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CustomColors.productBorderNormal),
          ),
          child: SelectableText(
            json,
            key: const Key('network_sweep_result'),
            style: _monospace,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _copy,
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy'),
            style: TextButton.styleFrom(
                foregroundColor: CustomColors.productNormal),
          ),
        ),
      ],
    );
  }

  Widget _factsCard() {
    return Container(
      key: const Key('network_sweep_facts'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CustomColors.fillWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CustomColors.productBorderNormal),
      ),
      child: Column(
        children: [
          for (final fact in _facts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Icon(
                    switch (fact.ok) {
                      true => Icons.check_circle_rounded,
                      false => Icons.error_rounded,
                      null => Icons.info_outline_rounded,
                    },
                    size: 18,
                    color: fact.ok == false
                        ? CustomColors.warningActive
                        : CustomColors.productNormal,
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(
                      fact.label,
                      style: CustomTypography()
                          .bodyMedium(color: CustomColors.textSecondaryContent),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      fact.value,
                      style: CustomTypography().bodyMedium(
                          color: fact.ok == false
                              ? CustomColors.warningActive
                              : CustomColors.textNormalContent,
                          weight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _run() async {
    setState(() => _running = true);
    Map<String, dynamic> report;
    try {
      report = await _sweep.run(measureThroughput: _measureThroughput);
    } catch (e) {
      report = {'error': '$e'};
    }
    if (!mounted) return;
    setState(() {
      _json = const JsonEncoder.withIndent('  ').convert(report);
      _facts = sweepFacts(report);
      _running = false;
    });
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _json!));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          const SnackBar(content: Text('Network sweep copied to clipboard')));
  }
}
