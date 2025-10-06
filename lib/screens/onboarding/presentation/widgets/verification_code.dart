import 'dart:developer' as dev;

import 'package:audio_diaries_flutter/theme/components/textfields.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/database/dao/experiment_dao.dart';
import '../../../../main.dart';
import '../../../../objectbox.g.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_icons.dart';
import '../../../../theme/custom_typography.dart';

import '../../../home/domain/entities/experiment.dart';
import '../../domain/repository/setup_repository.dart';

class VerificationCodeTextField extends StatefulWidget {
  final String title;
  final String errorMessage;
  final String hint;
  final TextEditingController? controller;
  final TextInputType fieldType;
  final bool error;
  final String warningMessage;
  final bool warning;
  const VerificationCodeTextField(
      {super.key,
      required this.title,
      required this.errorMessage,
      required this.hint,
      this.controller,
      this.fieldType = TextInputType.text,
      this.error = false,
      required this.warningMessage,
      this.warning = false});

  @override
  State<VerificationCodeTextField> createState() =>
      _VerificationCodeTextFieldState();
}

final ExperimentDAO _experimentDAO =
    ExperimentDAO(box: Box<Experiment>(objectbox.store));

class _VerificationCodeTextFieldState extends State<VerificationCodeTextField> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: CustomTypography().titleSmall(color: CustomColors.textWhite),
        ),
        const SizedBox(
          height: 6,
        ),
        CustomTextField(
          keyboardType: widget.fieldType,
          controller: widget.controller,
          error: widget.error,
          hint: widget.hint,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          filled: true,
          borderColor:
              widget.warning ? CustomColors.pumpkinOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          borderWidth: widget.warning ? 2 : 0,
          suffix: IconButton(
              onPressed: () => widget.controller!.clear(),
              icon: const Icon(
                CustomIcons.cancel,
                size: 20,
              ),
              color: CustomColors.productBorderNormal),
        ),
        // const SizedBox(
        //   height: 12,
        // ),
        widget.warning
            ? Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Container(
                  width: width,
                  padding: const EdgeInsets.all(16),
                  decoration: ShapeDecoration(
                      color: CustomColors.fillVanilla,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      )),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        size: 24,
                        color: CustomColors.pumpkinOrange, // Same orange
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 8,
                            children: [
                              Text(
                                "Participant ID Already in Use",
                                style: CustomTypography().bodyLarge(
                                    color: CustomColors.pumpkinOrange,
                                    weight: FontWeight.w700),
                              ),
                              Column(
                                children: [
                                  Text(
                                    widget.warningMessage,
                                    style: CustomTypography().bodyLarge(
                                      color: CustomColors.pumpkinOrange,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 45,
                                          decoration: ShapeDecoration(
                                            color: CustomColors.pumpkinOrange,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(11),
                                            ),
                                          ),
                                          child: TextButton(
                                            onPressed: () => launchEmail(),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      8, 4, 8, 8),
                                              child: Text(
                                                "Contact Researcher",
                                                style: CustomTypography()
                                                    .bodyLarge(
                                                  color:
                                                      CustomColors.fillVanilla,
                                                  weight: FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(),
        widget.error
            ? Container(
                width: width,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CustomColors.warningFill,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(CustomIcons.cancel,
                        size: 20, color: CustomColors.warningActive),
                    const SizedBox(
                      width: 10,
                    ),
                    Flexible(
                      child: Text(
                        widget.errorMessage,
                        style: CustomTypography()
                            .bodyLarge(color: CustomColors.warningActive),
                      ),
                    )
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}

// launch email to experiment owner email
Future<void> launchEmail() async {
  try {
    //get experiment owner email
    final repository = SetupRepository();
    final experiment = repository.getExperiment();
    final ownerEmail = experiment.ownerEmail;

    if (ownerEmail.isEmpty) {
      dev.log('No owner email found');
      return;
    }

    dev.log(ownerEmail);

    //create the email uri
    final uri = Uri(
      scheme: "mailto",
      path: ownerEmail,
      query: encodeQueryParameters(<String, String>{
        'subject': 'Assistance Needed: Participant ID Already in Use',
        'body':
            ''' Participant ID entered is already in use. Please confirm or advise next steps.
        
        
Name: '''
      }),
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

String? encodeQueryParameters(Map<String, String> params) {
  return params.entries
      .map((MapEntry<String, String> e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
}
