import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';

import '../components/buttons.dart';
import '../components/checkboxes.dart';
import '../custom_colors.dart';
import '../custom_icons.dart';

/// Pop up for showing a tip to the user.
///
/// [title] is the title of the pop up. - String?
///
/// [message] is the message of the pop up. - String?
///
/// [image] is the image to display. - String?
class BottomTipPopUp extends StatelessWidget {
  final String title;
  final String message;
  final String image;
  const BottomTipPopUp(
      {super.key,
      required this.title,
      required this.message,
      required this.image});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 34),
      constraints: const BoxConstraints.tightFor(),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          //Title
          Row(
            children: [
              const Expanded(
                  child: SizedBox(
                height: 24,
                width: 24,
              )),
              Expanded(
                  child: SizedBox(
                child: Text(title,
                    style: CustomTypography().headlineMedium(),
                    textAlign: TextAlign.center),
              )),
              Expanded(
                  child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 24,
                  width: 24,
                  alignment: Alignment.centerRight,
                  child: const Icon(CustomIcons.close, color: Colors.black),
                ),
              )),
            ],
          ),

          const SizedBox(height: 12),

          //Message
          Text(message,
              style: CustomTypography().bodyLarge(),
              textAlign: TextAlign.center),

          const SizedBox(height: 24),

          SizedBox(height: 150, child: Image.asset(image, fit: BoxFit.contain)),

          const SizedBox(height: 24),

          Container(
              alignment: Alignment.center,
              child: IntrinsicWidth(
                child: CustomCheckbox(
                    value: true,
                    label: "Don't show me again",
                    onChanged: (value) => print(value)),
              )),

          const SizedBox(height: 17),

          CustomElevatedButton(
              onClick: () => Navigator.pop(context), text: "GOT IT!")
        ],
      ),
    );
  }
}

/// Pop up for showing the research information.
///
/// [studyName] is the name of the study. - String?
///
/// [studyDescription] is the description of the study. - String?
///
/// [organisation] is the organisation of the study. - String?
///
/// [duration] is the duration of the study. - String?
///
/// [researcher] is the researcher of the study. - String?
class BottomResearcherInfoPopUp extends StatelessWidget {
  final String studyName;
  final String studyDescription;
  final String organisation;
  final String duration;
  final String researcher;
  const BottomResearcherInfoPopUp(
      {super.key,
      required this.studyName,
      required this.studyDescription,
      required this.organisation,
      required this.duration,
      required this.researcher});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 34),
      constraints: const BoxConstraints.tightFor(),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Study Name
          Text(
            studyName,
            style: CustomTypography().titleMedium(),
            textAlign: TextAlign.center,
          ),

          const SizedBox(
            height: 24,
          ),

          // Organisation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CustomIcons.assuredWorkload, size: 16),
              const SizedBox(
                width: 12,
              ),
              Text(
                organisation,
                style: CustomTypography().bodyMedium(),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          // Duration
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CustomIcons.calendarMonth, size: 16),
              const SizedBox(
                width: 12,
              ),
              Text(
                duration,
                style: CustomTypography().bodyMedium(),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          // Researcher
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CustomIcons.person, size: 16),
              const SizedBox(
                width: 12,
              ),
              Text(
                researcher,
                style: CustomTypography().bodyMedium(),
              ),
            ],
          ),

          const SizedBox(
            height: 24,
          ),

          // Study Description
          SizedBox(
              child: Text(
            studyDescription,
            style: CustomTypography().bodyMedium(),
          )),

          const SizedBox(
            height: 32,
          ),

          //Confirmation
          CustomElevatedButton(
              onClick: () => Navigator.pop(context), text: "CONFIRM JOINING"),
          const SizedBox(
            height: 16,
          ),
          //Deny
          CustomTextButton(
              onClick: () => Navigator.pop(context),
              text: "I have a problem with joining the study")
        ],
      ),
    );
  }
}

/// Pop up for when confirming the user's actions.
///
/// [title] is the title of the pop up. - String?
///
/// [message] is the message of the pop up. - String?
///
/// [buttonText] is the text of the button. - String?
class ConfirmationPopUp extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  const ConfirmationPopUp(
      {super.key,
      required this.title,
      required this.message,
      required this.buttonText});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.grey, width: 1)),
      surfaceTintColor: CustomColors.fillWhite,
      children: [
        Container(
          constraints: const BoxConstraints.tightFor(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 80,
                width: 80,
                child: Icon(CustomIcons.checkCircle,
                    size: 67, color: CustomColors.productNormal),
              ),
              const SizedBox(
                height: 24,
              ),
              // Title
              Text(
                title,
                style: CustomTypography().headlineMedium(),
              ),

              const SizedBox(
                height: 24,
              ),

              // Message
              Text(message,
                  style: CustomTypography().bodyLarge(),
                  textAlign: TextAlign.center),

              const SizedBox(
                height: 24,
              ),

              // Button
              CustomElevatedButton(
                  onClick: () => Navigator.pop(context), text: buttonText)
            ],
          ),
        ),
      ],
    );
  }
}

