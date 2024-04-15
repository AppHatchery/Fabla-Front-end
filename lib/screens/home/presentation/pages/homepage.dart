import 'dart:async';

import 'package:audio_diaries_flutter/screens/home/presentation/widgets/home_calendar.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/today_goal.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/todays_diary_list.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/weekly_goal.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/weekly_goal_popup.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../theme/dialogs/pop_ups.dart';
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
  String _name = "";
  late List<DiaryModel> diaries;

  late AnimationController _controller;

  bool isExpanded = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    homeCubit = BlocProvider.of<HomeCubit>(context);
    fetchData(context);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
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
    return Scaffold(
        backgroundColor: CustomColors.backgroundTertiary,
        appBar: AppBar(
          backgroundColor: CustomColors.backgroundTertiary,
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
                    ),
                  ),
                  IconButton(
                      onPressed: () {
                        if (isExpanded) {
                          setState(() {
                            isExpanded = false;
                            _controller.reverse();
                            _controller.addStatusListener(
                                (status) => _dismissAndShow(status));
                          });
                        } else {
                          showStudyCalendar();
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
                  child: BlocConsumer<HomeCubit, HomeState>(
                      listener: (context, state) {},
                      builder: (context, state) {
                        if (state is HomeInitial) {
                          return initialHome();
                        } else if (state is HomeLoading) {
                          return loading();
                        } else if (state is HomeLoaded) {
                          return loadedHome(state.diaries, state.startDate);
                        } else {
                          return initialHome();
                        }
                      })),
              Positioned(
                  top: 0,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -2),
                      end: const Offset(0, 0),
                    ).animate(CurvedAnimation(
                        parent: _controller, curve: Curves.fastOutSlowIn)),
                    child: const WeeklyGoalPopup(),
                  ))
            ],
          ),
        ));
  }

  Widget loading() {
    return const Center(
      child: CircularProgressIndicator(
        color: CustomColors.productNormalActive,
      ),
    );
  }

  Widget initialHome() {
    return Container();
  }

  Widget loadedHome(List<DiaryModel> diaries, DateTime startDate) {
    final today = DateTime.now();
    show4AmTip();
    if (today.isBefore(startDate)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 24,
          ),
          const SizedBox(
            height: 24,
          ),
          Text(
            "Today's Tasks",
            style: CustomTypography().headlineMedium(),
            textAlign: TextAlign.left,
          ),
          const Expanded(child: FreeDayWidget()),
        ],
      );
    } else if (today.isAfter(startDate.add(const Duration(days: 6)))) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 24,
          ),
          Text(
            "Today's Tasks",
            style: CustomTypography().headlineMedium(),
            textAlign: TextAlign.left,
          ),
          const Expanded(child: EndStateWidget()),
        ],
      );
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(
            height: 24,
          ),
          const TodayGoalWidget(),
          const SizedBox(
            height: 24,
          ),
          TodaysDiaryList(
            diaries: diaries,
            refresh: (value) => refresh(value),
            getPageName: () => "home",
          )
        ],
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

  void _dismissAndShow(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      showStudyCalendar();
    }

    // ignore: invalid_use_of_protected_member
    _controller.clearStatusListeners();
  }

  void showStudyCalendar() {
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
            return const StudyCalendar();
          }),
    );
  }

  void show4AmTip() async {
    final show =
        await PreferenceService().getBoolPreference(key: 'show_home_tip') ??
            true;
    if (mounted && show) {
      Future.delayed(const Duration(milliseconds: 500), () async {
        showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const Wrap(
                  children: [
                    BottomTipPopUp(
                      title: "Upload Diaries Until 4 AM",
                      message:
                          "Night owl? No need to rush! Share your diaries leisurely until 4 AM the next day! 🌙",
                      image: 'assets/images/midnight.png',
                    )
                  ],
                ));

        await PreferenceService()
            .setBoolPreference(key: 'show_home_tip', value: false);
      });
    }
  }
}
