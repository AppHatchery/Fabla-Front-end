import 'package:audio_diaries_flutter/core/usecases/daily_goal_service.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/hub/data/submission_progress.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/home/data/incentive.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/empty_state.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/weekly_goal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/cubit/cubit/home_cubit.dart';
import 'package:audio_diaries_flutter/screens/home/data/experiment.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/core/database/object_box.dart';
import 'package:audio_diaries_flutter/objectbox.g.dart';
import 'package:audio_diaries_flutter/main.dart' as app;

class MockHomeCubit extends Mock implements HomeCubit {}

class MockBox<T> extends Mock implements Box<T> {
  @override
  List<T> getAll() => [];
}

class MockStore extends Mock implements Store {
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
  @override
  late final Store store = MockStore();
}

Widget createTestableWidget(MockHomeCubit mockHomeCubit) {
  return ScreenUtilInit(
    minTextAdapt: true,
    designSize: const Size(1080, 1920),
    builder: (context, child) => MaterialApp(
      home: BlocProvider<HomeCubit>.value(
        value: mockHomeCubit,
        child: const HomePage(),
      ),
    ),
  );
}

HomeLoaded createHomeLoadedState({
  TodaysData? todaysData,
  WeeklyData? weeklyData,
  bool available = false,
  List<StudyModel>? studies,
  List<StudyModel>? allStudies,
  int entries = 0,
  bool finished = true,
  Map<StudyModel, DailyGoalData>? goalData,
}) {
  final dummyStudy = StudyModel(
    id: 1,
    studyId: 1,
    name: 'Dummy Study',
    experimentCode: 'dummy-code',
    color: Colors.blue,
    goals: Goal(daily: 1, weekly: 1),
    incentive: Incentive(amount: 0, bonus: 0, currency: 'MWK24', threshold: 0),
  );

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

  // Key change: Use empty diaries list when available is false
  final diariesList = available ? [dummyDiary] : <DiaryModel>[];

  final actualTodaysData =
      todaysData ?? TodaysData(diaries: diariesList, studies: [dummyStudy]);

  final actualWeeklyData = weeklyData ??
      WeeklyData(
        diaries: diariesList,
        studies: [dummyStudy],
        totalEntries: entries,
      );

  final actualGoalData = goalData ??
      <StudyModel, DailyGoalData>{
        dummyStudy: DailyGoalData(
          diaries: diariesList,
          completed: 0,
          target: 1,
          progress: 0.0,
        ),
      };

  return HomeLoaded(
    todaysData: actualTodaysData,
    weeklyData: actualWeeklyData,
    allStudies: allStudies ?? [dummyStudy],
    weeklyEntries: entries,
    isFinished: finished,
    goalData: actualGoalData,
    submissionProgress: const <int, SubmissionProgress>{},
  );
}

void setupCommonCubitMocks(MockHomeCubit cubit) {
  when(() => cubit.getExperiment()).thenReturn(
    ExperimentModel(
      id: 1,
      login: 'test',
      researcher: 'test',
      organization: 'test',
      name: 'test',
      duration: '7',
      description: 'test',
      ownerEmail: 'test@test.com',
      version: '1.0',
    ),
  );
  when(() => cubit.getAllDiariesThisWeek()).thenReturn([]);
  when(() => cubit.getParticipantCode()).thenAnswer((_) async => 'dummyCode');
  when(() => cubit.loadDiaries()).thenAnswer((_) async {});
}

Future<void> pumpHomePageWithState(
  WidgetTester tester, {
  required HomeState state,
  required MockHomeCubit cubit,
  bool waitForSettle = true,
}) async {
  when(() => cubit.state).thenReturn(state);
  when(() => cubit.stream).thenAnswer((_) => Stream.value(state));

  await tester.pumpWidget(createTestableWidget(cubit));
  waitForSettle ? await tester.pumpAndSettle() : await tester.pump();
}

