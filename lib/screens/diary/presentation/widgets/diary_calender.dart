import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../theme/components/cards.dart';
import '../../../../theme/custom_colors.dart';
import '../../../../theme/custom_typography.dart';
import '../../../home/presentation/widgets/empty_state.dart';
import '../../data/diary.dart';
import '../../domain/repository/diary_repository.dart';
import '../cubit/diary/diary_cubit.dart';
// import 'custom_calender.dart';

class DiaryCalender extends StatefulWidget {
  const DiaryCalender({super.key});

  @override
  State<DiaryCalender> createState() => _DiaryCalenderState();
}

class _DiaryCalenderState extends State<DiaryCalender> {
  late DiaryCubit diaryCubit;
  late List<DiaryModel> diaries;

  DateTime today = DateTime.now();

  @override
  void initState() {
    diaries = _getAllDiaries();
    diaryCubit = BlocProvider.of<DiaryCubit>(context);
    _fetchData(context);
    PendoService.track("CalenderTab", {"study_day": "${DateTime.now()}"});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // CustomCalender(
          //   diaries: diaries,
          //   selectDate: _changeDate,
          // ),
          const SizedBox(height: 24),
          BlocBuilder<DiaryCubit, DiaryState>(
            builder: (context, state) {
              if (state is DiaryInitial) {
                return initialDiary();
              } else if (state is DiaryLoading) {
                return loading();
              } else if (state is DiaryLoaded) {
                return loadedDiary(state.diaries, state.startDate);
              } else {
                return Container();
              }
            },
          ),
        ],
      ),
    );
  }

  List<DiaryModel> _getAllDiaries() {
    final DiaryRepository repository = DiaryRepository();
    return repository.getAllDiaries();
  }

  void _fetchData(BuildContext context) async {
    diaryCubit.loadDiaries();
  }

  void _refresh(bool shouldRefresh) {
    if (shouldRefresh) {
      diaryCubit.loadDiaries();
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

  Widget loadedDiary(List<DiaryModel> diaries, DateTime startDate) {
    if (today.isBefore(startDate) && diaries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(today),
            style: CustomTypography()
                .titleLarge(color: CustomColors.textNormalContent),
            textAlign: TextAlign.left,
          ),
          const SizedBox(
            height: 14,
          ),
          const FreeDayWidget(),
        ],
      );
    } else if (today.isAfter(startDate.add(const Duration(days: 6))) &&
        diaries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(today),
            style: CustomTypography()
                .titleLarge(color: CustomColors.textNormalContent),
            textAlign: TextAlign.left,
          ),
          const SizedBox(
            height: 14,
          ),
          const EndStateWidget(),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(0),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: diaries.length,
            itemBuilder: (context, index) {
              final diary = diaries[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(diary.start),
                    style: CustomTypography()
                        .titleLarge(color: CustomColors.textNormalContent),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  DiaryCard(
                    diary: diary,
                    refresh: _refresh,
                    getPageName: () => "history_calender",
                  ),
                ],
              );
            },
          )
        ],
      );
    }
  }

  _changeDate(DateTime? date) {
    if (date != null) {
      setState(() {
        today = date;
      });
      diaryCubit.loadDiaries(date: today);
    }
  }
}

String _formatDate(DateTime date) {
  DateTime today =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final DateFormat formatterOne = DateFormat("MMMM d',' y");
  final DateFormat formatterTwo = DateFormat("EEEE - MMMM d',' y");

  if (today == DateTime(date.year, date.month, date.day)) {
    return "Today - ${formatterOne.format(date)}";
  } else if (today.subtract(const Duration(days: 1)) ==
      DateTime(date.year, date.month, date.day)) {
    return "Yesterday - ${formatterOne.format(date)}";
  } else {
    return formatterTwo.format(date);
  }
}
