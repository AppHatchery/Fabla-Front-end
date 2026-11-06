import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/home/data/incentive.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/weekly_goal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildWidget({
    required StudyModel study,
    required List<DiaryModel> diaries,
  }) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: WeeklyGoalWidget(
            isExpanded: false,
            studies: [study],
            diaries: diaries,
          ),
        ),
      ),
    );
  }

  StudyModel buildStudy({int weeklyGoal = 4}) {
    return StudyModel(
      id: 1,
      studyId: 1,
      name: 'Test Study',
      experimentCode: 'test',
      color: Colors.blue,
      goals: Goal(daily: 1, weekly: weeklyGoal),
      incentive: Incentive(
        amount: 0,
        bonus: 0,
        currency: r'$',
        threshold: 0,
      ),
    );
  }

  DiaryModel buildDiary({
    required int id,
    required int entries,
    required DiaryStatus status,
  }) {
    return DiaryModel(
      id: id,
      studyID: 1,
      name: 'Test Diary $id',
      prompts: const [],
      tags: null,
      status: status,
      due: DateTime(2026, 10, 25),
      start: DateTime(2026, 10, 19),
      entries: entries,
      currentEntry: 0,
      end: DateTime(2026, 10, 25),
      notifications: const [],
      activeDays: const [],
      submissions: const [],
      completions: const [],
    );
  }

  double progressBarWidth(WidgetTester tester) {
    final container = tester.widget<Container>(
      find.byKey(const Key('weekly_goal_progress_bar')),
    );
    return container.constraints!.maxWidth;
  }

  testWidgets('calculates a finite width for normal weekly progress',
      (tester) async {
    final diaries = [
      buildDiary(id: 1, entries: 1, status: DiaryStatus.submitted),
      buildDiary(id: 2, entries: 1, status: DiaryStatus.submitted),
      buildDiary(id: 3, entries: 1, status: DiaryStatus.idle),
      buildDiary(id: 4, entries: 1, status: DiaryStatus.idle),
    ];

    await tester.pumpWidget(
      buildWidget(study: buildStudy(), diaries: diaries),
    );
    await tester.pumpAndSettle();

    // 2 completed entries / goal of 4 * 70-pixel bar = 35 pixels.
    expect(progressBarWidth(tester), 35.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses zero width when the weekly goal calculation is NaN',
      (tester) async {
    final diaries = [
      buildDiary(id: 1, entries: 0, status: DiaryStatus.idle),
    ];

    await tester.pumpWidget(
      buildWidget(study: buildStudy(), diaries: diaries),
    );
    await tester.pumpAndSettle();

    // 0 completed entries / goal of 0 would be NaN without the safeguard.
    expect(progressBarWidth(tester), 0.0);
    expect(tester.takeException(), isNull);
  });
}
