import 'dart:developer' as dev;

import 'package:url_launcher/url_launcher.dart';

import '../../screens/onboarding/domain/repository/setup_repository.dart';

Future<void> launchEmail({
  required String subject,
  required String body,
}) async {
  try {
    // Get experiment owner email
    final repository = SetupRepository();
    final experiment = repository.getExperiment();
    final ownerEmail = experiment.ownerEmail;

    // Use provided owner email or default
    final emailAddress = ownerEmail.isNotEmpty ? ownerEmail : "fabla@emory.edu";

    // Create the email URI
    final uri = Uri(
      scheme: "mailto",
      path: emailAddress,
        query: encodeQueryParameters(<String, String>{
        'subject': subject,
        'body': body,
      }),
    );

    // Launch the email client
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      dev.log('Could not launch email client');
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