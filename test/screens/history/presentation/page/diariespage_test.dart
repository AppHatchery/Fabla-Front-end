import 'dart:convert';

import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/diary/diary_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/pages/diaries.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/diary_list.dart';
import 'package:audio_diaries_flutter/screens/home/domain/entities/study.dart';
import 'package:audio_diaries_flutter/theme/components/cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/diary/diary_history_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:audio_diaries_flutter/core/database/object_box.dart';
import 'package:audio_diaries_flutter/objectbox.g.dart';
import 'package:audio_diaries_flutter/main.dart' as app;
import 'package:audio_diaries_flutter/screens/diary/presentation/widgets/empty_state.dart';

// Create a dummy diary for testing
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
);

class MockDiaryCubit extends Mock implements DiaryCubit {}

class MockDiaryHistoryCubit extends Mock implements DiaryHistoryCubit {}

@override
class MockBox<T> extends Mock implements Box<T> {
  @override
  List<T> getAll() {
    if (T.toString() == 'Study') {
      // Returning a dummy Study object for testing
      // In a real scenario, this would fetch from the database
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
              'threshold': 80
            }))
      ] as List<T>;
    }
    return [];
  }
}

class MockStore extends Mock implements Store {
  /// A map to hold the mock boxes for different types.
  final _boxes = <String, Box>{};

  @override
  Box<T> box<T>() {
    final typeKey = T.toString();
    if (!_boxes.containsKey(typeKey)) {
      final box = MockBox<T>();
      _boxes[typeKey] = box;
    }
    return _boxes[typeKey] as Box<T>;
  }
}

class MockObjectBox extends Mock implements ObjectBox {
  // Mocking the store property to return a MockStore instance
  @override
  late final Store store = MockStore();
}

Widget createTestableWidget(MockDiaryCubit mockDiaryCubit) {
  // This function creates a widget tree for testing DiariesPage with a mocked DiaryCubit.
  // It uses ScreenUtilInit for responsive design and sets up the MaterialApp with MultiBlocProvider.
  return ScreenUtilInit(
    minTextAdapt: true,
    designSize: const Size(1080, 1920),
    builder: (context, child) => MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<DiaryCubit>.value(value: mockDiaryCubit),
          BlocProvider<DiaryHistoryCubit>(
              create: (context) => DiaryHistoryCubit()),
        ],
        child: const DiariesPage(),
      ),
    ),
  );
}

