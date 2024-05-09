import 'package:audio_diaries_flutter/theme/components/cards.dart';
import 'package:audio_diaries_flutter/theme/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../theme/custom_colors.dart';
import '../../data/diary.dart';
import '../cubit/diary/diary_history_cubit.dart';
import 'empty_state.dart';

class DiaryList extends StatefulWidget {
  const DiaryList({super.key});

  @override
  State<DiaryList> createState() => _DiaryListState();
}

class _DiaryListState extends State<DiaryList> with WidgetsBindingObserver {
  late DiaryHistoryCubit historyCubit;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    historyCubit = BlocProvider.of<DiaryHistoryCubit>(context);
    _fetchHistoryData(context);
    super.initState();
  }

  @override
  dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchHistoryData(context);
    }
    super.didChangeAppLifecycleState(state);
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
          return loadedDiaryHistory(state.groupedDiaries);
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

  Widget loadedDiaryHistory(Map<String, List<DiaryModel>> groupedDiaries) {
    if (groupedDiaries.isEmpty) {
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
              itemCount: groupedDiaries.length,
              itemBuilder: (context, index) {
                final text = groupedDiaries.keys.elementAt(index);
                final diaries = groupedDiaries[text];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: CustomTypography()
                          .titleLarge(color: CustomColors.textNormalContent),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 6),
                    ListView.builder(
                      itemBuilder: (context, indexTwo) => Column(
                        children: [
                          DiaryCard(
                            diary: diaries![indexTwo],
                            refresh: (value) => refresh(value),
                            getPageName: () => "history_list",
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                      itemCount: diaries?.length ?? 0,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                    ),
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
