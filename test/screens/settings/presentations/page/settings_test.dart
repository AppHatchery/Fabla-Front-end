import 'package:audio_diaries_flutter/core/database/dao/experiment_dao.dart';
import 'package:audio_diaries_flutter/screens/home/domain/entities/experiment.dart';
import 'package:audio_diaries_flutter/screens/hub/presentation/cubit/hub_cubit.dart';
import 'package:audio_diaries_flutter/screens/settings/presentation/settings.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/screens/home/data/experiment.dart';
import 'package:audio_diaries_flutter/screens/settings/widgets/participant_details.dart';
import 'package:audio_diaries_flutter/screens/settings/widgets/settings_active_reminders.dart';
import 'package:audio_diaries_flutter/screens/settings/widgets/study_details.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:audio_diaries_flutter/screens/settings/cubit/settings_cubit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audio_diaries_flutter/core/database/object_box.dart';
import 'package:audio_diaries_flutter/objectbox.g.dart';
import 'package:audio_diaries_flutter/main.dart' as app;

//mock class for the test
class MockSettingsCubit extends Mock implements SettingsCubit {
  @override
  Stream<SettingsState> get stream => Stream<SettingsState>.empty();

  @override
  SettingsState get state => SettingsInitial();
}

class MockHubCubit extends Mock implements HubCubit {
  @override
  Stream<HubState> get stream => Stream<HubState>.empty();

  @override
  HubState get state => const HubInitial();
}

class MockSetupRepository extends Mock implements SetupRepository {}

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

class MockExperimentDAO extends Mock implements ExperimentDAO {}

class MockObjectBox extends Mock implements ObjectBox {
  final experimentDAO = MockExperimentDAO();
  final Store _store = MockStore();

  @override
  Store get store => _store;
}

class MockBox<T> extends Mock implements Box<T> {
  @override
  List<T> getAll() {
    if (T == Experiment) {
      return [
        Experiment(
          id: 1,
          login: 'test-login',
          researcher: 'Test Researcher',
          organization: 'Test Organization',
          name: 'Test Study',
          duration: '30 days',
          description: 'Test Description',
          version: '1.0.0',
        )
      ] as List<T>;
    }
    return [];
  }
}

Widget createTestableWidget(
    MockSettingsCubit mockSettingsCubit, MockSetupRepository mockRepository) {
  final mockHubCubit = MockHubCubit();

  return ScreenUtilInit(
    designSize: const Size(1080, 1920),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) {
      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
            BlocProvider<HubCubit>.value(value: mockHubCubit),
            RepositoryProvider<SetupRepository>.value(value: mockRepository),
          ],
          child: const Settings(),
        ),
      );
    },
  );
}

