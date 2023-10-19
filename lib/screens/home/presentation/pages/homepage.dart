import 'package:audio_diaries_flutter/screens/home/presentation/widgets/home_calendar.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/todays_diary_list.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/unsubmitted_diary_list.dart';
import 'package:audio_diaries_flutter/services/preference_service.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../theme/dialogs/pop_ups.dart';
import '../../../../theme/resources/strings.dart';
import '../../../diary/data/diary.dart';
import '../cubit/cubit/home_cubit.dart';
import '../widgets/empty_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late HomeCubit homeCubit;
  String _name = "";
  late List<Diary> diaries;
  late DateTime startDate;
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    homeCubit = BlocProvider.of<HomeCubit>(context);
    fetchData(context);
    getParticipant();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: CustomColors.fillNormal,
        appBar: AppBar(
          toolbarHeight: 105.h,
          backgroundColor: CustomColors.backgroundSecondary,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              width: width,
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hi, $_name",
                          style: CustomTypography().headlineLargeCustom(
                            color: CustomColors.fillWhite,
                            //fontSize: MediaQuery.of(context).textScaleFactor * 20,
                          ),
                        ),
                        Text(
                          "Welcome back ${Strings.wavingEmoji}",
                          style: CustomTypography()
                              .bodyLarge(color: CustomColors.fillWhite),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 12),
                      child: CustomElevatedIconButton(
                        onClick: () => showResearchInformation(),
                        icon: Icons.sticky_note_2,
                        color: CustomColors.fillWhite,
                        iconColor: CustomColors.productNormal,
                        shadowColor: CustomColors.productNormalActive,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        body: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: BlocConsumer<HomeCubit, HomeState>(
                listener: (context, state) {},
                builder: (context, state) {
                  if (state is HomeInitial) {
                    return initialHome();
                  } else if (state is HomeLoading) {
                    return loading();
                  } else if (state is HomeLoaded) {
                    return loadedHome(state.diaries, state.unSubmittedDiaries);
                  } else {
                    return initialHome();
                  }
                })));
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

  Widget loadedHome(List<Diary> diaries, List<Diary> unSubmittedDiaries) {
    final today = DateTime.now();
    show4AmTip();
    if (today.isBefore(startDate)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StreakCalendar(),
          const SizedBox(
            height: 24,
          ),
          Text(
            "Today's Diary",
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
          Text(
            "Today's Diary",
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
          const StreakCalendar(),
          const SizedBox(
            height: 24,
          ),
          unSubmittedDiaries.isNotEmpty
              ? UnsubmittedDiaryList(
                  diaries: unSubmittedDiaries,
                  refresh: (value) => refresh(value),
                )
              : const SizedBox.shrink(),
          const SizedBox(
            height: 12,
          ),
          TodaysDiaryList(diaries: diaries, refresh: (value) => refresh(value))
        ],
      ),
    );
  }

  void fetchData(BuildContext context) async {
    homeCubit.loadDiaries();
    diaries = homeCubit.getAllDiariesThisWeek();
    startDate = DateTime.fromMillisecondsSinceEpoch(
        await PreferenceService().getIntPreference(key: 'startDate') ?? 0);
  }

  void refresh(bool shouldRefresh) {
    if (shouldRefresh) {
      homeCubit.loadDiaries();
    }
  }

  void getParticipant() async {
    final name = await homeCubit.getParticipantName();
    setState(() {
      _name = name;
    });
  }

  void showResearchInformation() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Wrap(
              children: [
                BottomResearcherInfoPopUp(
                    studyName: Strings.studyName,
                    studyDescription: Strings.studyDescription,
                    organisation: "Emory School of Medicine",
                    duration: Strings.studyDuration,
                    researcher: Strings.researcherName)
              ],
            ));
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
