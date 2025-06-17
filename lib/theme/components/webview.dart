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
            surveyCompleted = false;
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
  void dispose() {
    _checkTimer?.cancel();
    controller.clearCache();
    controller.clearLocalStorage();
    super.dispose();
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

    const completionSelectors = [
        // Qualtrics completion
        '.EndOfSurvey',
        '#EndOfSurvey',
        '.SurveyEnd',
        '.CompleteMessage',
        '[class*="complete"]',
        '[class*="Complete"]',
        '[class*="thank"]',
        '[class*="Thank"]',

        // SurveyMonkey completion
        '.thank-you',
        '.completion-message',
        // Google Forms completion
        '.freebirdFormviewerViewResponseConfirmationMessage',

        // RedCap completion
        '.surveyacknowledgment',
        '#surveyacknowledgment',
        '[data-mlm="survey-acknowledgment"]',
        
        // Generic completion messages
        '[id*="complete"]',
        '[id*="Complete"]',
        '[id*="thank"]',
        '[id*="Thank"]'
      ];
      
      // If completion indicator found, survey is finished
      for (let selector of completionSelectors) {
        try {
          const elements = document.querySelectorAll(selector);
          for (let el of elements) {
            const isVisible = el.offsetParent !== null &&
              getComputedStyle(el).display !== 'none' &&
              getComputedStyle(el).visibility !== 'hidden';
            if (isVisible) {
              return true; // Survey completed
            }
          }
        } catch (e) {
          // Continue checking other selectors
        }
      }

    const nextButtonSelectors = [
        'button:contains("Next")',
        'input[type="button"][value*="Next"]',
        'input[type="submit"][value*="Next"]',
        'a:contains("Next")',
        '.next-button',
        '#nextButton',
        '[aria-label*="next"]',
        '[aria-label*="Next"]',
        '[title*="next"]',
        '[title*="Next"]',
        '[data-action*="next"]',
        '[data-action*="Next"]',
        '[data-role="next"]',
        '[data-role="Next"]',
        '[data-navigate="next"]',
        '[data-navigate="Next"]',
        '[data-direction="next"]',
        '[data-direction="Next"]',
        '[data-step="next"]',
        '[data-step="Next"]',
        '[data-qa*="next"]',
        '[data-qa*="Next"]',
        '[data-testid*="next"]',
        '[data-testid*="Next"]',
        '[data-cy*="next"]',
        '[data-cy*="Next"]',
        '[data-automation*="next"]',
        '[data-automation*="Next"]',

        // Qualtrics
        '.NextButton',
        '#NextButton',
        '[data-runtime-class*="NextButton"]',
        '.QR-NextButton',

        // SurveyMonkey
        '.btn-next',
        '.next',
        '.sm-next',
        '.surveymonkey-next',

        // Google Forms
        '.freebirdFormviewerViewNavigationNextButton',
        '.quantumWizButtonPaperbuttonNext',

        // Typeform
        '.next-button-container button',
        '[data-qa="next-button"]',

        // LimeSurvey
        '.ls-move-btn-next',
        '.moveNextBtn',

        // SurveyGizmo/Alchemer
        '.sg-next-button',

        // Generic patterns
        '[id*="next"]',
        '[class*="next"]',
        '[name*="next"]',
        '[onclick*="next"]',
        '[onclick*="Next"]',
        '[href*="next"]',
        '[href*="Next"]',

        // Common button patterns
        'button[type="submit"]',
        'input[type="submit"]',
        'button, input[type="button"], input[type="submit"], a.button',

        // Alternative text patterns
        'button:contains("Continue")',
        'input[value*="Continue"]',
        '[aria-label*="continue"]',
        '[aria-label*="Continue"]',
        'button:contains("Proceed")',
        'input[value*="Proceed"]',
        'button:contains("Forward")',
        'input[value*="Forward"]',
        'button:contains("→")',
        'button:contains("►")',
        'button:contains(">")',
        'button:contains(">>")'
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

    final data =
        await controller.runJavaScriptReturningResult(javaScript).catchError(
      (error) {
        // Handle any errors that occur during JavaScript execution
        print('Error running JavaScript: $error');
        return false; // Default to false if there's an error
      },
    );
    if (data == true && mounted) {
      // Add a small delay to double-check, preventing false positives during transitions
      await Future.delayed(Duration(milliseconds: 1000));

      // Run the check one more time to confirm
      final confirmData =
          await controller.runJavaScriptReturningResult(javaScript);

      if (confirmData == true && !loading && mounted) {
        _checkTimer?.cancel();
        widget.onComplete(true);
      } else if (mounted) {
        // If the confirmation check fails, reset the surveyCompleted state
        setState(() {
          surveyCompleted = false;
        });
      }
    } else if (mounted) {
      // If the initial check fails, reset the surveyCompleted state
      setState(() {
        surveyCompleted = false;
      });
    }
  }
}
