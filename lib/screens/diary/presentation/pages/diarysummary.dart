import 'package:audio_diaries_flutter/main.dart';
import 'package:audio_diaries_flutter/theme/custom_icons.dart';
import 'package:flutter/material.dart';

import '../../../../theme/components/buttons.dart';
import '../../../../theme/components/cards.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';
import 'diarycompletion.dart';

///This page holds all the questions that have been answered by the user
///Currently only takes a string as a parameter, later to be replaced by a list of questions and answers
///No functionality for the Add a new response button
class DiarySummaryPage extends StatelessWidget {
  final String? text;

  const DiarySummaryPage({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.fillNormal,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: CustomColors.fillNormal,
        leading:  IconButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Hub())
            );
          },
          icon: const Icon(CustomIcons.close),
          iconSize: 15.0,
        ),
        title: Text(
          "My Responses",
          style: CustomTypography().titleMedium(
            color: CustomColors.textNormalContent,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              "Review your responses",
              style: CustomTypography()
                  .headlineMedium(color: CustomColors.textNormalContent),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
              child: ListView.builder(
                  itemCount: 2,
                  itemBuilder: (BuildContext context, int index) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text.toString(),
                          style: CustomTypography().titleMedium(
                              color: CustomColors.textNormalContent),
                        ),
                        const SizedBox(height: 12),
                        const AudioDiaryCard(
                          path: "",
                        ),
                        const SizedBox(height: 12),
                        CustomElevatedButton(
                          onClick: () { },
                          text: "ADD A NEW RESPONSE",
                          color: CustomColors.productLightPrimaryNormalWhite,
                          textColor: CustomColors.productNormal,
                          shadowColor: CustomColors.productBorderNormal,
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }
                  )
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: CustomElevatedButton(
              onClick: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DiaryCompletionPage())
                );
              },
              text: "SUBMIT MY RESPONSE",
              color: CustomColors.productNormal,
              textColor: CustomColors.textWhite,
              shadowColor: CustomColors.productNormalActive,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