void main() {
  // This is the main function for the test suite.
  // It sets up the necessary mocks and runs the widget tests for DiariesPage.
  late MockDiaryCubit mockDiaryCubit;
  late MockDiaryHistoryCubit mockDiaryHistoryCubit;

  setUpAll(() async {
    app.objectbox = MockObjectBox();
  });
  setUp(() {
    mockDiaryCubit = MockDiaryCubit();
    mockDiaryHistoryCubit = MockDiaryHistoryCubit();

    // Create a dummy diary for the test
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
    );

    final groupedDiaries = {
      'Today': [dummyDiary]
    };

    // Set up the mock to return the grouped diaries
    when(() => mockDiaryHistoryCubit.state)
        .thenReturn(DiaryHistoryLoaded(groupedDiaries));
    when(() => mockDiaryHistoryCubit.stream).thenAnswer((_) =>
        Stream<DiaryHistoryState>.value(DiaryHistoryLoaded(groupedDiaries)));
    when(() => mockDiaryHistoryCubit.loadPastDiaries())
        .thenAnswer((_) async {});
  });
  testWidgets(
      'DiariesPage displays correct app bar, diary list cards and navigates to diary details',
      (WidgetTester tester) async {
    // This test checks if the DiariesPage displays the correct app bar title
    // and if the diary list cards are rendered correctly.
    await tester.pumpWidget(
      ScreenUtilInit(
        minTextAdapt: true,
        designSize: const Size(1080, 1920),
        builder: (context, child) => MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<DiaryCubit>.value(value: mockDiaryCubit),
              BlocProvider<DiaryHistoryCubit>.value(
                  value: mockDiaryHistoryCubit),
            ],
            child: const DiariesPage(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // AppBar title check
    expect(find.text('History'), findsOneWidget);

    // DiaryList present
    final diaryList = find.byType(DiaryList);
    expect(diaryList, findsOneWidget);

    //listview builder present
    final listView = find.descendant(
      of: diaryList,
      matching: find.byKey(const Key("diary_list_view")),
    );
    expect(listView, findsOneWidget);
    // Diary Card present
    final diaryCardList = find.descendant(
      of: listView,
      matching: find.byType(DiaryCard),
    );
    expect(diaryCardList, findsOneWidget);

    // Diary Card count
    final diaryCardCount = tester.widgetList<DiaryCard>(diaryCardList).length;
    expect(diaryCardCount, equals(1)); //one dummy diary

    await tester.tap(find.byType(DiaryCard));
    await tester.pumpAndSettle();
    // Check if the diary details page is pushed
    expect(find.text('Test Diary'), findsOneWidget);
  });

  testWidgets('DiariesPage shows loading indicator when in loading state',
      (WidgetTester tester) async {
    when(() => mockDiaryHistoryCubit.state)
        .thenReturn(const DiaryHistoryLoading());
    when(() => mockDiaryHistoryCubit.stream)
        .thenAnswer((_) => Stream.value(const DiaryHistoryLoading()));

    await tester.pumpWidget(
      ScreenUtilInit(
        minTextAdapt: true,
        designSize: const Size(1080, 1920),
        builder: (context, child) => MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<DiaryCubit>.value(value: mockDiaryCubit),
              BlocProvider<DiaryHistoryCubit>.value(
                  value: mockDiaryHistoryCubit),
            ],
            child: const DiariesPage(),
          ),
        ),
      ),
    );

    // Need to pump twice to allow the state to propagate
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('DiariesPage shows empty state when no diaries are available',
      (WidgetTester tester) async {
    when(() => mockDiaryHistoryCubit.state)
        .thenReturn(const DiaryHistoryLoaded({}));
    when(() => mockDiaryHistoryCubit.stream)
        .thenAnswer((_) => Stream.value(const DiaryHistoryLoaded({})));

    await tester.pumpWidget(
      ScreenUtilInit(
        minTextAdapt: true,
        designSize: const Size(1080, 1920),
        builder: (context, child) => MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<DiaryCubit>.value(value: mockDiaryCubit),
              BlocProvider<DiaryHistoryCubit>.value(
                  value: mockDiaryHistoryCubit),
            ],
            child: const DiariesPage(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byType(BeforeStartWidget), findsOneWidget);
  });

  testWidgets('DiariesPage refreshes when pull to refresh is triggered',
      (WidgetTester tester) async {
    final groupedDiaries = {
      'Today': [dummyDiary]
    };

    when(() => mockDiaryHistoryCubit.state)
        .thenReturn(DiaryHistoryLoaded(groupedDiaries));
    when(() => mockDiaryHistoryCubit.stream)
        .thenAnswer((_) => Stream.value(DiaryHistoryLoaded(groupedDiaries)));
    when(() => mockDiaryHistoryCubit.loadPastDiaries())
        .thenAnswer((_) async {});

    await tester.pumpWidget(
      ScreenUtilInit(
        minTextAdapt: true,
        designSize: const Size(1080, 1920),
        builder: (context, child) => MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<DiaryCubit>.value(value: mockDiaryCubit),
              BlocProvider<DiaryHistoryCubit>.value(
                  value: mockDiaryHistoryCubit),
            ],
            child: const DiariesPage(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    // Find the DiaryList widget which should contain the RefreshIndicator
    final diaryList = find.byType(DiaryList);
    expect(diaryList, findsOneWidget);

    // Trigger pull to refresh on the DiaryList
    await tester.drag(diaryList, const Offset(0, 300));
    await tester.pumpAndSettle();

    // Verify that loadPastDiaries was called
    verify(() => mockDiaryHistoryCubit.loadPastDiaries()).called(1);
  });

  testWidgets('DiariesPage displays correct diary information in cards',
      (WidgetTester tester) async {
    final groupedDiaries = {
      'Today': [dummyDiary]
    };

    when(() => mockDiaryHistoryCubit.state)
        .thenReturn(DiaryHistoryLoaded(groupedDiaries));
    when(() => mockDiaryHistoryCubit.stream)
        .thenAnswer((_) => Stream.value(DiaryHistoryLoaded(groupedDiaries)));

    await tester.pumpWidget(
      ScreenUtilInit(
        minTextAdapt: true,
        designSize: const Size(1080, 1920),
        builder: (context, child) => MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<DiaryCubit>.value(value: mockDiaryCubit),
              BlocProvider<DiaryHistoryCubit>.value(
                  value: mockDiaryHistoryCubit),
            ],
            child: const DiariesPage(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    // Verify diary card displays correct information
    expect(find.text('Test Diary'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('DiariesPage handles multiple diary groups correctly',
      (WidgetTester tester) async {
    final groupedDiaries = {
      'Today': [dummyDiary],
      'Yesterday': [
        DiaryModel(
          id: 2,
          studyID: 1,
          name: 'Yesterday Diary',
          prompts: [],
          tags: null,
          status: DiaryStatus.idle,
          due: DateTime.now().subtract(const Duration(days: 1)),
          start: DateTime.now().subtract(const Duration(days: 1)),
          entries: 1,
          currentEntry: 0,
          end: DateTime.now().subtract(const Duration(days: 1)),
          notifications: [],
          activeDays: [],
        )
      ]
    };

    when(() => mockDiaryHistoryCubit.state)
        .thenReturn(DiaryHistoryLoaded(groupedDiaries));
    when(() => mockDiaryHistoryCubit.stream)
        .thenAnswer((_) => Stream.value(DiaryHistoryLoaded(groupedDiaries)));

    await tester.pumpWidget(
      ScreenUtilInit(
        minTextAdapt: true,
        designSize: const Size(1080, 1920),
        builder: (context, child) => MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<DiaryCubit>.value(value: mockDiaryCubit),
              BlocProvider<DiaryHistoryCubit>.value(
                  value: mockDiaryHistoryCubit),
            ],
            child: const DiariesPage(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    // Verify both groups are displayed
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Test Diary'), findsOneWidget);
    expect(find.text('Yesterday Diary'), findsOneWidget);
  });
}
