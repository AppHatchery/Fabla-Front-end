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

    final emailAddress = ownerEmail;

    final queryParams = {
      'subject': subject,
      'body': body,
    };

    // CC only fabla@emory.edu
    queryParams['cc'] = "fabla@emory.edu";


    final uri = Uri(
      scheme: "mailto",
      path: emailAddress,
      query: encodeQueryParameters(queryParams),
    );

    // Launch the email client
    if (await canLaunchUrl(uri)) {
      dev.log(ownerEmail);
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