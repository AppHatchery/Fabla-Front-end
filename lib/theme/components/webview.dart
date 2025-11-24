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
  const CustomWebViewWidget(
      {super.key, required this.url, required this.onComplete});

  @override
  State<CustomWebViewWidget> createState() => CustomWebViewWidgetState();
}

class CustomWebViewWidgetState extends State<CustomWebViewWidget> {
  late WebViewController controller;

  Timer? _checkTimer;
  bool surveyCompleted = false;

  //ui elements
  bool loading = false;
  bool networkError = false;
  String errorTitle = '';
  String errorMessage = '';
  String errorButtonText = '';
  String errorIcon = '';

  //variables to show different UI elements on the error card
  bool showActionButton = false;
  bool showContactResearcher = false;
  bool showContactResearcherButton = false;
  late final uri = Uri.tryParse(widget.url);

  @override
  void initState() {
    super.initState();
    if (uri != null && uri!.hasScheme) {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              loading = true;
              surveyCompleted = false;
              networkError = false;
            });
          },
          onPageFinished: (url) async {
            // Check for error pages AFTER page loads
            await Future.delayed(Duration(milliseconds: 250));
            final errorInfo = await _checkForErrorPage();

            if (errorInfo != null && !networkError) {
              // Error page detected but no error callback was triggered
              setState(() {
                loading = false;
                networkError = true;
                errorTitle = errorInfo['title']!;
                errorMessage = errorInfo['message']!;
                errorButtonText = errorInfo['buttonText']!;
                errorIcon = errorInfo['icon']!;
                showActionButton = errorInfo['showActionButton'] == 'true';
                showContactResearcherButton =
                    errorInfo['showContactResearcherButton'] == 'true';
                showContactResearcher =
                    errorInfo['showContactResearcher'] == 'true';
              });
            } else if (errorInfo == null) {
              setState(() {
                loading = false;
              });
              _startPeriodicCheck();
            }
          },
          onWebResourceError: (error) {
            if (error.errorType == null) return;

            final errorType = error.errorType!;

            // Define error type groups
            final loginOrPermissionErrors = [
              WebResourceErrorType.authentication,
              WebResourceErrorType.proxyAuthentication,
              WebResourceErrorType.unknown
            ];

            final pageNotFoundErrors = [
              WebResourceErrorType.fileNotFound,
              WebResourceErrorType.unsupportedScheme,
            ];

            final slowOrLostConnectionErrors = [
              WebResourceErrorType.timeout,
              WebResourceErrorType.connect,
              WebResourceErrorType.hostLookup,
              WebResourceErrorType.io,
            ];

            final duplicateOrConflictErrors = [
              WebResourceErrorType.redirectLoop,
              WebResourceErrorType.tooManyRequests,
            ];

            final serverOrSystemFailureErrors = [
              WebResourceErrorType.failedSslHandshake,
              WebResourceErrorType.webContentProcessTerminated,
              WebResourceErrorType.webViewInvalidated,
            ];

            final inputOrFormErrors = [
              WebResourceErrorType.badUrl,
              WebResourceErrorType.unsupportedAuthScheme,
            ];

            // Check if error type is in any group
            if (loginOrPermissionErrors.contains(errorType) ||
                pageNotFoundErrors.contains(errorType) ||
                slowOrLostConnectionErrors.contains(errorType) ||
                duplicateOrConflictErrors.contains(errorType) ||
                serverOrSystemFailureErrors.contains(errorType) ||
                inputOrFormErrors.contains(errorType)) {
              setState(() {
                networkError = true;
                errorTitle = WebResourceErrorGroups.getErrorTitle(errorType);
                errorMessage = WebResourceErrorGroups.getErrorMessage(errorType);
                errorButtonText =
                    WebResourceErrorGroups.getErrorButtonText(errorType);
                errorIcon = WebResourceErrorGroups.getErrorIcon(errorType);

                // Showing states which trigger different UI elements
                if (loginOrPermissionErrors.contains(errorType)) {
                  showContactResearcherButton = true;
                } else {
                  showContactResearcherButton = false;
                }

                if (serverOrSystemFailureErrors.contains(errorType)) {
                  showContactResearcher = true;
                } else {
                  showContactResearcher = false;
                }

                if (pageNotFoundErrors.contains(errorType)) {
                  showActionButton = false;
                } else {
                  showActionButton = true;
                }
              });
            }

            dev.log(
                "WebView resource error: ${error.description}, Type: $errorType");
          },
          onHttpError: (error) {
            final statusCode = error.response?.statusCode;
            if (statusCode == null) return;

            // Check if status code is in any error group
            if (HttpErrorGroups.inputOrFormErrors.contains(statusCode) ||
                HttpErrorGroups.loginOrPermissionErrors.contains(statusCode) ||
                HttpErrorGroups.pageNotFoundErrors.contains(statusCode) ||
                HttpErrorGroups.slowOrLostConnectionErrors.contains(statusCode) ||
                HttpErrorGroups.duplicateOrConflictErrors.contains(statusCode) ||
                HttpErrorGroups.serverOrSystemFailureErrors
                    .contains(statusCode)) {
              setState(() {
                networkError = true;
                errorTitle = HttpErrorGroups.getErrorTitle(statusCode);
                errorMessage = HttpErrorGroups.getErrorMessage(statusCode);
                errorButtonText = HttpErrorGroups.getErrorButtonText(statusCode);
                errorIcon = HttpErrorGroups.getErrorIcon(statusCode);

                //showing states which trigger different UI elements
                if (HttpErrorGroups.loginOrPermissionErrors
                    .contains(statusCode)) {
                  showContactResearcherButton = true;
                } else {
                  showContactResearcherButton = false;
                }
                if (HttpErrorGroups.serverOrSystemFailureErrors
                    .contains(statusCode)) {
                  showContactResearcher = true;
                } else {
                  showContactResearcher = false;
                }
                if (HttpErrorGroups.pageNotFoundErrors.contains(statusCode)) {
                  showActionButton = false;
                } else {
                  showActionButton = true;
                }
              });
            }
            dev.log("WebView server error: ${error.response?.statusCode}");
          },
        ))
        ..loadRequest(Uri.parse(widget.url));
    } else {
      networkError = true;
      errorTitle = HttpErrorGroups.getErrorTitle(404);
      errorMessage = HttpErrorGroups.getErrorMessage(404);
      errorButtonText = HttpErrorGroups.getErrorButtonText(404);
      errorIcon = HttpErrorGroups.getErrorIcon(404);
      showActionButton = false;
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
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
        : networkError
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: WebViewErrorCard(
                    //error message content
                    title: errorTitle,
                    message: errorMessage,
                    buttonText: errorButtonText,
                    //show error icon
                    icon: errorIcon,
                    //shows the button for try again/contact researcher
                    showActionButton: showActionButton,
                    //shows the text button for contact researcher
                    showContactResearch: showContactResearcher,
                    //button action
                    onRetry:
                        showContactResearcherButton ? _launchEmail : _reTry,
                  ),
                ),
              )
            : WebViewWidget(controller: controller);
  }

  Future<Map<String, String>?> _checkForErrorPage() async {
    try {
      final result = await controller.runJavaScriptReturningResult('''
        (function() {
          // Check for Chrome/WebView error pages
          const body = document.body;
          const title = document.title.toLowerCase();
          const bodyText = body?.innerText || '';
          
          // Chrome error page indicators
          const hasErrorHeading = document.querySelector('[jsselect="heading"]');
          const hasErrorCode = document.querySelector('.error-code');
          
          // Check for common error patterns
          const errorPatterns = [
            'ERR_HTTP_RESPONSE_CODE_FAILURE',
            'HTTP ERROR 404',
            'HTTP ERROR 500',
            'HTTP ERROR 403',
            'HTTP ERROR 401',
            '404 Not Found',
            '500 Internal Server Error',
            '403 Forbidden',
            '401 Unauthorized'
          ];
          
          const hasErrorText = errorPatterns.some(pattern => 
            bodyText.includes(pattern)
          );
          
          // Check if page looks like an error page
          const looksLikeErrorPage = (
            hasErrorHeading || 
            hasErrorCode || 
            hasErrorText ||
            (title.includes('error') && body?.children.length < 5)
          );
          
          if (!looksLikeErrorPage) {
            return null;
          }
          
          // Try to extract status code
          let statusCode = null;
          const codeMatch = bodyText.match(/HTTP ERROR (\\d{3})|\\b(4\\d{2}|5\\d{2})\\b/);
          if (codeMatch) {
            statusCode = parseInt(codeMatch[1] || codeMatch[2]);
          }
          
          return statusCode || 'unknown';
        })();
      ''');

      if (result == 'null') {
        return null; // No error page detected
      }

      // Parse the status code
      int? statusCode;
      if (result is int) {
        statusCode = result;
      } else if (result is String && result != 'unknown') {
        statusCode = int.tryParse(result);
      }

      // Return appropriate error info based on status code
      if (statusCode != null) {
        return {
          'title': HttpErrorGroups.getErrorTitle(statusCode),
          'message': HttpErrorGroups.getErrorMessage(statusCode),
          'buttonText': HttpErrorGroups.getErrorButtonText(statusCode),
          'icon': HttpErrorGroups.getErrorIcon(statusCode),
          'showActionButton':
              (!HttpErrorGroups.pageNotFoundErrors.contains(statusCode))
                  .toString(),
          'showContactResearcherButton': HttpErrorGroups.loginOrPermissionErrors
              .contains(statusCode)
              .toString(),
          'showContactResearcher': HttpErrorGroups.serverOrSystemFailureErrors
              .contains(statusCode)
              .toString(),
        };
      } else {
        // Generic error
        return {
          'title': 'Connection Issue',
          'message': 'An unexpected error occurred. Please try again.',
          'buttonText': 'Try Again',
          'icon': 'assets/images/icons/warning.png',
          'showActionButton': 'true',
          'showContactResearcherButton': 'false',
          'showContactResearcher': 'true',
        };
      }
    } catch (e) {
      dev.log('Error checking for error page: $e');
      return null;
    }
  }

  _launchEmail() async {
    await launchEmail(
    subject: 'Permission Issue – Assistance Needed',
    body: ''' A permission issue was encountered. Please investigate and advise on next steps.
        
        
Participant ID: ''',
    );
  }

  void _reTry() {
    setState(() {
      networkError = false;
      loading = true;
    });
    controller.reload();
  }


  void _startPeriodicCheck() {
    _checkTimer?.cancel();

    // Check every 500 milliseconds
    _checkTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      detectSurveyFinish();
    });
  }

  void detectSurveyFinish() async {
    if (networkError) {
      widget.onComplete(null); // Pass null when there's an error
      _checkTimer?.cancel(); // Stop checking
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
