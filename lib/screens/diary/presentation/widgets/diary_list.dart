import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:audio_diaries_flutter/theme/components/cards.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../theme/custom_colors.dart';
import '../../data/diary.dart';
import '../cubit/diary/diary_history_cubit.dart';
import 'empty_state.dart';

class DiaryList extends StatefulWidget {
  const DiaryList({super.key});

  @override
  State<DiaryList> createState() => _DiaryListState();
}

class _DiaryListState extends State<DiaryList> {
  late DiaryHistoryCubit historyCubit;

  @override
  void initState() {
    PendoService.track("ListTab", {"study_day": "${DateTime.now()}"});
    historyCubit = BlocProvider.of<DiaryHistoryCubit>(context);
    _fetchHistoryData(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiaryHistoryCubit, DiaryHistoryState>(
      builder: (context, state) {
        if (state is DiaryHistoryInitial) {
          return initialHistory();
        } else if (state is DiaryHistoryLoading) {
          return loading();
        } else if (state is DiaryHistoryLoaded) {
          return loadedDiaryHistory(state.diaries);
        } else {
          return Container();
        }
      },
    );
  }

  void _fetchHistoryData(BuildContext context) async {
    historyCubit.loadPastDiaries();
  }

  void refresh(bool shouldRefresh) {
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

  Widget initialHistory() {
    return Container();
  }

  Widget loadedDiaryHistory(List<DiaryModel> diaries) {
    if (diaries.isEmpty) {
      return const BeforeStartWidget();
    } else {
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView.builder(
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
                    const SizedBox(height: 6),
                    DiaryCard(
                      diary: diary,
                      refresh: (value) => refresh(value),
                      getPageName: () => "history_list",
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            )
          ],
        ),
      );
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