/// Pop up for showing multiple tips to the user.
///
/// [title] is the title of the pop up. - String?
///
/// [message] is the message of the pop up. - String?
///
/// [tips] is the list of tips to be displayed. - String?
///
/// [buttonText] is the text of the button. - String?
class TipsPopUp extends StatelessWidget {
  final String title;
  final String message;
  final List<String?> tips;
  final String buttonText;
  const TipsPopUp(
      {super.key,
      required this.title,
      required this.message,
      required this.tips,
      required this.buttonText});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.grey, width: 1)),
      surfaceTintColor: CustomColors.fillWhite,
      children: [
        Container(
          constraints: const BoxConstraints.tightFor(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 80,
                width: 80,
                child: Icon(CustomIcons.tipsAndUpdates,
                    size: 67, color: CustomColors.productNormal),
              ),
              const SizedBox(
                height: 24,
              ),
              // Title
              Text(
                title,
                style: CustomTypography().headlineMedium(),
              ),

              const SizedBox(
                height: 24,
              ),

              // Message
              Text(message,
                  style: CustomTypography()
                      .bodyLarge(color: CustomColors.textTertiaryContent),
                  textAlign: TextAlign.center),

              const SizedBox(
                height: 24,
              ),

              //Tips
              for (var tip in tips)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    decoration: BoxDecoration(
                        color: CustomColors.productLightBackground
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(
                          CustomIcons.lightbulb,
                          size: 24,
                          color: CustomColors.textSecondaryContent,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                            child: Text(
                          tip.toString(),
                          style: CustomTypography().bodyLarge(
                              color: CustomColors.textSecondaryContent),
                        )),
                      ],
                    ),
                  ),
                ),

              const SizedBox(
                height: 24,
              ),

              // Button
              CustomElevatedButton(
                  onClick: () => Navigator.pop(context), text: buttonText)
            ],
          ),
        ),
      ],
    );
  }
}

/// Pop up for when the user wants to change their answer.
class WarningPopUp extends StatelessWidget {
  const WarningPopUp({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.grey, width: 1)),
      surfaceTintColor: CustomColors.fillWhite,
      children: [
        Container(
          constraints: const BoxConstraints.tightFor(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              Text(
                "Change Your Response?",
                style: CustomTypography().headlineMedium(),
              ),

              const SizedBox(
                height: 24,
              ),

              // Message
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                    style: CustomTypography().bodyLarge(),
                    children: const [
                      TextSpan(
                          text:
                              "Changing the first answer in multiple questions will change the subsequent questions and "),
                      TextSpan(
                          text: "your previous responses will be deleted.",
                          style: TextStyle(fontWeight: FontWeight.bold))
                    ]),
              ),

              const SizedBox(
                height: 24,
              ),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomFlatButton(
                      onClick: () => Navigator.pop(context),
                      text: "CANCEL",
                      color: CustomColors.greyLight,
                    ),
                  ),
                  const SizedBox(
                    width: 18,
                  ),
                  Expanded(
                    child: CustomFlatButton(
                      onClick: () => Navigator.pop(context),
                      text: "CHANGE RESPONSE",
                      color: CustomColors.warningActive,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }
}

/// Pop up for when the user wants to redo their answer.
class RedoPopUp extends StatelessWidget {
  const RedoPopUp({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.grey, width: 1)),
      surfaceTintColor: CustomColors.fillWhite,
      children: [
        Container(
          constraints: const BoxConstraints.tightFor(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              Text(
                "Redo Your Answer?",
                style: CustomTypography().headlineMedium(),
              ),

              const SizedBox(
                height: 24,
              ),

              // Message
              Text(
                "This will erase your current answer. Would you still like to redo it?",
                style: CustomTypography().bodyLarge(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 24,
              ),

              //Checkbox
              Container(
                  alignment: Alignment.center,
                  child: IntrinsicWidth(
                    child: CustomCheckbox(
                        value: true,
                        label: "Don't show me again",
                        onChanged: (value) => print(value)),
                  )),

              const SizedBox(
                height: 24,
              ),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomFlatButton(
                      onClick: () => Navigator.pop(context),
                      text: "CANCEL",
                      color: CustomColors.greyLight,
                    ),
                  ),
                  const SizedBox(
                    width: 18,
                  ),
                  Expanded(
                    child: CustomFlatButton(
                      onClick: () => Navigator.pop(context),
                      text: "YES",
                      color: CustomColors.warningActive,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }
}
