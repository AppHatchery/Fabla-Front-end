import 'package:audio_diaries_flutter/core/usecases/experiment_manager.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'hub_state.dart';

class HubCubit extends Cubit<HubState> {
  /// The experiment manager instance used for updates.
  /// If not provided, a default instance will be created.
  final ExperimentManager _experimentManager;

  /// The diary repository used to gate study updates.
  /// If not provided, a default instance will be created.
  final DiaryRepository _diaryRepository;

  /// Creates a HubCubit with optional dependency injection.
  ///
  /// [experimentManager] and [diaryRepository] can be provided for testing.
  /// If not provided, default instances will be used.
  HubCubit({
    ExperimentManager? experimentManager,
    DiaryRepository? diaryRepository,
  })  : _experimentManager = experimentManager ?? ExperimentManager(),
        _diaryRepository = diaryRepository ?? DiaryRepository(),
        super(const HubInitial());

  /// Returns true if any of today's diaries are already submitted or are
  /// pending submission (recorded but not yet uploaded). The study cannot be
  /// updated while either is true. O(n) over today's diaries.
  bool hasPendingOrSubmittedToday() {
    final diaries = _diaryRepository.getDailyDiaries(DateTime.now());
    return diaries.any((diary) =>
        diary.status == DiaryStatus.submitted ||
        diary.status == DiaryStatus.complete);
  }

  update() async {
    emit(HubUpdating());
    final done = await _experimentManager.update();

    emit(HubUpdated(done));

    emit(const HubInitial());
  }

  refresh() {
    emit(HubRefreshing());
  }
}
