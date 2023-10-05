import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/diary/diary_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/diary/diary_history_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/diary_calender.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/diary_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_icons.dart';
import '../../../../theme/custom_typography.dart';
import '../../../home/presentation/widgets/unsubmitted_diary_list.dart';
import '../../data/diary.dart';
import '../widgets/custom_calender.dart';
import '../widgets/custom_toggle_buttons.dart';

class DiariesPage extends StatefulWidget {
  const DiariesPage({super.key});

  @override
  State<DiariesPage> createState() => _DiaryPageState();
}

enum Calendar { list, calendar }

class _DiaryPageState extends State<DiariesPage> with WidgetsBindingObserver{
  late DiaryCubit diaryCubit;
  late DiaryHistoryCubit historyCubit;
  Map<DateTime, List<String>> events = {};

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    historyCubit = BlocProvider.of<DiaryHistoryCubit>(context);
    fetchHistoryData(context);
    diaryCubit = BlocProvider.of<DiaryCubit>(context);
    fetchData(context);
    getAllDiaries();
    super.initState();
  }

  bool isListButtonSelected = true;
  Calendar calendarView = Calendar.list;
  DateTime currentDate = DateTime.now();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchHistoryData(context);
      fetchData(context);
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.fillNormal,
      appBar: AppBar(
        backgroundColor: CustomColors.fillNormal,
        shadowColor: Colors.black,
        title: Text(
          "Diary History",
          style: CustomTypography()
              .titleLarge(color: CustomColors.textNormalContent),
        ),
        centerTitle: true,
        shape: const Border(
            bottom: BorderSide(
          color: CustomColors.productBorderNormal,
          width: 2.0,
        )),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Visibility(
                          visible: calendarView != Calendar.calendar,
                          child: Text(
                            "Diary History",
                            style: CustomTypography().headlineMedium(
                              color: CustomColors.textNormalContent,
                            ),
                          ),
                        ),
                        Visibility(
                          visible: calendarView != Calendar.list,
                          child: Text(
                            "Diary Calendar",
                            style: CustomTypography().headlineMedium(
                              color: CustomColors.textNormalContent,
                            ),
                          ),
                        ),
                        const Spacer(),
                        CustomToggleButtons(
                          isSelected: [
                            calendarView == Calendar.list,
                            calendarView == Calendar.calendar,
                          ],
                          onPressed: (int index) {
                            setState(() {
                              if (index == 0) {
                                calendarView = Calendar.list;
                              } else {
                                calendarView = Calendar.calendar;
                              }
                            });
                          },
                          selectedBackgroundColor: CustomColors.productNormal,
                          unselectedBackgroundColor: CustomColors.fillWhite,
                          children: [
                            SizedBox(
                              height: 30,
                              width: 56,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(
                                    CustomIcons.list,
                                    color: calendarView == Calendar.list
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 30,
                              width: 56,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(
                                    CustomIcons.calendarMonth,
                                    color: calendarView == Calendar.calendar
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ]),
                  const SizedBox(height: 12),
                  Visibility(
                    visible: calendarView == Calendar.calendar,
                    child: CustomCalender(events: events,),
                  ),
                  const SizedBox(height: 24),
                  Visibility(
                      visible: calendarView == Calendar.calendar,
                      child: BlocConsumer<DiaryCubit, DiaryState>(
                        listener: (context, state) {},
                        builder: (context, state) {
                          if (state is DiaryInitial) {
                            return initialDiary();
                          } else if (state is DiaryLoading) {
                            return loading();
                          } else if (state is DiaryLoaded) {
                            return loadedDiary(
                                state.diaries, state.unSubmittedDiaries);
                          } else {
                            return initialDiary();
                          }
                        },
                      )),
                  Visibility(
                      visible: calendarView == Calendar.list,
                      child: BlocConsumer<DiaryHistoryCubit, DiaryHistoryState>(
                        listener: (context, state) {},
                        builder: (context, state) {
                          if (state is DiaryHistoryInitial) {
                            return initialDiaryHistory();
                          } else if (state is DiaryHistoryLoading) {
                            return historyLoading();
                          } else if (state is DiaryHistoryLoaded) {
                            return loadedDiaryHistory(
                                state.diaries, state.unSubmittedDiaries);
                          } else {
                            return initialDiaryHistory();
                          }
                        },
                      ))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget historyLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: CustomColors.productBorderNormal,
      ),
    );
  }

  Widget initialDiaryHistory() {
    return Container(
      child: const Text("No Diary History"),
    );
  }

  Widget loadedDiaryHistory(
      List<Diary> diaries, List<Diary> unSubmittedDiaries) {
    return SingleChildScrollView(
      child: Column(
        children: [
          unSubmittedDiaries.isNotEmpty
              ? UnsubmittedDiaryList(
                  diaries: unSubmittedDiaries,
                  refresh: (value) => refresh(value),
                )
              : const SizedBox.shrink(),
          DiaryHistory(diaries: diaries, refresh: (value) => refresh(value)),
        ],
      ),
    );
  }

  void fetchHistoryData(BuildContext context) {
    historyCubit.loadPastDiaries();
  }

  void refreshHistory(bool shouldRefresh) {
    if (shouldRefresh) {
      historyCubit.loadPastDiaries();
    }
  }

  Widget loading() {
    return const Center(
        child: CircularProgressIndicator(
      color: CustomColors.productNormalActive,
    ));
  }

  Widget initialDiary() {
    return Container();
  }

  Widget loadedDiary(List<Diary> diaries, List<Diary> unSubmittedDiaries) {
    return SingleChildScrollView(
      child: Column(
        children: [
          unSubmittedDiaries.isNotEmpty
              ? UnsubmittedDiaryList(
                  diaries: unSubmittedDiaries,
                  refresh: (value) => refresh(value),
                )
              : const SizedBox.shrink(),
          DiaryCalender(diaries: diaries, refresh: (value) => refresh(value)),
        ],
      ),
    );
  }

  void fetchData(BuildContext context) {
    diaryCubit.loadDiaries();
  }

  void refresh(bool shouldRefresh) {
    if (shouldRefresh) {
      diaryCubit.loadDiaries();
    }
  }

  void getAllDiaries() {
    final DiaryRepository repository = DiaryRepository();
    List<Diary> diaries = repository.getAllDiaries();
    final date = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for(Diary diary in diaries){
      final day = DateTime(diary.start.year, diary.start.month, diary.start.day);
      if(day != date){ 
        events.addAll({day: ["Yes"]});
      }
    }
  }
}
