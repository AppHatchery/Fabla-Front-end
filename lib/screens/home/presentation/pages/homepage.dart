import 'dart:async';

import 'package:audio_diaries_flutter/screens/home/data/experiment.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/home_calendar.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/incentives.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/today_goal.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/todays_diary_list.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/weekly_goal.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/weekly_goal_popup.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
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
  late ExperimentModel experiment;
  final repository = SetupRepository();
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    homeCubit = BlocProvider.of<HomeCubit>(context);
    fetchData(context);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    experiment = repository.getExperiment();
    show4AmTip();
    trackLoad();
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
                return loadedHome(
                    state.diaries,
                    state.weeksDiaries,
                    state.available,
                    state.studies,
                    state.allStudies,
                    state.entries,
                    state.finished);
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

  Widget loadedHome(
      List<DiaryModel> diaries,
      List<DiaryModel> weeksDiaries,
      bool available,
      List<StudyModel> studies,
      List<StudyModel> allStudies,
      int entries,
      bool finished) {
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
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        if (isExpanded) {
                          isExpanded = !isExpanded;
                          _controller.reverse();
                        } else {
                          isExpanded = !isExpanded;
                          _controller.forward();
                          track();
                        }
                      }),
                      child: WeeklyGoalWidget(
                        isExpanded: isExpanded,
                        studies: studies,
                        diaries: weeksDiaries,
                      ),
                    ),
                  ),

                  // Incentive
                  incentives(allStudies),

                  // Calendar
                  IconButton(
                      onPressed: () {
                        if (isExpanded) {
                          setState(() {
                            isExpanded = false;
                            _controller.reverse();
                            _controller.addStatusListener((status) =>
                                _dismissAndShow(status, allStudies));
                          });
                        } else {
                          showStudyCalendar(allStudies);
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
                child: available == false || finished
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
                          Expanded(
                              child: finished
                                  ? EndStateWidget()
                                  : FreeDayWidget()),
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

  Widget incentives(List<StudyModel> allStudies) {
    // no incentives
    final available = allStudies.fold<double>(
        0,
        (prev, study) =>
            prev + (study.incentive.amount + study.incentive.bonus));

    return available <= 0
        ? const SizedBox.shrink()
        : GestureDetector(
            onTap: () => showStudyIncentives(allStudies),
            child: Image.asset(
              "assets/images/icons/incentives.png",
              height: 24,
              width: 24,
            ),
          );
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

  track() async {
    final now = DateTime.now();
    await PendoService.track(
        "Weekly Goal", {"viewed_at": now.toIso8601String()});
  }

  trackLoad() async {
    final now = DateTime.now();
    await PendoService.track("Home", {"loaded_at": now.toIso8601String()});
  }

  void showStudyCalendar(List<StudyModel> studies) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      routeSettings: RouteSettings(name: "/HomeCalendar"),
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

  void showStudyIncentives(List<StudyModel> studies) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      routeSettings: RouteSettings(name: "/HomeIncentives"),
      builder: (context) => DraggableScrollableSheet(
          initialChildSize: 1,
          maxChildSize: 1,
          minChildSize: 1,
          builder: (context, scrollController) {
            return StudyIncentives(
              studies: studies,
              refresh: (value) => refresh(value),
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
      final login = experiment.login;
      final service = PreferenceService();
      final pendoID = await service.getStringPreference(key: 'pendo-ID');

      if (pendoID == null) {
        final anonymousID =
            "$login-anonymous-${DateTime.now().millisecondsSinceEpoch}";
        await service.setStringPreference(key: 'pendo-ID', value: anonymousID);
        await PendoService.start(anonymousID, login);
      } else {
        await PendoService.start(pendoID, login);
      }

      await PendoService.track("HomePopUp", null);
    }

    setState(() {
      isHomeTipClosed.value = true;
    });
  }
}
