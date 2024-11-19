import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/main.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/completion/completion_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/calendar_widget.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/ghost_widget.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../theme/components/buttons.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';

/// this is the last page in the New Daily Diary flow
/// The button leads to the home page
class DiaryCompletionPage extends StatefulWidget {
  final DiaryModel diary;
  const DiaryCompletionPage({super.key, required this.diary});

  @override
  State<DiaryCompletionPage> createState() => _DiaryCompletionPageState();
}

class _DiaryCompletionPageState extends State<DiaryCompletionPage> {
  late CompletionCubit completionCubit;

  @override
  void initState() {
    completionCubit = BlocProvider.of<CompletionCubit>(context);
    fetchData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: CustomColors.fillWhite,
        body: SafeArea(
          child: BlocConsumer<CompletionCubit, CompletionState>(
            builder: (context, state) {
              if (state is CompletionInitial) {
                return initialCompletionPage();
              } else if (state is CompletionLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is CompletionLoaded) {
                return loadedCompletionPage(
                    context, state.studies, state.diary, state.diaries);
              } else {
                return initialCompletionPage();
              }
            },
            listener: (context, state) {
              if (state is CompletionError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.message),
                ));
              }
            },
          ),
        ));
  }

  Widget initialCompletionPage() {
    return Container();
  }

  Widget loadedCompletionPage(BuildContext context, List<StudyModel> studies,
      DiaryModel diary, List<DiaryModel> diaries) {
    final width = MediaQuery.of(context).size.width;

    final diariesForToday = diaries
        .where((element) =>
            element.due.year == diary.due.year &&
            element.due.month == diary.due.month &&
            element.due.day == diary.due.day)
        .toList();

    final diaryIds = diariesForToday.map((diary) => diary.studyID).toSet();

    final studiesForTheDay =
        studies.where((study) => diaryIds.contains(study.studyId)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 34.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 150,
                    width: width,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: avatarCircularProgress(
                                studiesForTheDay, diariesForToday),
                          ),
                        ),
                        Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 5,
                                  height: 10,
                                  color: Colors.white,
                                ),
                              ],
                            )),
                        GhostCompletionWidget(
                            diaries: diariesForToday,
                            studies: studiesForTheDay),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  Text(
                    "Thanks for your response!",
                    style: CustomTypography().headlineMedium(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  Text(
                    "Your input is incredibly valuable for our study's progress. We can't wait to hear from you again soon!",
                    style: CustomTypography().bodyLarge(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  CompleteCalendarWidget(
                    diary: diary,
                    diaries: diaries,
                    studies: studies,
                  )
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: CustomFlatButton(
              onClick: () {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const Hub()),
                    (route) => false);
              },
              text: "Return Home",
              color: CustomColors.productNormal,
              textColor: CustomColors.textWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget avatarCircularProgress(
      List<StudyModel> studies, List<DiaryModel> diaries) {
    final totalEntries =
        diaries.where((diary) => diary.status == DiaryStatus.submitted).length;
    final totalGoal =
        studies.fold(0, (prev, study) => prev + study.goals.daily);

    final begin = (totalEntries - 1) / totalGoal;
    final end = totalEntries / totalGoal;

    return SizedBox(
        height: 150,
        width: 150,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: begin, end: end),
          duration: const Duration(milliseconds: 1000),
          builder: (context, value, _) => CircularProgressIndicator(
            strokeWidth: 5,
            value: value,
            backgroundColor: CustomColors.productLightBackground,
            color: CustomColors.productNormal,
          ),
        ));
  }

  fetchData() {
    completionCubit.completeDiary(widget.diary);
  }
}
