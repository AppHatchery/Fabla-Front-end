import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CustomWebViewWidget extends StatefulWidget {
  final String url;
  const CustomWebViewWidget({super.key, required this.url});

  @override
  State<CustomWebViewWidget> createState() => _CustomWebViewWidgetState();
}

class _CustomWebViewWidgetState extends State<CustomWebViewWidget> {
  late WebViewController controller;

  @override
  void initState() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: controller);
  }
  
}
