import 'dart:async';

import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CustomWebViewWidget extends StatefulWidget {
  final String url;
  final Function(bool) onComplete;
  const CustomWebViewWidget(
      {super.key, required this.url, required this.onComplete});

  @override
  State<CustomWebViewWidget> createState() => _CustomWebViewWidgetState();
}

class _CustomWebViewWidgetState extends State<CustomWebViewWidget> {
  late WebViewController controller;

  Timer? _checkTimer;
  bool surveyCompleted = false;

  bool loading = false;

  @override
  void initState() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          setState(() {
            loading = true;
          });
        },
        onPageFinished: (url) {
          setState(() {
            loading = false;
          });
          _startPeriodicCheck();
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? Center(
            child: CircularProgressIndicator(
            color: CustomColors.productNormalActive,
            strokeCap: StrokeCap.round,
            strokeWidth: 8,
          ))
        : WebViewWidget(controller: controller);
  }

  void _startPeriodicCheck() {
    _checkTimer?.cancel();

    // Check every 500 milliseconds
    _checkTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      detectSurveyFinish();
    });
  }

  void detectSurveyFinish() async {
    final String javaScript = '''
    (function() {
      function detectPhrases() {
        const targetPhrases = [
          "We thank you for your time spent taking this survey",
          "Your response has been recorded",
          "Thank you for taking the survey",
        ];
        
        const pageContent = document.body.textContent || "";
        
        const foundPhrases = targetPhrases.filter(phrase => {
          const regex = new RegExp('\\\\b' + phrase + '\\\\b', 'i');
          return regex.test(pageContent);
        });
        
        if (foundPhrases.length > 0) {
          return true;
        } else {
          return false;
        }
      }
      
      // Execute the function and return the result
      return detectPhrases();
    })();
    ''';

    final data = await controller.runJavaScriptReturningResult(javaScript);

    if (data == true && mounted) {
      _checkTimer?.cancel();
      widget.onComplete(true);
    }
  }
}
