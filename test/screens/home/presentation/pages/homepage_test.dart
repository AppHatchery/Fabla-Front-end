import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/screens/home/data/incentive.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/empty_state.dart';
import 'package:audio_diaries_flutter/screens/home/presentation/widgets/today_goal.dart';
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
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

class MockHomeCubit extends Mock implements HomeCubit {}

// Add a mock class for ObjectBox
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

// Sets up a dummy method channel handler for the Rive dynamic library.
class FakeRiveAnimationController extends Fake
    implements RiveAnimationController {}

class FakeRiveAnimation extends Fake {}

class FakeArtboard extends Fake implements RuntimeArtboard {}

class FakeRiveFile extends Fake implements RiveFile {}

class MockRiveFile extends Mock implements RiveFile {
  static Future<RiveFile> asset(String asset,
      {Uint8List? bytes, String? bundle}) async {
    return MockRiveFile();
  }
}

class MockRuntimeArtboard extends Mock implements RuntimeArtboard {}

class MockStateMachineInstance extends Mock {}

// Mock Rive's native functionality
class MockRiveTextHelper {
  static bool _initialized = false;
  static void init() {
    if (!_initialized) {
      _initialized = true;
    }
  }
}

class MockRiveDynamicLibraryHelper {
  static dynamic nativeLib() {
    return null;
  }
}

// Mock Rive widget to replace actual Rive animations during tests
class MockRiveWidget extends StatelessWidget {
  final String asset;
  final Function(Artboard)? onInit;
  final BoxFit fit;

  const MockRiveWidget({
    super.key,
    required this.asset,
    this.onInit,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // Return a simple colored container instead of the actual Rive animation
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Text('Mock Rive: $asset'),
      ),
    );
  }
}

// Override RiveAnimation.asset to use our mock widget during tests
class TestRiveAnimation {
  static Widget asset(
    String asset, {
    Function(Artboard)? onInit,
    BoxFit fit = BoxFit.cover,
  }) {
    return MockRiveWidget(
      asset: asset,
      onInit: onInit,
      fit: fit,
    );
  }
}

void setupRiveMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock the rive_common channel
  const MethodChannel channel = MethodChannel('rive_common');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'loadFile':
        return Uint8List(0).buffer.asUint8List();
      case 'initialize':
        return true;
      case 'loadDynamicLibrary':
        return true;
      default:
        return null;
    }
  });

  // Mock the rive_text channel
  const MethodChannel textChannel = MethodChannel('rive_text');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(textChannel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'init':
        return true;
      case 'loadTypeface':
        return true;
      default:
        return null;
    }
  });

  // Mock the rive_core channel
  const MethodChannel coreChannel = MethodChannel('rive_core');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(coreChannel, (MethodCall methodCall) async {
    return null;
  });

  registerFallbackValue(FakeRiveAnimationController());
  registerFallbackValue(FakeRiveAnimation());
  registerFallbackValue(FakeArtboard());
  registerFallbackValue(FakeRiveFile());
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

// Create a function to generate HomeLoaded state with custom parameters
HomeLoaded createHomeLoadedState({
  List<DiaryModel>? diaries,
  List<DiaryModel>? weeksDiaries,
  bool available = false,
  List<StudyModel>? studies,
  List<StudyModel>? allStudies,
  int entries = 0,
  bool finished = true,
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
  );

  return HomeLoaded(
    diaries ?? [dummyDiary],
    weeksDiaries ?? [dummyDiary],
    available,
    studies ?? [dummyStudy],
    allStudies ?? [dummyStudy],
    entries,
    finished,
  );
}

