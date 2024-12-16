import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/buttons.dart';
import '../components/checkboxes.dart';
import '../custom_colors.dart';
import '../custom_icons.dart';

/// Pop up for showing a tip to the user.
///
/// [title] is the title of the pop up. - String?
///
/// [messageOne] is the first message of the pop up. - String?
///
/// [iconOne] is the icon for the first message - String?
///
/// [messageTwo] is the second message of the pop up. - String?
///
/// [iconTwo] is the icon for the second message - String?
///
/// [image] is the image to display. - String?
class QuickTipPopUp extends StatefulWidget {
  final String title;
  final String image;
  final String messageOne;
  final String descriptionOne;
  final String iconOne;
  final String messageTwo;
  final String descriptionTwo;
  final String iconTwo;
  final bool? dontShowAgain;

  const QuickTipPopUp({
    super.key,
    required this.title,
    required this.image,
    required this.messageOne,
    required this.descriptionOne,
    required this.iconOne,
    required this.messageTwo,
    required this.descriptionTwo,
    required this.iconTwo,
    this.dontShowAgain,
  });

  @override
  State<QuickTipPopUp> createState() => _QuickTipPopUpState();
}

class _QuickTipPopUpState extends State<QuickTipPopUp> {
  bool dontShowAgain = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height * .8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 34),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              //Image
              SizedBox(
                  height: 100,
                  child: Image.asset(widget.image, fit: BoxFit.contain)),

              const SizedBox(height: 24),
              //Title
              Row(
                children: [
                  Expanded(
                      child: SizedBox(
                    child: Text(widget.title,
                        style: CustomTypography().headlineMedium(),
                        textAlign: TextAlign.center),
                  )),
                ],
              ),

              const SizedBox(height: 24),

              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                //Icon One
                SizedBox(
                    height: 30,
                    child: Image.asset(widget.iconOne, fit: BoxFit.contain)),
                const SizedBox(width: 10),
                //Message One
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.messageOne,
                          style: CustomTypography().titleSmallCustom(),
                          textAlign: TextAlign.start,
                        ),
                        Text(widget.descriptionOne,
                            style: CustomTypography().bodyLight(),
                            textAlign: TextAlign.start),
                      ]),
                )
              ]),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                //Icon Two
                SizedBox(
                    height: 30,
                    child: Image.asset(widget.iconTwo, fit: BoxFit.contain)),
                const SizedBox(width: 10),
                //MessageTwo
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.messageTwo,
                          style: CustomTypography().titleSmallCustom(),
                          textAlign: TextAlign.start,
                        ),
                        Text(
                          widget.descriptionTwo,
                          style: CustomTypography().bodyLight(),
                          textAlign: TextAlign.start,
                        ),
                      ]),
                )
              ]),

              const SizedBox(height: 32),

              Container(
                  alignment: Alignment.center,
                  child: IntrinsicWidth(
                    child: CustomCheckbox(
                        value: dontShowAgain,
                        label: "Don't show me again",
                        onChanged: (value) => {
                              setState(() {
                                dontShowAgain = value!;
                              }),
                            }),
                  )),

              const SizedBox(height: 12),

              CustomFlatButton(onClick: _save, text: "Got It!")
            ],
          ),
        ),
      ),
    );
  }

  void _save() async {
    await PreferenceService()
        .setBoolPreference(key: "show_home_tip", value: !dontShowAgain);

    if (mounted) Navigator.pop(context);
  }
}

/// Pop up for showing a tip to the user.
///
/// [title] is the title of the pop up. - String?
///
/// [message] is the message of the pop up. - String?
///
/// [image] is the image to display. - String?
class BottomTipPopUp extends StatefulWidget {
  final String title;
  final String message;
  final String image;
  final bool? dontShowAgain;

  const BottomTipPopUp({
    super.key,
    required this.title,
    required this.message,
    required this.image,
    this.dontShowAgain,
  });

  @override
  State<BottomTipPopUp> createState() => _BottomTipPopUpState();
}

class _BottomTipPopUpState extends State<BottomTipPopUp> {
  late bool? _dontShowAgain;

