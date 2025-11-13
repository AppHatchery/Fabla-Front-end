// Error code groups and helper class
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
    if (inputOrFormErrors.contains(statusCode)) {
      return "Try Again";
    } else if (loginOrPermissionErrors.contains(statusCode)) {
      return "Contact Researcher";
    } else if (pageNotFoundErrors.contains(statusCode)) {
      return "";
    } else if (slowOrLostConnectionErrors.contains(statusCode)) {
      return "Try Again";
    } else if (duplicateOrConflictErrors.contains(statusCode)) {
      return "Try Again";
    } else if (serverOrSystemFailureErrors.contains(statusCode)) {
      return "Try Again";
    }
    return "Try Again";
  }
}