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
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    historyCubit = BlocProvider.of<DiaryHistoryCubit>(context);
    _scrollController = ScrollController()..addListener(_onScroll);
    _fetchHistoryData(context);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _fetchHistoryData(context);
    }
  }

  void _onScroll() {
    if (_isBottom && !_isLoadingMore) {
      _isLoadingMore = true;
      historyCubit.loadMoreDiaries().then((_) {
        _isLoadingMore = false;
      });
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
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
          return loadedDiaryHistory(
            state.groupedDiaries,
            hasMore: state.hasMore,
          );
        } else if (state is DiaryHistoryLoadingMore) {
          return loadedDiaryHistory(
            state.currentDiaries,
            hasMore: true,
            isLoadingMore: true,
          );
        } else {
          return Container();
        }
      },
    );
  }

  void _fetchHistoryData(BuildContext context) {
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
      ),
    );
  }

  Widget initialHistory() {
    return Container();
  }

  Widget loadedDiaryHistory(
    Map<String, List<DiaryModel>> groupedDiaries, {
    bool hasMore = false,
    bool isLoadingMore = false,
  }) {
    if (groupedDiaries.isEmpty) {
      return const BeforeStartWidget();
    }

    return ListView.builder(
      key: const Key("diary_list_view"),
      controller: _scrollController,
      itemCount: groupedDiaries.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= groupedDiaries.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(
                color: CustomColors.productNormalActive,
              ),
            ),
          );
        }

        final dateKey = groupedDiaries.keys.elementAt(index);
        final diaries = groupedDiaries[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateKey,
              style: CustomTypography()
                  .titleLarge(color: CustomColors.textNormalContent),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 6),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: diaries.length,
              itemBuilder: (context, diaryIndex) {
                return Column(
                  children: [
                    DiaryCard(
                      diary: diaries[diaryIndex],
                      refresh: (value) => refresh(value),
                      getPageName: () => "history_list",
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}
