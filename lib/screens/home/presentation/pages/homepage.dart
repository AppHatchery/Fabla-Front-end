import 'package:audio_diaries_flutter/screens/home/presentation/widgets/todays_diary_list.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/unsubmitted_diary_list.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/components/cards.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../theme/dialogs/pop_ups.dart';
import '../../../../theme/resources/strings.dart';
import '../../../diary/data/diary.dart';
import '../cubit/cubit/home_cubit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomeCubit homeCubit;
  String _name = "";
  @override
  void initState() {
    homeCubit = BlocProvider.of<HomeCubit>(context);
    fetchData(context);
    getParticipant();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: CustomColors.fillNormal,
        appBar: AppBar(
          toolbarHeight: 105.h,
          backgroundColor: CustomColors.productNormal,
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
                          style: CustomTypography()
                              .headlineLargeCustom(color: CustomColors.fillWhite,
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: ListView(
            children: [
              const CalendaerCard(),
              const SizedBox(
                height: 24,
              ),
              BlocConsumer<HomeCubit, HomeState>(
                  listener: (context, state) {},
                  builder: (context, state) {
                    if (state is HomeInitial) {
                      return initialHome();
                    } else if (state is HomeLoading) {
                      return loading();
                    } else if (state is HomeLoaded) {
                      return loadedHome(
                          state.diaries, state.unSubmittedDiaries);
                    } else {
                      return initialHome();
                    }
                  })
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

  Widget loadedHome(List<Diary> diaries, List<Diary> unSubmittedDiaries) {
    return SingleChildScrollView(
      child: Column(
        children: [
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

  void fetchData(BuildContext context) {
    homeCubit.loadDiaries();
  }

  void refresh(bool shouldRefresh) {
    if (shouldRefresh) {
      homeCubit.loadDiaries();
    }
  }

  void getParticipant() async{
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
                    studyName: "Audio Diary Study for Emotional Regulation.  ",
                    studyDescription: Strings.studyDescription,
                    organisation: "Emory School of Medicine",
                    duration: "Oct 2022 - Aug 2023",
                    researcher: "Dr. Jane Doe")
              ],
            ));
  }
}
