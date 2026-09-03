import 'package:audio_diaries_flutter/core/usecases/experiment_manager.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/repository/diary_repository.dart';
import 'package:audio_diaries_flutter/services/notification_service.dart';
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

  /// Returns true if any of today's diaries are in-progress or have been
  /// recorded but not yet submitted. Used to defer a pending update by a day.
  bool hasOngoingOrCompleteToday() {
    final diaries = _diaryRepository.getDailyDiaries(DateTime.now());
    return diaries.any((diary) =>
        diary.status == DiaryStatus.ongoing ||
        diary.status == DiaryStatus.complete ||
        diary.status == DiaryStatus.submitted);
  }

  void update() async {
    emit(HubUpdating());
    final done = await _experimentManager.update();

    if (done == true) {
      await _experimentManager.setUpdateStatus(UpdateStatus.none);
      return emit(HubUpdated());
    }

    emit(HubUpdateFailed(connectionError: done == null));

    emit(const HubInitial());
  }

  void scheduleForLater() async {
    await _rescheduleWithNotification();
  }

  // Fixed ID so re-scheduling always replaces the previous notification.
  static const int _studyUpdateNotificationId = 900001;

  /// Saves the pending status + next-day date, then schedules a notification
  /// 15 minutes before the first diary of that day starts.
  Future<void> _rescheduleWithNotification() async {
    final pendingDate = await _experimentManager.reschedule();

    final diaries = _diaryRepository.getDiaries(pendingDate);
    if (diaries.isEmpty) return;

    final earliest = diaries.reduce(
      (a, b) => a.start.isBefore(b.start) ? a : b,
    );

    final notificationTime =
        earliest.start.subtract(const Duration(minutes: 15));
    if (notificationTime.isBefore(DateTime.now())) return;

    await NotificationService.createNotification(
      id: _studyUpdateNotificationId,
      title: 'Study Update Available',
      body:
          'Your first entry for the day begins in 15 minutes! Before you proceed, please update the study by clicking here.',
      date: notificationTime.toUtc(),
      payload: {'type': 'study_update'},
    );
  }

  void refresh() {
    emit(HubRefreshing());
  }

  Future<void> checkForUpdates() async {
    final status = await _experimentManager.checkForUpdates();
    if (status == UpdateStatus.available) {
      if (hasOngoingOrCompleteToday()) {
        await _rescheduleWithNotification();
        return;
      }
      emit(HubUpdateAvailable());
    } else if (status == UpdateStatus.pending) {
      final pendingDate = await _experimentManager.getPendingDate();
      if (pendingDate == null || DateTime.now().isBefore(pendingDate)) return;

      // Scheduled date has arrived — check for blocking diaries.
      if (hasOngoingOrCompleteToday()) {
        // User has active or unsubmitted diaries; defer by another day.
        await _rescheduleWithNotification();
      } else {
        await _experimentManager.setUpdateStatus(UpdateStatus.available);
        emit(HubUpdateAvailable());
      }
    }
  }
}
