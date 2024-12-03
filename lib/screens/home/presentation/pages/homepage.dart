import 'dart:async';

import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/home_calendar.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/today_goal.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/todays_diary_list.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/weekly_goal.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/weekly_goal_popup.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// import '../../../../theme/dialogs/pop_ups.dart';
import '../../../diary/data/diary.dart';
import '../cubit/cubit/home_cubit.dart';
import '../widgets/empty_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late HomeCubit homeCubit;
  late List<DiaryModel> diaries;
  late List<DiaryModel> calendarDiaries;

  late AnimationController _controller;

  bool isExpanded = false;
  ValueNotifier<bool> isHomeTipClosed = ValueNotifier(true);

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    homeCubit = BlocProvider.of<HomeCubit>(context);
    fetchData(context);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    show4AmTip();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchData(context);
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, CustomColors.fillNormal],
          ),
        ),
        child: BlocConsumer<HomeCubit, HomeState>(
            listener: (context, state) {},
            builder: (context, state) {
              if (state is HomeInitial) {
                return initialHome();
              } else if (state is HomeLoading) {
                return loading();
              } else if (state is HomeLoaded) {
                return loadedHome(state.diaries, state.weeksDiaries,
                    state.available, state.studies, state.entries);
              } else {
                return initialHome();
              }
            }));
  }

  Widget loading() {
    return const Scaffold(
        body: Center(
      child: CircularProgressIndicator(
        color: CustomColors.productNormalActive,
      ),
    ));
  }

  Widget initialHome() {
    return Scaffold(
      body: Container(),
    );
  }

  Widget loadedHome(List<DiaryModel> diaries, List<DiaryModel> weeksDiaries,
      bool available, List<StudyModel> studies, int entries) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: CustomColors.fillWhiteShade,
          scrolledUnderElevation: 0.0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      if (isExpanded) {
                        isExpanded = !isExpanded;
                        _controller.reverse();
                      } else {
                        isExpanded = !isExpanded;
                        _controller.forward();
                      }
                    }),
                    child: WeeklyGoalWidget(
                      isExpanded: isExpanded,
                      weeklyGoal:
                          studies.isNotEmpty ? studies.first.goals.weekly : 0,
                      currentEntries: entries,
                      studies: studies,
                    ),
                  ),
                  IconButton(
                      onPressed: () {
                        if (isExpanded) {
                          setState(() {
                            isExpanded = false;
                            _controller.reverse();
                            _controller.addStatusListener(
                                (status) => _dismissAndShow(status, studies));
                          });
                        } else {
                          showStudyCalendar(studies);
                        }
                      },
                      icon: const Icon(
                        Icons.calendar_month,
                        color: CustomColors.productNormal,
                      ))
                ],
              ),
            ),
          ),
        ),
        body: GestureDetector(
          onTap: () {
            if (isExpanded) {
              setState(() {
                isExpanded = false;
                _controller.reverse();
              });
            }
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: available == false
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 24,
                          ),
                          Text(
                            "Today's Entries",
                            style: CustomTypography().headlineMedium(),
                            textAlign: TextAlign.left,
                          ),
                          const Expanded(child: FreeDayWidget()),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                        children: [
                          const SizedBox(
                            height: 24,
                          ),
                          TodayGoalWidget(
                            dailyGoal: studies.firstOrNull?.goals.daily ?? 0,
                            studies: studies,
                            diaries: weeksDiaries,
                            weeklyEntries: entries,
                            isHomeTipClosed: isHomeTipClosed,
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                          TodaysDiaryList(
                            diaries: diaries,
                            refresh: (value) => refresh(value),
                            getPageName: () => "home",
                          )
                        ],
                      )),
              ),
              Positioned(
                  top: 0,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -2),
                      end: const Offset(0, 0),
                    ).animate(CurvedAnimation(
                        parent: _controller, curve: Curves.fastOutSlowIn)),
                    child: WeeklyGoalPopup(
                      studies: studies,
                      diaries: weeksDiaries,
                    ),
                  ))
            ],
          ),
        ));
  }

  void fetchData(BuildContext context) async {
    homeCubit.loadDiaries();
    diaries = homeCubit.getAllDiariesThisWeek();
  }

  void refresh(bool shouldRefresh) {
    if (shouldRefresh) {
      homeCubit.loadDiaries();
    }
  }

  void _dismissAndShow(AnimationStatus status, List<StudyModel> studies) {
    if (status == AnimationStatus.dismissed) {
      showStudyCalendar(studies);
    }

    // ignore: invalid_use_of_protected_member
    _controller.clearStatusListeners();
  }

  void showStudyCalendar(List<StudyModel> studies) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      builder: (context) => DraggableScrollableSheet(
          initialChildSize: 1,
          maxChildSize: 1,
          minChildSize: 1,
          builder: (context, scrollController) {
            return StudyCalendar(
              studies: studies,
              refresh: (value) => refresh(value),
              getPageName: () => "calendar",
            );
          }),
    );
  }

  void show4AmTip() async {
    final show =
        await PreferenceService().getBoolPreference(key: 'show_home_tip') ??
            true;
    if (mounted && show) {
      isHomeTipClosed.value = true;
      Future.delayed(const Duration(milliseconds: 500), () async {
        // showModalBottomSheet(
        //     context: context,
        //     isScrollControlled: true,
        //     builder: (context) => const Wrap(
        //           children: [
        //             QuickTipPopUp(
        //               title: "Quick Tips to Get You Started",
        //               image: 'assets/images/idea.png',
        //               messageOne: "Separate Logs for Each Encounter",
        //               descriptionOne:
        //                   "Please log each encounter separately to capture every detail",
        //               messageTwo: "Don't be limited to your daily goals!",
        //               descriptionTwo:
        //                   "You are encouraged to log as many encounters as you can: More entries, more insights!",
        //               iconOne: "assets/images/arrow_split.png",
        //               iconTwo: "assets/images/record_voice_over.png",
        //             )
        //           ],
        //         )).whenComplete(() async {
        //   setState(() {
        //     isHomeTipClosed.value = true;
        //   });
        // });
        await PendoService.track("HomePopUp", null);
        setState(() {
          isHomeTipClosed.value = true;
        });
      });
    }
  }
}
