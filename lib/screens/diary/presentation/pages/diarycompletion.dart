import 'package:audio_diaries_flutter/core/utils/dummy_data.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/main.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/data/protocol.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/completion/completion_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/calendar_widget.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/ghost_widget.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
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
  bool isSurvey = false;

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
                return loadedCompletionPage(context, state.protocol,
                    state.diary, state.diaries, state.showWidget);
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

  Widget loadedCompletionPage(BuildContext context, Protocol protocol,
      DiaryModel diary, List<DiaryModel> diaries, bool showWidget) {
    final width = MediaQuery.of(context).size.width;

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
                              child: avatarCircularProgress(protocol, diaries),
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
                          showWidget
                              ? GhostCompletionWidget(
                                  currentEntry: diary.currentEntry,
                                  dailyGoal: protocol.dailyGoal,
                                  weeklyGoal: protocol.weeklyGoal)
                              : const SizedBox.shrink(),
                        ],
                      )),
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
                    diaries: diaries,
                    dailyGoal: protocol.dailyGoal,
                    weeklyGoal: protocol.weeklyGoal,
                    isSurvey: isSurvey,
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

  Widget avatarCircularProgress(Protocol protocol, List<DiaryModel> diaries) {
    final today = DateTime.now();
    double emaDailyTotalGoal = (emaGoal.daily + diaryGoal.daily).toDouble();
    double surveyTotalGoal = surveyGoal.daily.toDouble();
    int emaDailyTotalEntries = 0;
    int surveyTotalEntries = 0;

    final diariesToday = diaries.where((diary) {
      final diaryDate = diary.start;
      return diaryDate.year == today.year &&
          diaryDate.month == today.month &&
          diaryDate.day == today.day;
    }).toList();

    for (final diary in diariesToday) {
      if (diary.type == DiaryTypes.ema || diary.type == DiaryTypes.daily) {
        emaDailyTotalEntries += diary.currentEntry;
      } else if (diary.type == DiaryTypes.survey) {
        surveyTotalEntries += diary.currentEntry;
      }
    }

    double beginEmaDaily = (emaDailyTotalEntries - 1) / emaDailyTotalGoal;
    double endEmaDaily = (emaDailyTotalEntries) / emaDailyTotalGoal;

    double beginSurvey = (surveyTotalEntries - 1) / surveyTotalGoal;
    double endSurvey = (surveyTotalEntries) / surveyTotalGoal;

    return SizedBox(
        height: 150,
        width: 150,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(
              begin: isSurvey ? beginSurvey : beginEmaDaily,
              end: isSurvey ? endSurvey : endEmaDaily),
          duration: const Duration(milliseconds: 1000),
          builder: (context, value, _) => CircularProgressIndicator(
            strokeWidth: 5,
            value: value,
            backgroundColor: CustomColors.productLightBackground,
            color: CustomColors.productNormal,
          ),
        ));
  }

  fetchData() async{
    getDay();
    completionCubit.completeDiary(widget.diary);
  }

  void getDay() async {
    //Get day here
    final now = DateTime.now();
    final lastString =
        await PreferenceService().getStringPreference(key: 'lastDay');
    final last = DateTime.parse(lastString!);
    final realDay = last.subtract(const Duration(days: 7));
    final isToday = DateTime(now.year, now.month, now.day).isAtSameMomentAs(
            DateTime(realDay.year, realDay.month, realDay.day)) ||
        DateTime(now.year, now.month, now.day)
            .isAtSameMomentAs(DateTime(last.year, last.month, last.day));
    setState(() {
      isSurvey = isToday;
    });
  }
}
