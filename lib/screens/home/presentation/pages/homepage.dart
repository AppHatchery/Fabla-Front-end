import 'package:audio_diaries_flutter/screens/home/data/experiment.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/home_calendar.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/incentives.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/pending_submission_widget.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/today_goal.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/todays_diary_list.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/weekly_goal.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/weekly_goal_popup.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
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

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    homeCubit = BlocProvider.of<HomeCubit>(context);
    fetchData(context);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    experiment = homeCubit.getExperiment();
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
                return loadedHome(state);
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

  Widget loadedHome(HomeLoaded state) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(state),
      body: GestureDetector(
        onTap: _handleBackgroundTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildMainContent(state),
            ),
            _buildWeeklyGoalPopup(state),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(HomeLoaded state) {
    return AppBar(
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
                  key: const Key("weekly_goal_widget"),
                  onTap: _handleWeeklyGoalTap,
                  child: WeeklyGoalWidget(
                    isExpanded: isExpanded,
                    studies: state.weeklyData.studies,
                    diaries: state.weeklyData.diaries,
                  ),
                ),
              ),
              incentives(state.allStudies),
              IconButton(
                onPressed: () => _handleCalendarTap(state.allStudies),
                icon: const Icon(
                  Icons.calendar_month,
                  color: CustomColors.productNormal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(HomeLoaded state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Always show pending submissions
          PendingSubmissionWidget(),
          const SizedBox(height: 24),

          // Show goal widget if there are goals (even when finished)
          if (state.shouldShowGoalWidget) ...[
            TodayGoalWidget(
              dailyGoal: state.goalData,
              weeklyEntries: state.weeklyEntries,
              isHomeTipClosed: isHomeTipClosed,
            ),
            const SizedBox(height: 24),
          ],

          // Content based on state
          if (state.shouldShowDiaryList) ...[
            TodaysDiaryList(
              diaries: state.todaysData.diaries,
              refresh: (value) => refresh(value),
              getPageName: () => "home",
            ),
          ] else if (state.shouldShowEndState) ...[
            Text(
              "Today's Entries",
              style: CustomTypography().headlineMedium(),
              textAlign: TextAlign.left,
            ),
            Center(child: EndStateWidget()),
          ] else if (state.shouldShowFreeDay) ...[
            Text(
              "Today's Entries",
              style: CustomTypography().headlineMedium(),
              textAlign: TextAlign.left,
            ),
            Center(child: FreeDayWidget()),
          ],
        ],
      ),
    );
  }

  Widget _buildWeeklyGoalPopup(HomeLoaded state) {
    return Positioned(
      top: 0,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -2),
          end: const Offset(0, 0),
        ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn)),
        child: WeeklyGoalPopup(
          studies: state.weeklyData.studies,
          diaries: state.weeklyData.diaries,
        ),
      ),
    );
  }

  /// Handle weekly goal widget tap
  void _handleWeeklyGoalTap() {
    setState(() {
      if (isExpanded) {
        isExpanded = false;
        _controller.reverse();
      } else {
        isExpanded = true;
        _controller.forward();
        track();
      }
    });
  }

  /// Handle calendar button tap
  void _handleCalendarTap(List<StudyModel> allStudies) {
    if (isExpanded) {
      setState(() {
        isExpanded = false;
        _controller.reverse();
        _controller
            .addStatusListener((status) => _dismissAndShow(status, allStudies));
      });
    } else {
      showStudyCalendar(allStudies);
    }
  }

  /// Handle background tap to close expanded view
  void _handleBackgroundTap() {
    if (isExpanded) {
      setState(() {
        isExpanded = false;
        _controller.reverse();
      });
    }
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
            key: const Key("Incentive"),
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
    if (mounted) {
      final login = experiment.login;
      final pendoID = await homeCubit.getParticipantCode();

      await PendoService.start(pendoID, login);
      await PendoService.track("HomePopUp", null);
    }

    setState(() {
      isHomeTipClosed.value = true;
    });
  }
}