  @override
  void initState() {
    _dontShowAgain = widget.dontShowAgain;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      width: width,
      // color: CustomColors.fillWhite,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 34),
      constraints: const BoxConstraints.tightFor(),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          //Title
          Row(
            children: [
              // const Expanded(
              //     child: SizedBox(
              //   height: 24,
              //   width: 24,
              // )),
              Expanded(
                  child: SizedBox(
                child: Text(widget.title,
                    style: CustomTypography().headlineMedium(),
                    textAlign: TextAlign.center),
              )),
              // Expanded(
              //     child: GestureDetector(
              //   onTap: () => Navigator.pop(context),
              //   child: Container(
              //     height: 24,
              //     width: 24,
              //     alignment: Alignment.centerRight,
              //     child: const Icon(CustomIcons.close, color: Colors.black),
              //   ),
              // )),
            ],
          ),

          const SizedBox(height: 24),

          SizedBox(
              height: 100,
              child: Image.asset(widget.image, fit: BoxFit.contain)),

          const SizedBox(height: 24),

          //Message
          Text(widget.message,
              style: CustomTypography().bodyLarge(),
              textAlign: TextAlign.center),

          const SizedBox(height: 32),

          _dontShowAgain != null
              ? Container(
                  alignment: Alignment.center,
                  child: IntrinsicWidth(
                    child: CustomCheckbox(
                        value: _dontShowAgain!,
                        label: "Don't show me again",
                        onChanged: (value) => {
                              setState(() {
                                _dontShowAgain = value!;
                              }),
                            }),
                  ))
              : const SizedBox.shrink(),

          const SizedBox(height: 12),

          CustomFlatButton(onClick: _save, text: "Got It!")
        ],
      ),
    );
  }

  void _save() async {
    if (_dontShowAgain != null) {
      await PreferenceService()
          .setBoolPreference(key: "show_diary_tip", value: !_dontShowAgain!);
    }
    if (mounted) Navigator.pop(context);
  }
}

class CustomBottomTipPopUp extends StatefulWidget {
  const CustomBottomTipPopUp({super.key});

  @override
  State<CustomBottomTipPopUp> createState() => _CustomBottomTipPopUpState();
}

class _CustomBottomTipPopUpState extends State<CustomBottomTipPopUp> {
  bool dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * .8,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 34),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                  height: 100,
                  child: Image.asset('assets/images/idea.png',
                      fit: BoxFit.contain)),

              //Title
              const SizedBox(height: 24),
              Row(
                children: [
                  // const Expanded(
                  //     child: SizedBox(
                  //   height: 24,
                  //   width: 24,
                  // )),
                  Expanded(
                      child: SizedBox(
                    child: Text('Privacy and Audio Quality Assurance',
                        style: CustomTypography().headlineMedium(),
                        textAlign: TextAlign.center),
                  )),
                  // Expanded(
                  //     child: GestureDetector(
                  //   onTap: () => Navigator.pop(context),
                  //   child: Container(
                  //     height: 24,
                  //     width: 24,
                  //     alignment: Alignment.centerRight,
                  //     child: const Icon(CustomIcons.close, color: Colors.black),
                  //   ),
                  // )),
                ],
              ),

              const SizedBox(height: 32),

              //Message
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.privacy_tip_outlined, color: Colors.black),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your privacy matters',
                          style: CustomTypography()
                              .bodyLarge(weight: FontWeight.w600),
                        ),
                        Text(
                          'Participant anonymity is ensured using participant ID, not personal information, in all records and publications.',
                          style: CustomTypography().bodyLarge(
                              color: CustomColors.textTertiaryContent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chair_outlined, color: Colors.black),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quiet spot for clear recordings',
                          style: CustomTypography()
                              .bodyLarge(weight: FontWeight.w600),
                        ),
                        Text(
                          'Find a quiet place before we start so we can ensure the quality of the audio diary.',
                          style: CustomTypography().bodyLarge(
                              color: CustomColors.textTertiaryContent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Container(
                  alignment: Alignment.center,
                  child: IntrinsicWidth(
                    child: CustomCheckbox(
                        value: dontShowAgain,
                        label: "Don't show me again",
                        onChanged: (value) => {
                              setState(() {
                                dontShowAgain = value!;
                              }),
                            }),
                  )),

              const SizedBox(height: 12),

              CustomFlatButton(onClick: _save, text: "GOT IT!")
            ],
          ),
        ),
      ),
    );
  }

  void _save() async {
    await PreferenceService()
        .setBoolPreference(key: "show_diary_tip", value: !dontShowAgain);
    if (mounted) Navigator.pop(context);
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
  final List<Widget>? actions;

  const BottomResearcherInfoPopUp(
      {super.key,
      required this.studyName,
      required this.studyDescription,
      required this.organisation,
      required this.duration,
      required this.researcher,
      this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 34),
      constraints: BoxConstraints(maxHeight: height * 0.75, maxWidth: width),
      child: SingleChildScrollView(
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

            actions!.isNotEmpty
                ? Column(
                    children: actions!,
                  )
                : Container()

            //Confirmation
            // CustomElevatedButton(
            //     onClick: () => Navigator.pop(context), text: "CONFIRM JOINING"),
            // const SizedBox(
            //   height: 16,
            // ),
            // //Deny
            // CustomTextButton(
            //     onClick: () => Navigator.pop(context),
            //     text: "I have a problem with joining the study")
          ],
        ),
      ),
    );
  }
}

