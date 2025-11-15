import 'dart:async';
import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/theme/components/cards.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/utils/errorCodes.dart';
import '../../screens/onboarding/domain/repository/setup_repository.dart';

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

  //ui elements
  bool loading = false;
  bool networkError = false;
  String errorTitle = '';
  String errorMessage = '';
  String errorButtonText = '';

  //variables to show different UI elements on the error card
  bool showActionButton = false;
  bool showContactResearcher = false;
  bool showContactResearcherButton = false;

  @override
  void initState() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(onPageStarted: (url) {
        setState(() {
          loading = true;
          surveyCompleted = false;
          networkError = false;
        });
      }, onPageFinished: (url) {
        setState(() {
          loading = false;
        });
        _startPeriodicCheck();
      },
          // Only show error for connection issues
          // Only show error for connection issues
          onWebResourceError: (error) {
        // Check if errorType is null
        if (error.errorType == null) return;

        final errorType = error.errorType!;

        // Define error type groups
        final loginOrPermissionErrors = [
          WebResourceErrorType.authentication,
          WebResourceErrorType.proxyAuthentication,
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

          // Check HTTP status codes and categorize errors
          onHttpError: (error) {
        final statusCode = error.response?.statusCode;
        if (statusCode == null) return;

        // Check if status code is in any error group
        if (HttpErrorGroups.inputOrFormErrors.contains(statusCode) ||
            HttpErrorGroups.loginOrPermissionErrors.contains(statusCode) ||
            HttpErrorGroups.pageNotFoundErrors.contains(statusCode) ||
            HttpErrorGroups.slowOrLostConnectionErrors.contains(statusCode) ||
            HttpErrorGroups.duplicateOrConflictErrors.contains(statusCode) ||
            HttpErrorGroups.serverOrSystemFailureErrors.contains(statusCode)) {
          setState(() {
            networkError = true;
            errorTitle = HttpErrorGroups.getErrorTitle(statusCode);
            errorMessage = HttpErrorGroups.getErrorMessage(statusCode);
            errorButtonText = HttpErrorGroups.getErrorButtonText(statusCode);

            //showing states which trigger different UI elements
            if (HttpErrorGroups.loginOrPermissionErrors.contains(statusCode)) {
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
        dev.log("WebView server error: ${error.response}");
      }))
      ..loadRequest(Uri.parse(widget.url));
    super.initState();
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
                      //shows the button for try again/contact researcher
                      showActionButton: showActionButton,
                      //shows the text button for contact researcher
                      showContactResearch: showContactResearcher,
                      //button action
                      onRetry: showContactResearcherButton ? _launchEmail : _reTry),
                ),
              )
            : WebViewWidget(controller: controller);
  }

  void _reTry() {
    setState(() {
      networkError = false;
      loading = true;
    });
    controller.reload();
  }

  Future<void> _launchEmail() async {
    try {
      //get experiment owner email
      final repository = SetupRepository();
      final experiment = repository.getExperiment();
      final ownerEmail = experiment.ownerEmail;

      //create the email uri
      final uri = Uri(
        scheme: "mailto",
        path: ownerEmail.isNotEmpty ? ownerEmail : "fabla@emory.edu",
        queryParameters: {
          'subject': 'WebView Permission Issue',
          'body': ''' I am having troubles accessing the webview
        
        
Name: '''
        },
      );

      //launch the email client
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        dev.log('Could not launch email client');
      }
    } catch (e) {
      dev.log('Error launching email: $e');
    }
  }

  void _startPeriodicCheck() {
    _checkTimer?.cancel();

    // Check every 500 milliseconds
    _checkTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      detectSurveyFinish();
    });
  }

  void detectSurveyFinish() async {
    //leaving the continue button available so users can skip this if an error occurs.
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
