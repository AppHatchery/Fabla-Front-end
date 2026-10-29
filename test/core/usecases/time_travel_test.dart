import 'package:audio_diaries_flutter/core/database/dao/diary_dao.dart';
import 'package:audio_diaries_flutter/core/usecases/time_travel.dart';
import 'package:audio_diaries_flutter/core/utils/app_clock.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/diary_entity.dart';
import 'package:audio_diaries_flutter/services/developer_mode_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockDiaryDAO extends Mock implements DiaryDAO {}

Diary _diary(
  int id, {
  required DateTime start,
  DiaryStatus status = DiaryStatus.idle,
  int currentEntry = 0,
  int entries = 1,
}) =>
    Diary(
      id: id,
      studyID: 1,
      name: 'Diary $id',
      start: start,
      end: start.add(const Duration(hours: 20)),
      due: start.add(const Duration(hours: 24)),
      entries: entries,
      currentEntry: currentEntry,
      deadline: '',
      notifications: '[]',
      status: status,
      activeDays: null,
      submissions: null,
      completions: null,
    );

void main() {
  // 10:00 on 16 Oct; today's sweep cutoff is 04:00 on 16 Oct.
  final now = DateTime(2026, 10, 16, 10);
  final today = DateTime(2026, 10, 16, 4);

  group('planStatusRepairs', () {
    test('restores a status the snapshot had when nothing was submitted', () {
      final diary = _diary(1,
          start: today.add(const Duration(days: 2)),
          status: DiaryStatus.missed);

      final repairs = planStatusRepairs(
          [diary], {1: const DiaryStatusSnapshot(DiaryStatus.idle, 0)}, now);

      expect(repairs, hasLength(1));
      expect(repairs.single.from, DiaryStatus.missed);
      expect(repairs.single.to, DiaryStatus.idle);
    });

    test('restores a past diary too when the snapshot says so', () {
      // Due before the cutoff, but the snapshot shows travel made it missed.
      final diary = _diary(1,
          start: today.subtract(const Duration(days: 3)),
          status: DiaryStatus.submitted,
          currentEntry: 1,
          entries: 3);

      final repairs = planStatusRepairs([diary],
          {1: const DiaryStatusSnapshot(DiaryStatus.complete, 1)}, now);

      expect(repairs.single.to, DiaryStatus.complete);
    });

    test(
        'without a snapshot, resets missed with no entries before its due date',
        () {
      final diary = _diary(1, start: today, status: DiaryStatus.missed);

      final repairs = planStatusRepairs([diary], const {}, now);

      expect(repairs.single.to, DiaryStatus.idle);
    });

    test('without a snapshot, resets submitted with entries left', () {
      final diary = _diary(1,
          start: today.add(const Duration(days: 1)),
          status: DiaryStatus.submitted,
          currentEntry: 2,
          entries: 5);

      expect(planStatusRepairs([diary], const {}, now).single.to,
          DiaryStatus.idle);
    });

    test('leaves diaries really past their due date alone', () {
      final diary = _diary(1,
          start: today.subtract(const Duration(days: 2)),
          status: DiaryStatus.missed);

      expect(planStatusRepairs([diary], const {}, now), isEmpty);
    });

    test('leaves a diary submitted for real while travelling alone', () {
      // currentEntry moved on since the snapshot, and all entries are done.
      final diary = _diary(1,
          start: today.add(const Duration(days: 1)),
          status: DiaryStatus.submitted,
          currentEntry: 1);

      final repairs = planStatusRepairs(
          [diary], {1: const DiaryStatusSnapshot(DiaryStatus.idle, 0)}, now);

      expect(repairs, isEmpty);
    });

    test('never touches ongoing or complete entries', () {
      final future = today.add(const Duration(days: 1));
      final repairs = planStatusRepairs([
        _diary(1, start: future, status: DiaryStatus.complete),
        _diary(2, start: future, status: DiaryStatus.ongoing),
      ], {
        1: const DiaryStatusSnapshot(DiaryStatus.idle, 0),
        2: const DiaryStatusSnapshot(DiaryStatus.idle, 0),
      }, now);

      expect(repairs, isEmpty);
    });
  });

  group('TimeTravel', () {
    late _MockDiaryDAO dao;
    late DeveloperModeService developerMode;
    late List<Diary> stored;
    late int rescheduled;
    late TimeTravel timeTravel;

    setUpAll(() => registerFallbackValue(<Diary>[]));

    setUp(() async {
      SharedPreferences.setMockInitialValues(
          {DeveloperModeService.preferenceKey: true});
      developerMode = DeveloperModeService();
      await developerMode.load();
      final start = DateTime.now().add(const Duration(days: 1));
      stored = [_diary(1, start: start), _diary(2, start: start)];
      dao = _MockDiaryDAO();
      when(() => dao.getAllDiaries()).thenAnswer((_) => stored);
      rescheduled = 0;
      timeTravel = TimeTravel(
        diaryDAO: dao,
        developerMode: developerMode,
        rescheduleNotifications: () => rescheduled++,
      );
    });

    tearDown(() => developerMode.disable());

    test('travelling shifts the app clock and takes a snapshot', () async {
      await timeTravel.travel(const Duration(days: 3));

      expect(developerMode.timeTravel.value, const Duration(days: 3));
      expect(AppClock.offset, const Duration(days: 3));
      expect(await timeTravel.hasSnapshot(), isTrue);
    });

    test('does nothing while developer mode is off', () async {
      await developerMode.disable();

      await timeTravel.travel(const Duration(days: 3));

      expect(AppClock.isShifted, isFalse);
      expect(await timeTravel.hasSnapshot(), isFalse);
    });

    test('a second trip keeps the first snapshot', () async {
      await timeTravel.travel(const Duration(days: 3));
      stored.first.status = DiaryStatus.missed; // saved while travelling
      await timeTravel.travel(const Duration(days: 5));
      await timeTravel.returnToPresent();

      final repairs = await timeTravel.pendingRepairs();

      expect(repairs.single.diary.id, 1);
      expect(repairs.single.to, DiaryStatus.idle);
    });

    test('lists no repairs while still travelling', () async {
      await timeTravel.travel(const Duration(days: 3));
      stored.first.status = DiaryStatus.missed;

      expect(await timeTravel.pendingRepairs(), isEmpty);
      expect(await timeTravel.repair(), 0);
    });

    test('repair saves the fixes, clears the snapshot and reschedules',
        () async {
      await timeTravel.travel(const Duration(days: 3));
      stored.first.status = DiaryStatus.missed;
      await timeTravel.returnToPresent();

      expect(await timeTravel.repair(), 1);

      final saved = verify(() => dao.updateDiaries(captureAny()))
          .captured
          .single as List<Diary>;
      expect(saved.single.id, 1);
      expect(saved.single.status, DiaryStatus.idle);
      expect(await timeTravel.hasSnapshot(), isFalse);
      expect(rescheduled, 1);
    });
  });
}
