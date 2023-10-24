import 'package:flutter/material.dart';

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
                            "Don't worry! We're here to help. Please reach out to us at [our@email.com] for assistance.",
                            style: CustomTypography().bodyLarge(
                              color: CustomColors.textSecondaryContent,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: CustomFlatButton(
                        onClick: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Hub()));
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
}
