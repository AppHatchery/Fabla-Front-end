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
    const nextButtonSelectors = [
        'button:contains("Next")', 
        'input[type="button"][value*="Next"]',
        'input[type="submit"][value*="Next"]',
        'a:contains("Next")',
        '.next-button',
        '#nextButton',
        '[aria-label*="next"]',
        '[aria-label*="Next"]',
        
        // Qualtrics
        '.NextButton',
        '#NextButton',
        
        // SurveyMonkey
        '.btn-next',
        '.next',
        
        // Google Forms
        '.freebirdFormviewerViewNavigationNextButton',
        
        // Generic
        '[id*="next"]',
        '[class*="next"]',
        '[name*="next"]',
        
        'button, input[type="button"], input[type="submit"], a.button'
    ];

    for (let selector of nextButtonSelectors) {
        try {
            const elements = document.querySelectorAll(selector);
            for (let el of elements) {
                const tag = el.tagName.toLowerCase();
                if (!['button', 'input', 'a'].includes(tag)) continue;

                const elementText = el.innerText || el.value || el.textContent || '';
                const ariaLabel = el.getAttribute('aria-label') || '';
                const isVisible = el.offsetParent !== null &&
                                  getComputedStyle(el).display !== 'none' &&
                                  getComputedStyle(el).visibility !== 'hidden';

                if (isVisible && (
                    elementText.toLowerCase().includes('next') ||
                    ariaLabel.toLowerCase().includes('next')
                )) {
                    // Found a visible "Next" button
                    return false;
                }
            }
        } catch (e) {
        }
    }

    // No "Next" button found
    return true;
})();
    ''';

    final data = await controller.runJavaScriptReturningResult(javaScript);

    if (data == true && mounted) {
      _checkTimer?.cancel();
      widget.onComplete(true);
    }
  }
}
