import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:audio_diaries_flutter/main.dart' as app;
import 'package:audio_diaries_flutter/core/database/object_box.dart';
import 'package:audio_diaries_flutter/objectbox.g.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/pages/diaries.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/diary_list.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/empty_state.dart';
import 'package:audio_diaries_flutter/theme/components/cards.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/diary/diary_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/diary/diary_history_cubit.dart';
import 'package:audio_diaries_flutter/screens/home/domain/entities/study.dart';

class MockDiaryCubit extends Mock implements DiaryCubit {}

class MockDiaryHistoryCubit extends Mock implements DiaryHistoryCubit {}

class MockBox<T> extends Mock implements Box<T> {
  @override
  List<T> getAll() {
    if (T.toString() == 'Study') {
      return [
        Study(
          id: 1,
          studyId: 1,
          name: 'Test Study',
          experimentCode: 'EXP123',
          goals: jsonEncode({'daily': 1, 'weekly': 1}),
          incentive: jsonEncode({
            'amount': '5.0',
            'bonus': '10.0',
            'currency': 'MWK',
            'threshold': 80,
          }),
        )
      ] as List<T>;
    }
    return [];
  }
}

class MockStore extends Mock implements Store {
  final _boxes = <String, Box>{};

  @override
  Box<T> box<T>() {
    final typeKey = T.toString();
    return _boxes.putIfAbsent(typeKey, () => MockBox<T>()) as Box<T>;
  }
}

class MockObjectBox extends Mock implements ObjectBox {
  @override
  late final Store store = MockStore();
}

// Dummy Diary
final dummyDiary = DiaryModel(
  id: 1,
  studyID: 1,
  name: 'Test Diary',
  prompts: [],
  tags: null,
  status: DiaryStatus.idle,
  due: DateTime.now(),
  start: DateTime.now(),
  entries: 1,
  currentEntry: 0,
  end: DateTime.now(),
  notifications: [],
  activeDays: [],
  submissions: [],
  completions: const []
);

Future<void> pumpDiariesPageWithState(
  WidgetTester tester, {
  required DiaryHistoryState state,
  required DiaryCubit diaryCubit,
  required DiaryHistoryCubit historyCubit,
  bool waitForSettle = true,
}) async {
  when(() => historyCubit.state).thenReturn(state);
  when(() => historyCubit.stream).thenAnswer((_) => Stream.value(state));
  when(() => historyCubit.loadPastDiaries()).thenAnswer((_) async {});

  await tester.pumpWidget(
    ScreenUtilInit(
      minTextAdapt: true,
      designSize: const Size(1080, 1920),
      builder: (context, child) => MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<DiaryCubit>.value(value: diaryCubit),
            BlocProvider<DiaryHistoryCubit>.value(value: historyCubit),
          ],
          child: const DiariesPage(),
        ),
      ),
    ),
  );
  waitForSettle ? await tester.pumpAndSettle() : await tester.pump();
}

void main() {
  late MockDiaryCubit mockDiaryCubit;
  late MockDiaryHistoryCubit mockDiaryHistoryCubit;

  setUpAll(() => app.objectbox = MockObjectBox());

  setUp(() {
    mockDiaryCubit = MockDiaryCubit();
    mockDiaryHistoryCubit = MockDiaryHistoryCubit();
  });

  testWidgets('displays app bar, diary list, and diary cards', (tester) async {
    final diaries = {
      'Today': [dummyDiary]
    };

    await pumpDiariesPageWithState(
      tester,
      state: DiaryHistoryLoaded(diaries),
      diaryCubit: mockDiaryCubit,
      historyCubit: mockDiaryHistoryCubit,
      waitForSettle: true,
    );

    expect(find.text('History'), findsOneWidget);
    expect(find.byType(DiaryList), findsOneWidget);
    expect(find.byType(DiaryCard), findsNWidgets(1));
    expect(find.text('Test Diary'), findsOneWidget);

    await tester.tap(find.byType(DiaryCard));
    await tester.pumpAndSettle();

    expect(find.text('Test Diary'), findsOneWidget); // Detail screen title
  });

  testWidgets('shows loading indicator', (tester) async {
    await pumpDiariesPageWithState(
      tester,
      state: const DiaryHistoryLoading(),
      diaryCubit: mockDiaryCubit,
      historyCubit: mockDiaryHistoryCubit,
      waitForSettle: false,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty state', (tester) async {
    await pumpDiariesPageWithState(
      tester,
      state: const DiaryHistoryLoaded({}),
      diaryCubit: mockDiaryCubit,
      historyCubit: mockDiaryHistoryCubit,
      waitForSettle: true,
    );

    expect(find.byType(BeforeStartWidget), findsOneWidget);
  });

  testWidgets('triggers pull to refresh', (tester) async {
    final diaries = {
      'Today': [dummyDiary]
    };

    await pumpDiariesPageWithState(
      tester,
      state: DiaryHistoryLoaded(diaries),
      diaryCubit: mockDiaryCubit,
      historyCubit: mockDiaryHistoryCubit,
      waitForSettle: true,
    );

    final diaryList = find.byType(DiaryList);
    await tester.drag(diaryList, const Offset(0, 300));
    await tester.pumpAndSettle();

    verify(() => mockDiaryHistoryCubit.loadPastDiaries()).called(1);
  });

  testWidgets('renders multiple diary groups correctly', (tester) async {
    final diaries = {
      'Today': [dummyDiary],
      'Yesterday': [
        dummyDiary.copyWith(
          id: 2,
          name: 'Yesterday Diary',
          start: DateTime.now().subtract(const Duration(days: 1)),
          due: DateTime.now().subtract(const Duration(days: 1)),
          studyID: 1,
        )
      ],
    };

    await pumpDiariesPageWithState(
      tester,
      state: DiaryHistoryLoaded(diaries),
      diaryCubit: mockDiaryCubit,
      historyCubit: mockDiaryHistoryCubit,
      waitForSettle: true,
    );

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Test Diary'), findsOneWidget);
    expect(find.text('Yesterday Diary'), findsOneWidget);
  });
}
