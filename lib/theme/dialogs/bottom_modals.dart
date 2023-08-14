import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:flutter/material.dart';

import '../components/buttons.dart';
import '../custom_icons.dart';
import '../custom_typography.dart';
import '../resources/strings.dart';

final tabs = [
  Tab(
    child: SizedBox(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            const Icon(CustomIcons.graphicEq),
            const SizedBox(
              width: 5,
            ),
            Text(
              "Audio",
              style: CustomTypography().bodyMedium(),
            )
          ],
        ),
      ),
    ),
  ),
  Tab(
    child: SizedBox(
      height: 32,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            const Icon(CustomIcons.sort),
            const SizedBox(
              width: 5,
            ),
            Text(
              "Transcript",
              style: CustomTypography().bodyMedium(),
            )
          ],
        ),
      ),
    ),
  ),
];

/// Bottom Modal for when the user needs to record.
class BottomRecordingModal extends StatefulWidget {
  const BottomRecordingModal({super.key});

  @override
  State<BottomRecordingModal> createState() => _BottomRecordingModalState();
}

class _BottomRecordingModalState extends State<BottomRecordingModal>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    tabController = TabController(length: tabs.length, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight / 2,
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 30),
              height: (screenHeight / 2) - 130,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  )),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //Tab Indicator
                  tabIndicatos(),

                  // Title & Rename Button
                  recordingTitle(),

                  // Timer
                  recordingTimer(),

                  // Waveform & Transcript
                  waveFormAndTranscript(),

                  // Controls
                  recordingControls(),
                ],
              ),
            ),
          ),

          // Avatar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 19.86),
                    height: 150,
                    child: Image.asset("assets/images/avatar_listening.png"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget tabIndicatos() {
    return SizedBox(
      child: TabBar(
          isScrollable: true,
          controller: tabController,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorColor: Colors.transparent,
          labelColor: CustomColors.productNormalActive,
          unselectedLabelColor: CustomColors.textTertiaryContent,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: CustomColors.productLightPrimaryActive,
          ),
          padding: EdgeInsets.zero,
          indicatorPadding: EdgeInsets.zero,
          labelPadding: EdgeInsets.zero,
          tabs: tabs),
    );
  }

  Widget recordingTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "New Diary",
          style: CustomTypography().headlineMedium(),
        ),
        const SizedBox(
          width: 5,
        ),
        const IconButton(onPressed: null, icon: Icon(CustomIcons.editNote))
      ],
    );
  }

  Widget recordingTimer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 15,
          width: 15,
          decoration: const BoxDecoration(
              color: CustomColors.warningActive, shape: BoxShape.circle),
        ),
        const SizedBox(
          width: 5,
        ),
        Text(
          "00:34:33",
          style: CustomTypography().bodyLarge(),
        )
      ],
    );
  }

  Widget waveFormAndTranscript() {
    return Expanded(
        child: TabBarView(
      physics: const NeverScrollableScrollPhysics(),
      controller: tabController,
      children: [
        Container(
          color: Colors.red,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
          child: SingleChildScrollView(
              child: Text(
            Strings.lorem,
            style: CustomTypography().bodyMedium(),
          )),
        ),
      ],
    ));
  }

  Widget recordingControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        //Redo
        TextButton(
            onPressed: null,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 31.0, vertical: 9.5),
              child: Text("Redo",
                  style: CustomTypography()
                      .button(color: CustomColors.textSecondaryContent)),
            )),

        //Play Pause Resume
        IconButton(
            onPressed: null,
            icon: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                    horizontal: 44, vertical: 14.5),
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.red, width: 2),
                ),
                child: const Icon(CustomIcons.pause))),

        IconButton(
            onPressed: null,
            icon: Container(
              height: 60,
              width: 60,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: CustomColors.textTertiaryContent, width: 2)),
              child: Container(
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: CustomColors.warningActive),
              ),
            )),

        //Save
        TextButton(
            onPressed: () => {Navigator.pop(context)},
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 31.0, vertical: 9.5),
              child: Text("Save",
                  style: CustomTypography()
                      .button(color: CustomColors.textSecondaryContent)),
            )),
      ],
    );
  }
}

/// Bottom Modal for when the user has successfull answered a prompt.
class BottomSuccessModal extends StatelessWidget {
  const BottomSuccessModal({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SizedBox(
      child: Container(
          constraints: const BoxConstraints.tightFor(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 34),
          width: width,
          decoration: const BoxDecoration(
            color: CustomColors.productLightBackground,
          ),
          child: Wrap(
            children: [
              Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          CustomIcons.checkCircle,
                          color: CustomColors.productNormalActive,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text("Great!",
                            style: CustomTypography().headlineMedium(
                                color: CustomColors.productNormalActive)),
                      ],
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      "Your response has been automatically saved.",
                      style: CustomTypography()
                          .body(color: CustomColors.productNormalActive),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: CustomElevatedButton(
                                onClick: () => Navigator.pop(context),
                                text: "CONTINUE"),
                          ),
                        ),
                      ],
                    ),
                  ]),
            ],
          )),
    );
  }
}

/// Bottom modal for error
class BottomErrorModal extends StatelessWidget {
  const BottomErrorModal({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SizedBox(
      child: Container(
          constraints: const BoxConstraints.tightFor(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 34),
          width: width,
          decoration: const BoxDecoration(
            color: CustomColors.warningFill,
          ),
          child: Wrap(
            children: [
              Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          CustomIcons.cancel,
                          color: CustomColors.warningActive,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text("Error",
                            style: CustomTypography().headlineMedium(
                                color: CustomColors.warningActive)),
                      ],
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text("We didn’t detect your answer.",
                        style: CustomTypography()
                            .body(color: CustomColors.warningActive)),
                    const SizedBox(
                      height: 24,
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: CustomElevatedButton(
                            onClick: () => Navigator.pop(context),
                            text: "TRY AGAIN",
                            color: CustomColors.warningActive,
                            shadowColor: const Color(0xFFC72C1E),
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: CustomElevatedIconButton(
                            icon: Icons.help_outline_rounded,
                            onClick: null,
                            color: CustomColors.warningFill,
                            shadowColor: const Color(0xFFC72C1E),
                            iconColor: CustomColors.warningActive,
                            border: Border.all(
                                color: CustomColors.warningActive, width: 1),
                            elevation: 2.5,
                          ),
                        )
                      ],
                    ),
                  ]),
            ],
          )),
    );
  }
}
