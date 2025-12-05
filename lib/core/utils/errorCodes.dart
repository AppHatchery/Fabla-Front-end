import 'dart:ffi';

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
      return "Something seems wrong with what you entered. Please review and try again, or choose to skip. If you skip, you won’t be able to submit the web survey later, but your other responses will be saved.";
    } else if (loginOrPermissionErrors.contains(statusCode)) {
      return "You don’t have permission to access this page. Contact the researcher or skip. If you skip, you won’t be able to submit the web survey later, but your other responses will be saved.";
    } else if (pageNotFoundErrors.contains(statusCode)) {
      return "The web survey you’re trying to open isn’t available. Contact the researcher or skip. If you skip, you won’t be able to submit it later, but your other responses will be saved.";
    } else if (slowOrLostConnectionErrors.contains(statusCode)) {
      return "It’s taking too long or there were too many requests. Try again shortly or skip. If you skip, you won’t be able to submit it later, but your other responses will be saved.";
    } else if (duplicateOrConflictErrors.contains(statusCode)) {
      return "We couldn’t save your form. Try again or skip. If you skip, you won’t be able to submit it later, but your other responses will be saved.";
    } else if (serverOrSystemFailureErrors.contains(statusCode)) {
      return "Something went wrong on our end. Try again later or skip. If you skip, you won’t be able to submit it later, but your other responses will be saved.";
    }
    return "It looks like your internet might be slow or disconnected. Please check your connection. You need internet to start this entry.";
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
    if (loginOrPermissionErrors.contains(statusCode) ||
        pageNotFoundErrors.contains(statusCode)) {
      return "Contact Researcher";
    }
    return "Try Again";
  }

  static String getErrorIcon(int statusCode) {
    if (inputOrFormErrors.contains(statusCode)) {
      return "assets/images/icons/content_paste_off.png";
    } else if (loginOrPermissionErrors.contains(statusCode)) {
      return "assets/images/icons/lock.png";
    } else if (pageNotFoundErrors.contains(statusCode)) {
      return "assets/images/icons/link_off.png";
    } else if (slowOrLostConnectionErrors.contains(statusCode)) {
      return "assets/images/icons/paceError.png";
    } else if (duplicateOrConflictErrors.contains(statusCode)) {
      return "assets/images/icons/scan_delete.png";
    } else if (serverOrSystemFailureErrors.contains(statusCode)) {
      return "assets/images/icons/database_off.png";
    }
    return "assets/images/icons/link_off.png";
  }

  static bool getConnectionStatus(int statusCode){
    if(inputOrFormErrors.contains(statusCode) ||
    loginOrPermissionErrors.contains(statusCode) ||
    pageNotFoundErrors.contains(statusCode) ||
    slowOrLostConnectionErrors.contains(statusCode) ||
    duplicateOrConflictErrors.contains(statusCode) ||
    serverOrSystemFailureErrors.contains(statusCode)){
      return false;
    }
    return true;
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
    WebResourceErrorType.unknown
  ];

  static const slowOrLostConnectionErrors = [
    WebResourceErrorType.timeout,
    WebResourceErrorType.connect,
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
      return "Permission Issue";
    } else if (pageNotFoundErrors.contains(errorType)) {
      return "Page Not Found";
    } else if (slowOrLostConnectionErrors.contains(errorType)) {
      return "Connection Issue";
    } else if (duplicateOrConflictErrors.contains(errorType)) {
      return "Submission Error";
    } else if (serverOrSystemFailureErrors.contains(errorType)) {
      return "Server Error";
    } else if (inputOrFormErrors.contains(errorType)) {
      return "Input Error";
    }
    return "Connection Issue";
  }

  static String getErrorMessage(WebResourceErrorType errorType) {
    if (loginOrPermissionErrors.contains(errorType)) {
      return "You don’t have permission to access this page. Contact the researcher or skip. If you skip, you won’t be able to submit the web survey later, but your other responses will be saved.";
    } else if (pageNotFoundErrors.contains(errorType)) {
      return "The web survey you’re trying to open isn’t available. Contact the researcher or skip. If you skip, you won’t be able to submit it later, but your other responses will be saved.";
    } else if (slowOrLostConnectionErrors.contains(errorType)) {
      return "It’s taking too long or there were too many requests. Try again shortly or skip. If you skip, you won’t be able to submit it later, but your other responses will be saved.";
    } else if (duplicateOrConflictErrors.contains(errorType)) {
      return "We couldn’t save your form. Try again or skip. If you skip, you won’t be able to submit it later, but your other responses will be saved.";
    } else if (serverOrSystemFailureErrors.contains(errorType)) {
      return "Something went wrong on our end. Try again later or skip. If you skip, you won’t be able to submit it later, but your other responses will be saved.";
    } else if (inputOrFormErrors.contains(errorType)) {
      return "Something seems wrong with what you entered. Please review and try again, or choose to skip. If you skip, you won’t be able to submit the web survey later, but your other responses will be saved.";
    }
    return "It looks like your internet might be slow or disconnected. Please check your connection. You need internet to start this entry.";
  }

  static String getErrorButtonText(WebResourceErrorType errorType) {
    if (loginOrPermissionErrors.contains(errorType) ||
        pageNotFoundErrors.contains(errorType)) {
      return "Contact Researcher";
    }
    return "Try Again";
  }

  static String getErrorIcon(WebResourceErrorType errorType) {
    if (loginOrPermissionErrors.contains(errorType)) {
      return "assets/images/icons/lock.png";
    } else if (pageNotFoundErrors.contains(errorType)) {
      return "assets/images/icons/link_off.png";
    } else if (slowOrLostConnectionErrors.contains(errorType)) {
      return "assets/images/icons/paceError.png";
    } else if (duplicateOrConflictErrors.contains(errorType)) {
      return "assets/images/icons/scan_delete.png";
      ;
    } else if (serverOrSystemFailureErrors.contains(errorType)) {
      return "assets/images/icons/database_off.png";
    } else if (inputOrFormErrors.contains(errorType)) {
      return "assets/images/icons/content_paste_off.png";
    }
    return "assets/images/icons/link_off.png";
  }

  static bool getConnectionStatus(WebResourceErrorType errorType){
    if(inputOrFormErrors.contains(errorType) ||
        loginOrPermissionErrors.contains(errorType) ||
        pageNotFoundErrors.contains(errorType) ||
        slowOrLostConnectionErrors.contains(errorType)||
        duplicateOrConflictErrors.contains(errorType) ||
        serverOrSystemFailureErrors.contains(errorType)){
      return false;
    }
    return true;
  }
}
