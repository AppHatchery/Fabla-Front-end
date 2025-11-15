import 'package:webview_flutter/webview_flutter.dart';

// Error code groups and helper class

//server side error codes
class HttpErrorGroups {
  static const inputOrFormErrors = [400, 406, 411, 412, 413, 414, 415, 416, 417, 422, 431];
  static const loginOrPermissionErrors = [401, 402, 403, 407, 511];
  static const pageNotFoundErrors = [404, 405, 410, 451];
  static const slowOrLostConnectionErrors = [408, 504];
  static const duplicateOrConflictErrors = [409, 423, 424, 425, 428, 429];
  static const serverOrSystemFailureErrors = [421, 426, 500, 501, 502, 503, 505, 506, 507, 508, 509, 510];

  static String getErrorMessage(int statusCode) {
    if (inputOrFormErrors.contains(statusCode)) {
      return "Something seems wrong with what you entered. Please review and try again.";
    } else if (loginOrPermissionErrors.contains(statusCode)) {
      return "You don’t have access permission to this page.";
    } else if (pageNotFoundErrors.contains(statusCode)) {
      return "The page or form you’re trying to open isn’t available.";
    } else if (slowOrLostConnectionErrors.contains(statusCode)) {
      return "It’s taking too long or too many requests were made. Please wait a moment and try again.";
    } else if (duplicateOrConflictErrors.contains(statusCode)) {
      return "There was a problem saving your form. Please refresh and try again.";
    } else if (serverOrSystemFailureErrors.contains(statusCode)) {
      return "Something went wrong on our end. Please try again later.";
    }
    return "An unexpected error occurred. Please try again.";
  }

  static String getErrorTitle(int statusCode) {
    if (inputOrFormErrors.contains(statusCode)) {
      return "Input Error";
    } else if (loginOrPermissionErrors.contains(statusCode)) {
      return "Permission Error";
    } else if (pageNotFoundErrors.contains(statusCode)) {
      return "Page Not Found";
    } else if (slowOrLostConnectionErrors.contains(statusCode)) {
      return "Please Try Again";
    } else if (duplicateOrConflictErrors.contains(statusCode)) {
      return "Submission Error";
    } else if (serverOrSystemFailureErrors.contains(statusCode)) {
      return "Server Error";
    }
    return "Connection Issue";
  }

  static String getErrorButtonText(int statusCode) {
    if (loginOrPermissionErrors.contains(statusCode)) {
      return "Contact Researcher";
    } else if (pageNotFoundErrors.contains(statusCode)) {
      return "";
    }
    return "Try Again";
  }
}

//client side error codes
class WebResourceErrorGroups {

  static const loginOrPermissionErrors = [
    WebResourceErrorType.authentication,
    WebResourceErrorType.proxyAuthentication,
  ];

  static const pageNotFoundErrors = [
    WebResourceErrorType.fileNotFound,
    WebResourceErrorType.unsupportedScheme,
  ];

  static const slowOrLostConnectionErrors = [
    WebResourceErrorType.timeout,
    WebResourceErrorType.connect,
    WebResourceErrorType.hostLookup,
    WebResourceErrorType.io,
  ];

  static const duplicateOrConflictErrors = [
    WebResourceErrorType.redirectLoop,
    WebResourceErrorType.tooManyRequests,
  ];

  static const serverOrSystemFailureErrors = [
    WebResourceErrorType.failedSslHandshake,
    WebResourceErrorType.webContentProcessTerminated,
    WebResourceErrorType.webViewInvalidated,
  ];

  static const inputOrFormErrors = [
    WebResourceErrorType.badUrl,
    WebResourceErrorType.unsupportedAuthScheme,
  ];

  static String getErrorTitle(WebResourceErrorType errorType) {
    if (loginOrPermissionErrors.contains(errorType)) {
      return "Authentication Required";
    } else if (pageNotFoundErrors.contains(errorType)) {
      return "Page Not Found";
    } else if (slowOrLostConnectionErrors.contains(errorType)) {
      return "Connection Issue";
    } else if (duplicateOrConflictErrors.contains(errorType)) {
      return "Too Many Attempts";
    } else if (serverOrSystemFailureErrors.contains(errorType)) {
      return "Server Error";
    } else if (inputOrFormErrors.contains(errorType)) {
      return "Invalid Request";
    }
    return "Error";
  }

  static String getErrorMessage(WebResourceErrorType errorType) {
    if (loginOrPermissionErrors.contains(errorType)) {
      return "Authentication is required to access this content. Please check your credentials.";
    } else if (pageNotFoundErrors.contains(errorType)) {
      return "The requested page could not be found. Please check the URL or contact support.";
    } else if (slowOrLostConnectionErrors.contains(errorType)) {
      return "Your internet connection is unstable. The survey can't be accessed right now. Please reconnect to access the survey.";
    } else if (duplicateOrConflictErrors.contains(errorType)) {
      return "Too many requests or redirects. Please wait a moment and try again.";
    } else if (serverOrSystemFailureErrors.contains(errorType)) {
      return "The server is experiencing issues. Please try again later or contact support.";
    } else if (inputOrFormErrors.contains(errorType)) {
      return "The request format is invalid. Please check the URL or contact support.";
    }
    return "An unexpected error occurred. Please try again.";
  }

  static String getErrorButtonText(WebResourceErrorType errorType) {
    if (pageNotFoundErrors.contains(errorType)) {
      return "Go Back";
    }
    return "Try Again";
  }
}