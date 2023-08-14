import 'package:audio_diaries_flutter/screens/home/presentation/widgets/todays_diary_list.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/unsubmitted_diary_list.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/components/cards.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../theme/dialogs/pop_ups.dart';
import '../../../../theme/resources/strings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar: AppBar(
          toolbarHeight: 105.h,
          backgroundColor: CustomColors.productNormal,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              width: width,
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hi, Christopher",
                          style: CustomTypography()
                              .headlineLarge(color: CustomColors.fillWhite),
                        ),
                        Text(
                          "Welcome back ${Strings.wavingEmoji}",
                          style: CustomTypography()
                              .bodyLarge(color: CustomColors.fillWhite),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 12),
                      child: CustomElevatedIconButton(
                        onClick: () => showResearchInformation(),
                        icon: Icons.sticky_note_2,
                        color: CustomColors.fillWhite,
                        iconColor: CustomColors.productNormal,
                        shadowColor: CustomColors.productNormalActive,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: ListView(
            children: const [
              CalendaerCard(),

              SizedBox(height: 24,),


              UnsubmittedDiaryList(),

              SizedBox(height: 24,),

              TodaysDiaryList(),
            ],
          ),
        ));
  }

  void showResearchInformation() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Wrap(
              children: [
                BottomResearcherInfoPopUp(
                    studyName: "Audio Diary Study for Emotional Regulation.  ",
                    studyDescription: Strings.studyDescription,
                    organisation: "Emory School of Medicine",
                    duration: "Oct 2022 - Aug 2023",
                    researcher: "Dr. Jane Doe")
              ],
            ));
  }

}