void main() {
  late MockSettingsCubit mockSettingsCubit;
  late MockSetupRepository mockSetupRepository;
  late MockExperimentDAO mockExperimentDAO;
  late MockObjectBox mockObjectBox;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(ExperimentModel(
      id: 0,
      login: '',
      researcher: '',
      organization: '',
      name: '',
      duration: '',
      description: '',
      version: '',
    ));
  });

  setUp(() {
    // Initialize mocks
    mockSettingsCubit = MockSettingsCubit();
    mockSetupRepository = MockSetupRepository();
    mockExperimentDAO = MockExperimentDAO();
    mockObjectBox = MockObjectBox();

    // Setup test experiment data
    final testExperiment = ExperimentModel(
      id: 1,
      login: 'test-login',
      researcher: 'Test Researcher',
      organization: 'Test Organization',
      name: 'Test Study',
      duration: '30 days',
      description: 'Test Description',
      version: '1.0.0',
    );

    // Mock experiment for DAO
    final mockDaoExperiment = Experiment(
      id: 1,
      login: 'test-login',
      researcher: 'Test Researcher',
      organization: 'Test Organization',
      name: 'Test Study',
      duration: '30 days',
      description: 'Test Description',
      version: '1.0.0',
    );

    // Setup mocks in correct order
    when(() => mockExperimentDAO.getExperiment()).thenReturn(mockDaoExperiment);

    when(() => mockSetupRepository.getExperiment()).thenReturn(testExperiment);

    when(() => mockSetupRepository.getParticipant()).thenReturn(null);

    // Set up app.objectbox after mocking
    app.objectbox = mockObjectBox;
  });

  testWidgets('AppBar displays proper title and has correct styles',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        createTestableWidget(mockSettingsCubit, mockSetupRepository));
    await tester.pumpAndSettle();

    final appFinder = find.byType(AppBar);
    expect(appFinder, findsOneWidget);

    expect(find.text("Settings"), findsOneWidget);
  });

  testWidgets('Checking all texts displays and emory image displays',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        createTestableWidget(mockSettingsCubit, mockSetupRepository));
    await tester.pumpAndSettle();

    expect(find.text('Enable Microphone Access'), findsOneWidget);
    expect(
        find.text('You must enable microphone Access to record audio diaries.'),
        findsOneWidget);
    expect(find.text('Open Settings'), findsNWidgets(2));
    expect(find.byKey(Key("emory_image")), findsOneWidget);
    expect(find.text("Microphone"), findsOneWidget);
    expect(find.text("Study Details"), findsOneWidget);
    expect(find.text("Participant Details"), findsOneWidget);
    expect(
        find.text(
            "We will keep you in the loop on your entries and provide reminders for completion."),
        findsOneWidget);
    expect(find.text("Enable Notifications"), findsOneWidget);
    expect(
        find.text("You must enable microphone Access to record audio diaries."),
        findsOneWidget);
    expect(find.text("Enable Microphone Access"), findsOneWidget);
    expect(find.text("Reminders"), findsOneWidget);
    expect(find.text("Add a Reminder Time"), findsOneWidget);
  });

  // study details
  testWidgets('Checking study details displays', (WidgetTester tester) async {
    await tester.pumpWidget(
        createTestableWidget(mockSettingsCubit, mockSetupRepository));
    await tester.pumpAndSettle();

    expect(find.text("Study Details"), findsOneWidget);

    final studyDetailsFinder = find.byType(SettingsStudyDetails);
    expect(studyDetailsFinder, findsOneWidget);

    final viewDetailsButtonFinder = find.byKey(Key("view_details_button"));
    expect(viewDetailsButtonFinder, findsOneWidget);

    final leaveStudyButtonFinder = find.byKey(Key("leave_study_button"));
    expect(leaveStudyButtonFinder, findsOneWidget);
  });

  // participant details
  testWidgets('Checking participant details displays',
      (WidgetTester tester) async {
    await tester.pumpWidget(
        createTestableWidget(mockSettingsCubit, mockSetupRepository));
    await tester.pumpAndSettle();

    expect(find.text("Participant Details"), findsOneWidget);

    final participantDetailsFinder = find.byType(ParticipantDetails);
    expect(participantDetailsFinder, findsOneWidget);

    // Verify initial state of ParticipantDetails
    expect(find.text("Onboarding Survey"), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    // Verify container styling
    final containerFinder = find.ancestor(
      of: find.text("Onboarding Survey"),
      matching: find.byType(Container),
    );
    final container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration as BoxDecoration;

    expect(decoration.borderRadius, BorderRadius.circular(16));
    expect(decoration.border?.top.color, CustomColors.productBorderNormal);

    // Verify layout structure
    expect(find.byType(Column), findsWidgets);
    expect(find.byType(Row), findsWidgets);
    expect(find.byType(Padding), findsWidgets);

    // Verify text styling
    final titleFinder = find.text("Participant Details");
    final titleWidget = tester.widget<Text>(titleFinder);
    expect(titleWidget.style?.color, CustomColors.textNormalContent);
  });

  //Reminders
  testWidgets('Checking reminders displays', (WidgetTester tester) async {
    await tester.pumpWidget(
        createTestableWidget(mockSettingsCubit, mockSetupRepository));
    await tester.pumpAndSettle();

    final remindersFinder = find.byType(ActiveReminders);
    expect(remindersFinder, findsOneWidget);

    final addReminderTimeButtonFinder = find.text("Add a Reminder Time");
    expect(addReminderTimeButtonFinder, findsOneWidget);
  });
}
