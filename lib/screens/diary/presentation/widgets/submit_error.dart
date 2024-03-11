import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../main.dart';
import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';

class SubmitErrorPage extends StatefulWidget {
  const SubmitErrorPage({super.key});

  @override
  State<SubmitErrorPage> createState() => _SubmitErrorPageState();
}

class _SubmitErrorPageState extends State<SubmitErrorPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 30.0, vertical: 12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error,
                            color: CustomColors.warningActive,
                            size: 48,
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                          Text(
                            "Oops! Something went wrong.",
                            style: CustomTypography().headlineMedium(
                                color: CustomColors.textSecondaryContent),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            "Don't worry! We're here to help. Please reach out for assistance at",
                            style: CustomTypography().bodyLarge(
                              color: CustomColors.textSecondaryContent,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          GestureDetector(
                              onTap: () => launchEmail(),
                              child: Text(
                                "support@apphatchery.org",
                                style: TextStyle(
                                    fontSize:
                                    CustomTypography().bodyMedium().fontSize,
                                    fontWeight: CustomTypography()
                                        .bodyMedium()
                                        .fontWeight,
                                    decoration: TextDecoration.underline,
                                    decorationColor: CustomColors.productNormal,
                                    color: CustomColors.productNormal),
                              )
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: CustomFlatButton(
                        onClick: () {
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Hub()), (route) => false);
                        },
                        text: "Return Home",
                        color: CustomColors.productNormal,
                        textColor: CustomColors.textWhite,
                      ),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                  ],
                ))));
  }

  Future<void> launchEmail() async {
    final uri = Uri(
        scheme: "mailto",
        path: "support@apphatchery.org",
        query: encodeQueryParameters(<String, String>{
          'subject': 'Had an error submitting my diary',
          'body': 'I had a problem submitting my diary on day: '
        }));

    await launchUrl(uri);
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
