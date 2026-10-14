import 'package:flutter/material.dart';
import '../../../../core/diagnostics/debug_trace.dart';
import '../../../../core/utils/participant_experiment_details.dart';
import '../../../../main.dart';
import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';
import 'submission_debug_panel.dart';

class SubmitErrorPage extends StatefulWidget {
  /// The failed submission's trace, shown in developer mode.
  final DebugTrace? trace;

  const SubmitErrorPage({super.key, this.trace});

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
                      // Scrolls so the expanded debug panel fits; stays
                      // centred when short.
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
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
                                    "fabla@emory.edu",
                                    style: TextStyle(
                                        fontSize: CustomTypography()
                                            .bodyMedium()
                                            .fontSize,
                                        fontWeight: CustomTypography()
                                            .bodyMedium()
                                            .fontWeight,
                                        decoration: TextDecoration.underline,
                                        decorationColor:
                                            CustomColors.productNormal,
                                        color: CustomColors.productNormal),
                                  )),
                              DeveloperModeDebugPanel(trace: widget.trace),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: CustomFlatButton(
                        onClick: () {
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Hub(),
                                  settings: RouteSettings(name: "/Hub")),
                              (route) => false);
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
    await ParticipantAndExperimentDetails().launchSupportEmail(
        subject: 'Had an error submitting my diary',
        body: 'I had a problem submitting my diary on day   ',
        example: '');
  }
}
