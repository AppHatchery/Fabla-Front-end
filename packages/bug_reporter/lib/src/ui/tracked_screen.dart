import 'package:flutter/widgets.dart';

import '../diagnostics/breadcrumbs.dart';

class TrackedScreen extends StatefulWidget {
  final String name;
  final Widget child;

  const TrackedScreen({super.key, required this.name, required this.child});

  @override
  State<TrackedScreen> createState() => _TrackedScreenState();
}

class _TrackedScreenState extends State<TrackedScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      Breadcrumbs.instance.setRouteName(route, widget.name);
    }
    Breadcrumbs.instance.setRouteScreen(widget.name);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
