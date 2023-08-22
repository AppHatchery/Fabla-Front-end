import 'package:audio_diaries_flutter/screens/diary/presentation/pages/diarysummary.dart';
import 'package:audio_diaries_flutter/theme/custom_icons.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';

import '../../../../theme/components/buttons.dart';
import '../../../../theme/components/cards.dart';
import '../../../../theme/components/indicators.dart';
import '../../../../theme/components/notes.dart';
import '../../../../theme/components/options.dart';
import '../../../../theme/custom_colors.dart';

class DiariesPage extends StatelessWidget {
  const DiariesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DiaryPageView();
  }
}

/// This class holds and manages all the pages in the page view
/// It has all the UI elements of the New Daily Diary flow
/// The pages have been hardcoded into the PageView(later to be replaced by the number of questions in the diary)
/// The page view has a controller which is used to navigate between pages
class DiaryPageView extends StatefulWidget {
  const DiaryPageView({super.key});

  @override
  State<DiaryPageView> createState() => _DiaryPageViewState();
}

class _DiaryPageViewState extends State<DiaryPageView>
    with SingleTickerProviderStateMixin {
  late PageController controller;
  int currentPage = 0;
  int pageCount = 2;

  @override
  void initState() {
    super.initState();
    controller = PageController(
      viewportFraction: 1.0,
    )..addListener(() {
        setState(() {
          currentPage = controller.page!.round();
        });
      });
  }

  void nextPage() {
    if (currentPage < pageCount - 1) {
      controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const DiarySummaryPage(
                  text: "Tell me about something happy that happened today.")));
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.fillNormal,
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          CustomBarIndicator(
            pageCount: 2,
            currentPage: currentPage,
          ),
          Expanded(
            child: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: controller,
              children: <Widget>[
                Center(
                  child: NewDailyDiaryPage(
                    onNextPage: nextPage,
                    question: "Did fatigue happen to you?",
                  ),
                ),
                Center(
                  child: NewDailyDiaryPage(
                    onNextPage: nextPage,
                    question: "Tell me about something happy that happened today.",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// This class is the page that is being duplicated in the PageView
/// It has two parameters:
/// onNextPage: a function that is called when the user clicks on the continue button
/// question: the question that is being asked in the diary
class NewDailyDiaryPage extends StatefulWidget {
  final VoidCallback? onNextPage;
  final String? question;

  const NewDailyDiaryPage({Key? key, this.onNextPage, required this.question}) : super(key: key);

  @override
  State<NewDailyDiaryPage> createState() => _NewDailyDiaryPageState();
}

class _NewDailyDiaryPageState extends State<NewDailyDiaryPage> {
  bool showMyResponse = false;
  bool isClicked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.fillNormal,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text:
                                widget.question,
                            style: CustomTypography().titleLarge(
                                color: CustomColors.textNormalContent),
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isClicked = !isClicked;
                                    });
                                  },
                                  icon: const Icon(CustomIcons.note_1),
                                  color: CustomColors.productNormal,
                                  iconSize: 22.0,
                                  padding: const EdgeInsets.all(0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isClicked) const ResearchersNote(),
                  const SizedBox(height: 24),
                  if (!showMyResponse)
                    CustomOptionGroup(
                      options: const [
                        "RECORD RESPONSE",
                        "I DON'T WANT TO ANSWER THIS QUESTION",
                      ],
                      onSelect: (selectedOption) {
                        if (selectedOption == "RECORD RESPONSE") {
                          setState(() {
                            showMyResponse = true;
                          });
                        } else if (selectedOption ==
                            "I DON'T WANT TO ANSWER THIS QUESTION") {
                          print("SELECTED");
                        }
                      },
                    ),
                  if (showMyResponse) const MyResponse(),
                  Expanded(child: Container()),
                  Container(
                    alignment: Alignment.bottomCenter,
                    child: CustomFlatButton(
                      onClick: () {
                        widget.onNextPage!();
                      },
                      text: "CONTINUE",
                      textColor: CustomColors.greyDark,
                      color: CustomColors.fillDisabled,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// This class is the UI element that is displayed when the user selects the option "RECORD RESPONSE"
/// and has recorded an audio
/// it displays the Audio that the user has recorded
/// and a button for them to add a new response(no functionality yet)
/// the My response section, to be changed into a  list in case of multiple responses
class MyResponse extends StatelessWidget {
  const MyResponse({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "My Response",
          style: CustomTypography()
              .titleLarge(color: CustomColors.textNormalContent),
        ),
        const SizedBox(height: 12),
        const AudioDiaryCard(
          path:"",
        ),
        const SizedBox(height: 12),
        CustomElevatedButton(
          onClick: () {},
          text: "ADD A NEW RESPONSE",
          color: CustomColors.productLightPrimaryNormalWhite,
          textColor: CustomColors.productNormal,
          shadowColor: CustomColors.productBorderNormal,
        ),
      ],
    );
  }
}

/// this is a custom AppBar that is being used in the DiaryPageView
/// the skip button has no functionality yet
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: CustomColors.fillNormal,
      title: Row(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(CustomIcons.close),
              iconSize: 15.0,
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Text(
                "New Daily Diary",
                style: CustomTypography()
                    .titleSmall(color: CustomColors.textNormalContent),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: () {
                print("Skip clicked!");
              },
              child: Text(
                "Skip",
                style: CustomTypography()
                    .titleSmall(color: CustomColors.textNormalContent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
