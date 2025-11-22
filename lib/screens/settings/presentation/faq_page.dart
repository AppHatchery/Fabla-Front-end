import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.fillNormal,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: CustomColors.fillNormal,
        scrolledUnderElevation: 0.0,
        title: Text(
          "FAQs",
          style: CustomTypography().titleLarge(),
        ),
        centerTitle: true,
        leading: IconButton(
            key: Key("back_button"),
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 32,
            )),
        shape: const Border(
            bottom: BorderSide(
          color: CustomColors.productBorderNormal,
          width: 2,
        )),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ...questions.map((question) => ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12.0),
                    title: Text(
                      question,
                      style: CustomTypography()
                          .bodyLarge(color: CustomColors.textNormalContent),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        child: Text(
                          "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                          style: CustomTypography().bodyMedium(
                              color: CustomColors.textTertiaryContent),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        child: Text(
                          "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                          style: CustomTypography().bodyMedium(
                              color: CustomColors.textTertiaryContent),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        child: Text(
                          "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                          style: CustomTypography().bodyMedium(
                              color: CustomColors.textTertiaryContent),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        child: Text(
                          "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                          style: CustomTypography().bodyMedium(
                              color: CustomColors.textTertiaryContent),
                        ),
                      ),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }

  final questions = [
    "How do I reschedule a diary?",
    "How do I change my notification settings?",
    "How do I check my incentives?",
    "How do I check my study progress?",
    "What do these icons mean?",
  ];
}
