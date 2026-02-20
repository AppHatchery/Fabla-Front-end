import 'dart:async';
import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/theme/components/cards.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/utils/errorCodes.dart';

class CustomWebViewWidget extends StatefulWidget {
  final String url;
  final Function(bool?) onComplete;
  final Function(dynamic) errorText;
  const CustomWebViewWidget(
      {super.key,
      required this.url,
      required this.onComplete,
      required this.errorText});

  @override
  State<CustomWebViewWidget> createState() => CustomWebViewWidgetState();
}

class CustomWebViewWidgetState extends State<CustomWebViewWidget> {
  WebViewController? controller;

  Timer? _checkTimer;
  Timer? _startTimer;
  bool surveyCompleted = false;

  //ui elements
  bool loading = false;
  WebViewError? webViewError;
  bool timeOut = true;

  late final uri = Uri.tryParse(widget.url);

  @override
  void initState() {
    super.initState();
    if (uri != null && uri!.hasScheme) {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (url) {
            _checkTimer?.cancel();
            if (mounted && webViewError == null) {
              setState(() {
                loading = true;
                timeOut = true;
              });
              _startTimeout();
            }
          },
          onPageFinished: (url) async {
            if (!mounted) return;
            if (webViewError != null) return;

            if (mounted) {
              setState(() {
                loading = false;
                timeOut = false;
              });
              _startPeriodicCheck();
            }
          },
          onWebResourceError: (error) {
            dev.log(
                'onWebResourceError triggered: ${error.errorCode} | ${error.description} | ${error.errorType} | ${error.isForMainFrame}');
            track({
              "code": error.errorCode,
              "description": error.description,
              "type": error.errorType.toString(),
              "main_frame": error.isForMainFrame,
            });
            if (error.isForMainFrame != true) return;

            if (error.description.toLowerCase().contains('cancelled')) return;

            if (error.description.contains("net::ERR_INTERNET_DISCONNECTED")) {
              if (mounted) {
                setState(() {
                  webViewError =
                      WebResourceErrorGroups.getNoInternetWebViewError(
                          initial: true);
                  loading = false;
                });
                _checkTimer?.cancel();
                _startTimer?.cancel();
              }
              return;
            }
            if (mounted) {
              setState(() {
                webViewError = WebResourceErrorGroups.getWebViewError(
                    error.errorType ?? WebResourceErrorType.unknown);
                loading = false;
              });
              _checkTimer?.cancel();
              _startTimer?.cancel();
            }
          },

          // NOTE: onHttpError IS ANDROID ONLY
          onHttpError: (error) {
            dev.log('onHttpError triggered: ${error.response?.statusCode}');

            if (webViewError != null) {
              _checkTimer?.cancel();
              _startTimer?.cancel();
              return;
            }

            track({
              "code": error.response?.statusCode ?? 'unknown',
              "type": 'HTTP Error',
            });
            if (mounted) {
              setState(() {
                webViewError = HttpErrorGroups.getWebViewError(
                    error.response?.statusCode ?? 404);
                loading = false;
              });

              _checkTimer?.cancel();
              _startTimer?.cancel();
            }
          },
        ))
        ..loadRequest(Uri.parse(widget.url));
    } else {
      // Handle invalid URL at start
      loading = false;
      webViewError = HttpErrorGroups.getWebViewError(404);

      // Cancel any survey checking
      _checkTimer?.cancel();
      _startTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _startTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
          child: CircularProgressIndicator(
        color: CustomColors.productNormalActive,
        strokeCap: StrokeCap.round,
        strokeWidth: 8,
      ));
    }

    if (webViewError != null) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 19.0),
            child: WebViewErrorCard(
                title: webViewError!.title,
                message: webViewError!.message,
                buttonText: webViewError!.buttonText,
                icon: webViewError!.icon,
                showContactResearch: webViewError!.contactResearcher,
                onRetry: _reTry,
                skip: _skip,
                connection: webViewError!.connected,
                screenChange: _screenChange),
          ),
        ),
      );
    }
    if (controller == null) return const SizedBox.shrink();
    return WebViewWidget(controller: controller!);
  }

  void _reTry() async {
    // Cancel the timers first
    _startTimer?.cancel();
    _startTimer = null;

    // Reset ALL state variables
    setState(() {
      loading = true;
      timeOut = true;
      webViewError = null;
      surveyCompleted = false;
    });

    // Notify parent
    widget.onComplete(false);

    // Small delay to let the UI rebuild for iOS
    await Future.delayed(const Duration(milliseconds: 80));

    // force a fresh navigation on iOS
    final cacheBustedUrl = Uri.parse(
      '${widget.url}${widget.url.contains('?') ? '&' : '?'}_ts=${DateTime.now().millisecondsSinceEpoch}',
    );

    try {
      await controller?.loadRequest(cacheBustedUrl);
      // Give a moment for the page to start loading
      await Future.delayed(const Duration(milliseconds: 120));
      return;
    } catch (e) {
      dev.log('loadRequest(cacheBustedUrl) failed: $e');
    }
  }

  void _startTimeout() async {
    _startTimer?.cancel();
    _startTimer = Timer(Duration(seconds: 15), () {
      if (mounted && timeOut) {
        dev.log("connection Time Out");
        final error = WebResourceErrorGroups.getWebViewError(
            WebResourceErrorType.timeout);
        setState(() {
          loading = false;
          timeOut = false;
          webViewError = error;
        });

        track({
          "code": "timeout",
          "type": error.errorType.toString(),
        });
        _checkTimer?.cancel();
        _startTimer?.cancel();
      }
    });
  }

  void _skip() {
    _startTimer?.cancel();
    widget.errorText(webViewError?.title ?? '');
    widget.onComplete(null);
  }

  void _screenChange() {
    setState(() {
      webViewError = WebResourceErrorGroups.getNoInternetWebViewError();
    });
  }

  void _startPeriodicCheck() {
    _checkTimer?.cancel();

    // Check every 500 milliseconds
    _checkTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      detectSurveyFinish();
    });
  }

  void detectSurveyFinish() async {
    // Don't run survey checks if there's an error
    if (controller == null || webViewError != null || loading) {
      _checkTimer?.cancel();
      return;
    }

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
        await controller!.runJavaScriptReturningResult(javaScript).catchError(
      (error) {
        // Handle any errors that occur during JavaScript execution
        dev.log('Error running JavaScript: $error');
        return false;
      },
    );
    if (data == true && mounted) {
      // Add a small delay to double-check, preventing false positives during transitions
      await Future.delayed(Duration(milliseconds: 1000));

      // Run the check one more time to confirm
      final confirmData =
          await controller?.runJavaScriptReturningResult(javaScript);

      if (confirmData == true &&
          !loading &&
          mounted &&
          webViewError == null &&
          !surveyCompleted) {
        setState(() {
          surveyCompleted = true;
        });
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

  Future<void> track(Map<String, dynamic> data) async {
    if (kReleaseMode) {
      await PendoService.track("Webview Error", data);
    }
  }
}
