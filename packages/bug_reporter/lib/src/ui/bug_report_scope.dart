import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../diagnostics/breadcrumbs.dart';
import '../diagnostics/tap_target_resolver.dart';
import 'bug_report_overlay.dart';

class BugReportScope extends StatefulWidget {
  final Widget child;

  const BugReportScope({super.key, required this.child});

  @override
  State<BugReportScope> createState() => _BugReportScopeState();
}

class _BugReportScopeState extends State<BugReportScope>
    with WidgetsBindingObserver {
  SemanticsHandle? _semanticsHandle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (kDebugMode) {
      _semanticsHandle = SemanticsBinding.instance.ensureSemantics();
    }
  }

  @override
  void dispose() {
    _semanticsHandle?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Breadcrumbs.instance.lifecycle(state.name);
  }

  void _onPointerDown(PointerDownEvent event) {
    final target = TapTargetResolver.labelAt(event.position, event.viewId);
    Breadcrumbs.instance.tap('tap', data: {
      if (target != null) 'target': target,
      'dx': event.position.dx.round(),
      'dy': event.position.dy.round(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      child: BugReportOverlay(child: widget.child),
    );
  }
}
