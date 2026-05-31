// import 'dart:developer' as dev;
//
// import 'package:url_launcher/url_launcher.dart';
//
// import '../../screens/onboarding/domain/repository/setup_repository.dart';

// Future<void> launchEmail({
//   required String subject,
//   required String body,
// }) async {
//   try {
//     // Get experiment owner email
//     final repository = SetupRepository();
//     final experiment = repository.getExperiment();
//     final ownerEmail = experiment.ownerEmail;
//
//     const emailAddress = "fabla@emory.edu";
//
//     final queryParams = {
//       'subject': subject,
//       'body': body,
//     };
//
//     // CC only if ownerEmail exists and is not empty
//     if (ownerEmail.isNotEmpty) {
//       queryParams['cc'] = ownerEmail;
//     }
//
//     final uri = Uri(
//       scheme: "mailto",
//       path: emailAddress,
//       query: encodeQueryParameters(queryParams),
//     );
//
//     // Launch the email client
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     } else {
//       dev.log('Could not launch email client for: $uri');
//     }
//   } catch (e) {
//     dev.log('Error launching email: $e');
//   }
// }
//
// String? encodeQueryParameters(Map<String, String> params) {
//   return params.entries
//       .map((MapEntry<String, String> e) =>
//   '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
//       .join('&');
// }

import 'dart:developer' as dev;
import 'dart:io' show Platform;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../screens/onboarding/domain/repository/setup_repository.dart';


class EmailLauncher {
  static const String supportEmail = "fabla@emory.edu";

  // For login screen
  static Future<void> launchLoginEmail({
    String issueDescription = "",
  }) async {
    try {
      final repository = SetupRepository();
      final experiment = repository.getExperiment();
      final ownerEmail = experiment.ownerEmail;

      const subject = "Fabla Participant Login Issue";

      final appVersion = await _getAppVersion();
      final deviceInfo = await _getDeviceInfo();

      final body = """

Describe the issue you are facing: $issueDescription

App Version: $appVersion
Device and OS: $deviceInfo
""";

      final queryParams = <String, String>{
        'subject': subject,
        'body': body,
      };

      // CC the researcher if email exists
      if (ownerEmail.isNotEmpty) {
        queryParams['cc'] = ownerEmail;
      }

      final uri = Uri(
        scheme: "mailto",
        path: supportEmail,
        query: _encodeQueryParameters(queryParams),
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        dev.log('Could not launch email client for: $uri');
      }
    } catch (e) {
      dev.log('Error launching email: $e');
    }
  }

  // For in-app contact "Contact Researcher" after login
  static Future<void> launchParticipantEmail({
    required String studyString,
    required String participantId,
    required String dateJoined,
    String? dateLastUpdated,
    String issueDescription = "",
  }) async {
    try {
      final repository = SetupRepository();
      final experiment = repository.getExperiment();
      final ownerEmail = experiment.ownerEmail;

      final subject = "Fabla Participant Issue $studyString $participantId";

      final appVersion = await _getAppVersion();
      final deviceInfo = await _getDeviceInfo();

      final body = """
Describe the issue you are facing: $issueDescription

Study String: $studyString
Participant ID: $participantId
Date Joined: $dateJoined
Date last updated: ${dateLastUpdated ?? 'N/A'}

App Version: $appVersion
Device and OS: $deviceInfo
""";
      final queryParams = <String, String>{
        'subject': subject,
        'body': body,
      };
      if (ownerEmail.isNotEmpty) {
        queryParams['cc'] = ownerEmail;
      }

      final uri = Uri(
        scheme: "mailto",
        path: supportEmail,
        query: _encodeQueryParameters(queryParams),
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        dev.log('Could not launch email client for: $uri');
      }
    } catch (e) {
      dev.log('Error launching email: $e');
    }
  }

  // Helper methods
  static Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return "${packageInfo.version} (${packageInfo.buildNumber})";
    } catch (e) {
      return "Unknown";
    }
  }

  static Future<String> _getDeviceInfo() async {
    try {
      return "${Platform.operatingSystem} ${Platform.operatingSystemVersion}";
    } catch (e) {
      return "Unknown";
    }
  }

  static String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}


@Deprecated('Use EmailLauncher.launchLoginEmail() or EmailLauncher.launchParticipantEmail() instead')
Future<void> launchEmail({
  required String subject,
  required String body,
}) async {
  try {
    final repository = SetupRepository();
    final experiment = repository.getExperiment();
    final ownerEmail = experiment.ownerEmail;

    const emailAddress = "fabla@emory.edu";

    final queryParams = {
      'subject': subject,
      'body': body,
    };

    if (ownerEmail.isNotEmpty) {
      queryParams['cc'] = ownerEmail;
    }

    final uri = Uri(
      scheme: "mailto",
      path: emailAddress,
      query: encodeQueryParameters(queryParams),
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      dev.log('Could not launch email client for: $uri');
    }
  } catch (e) {
    dev.log('Error launching email: $e');
  }
}

String? encodeQueryParameters(Map<String, String> params) {
  return params.entries
      .map((MapEntry<String, String> e) =>
  '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
}