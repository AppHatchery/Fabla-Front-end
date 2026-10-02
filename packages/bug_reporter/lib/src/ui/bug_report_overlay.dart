import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../bug_reporter.dart';
import '../diagnostics/breadcrumbs.dart';
import '../diagnostics/breadcrumb_formatter.dart';
import '../diagnostics/device_info_collector.dart';
import '../models/bug_report_payload.dart';
import 'bug_report_screen.dart';

class BugReportOverlay extends StatefulWidget {
  final Widget child;

  const BugReportOverlay({super.key, required this.child});

  @override
  State<BugReportOverlay> createState() => _BugReportOverlayState();
}

class _BugReportOverlayState extends State<BugReportOverlay> {
  static const double _fabSize = 40;

  final GlobalKey _repaintKey = GlobalKey();
  Offset? _fabPosition;
  bool _capturing = false;

  Future<void> _onReportPressed() async {
    if (_capturing) return;
    final currentScreen =
        BreadcrumbFormatter.friendlyRoute(Breadcrumbs.instance.currentScreen);
    setState(() => _capturing = true);
    await WidgetsBinding.instance.endOfFrame;

    final screenshot = await _captureScreenshot();
    final breadcrumbs = Breadcrumbs.instance.snapshot();
    if (!mounted) return;
    final deviceInfo = await DeviceInfoCollector.collect(context);

    if (!mounted) return;
    setState(() => _capturing = false);

    if (screenshot == null) {
      Breadcrumbs.instance.custom('bug_report_capture_failed');
      return;
    }

    final navigator = BugReporter.config.navigatorKey?.currentState;
    if (navigator == null) return;

    Breadcrumbs.instance.custom('bug_report_opened');
    navigator.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: kBugReportRouteName),
        builder: (_) => BugReportScreen(
          draft: BugReportDraft(
            screenshot: screenshot,
            breadcrumbs: breadcrumbs,
            deviceInfo: deviceInfo,
            capturedAt: DateTime.now(),
            currentScreen: currentScreen,
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> _captureScreenshot() async {
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showButton = BugReporter.config.showReportButton;
    return Stack(
      children: [
        RepaintBoundary(key: _repaintKey, child: widget.child),
        if (showButton && !_capturing) _buildFab(context),
      ],
    );
  }

  Widget _buildFab(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxX = (size.width - _fabSize).clamp(0.0, double.infinity);
    final maxY = (size.height - _fabSize).clamp(0.0, double.infinity);
    final position = _fabPosition ?? Offset(maxX, size.height * 0.4);

    return Positioned(
      left: position.dx.clamp(0.0, maxX),
      top: position.dy.clamp(0.0, maxY),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _fabPosition = Offset(
              (position.dx + details.delta.dx).clamp(0.0, maxX),
              (position.dy + details.delta.dy).clamp(0.0, maxY),
            );
          });
        },
        child: FloatingActionButton(
          heroTag: 'fab_bug_report',
          mini: true,
          backgroundColor: Colors.redAccent,
          onPressed: _onReportPressed,
          child: const Icon(Icons.bug_report, color: Colors.white),
        ),
      ),
    );
  }
}
