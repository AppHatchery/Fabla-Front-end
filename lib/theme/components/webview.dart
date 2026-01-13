import 'dart:async';
import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/theme/components/cards.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/utils/emailFunction.dart';
import '../../core/utils/errorCodes.dart';

class CustomWebViewWidget extends StatefulWidget {
  final String url;
  final Function(bool?) onComplete;
  final Function(dynamic) errorText;
  const CustomWebViewWidget(
      {super.key, required this.url, required this.onComplete, required this.errorText});

  @override
  State<CustomWebViewWidget> createState() => CustomWebViewWidgetState();
}

class CustomWebViewWidgetState extends State<CustomWebViewWidget> {
  late WebViewController controller;

  Timer? _checkTimer;
  Timer? _startTimer;
  bool surveyCompleted = false;

  //ui elements
  bool loading = false;
  bool networkError = false;
  String errorTitle = '';
  String errorMessage = '';
  String errorButtonText = '';
  String errorIcon = '';
  bool connection = false;
  bool timeOut = true;

  //variables to show different UI elements on the error card
  bool showContactResearcher = false;

  //Flag to prevent error callbacks from overwriting JS-detected errors
  bool errorAlreadyHandled = false;

  late final uri = Uri.tryParse(widget.url);

  @override
  void initState() {
    super.initState();
    if (uri != null && uri!.hasScheme) {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                loading = true;
                errorAlreadyHandled = false;// Reset flag on new page load
              });
            }
            _startTimeout();
          },
          onPageFinished: (url) async {

            if (!mounted) return;

            final errorInfo = await _checkForErrorPage();

            if (errorInfo != null) {
              // Error detected - set flag FIRST, then update UI
              errorAlreadyHandled = true;

              if (mounted) {
                setState(() {
                  loading = false;
                  networkError = true;
                  errorTitle = errorInfo['title']!;
                  errorMessage = errorInfo['message']!;
                  errorButtonText = errorInfo['buttonText']!;
                  errorIcon = errorInfo['icon']!;
                  showContactResearcher = errorInfo['showContactResearcher'] == 'true';
                  connection = false;
                  timeOut = false;
                });

                // Cancel any survey checking
                _checkTimer?.cancel();
                _startTimer?.cancel();

              }
            } else {
              // Success load - only update if no error was already set
              if (mounted && !networkError) {
                setState(() {
                  loading = false;
                  networkError = false;
                  timeOut = false;
                });
                _startPeriodicCheck();
              }
            }
          },
          onWebResourceError: (error) {

            // CRITICAL: Don't overwrite errors already detected by JavaScript
            if (errorAlreadyHandled) {
              dev.log("Ignoring onWebResourceError - error already handled via JS");
              return;
            }

            // CRITICAL FIX FOR iOS: IGNORE CANCELLED REQUESTS
            // iOS throws "NSURLErrorDomain code -999" (Cancelled) when
            // a redirect happens. This is NOT a real error.
            if (error.description.toLowerCase().contains('cancelled') ||
                error.description.contains('NSURLErrorDomain code -999')) {
              return;
            }

            /// CRITICAL FIX FOR ORB BLOCKING
            /// Android fix for 'net::ERR_BLOCKED_BY_ORB' errors
            /// These errors occur when the OS blocks responses due to
            /// the response headers not having proper CORS settings.
            if (error.description.contains('net::ERR_BLOCKED_BY_ORB')) {
                  errorAlreadyHandled = true;
              return;
            }


            final errorType = error.errorType;
            if (errorType == null) return;

            errorAlreadyHandled = true; // Mark error as handled

            if (mounted) {
              setState(() {
                networkError = true;
                loading = false;
                errorTitle = WebResourceErrorGroups.getErrorTitle(errorType);
                errorMessage = WebResourceErrorGroups.getErrorMessage(errorType);
                errorButtonText = WebResourceErrorGroups.getErrorButtonText(errorType);
                errorIcon = WebResourceErrorGroups.getErrorIcon(errorType);
                connection = WebResourceErrorGroups.getConnectionStatus(errorType);
                showContactResearcher = WebResourceErrorGroups.serverOrSystemFailureErrors.contains(errorType) ||
                    WebResourceErrorGroups.pageNotFoundErrors.contains(errorType) ||
                    WebResourceErrorGroups.loginOrPermissionErrors.contains(errorType);
              });

              // Cancel any survey checking
              _checkTimer?.cancel();
              _startTimer?.cancel();

            }

            dev.log(
                "WebView resource error: ${error.description}, Type: $errorType");
          },

          // NOTE: onHttpError IS ANDROID ONLY
          onHttpError: (error) {

            // CRITICAL: Don't overwrite errors already detected by JavaScript
            if (errorAlreadyHandled) {
              dev.log("Ignoring onHttpError - error already handled via JS");
              return;
            }

            final statusCode = error.response?.statusCode;
            if (statusCode == null) return;

            errorAlreadyHandled = true; // Mark error as handled

            if (mounted) {
              setState(() {
                networkError = true;
                loading = false;
                errorTitle = HttpErrorGroups.getErrorTitle(statusCode);
                errorMessage = HttpErrorGroups.getErrorMessage(statusCode);
                errorButtonText =
                    HttpErrorGroups.getErrorButtonText(statusCode);
                errorIcon = HttpErrorGroups.getErrorIcon(statusCode);
                connection = HttpErrorGroups.getConnectionStatus(statusCode);
                showContactResearcher =  HttpErrorGroups.serverOrSystemFailureErrors.contains(statusCode) ||
                    HttpErrorGroups.pageNotFoundErrors.contains(statusCode) ||
                    HttpErrorGroups.loginOrPermissionErrors.contains(statusCode);

              });

              // Cancel any survey checking
              _checkTimer?.cancel();

              _startTimer?.cancel();

            }

            dev.log("WebView server error: ${error.response?.statusCode}");
          },
        ))
        ..loadRequest(Uri.parse(widget.url));
    } else {
      // Handle invalid URL at start
      networkError = true;
      loading = false;
      errorTitle = HttpErrorGroups.getErrorTitle(404);
      errorMessage = HttpErrorGroups.getErrorMessage(404);
      errorButtonText = HttpErrorGroups.getErrorButtonText(404);
      errorIcon = HttpErrorGroups.getErrorIcon(404);
      connection = HttpErrorGroups.getConnectionStatus(404);

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
    dev.log('WebView build - loading: $loading, networkError: $networkError, errorTitle: $errorTitle');

    if (loading) {
      return Center(
          child: CircularProgressIndicator(
            color: CustomColors.productNormalActive,
            strokeCap: StrokeCap.round,
            strokeWidth: 8,
          ));
    }

    if (networkError) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 19.0),
            child: WebViewErrorCard(
                title: errorTitle,
                message: errorMessage,
                buttonText: errorButtonText,
                icon: errorIcon,
                showContactResearch: showContactResearcher,
                onRetry: _reTry,
                skip: _skip,
                connection: connection,
                screenChange: _screenChange),
          ),
        ),
      );
    }

    return WebViewWidget(controller: controller);
  }

  // UPDATED JS CHECKER FOR iOS COMPATIBILITY
  Future<Map<String, String>?> _checkForErrorPage() async {
    try {
      final result = await controller.runJavaScriptReturningResult('''
        (function() {
          // 1. Get basic info
          const bodyText = document.body ? document.body.innerText : '';
          const title = document.title ? document.title.toLowerCase() : '';
          
          // 2. iOS/Standard WebKit Checks (Since onHttpError doesn't work on iOS)
          // Check for explicit status codes in title or body first
          const statusCodeMatch = bodyText.match(/\\b(4\\d{2}|5\\d{2})\\b/) || title.match(/\\b(4\\d{2}|5\\d{2})\\b/);
          if (statusCodeMatch) {
            const code = parseInt(statusCodeMatch[1]);
            if (code >= 400 && code < 600) {
              return code;
            }
          }
          
          // Specific error page checks
          if (title.includes('404') || bodyText.includes('404') || 
              title.includes('not found') || bodyText.includes('Not Found')) {
             return 404;
          }
          if (title.includes('500') || bodyText.includes('500') || 
              title.includes('internal server error') || bodyText.includes('Internal Server Error')) {
             return 500;
          }
          if (title.includes('403') || bodyText.includes('403') || 
              title.includes('forbidden') || bodyText.includes('Forbidden')) {
             return 403;
          }
          if (title.includes('401') || bodyText.includes('401') || 
              title.includes('unauthorized') || bodyText.includes('Unauthorized')) {
             return 401;
          }
          if (title.includes('400') || bodyText.includes('400') || 
              title.includes('bad request') || bodyText.includes('Bad Request')) {
             return 400;
          }
          if (title.includes('503') || bodyText.includes('503') || 
              title.includes('service unavailable') || bodyText.includes('Service Unavailable')) {
             return 503;
          }

          // 3. Chrome/Android specific checks
          const errorPatterns = [
            'ERR_HTTP_RESPONSE_CODE_FAILURE',
            'ERR_NAME_NOT_RESOLVED',
            'ERR_CONNECTION_REFUSED'
          ];
          
          if (errorPatterns.some(pattern => bodyText.includes(pattern))) {
             return 'connection';
          }
          
          return null;
        })();
      ''');

      if (result == null || result == 'null') {
        return null;
      }

      int? statusCode;
      if (result is int) {
        statusCode = result;
      } else if (result is String) {
        // Try to parse as integer first
        statusCode = int.tryParse(result);

        // If it's the string 'connection', handle separately
        if (statusCode == null && result == 'connection') {
          return {
            'title': 'Connection Issue',
            'message': 'We could not connect to the server.',
            'buttonText': 'Try Again',
            'icon': 'assets/images/icons/paceError.png',
            'showActionButton': 'true',
            'showContactResearcher': 'false',
          };
        }
      }

      if (statusCode != null && statusCode >= 400 && statusCode < 600) {
        dev.log('JavaScript detected HTTP error: $statusCode');

        // Return mapped error info
        return {
          'title': HttpErrorGroups.getErrorTitle(statusCode),
          'message': HttpErrorGroups.getErrorMessage(statusCode),
          'buttonText': HttpErrorGroups.getErrorButtonText(statusCode),
          'icon': HttpErrorGroups.getErrorIcon(statusCode),
          'showActionButton':
          (!HttpErrorGroups.pageNotFoundErrors.contains(statusCode))
              .toString(),
          'showContactResearcher': (
              HttpErrorGroups.serverOrSystemFailureErrors.contains(statusCode) ||
                  HttpErrorGroups.loginOrPermissionErrors.contains(statusCode) ||
                  HttpErrorGroups.pageNotFoundErrors.contains(statusCode)
          ).toString(),
        };
      }

      return null;
    } catch (e) {
      dev.log('Error checking for error page: $e');
      return null;
    }
  }

  void _reTry() async {
    // Cancel the timers first
    _startTimer?.cancel();
    _startTimer = null;

    // Reset ALL state variables
    setState(() {
      networkError = false;
      loading = true;
      errorAlreadyHandled = false;
      timeOut = true;
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
      await controller.loadRequest(cacheBustedUrl);
      // Give a moment for the page to start loading
      await Future.delayed(const Duration(milliseconds: 120));
      return;
    } catch (e) {
      dev.log('loadRequest(cacheBustedUrl) failed: $e');
    }
  }


  void _startTimeout() async {

    _startTimer?.cancel();
    _startTimer = Timer(Duration(seconds: 15),(){

      if (mounted && timeOut) {

        errorAlreadyHandled = true;
        dev.log("connection Time Out");

        setState(() {
          loading = false;
          errorTitle = "Connection Issue";
          errorMessage =
          "It looks like your internet might be slow or disconnected. Please check your connection. You need internet to start this entry.";
          errorButtonText = "Try Again";
          errorIcon = "assets/images/icons/link_off.png";
          connection = true;
          networkError = true;
        });
      }
    });
  }

  void _skip(){
    setState(() {
      widget.errorText(errorTitle);
      widget.onComplete(null);
    });
    _startTimer?.cancel();
  }

  void _screenChange(){
    setState(() {
      errorTitle = "No Internet Connection";
      errorMessage = "We’re unable to load the survey due to no internet connection. Reconnect or skip to continue. If you skip, you won’t be able to submit the web survey later, but your remaining responses will still be recorded.";
      errorIcon = "assets/images/icons/android_wifi_3_bar_off.png";
      errorButtonText = "Try Again";
      connection = false;
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
    if (networkError || loading) {
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
        await controller.runJavaScriptReturningResult(javaScript).catchError(
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