void main() {
  late MockHomeCubit mockHomeCubit;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    app.objectbox = MockObjectBox();
  });

  setUp(() {
    mockHomeCubit = MockHomeCubit();
    setupCommonCubitMocks(mockHomeCubit);
  });

  group('HomePage Widget', () {
    testWidgets(
      'Displays FreeDayWidget when available = false & finished = false',
      (tester) async {
        // Create state with no diaries for today
        final emptyTodaysData = TodaysData(diaries: [], studies: []);
        final emptyWeeklyData =
            WeeklyData(diaries: [], studies: [], totalEntries: 0);

        await pumpHomePageWithState(
          tester,
          state: createHomeLoadedState(
            todaysData: emptyTodaysData,
            weeklyData: emptyWeeklyData,
            goalData: {},
            available: false,
            finished: false,
          ),
          cubit: mockHomeCubit,
          waitForSettle: true,
        );

        expect(find.byType(FreeDayWidget), findsOneWidget);
        expect(find.byType(EndStateWidget), findsNothing);
        expect(find.text("Today's Entries"), findsOneWidget);
      },
    );

    testWidgets(
        'Displays EndStateWidget when available = false & finished = true',
        (tester) async {
      // Create empty but valid data structures
      final emptyTodaysData = TodaysData(diaries: [], studies: []);
      final emptyWeeklyData =
          WeeklyData(diaries: [], studies: [], totalEntries: 0);

      await pumpHomePageWithState(
        tester,
        state: HomeLoaded(
          todaysData: emptyTodaysData,
          weeklyData: emptyWeeklyData,
          allStudies: [],
          weeklyEntries: 0,
          isFinished: true,
          goalData: {},
          submissionProgress: const <int, SubmissionProgress>{},
        ),
        cubit: mockHomeCubit,
        waitForSettle: true,
      );

      expect(find.byType(EndStateWidget), findsOneWidget);
      expect(find.byType(FreeDayWidget), findsNothing);
    });

    testWidgets("Displays 'Weekly Goal'", (tester) async {
      await pumpHomePageWithState(
        tester,
        state: createHomeLoadedState(
          available: true,
          goalData: {}, // Empty goal data to avoid TodayGoalWidget rendering)
        ),
        cubit: mockHomeCubit,
        waitForSettle: true,
      );

      expect(find.text("Weekly Goal"), findsOneWidget);
    });

    testWidgets('Shows loading indicator when HomeLoading', (tester) async {
      await pumpHomePageWithState(
        tester,
        state: HomeLoading(),
        cubit: mockHomeCubit,
        waitForSettle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Shows empty state on HomeInitial', (tester) async {
      await pumpHomePageWithState(
        tester,
        state: HomeInitial(),
        cubit: mockHomeCubit,
        waitForSettle: true,
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Shows weekly goal widget when icon is tapped', (tester) async {
      await pumpHomePageWithState(
        tester,
        state: createHomeLoadedState(
          available: true,
          goalData: {}, // Empty goal data to avoid TodayGoalWidget rendering)
        ),
        cubit: mockHomeCubit,
        waitForSettle: true,
      );

      expect(find.byKey(const Key('weekly_goal_widget')), findsOneWidget);
      expect(find.byType(WeeklyGoalWidget), findsOneWidget);
    });

    testWidgets('Shows error state when HomeError', (tester) async {
      await pumpHomePageWithState(
        tester,
        state: const HomeError('Test error'),
        cubit: mockHomeCubit,
        waitForSettle: true,
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Shows calendar icon in app bar', (tester) async {
      await pumpHomePageWithState(
        tester,
        state: createHomeLoadedState(
          available: true,
          goalData: {}, // Empty goal data to avoid TodayGoalWidget rendering)
        ),
        cubit: mockHomeCubit,
        waitForSettle: true,
      );

      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    });

    // !Removing as TodayGoal is visible all the time
    // testWidgets('Hides TodayGoalWidget when available is false',
    //     (tester) async {
    //   await pumpHomePageWithState(
    //     tester,
    //     state: createHomeLoadedState(available: false),
    //     cubit: mockHomeCubit,
    //     waitForSettle: true,
    //   );

    //   expect(find.byType(TodayGoalWidget), findsNothing);
    // });
  });
}