void main() {
  late MockHomeCubit mockHomeCubit;

  // Mock or initialize the global objectbox before tests
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    app.objectbox = MockObjectBox();
    setupRiveMocks();
  });

  setUp(() {
    setupRiveMocks();
    mockHomeCubit = MockHomeCubit();

    when(() => mockHomeCubit.getExperiment()).thenReturn(
      ExperimentModel(
        id: 1,
        login: 'test',
        researcher: 'test',
        organization: 'test',
        name: 'test',
        duration: '7',
        description: 'test',
        version: '1.0',
      ),
    );

    when(() => mockHomeCubit.getAllDiariesThisWeek()).thenReturn([]);

    final dummyStudy = StudyModel(
      id: 1,
      studyId: 1,
      name: 'Dummy Study',
      experimentCode: 'dummy-code',
      color: Colors.blue,
      goals: Goal(daily: 1, weekly: 1),
      incentive:
          Incentive(amount: 0, bonus: 0, currency: 'MWK24', threshold: 0),
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
    );

    HomeLoaded createHomeLoadedState({
      List<DiaryModel>? diaries,
      List<DiaryModel>? weeksDiaries,
      bool available = false,
      List<StudyModel>? studies,
      List<StudyModel>? allStudies,
      int entries = 0,
      bool finished = true,
    }) {
      return HomeLoaded(
        diaries ?? [dummyDiary],
        weeksDiaries ?? [dummyDiary],
        available,
        studies ?? [dummyStudy],
        allStudies ?? [dummyStudy],
        entries,
        finished,
      );
    }

    final homeLoadedState = createHomeLoadedState();

    when(() => mockHomeCubit.state).thenReturn(homeLoadedState);
    when(() => mockHomeCubit.stream)
        .thenAnswer((_) => Stream.value(homeLoadedState));
    when(() => mockHomeCubit.getParticipantCode())
        .thenAnswer((_) async => 'dummyCode');
    when(() => mockHomeCubit.loadDiaries())
        .thenAnswer((_) async => Future.value());
  });

  group('HomePage Widget', () {
    testWidgets(
        'Displays FreeDayWidget when available is false and finished is false',
        (tester) async {
      // Override both the state and stream with the desired values
      final testState =
          createHomeLoadedState(available: false, finished: false);

      when(() => mockHomeCubit.state).thenReturn(testState);
      when(() => mockHomeCubit.stream)
          .thenAnswer((_) => Stream.value(testState));

      await tester.pumpWidget(createTestableWidget(mockHomeCubit));
      await tester.pumpAndSettle();

      // Verify FreeDayWidget exists
      expect(find.byType(FreeDayWidget), findsOneWidget);
      // Verify EndStateWidget does not exist
      expect(find.byType(EndStateWidget), findsNothing);
      expect(find.text("Today's Entries"), findsOneWidget);
    });

    testWidgets(
        'Displays EndStateWidget when available is false and finished is true',
        (tester) async {
      // Update state to make available = false and finished = false
      final testState = createHomeLoadedState(available: false, finished: true);

      when(() => mockHomeCubit.state).thenReturn(testState);
      when(() => mockHomeCubit.stream)
          .thenAnswer((_) => Stream.value(testState));

      await tester.pumpWidget(createTestableWidget(mockHomeCubit));
      await tester.pumpAndSettle();
      // Verify FreeDayWidget exists
      expect(find.byType(EndStateWidget), findsOneWidget);
      // Verify EndStateWidget does not exist
      expect(find.byType(FreeDayWidget), findsNothing);
      expect(find.text("Today's Entries"), findsOneWidget);
    });

    testWidgets("displays Today's Entries text", (tester) async {
      await tester.pumpWidget(createTestableWidget(mockHomeCubit));
      await tester.pumpAndSettle();
      expect(find.text("Today's Entries"), findsOneWidget);
    });

    testWidgets("displays Weekly Goal text", (tester) async {
      await tester.pumpWidget(createTestableWidget(mockHomeCubit));
      await tester.pumpAndSettle();
      expect(find.text("Weekly Goal"), findsOneWidget);
    });

    testWidgets('shows loading indicator when state is HomeLoading',
        (tester) async {
      when(() => mockHomeCubit.state).thenReturn(HomeLoading());
      when(() => mockHomeCubit.stream)
          .thenAnswer((_) => Stream.value(HomeLoading()));

      await tester.pumpWidget(createTestableWidget(mockHomeCubit));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when state is HomeInitial', (tester) async {
      when(() => mockHomeCubit.state).thenReturn(HomeInitial());
      when(() => mockHomeCubit.stream)
          .thenAnswer((_) => Stream.value(HomeInitial()));

      await tester.pumpWidget(createTestableWidget(mockHomeCubit));
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows weekly goal widget when dropdown icon is tapped',
        (tester) async {
      await tester.pumpWidget(createTestableWidget(mockHomeCubit));
      await tester.pumpAndSettle();

      final weeklyIcon = find.byKey(const Key('weekly_goal_widget'));
      expect(weeklyIcon, findsOneWidget);

      expect(find.byType(WeeklyGoalWidget), findsOneWidget);
      expect(find.text('Weekly Goal'), findsOneWidget);
    });

    testWidgets('shows error state when state is HomeError', (tester) async {
      when(() => mockHomeCubit.state).thenReturn(const HomeError('Test error'));
      when(() => mockHomeCubit.stream)
          .thenAnswer((_) => Stream.value(const HomeError('Test error')));

      await tester.pumpWidget(createTestableWidget(mockHomeCubit));
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows calendar icon in app bar', (tester) async {
      await tester.pumpWidget(createTestableWidget(mockHomeCubit));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    });

    testWidgets('hides TodayGoalWidget when available is false',
        (tester) async {
      final testState = createHomeLoadedState(
        available: false,
        finished: false,
      );

      when(() => mockHomeCubit.state).thenReturn(testState);
      when(() => mockHomeCubit.stream)
          .thenAnswer((_) => Stream.value(testState));

      await tester.pumpWidget(createTestableWidget(mockHomeCubit));
      await tester.pumpAndSettle();

      expect(find.byType(TodayGoalWidget), findsNothing);
    });
  });
}