class BottomStudyInfoPopUp extends StatelessWidget {
  final String studyName;
  final String organisation;
  final String duration;
  final String description;
  final String researcher;

  const BottomStudyInfoPopUp(
      {super.key,
      required this.studyName,
      required this.organisation,
      required this.duration,
      required this.description,
      required this.researcher});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 34),
      decoration: const BoxDecoration(
          color: CustomColors.fillWhite,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      constraints: BoxConstraints(maxHeight: height * 0.75, maxWidth: width),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                const Expanded(
                  flex: 1,
                  child: SizedBox(),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Study Information",
                    style: CustomTypography().headlineMedium(),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 24,
            ),

            // Study Name
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.doc_plaintext, size: 16),
                const SizedBox(
                  width: 12,
                ),
                Text(
                  studyName,
                  style: CustomTypography().bodyMedium(),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
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
            CustomFormatterText(
              text: description,
            )
          ],
        ),
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
                      text: "Cancel",
                      color: CustomColors.greyLight,
                    ),
                  ),
                  const SizedBox(
                    width: 18,
                  ),
                  Expanded(
                    child: CustomFlatButton(
                      onClick: () => Navigator.pop(context),
                      text: "Change Response",
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
class RedoPopUp extends StatefulWidget {
  const RedoPopUp({super.key});

  @override
  State<RedoPopUp> createState() => _RedoPopUpState();
}

class _RedoPopUpState extends State<RedoPopUp> {
  bool _dontShowAgain = false;

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
                        value: _dontShowAgain,
                        label: "Don't show me again",
                        onChanged: (value) {
                          setState(() {
                            _dontShowAgain = value!;
                          });
                        }),
                  )),

              const SizedBox(
                height: 24,
              ),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomFlatButton(
                      onClick: () => Navigator.pop(context, false),
                      text: "Cancel",
                      color: CustomColors.greyLight,
                    ),
                  ),
                  const SizedBox(
                    width: 18,
                  ),
                  Expanded(
                    child: CustomFlatButton(
                      onClick: () => Navigator.pop(context, true),
                      text: "Yes",
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

/// Pop up for when the user wants to delete their answer.
class DeletePopUp extends StatelessWidget {
  final String? title;
  final String? subheader;
  const DeletePopUp({super.key, this.title, this.subheader});

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
                title ?? "Delete your response?",
                style: CustomTypography().headlineMedium(),
                textAlign: TextAlign.center,
              ),

              const SizedBox(
                height: 24,
              ),

              // Message
              Text(
                subheader ??
                    "Deleting a reply only deletes the recording on the device. Continue deleting?",
                style: CustomTypography().bodyLarge(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 24,
              ),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomFlatButton(
                      onClick: () => Navigator.pop(context, false),
                      text: "Cancel",
                      color: CustomColors.greyLight,
                    ),
                  ),
                  const SizedBox(
                    width: 18,
                  ),
                  Expanded(
                    child: CustomFlatButton(
                      onClick: () => Navigator.pop(context, true),
                      text: "Delete",
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

class ExitPopUp extends StatelessWidget {
  final String title;
  final String subheader;
  const ExitPopUp({super.key, required this.title, required this.subheader});

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
                title,
                style: CustomTypography().headlineMedium(),
                textAlign: TextAlign.center,
              ),

              const SizedBox(
                height: 24,
              ),

              // Message
              Text(
                subheader,
                style: CustomTypography().bodyLarge(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 24,
              ),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomFlatButton(
                      onClick: () => Navigator.pop(context, false),
                      text: "Dismiss",
                      color: CustomColors.greyLight,
                      borderColor: CustomColors.greyLight,
                    ),
                  ),
                  const SizedBox(
                    width: 18,
                  ),
                  Expanded(
                    child: CustomFlatButton(
                      onClick: () => Navigator.pop(context, true),
                      text: "Exit",
                      color: CustomColors.warningActive,
                      borderColor: CustomColors.warningActive,
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
