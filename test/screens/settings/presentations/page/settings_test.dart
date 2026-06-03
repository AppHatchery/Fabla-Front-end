// Widget tests for the redesigned Settings page.
//
// `SettingsStudyDetails` and `ParticipantDetails` each build their OWN
// `SetupRepository`, which reads:
//   - the experiment through `box.getAll()`            (ExperimentDAO)
//   - the participant through `box.query()....findFirst()` (ParticipantDAO)
// Both screens render a `CircularProgressIndicator` until that data hydrates,
// so the mock store has to satisfy the participant query chain or `pumpAndSettle`
// would time out on the spinner. SharedPreferences / PackageInfo / permission
// channels are mocked for the same reason (deterministic, no plugin exceptions).
import 'package:audio_diaries_flutter/core/database/object_box.dart';
import 'package:audio_diaries_flutter/objectbox.g.dart';
import 'package:audio_diaries_flutter/main.dart' as app;
import 'package:audio_diaries_flutter/screens/home/data/experiment.dart';
import 'package:audio_diaries_flutter/screens/home/domain/entities/experiment.dart';
import 'package:audio_diaries_flutter/screens/hub/presentation/cubit/hub_cubit.dart';
import 'package:audio_diaries_flutter/screens/onboarding/data/questions.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/participant.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/screens/settings/cubit/settings_cubit.dart';
import 'package:audio_diaries_flutter/screens/settings/presentation/settings.dart';
import 'package:audio_diaries_flutter/screens/settings/widgets/participant_details.dart';
import 'package:audio_diaries_flutter/screens/settings/widgets/settings_active_reminders.dart';
import 'package:audio_diaries_flutter/screens/settings/widgets/study_details.dart';
import 'package:audio_diaries_flutter/theme/custom_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Cubit mocks ──────────────────────────────────────────────────────────────
class MockSettingsCubit extends Mock implements SettingsCubit {
  // Defaults to SettingsInitial; individual tests can override via [stubbedState]
  // to drive the loaded UI (e.g. the onboarding survey tile).
  SettingsState stubbedState = SettingsInitial();

  @override
  Stream<SettingsState> get stream => Stream<SettingsState>.empty();

  @override
  SettingsState get state => stubbedState;
}

class MockHubCubit extends Mock implements HubCubit {
  @override
  Stream<HubState> get stream => Stream<HubState>.empty();

  @override
  HubState get state => const HubInitial();
}

class MockSetupRepository extends Mock implements SetupRepository {}

// ── ObjectBox mocks ──────────────────────────────────────────────────────────
class MockParticipantBox extends Mock implements Box<Participant> {}

class MockParticipantQueryBuilder extends Mock
    implements QueryBuilder<Participant> {}

class MockParticipantQuery extends Mock implements Query<Participant> {}

/// Generic fallback box. `getAll()` returns a single experiment so
/// `ExperimentDAO.getExperiment()` (`box.getAll().first`) resolves; every other
/// type returns an empty list (those boxes are constructed but never queried).
class MockBox<T> extends Mock implements Box<T> {
  @override
  List<T> getAll() {
    if (T == Experiment) {
      return <Experiment>[
        Experiment(
          id: 1,
          login: 'test-login',
          researcher: 'Test Researcher',
          organization: 'Test Organization',
          name: 'Test Study',
          duration: '30 days',
          description: 'Test Description',
          version: '1.0.0',
          ownerEmail: 'test@test.com',
        ),
      ] as List<T>;
    }
    return <T>[];
  }
}

class MockStore extends Mock implements Store {
  MockStore(this.participantBox);

  final Box<Participant> participantBox;
  final _boxes = <String, Box>{};

  @override
  Box<T> box<T>() {
    if (T == Participant) return participantBox as Box<T>;
    return _boxes.putIfAbsent(T.toString(), () => MockBox<T>()) as Box<T>;
  }
}

class MockObjectBox extends Mock implements ObjectBox {
  MockObjectBox(Box<Participant> participantBox)
      : _store = MockStore(participantBox);

  final Store _store;

  @override
  Store get store => _store;
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

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    registerFallbackValue(ExperimentModel(
      id: 0,
      login: '',
      researcher: '',
      organization: '',
      name: '',
      duration: '',
      description: '',
      version: '',
      ownerEmail: '',
    ));

    // PackageInfo.fromPlatform() is awaited by Settings and SettingsStudyDetails.
    PackageInfo.setMockInitialValues(
      appName: 'Fabla',
      packageName: 'com.test.fabla',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );

    // Keep microphone + notification permissions "denied" (status index 0) so the
    // enable-permission cards — and their two "Open Settings" buttons — stay visible.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (call) async => call.method == 'requestPermissions' ? <int, int>{} : 0,
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    mockSettingsCubit = MockSettingsCubit();
    mockSetupRepository = MockSetupRepository();

    when(() => mockSetupRepository.getExperiment()).thenReturn(ExperimentModel(
      id: 1,
      login: 'test-login',
      researcher: 'Test Researcher',
      organization: 'Test Organization',
      name: 'Test Study',
      duration: '30 days',
      description: 'Test Description',
      version: '1.0.0',
      ownerEmail: 'test@test.com',
    ));
    when(() => mockSetupRepository.getParticipant()).thenReturn(null);

    // ParticipantDAO.get() == box.query().build().findFirst()
    final participantBox = MockParticipantBox();
    final participantQueryBuilder = MockParticipantQueryBuilder();
    final participantQuery = MockParticipantQuery();
    when(() => participantBox.query()).thenReturn(participantQueryBuilder);
    when(() => participantQueryBuilder.build()).thenReturn(participantQuery);
    when(() => participantQuery.findFirst())
        .thenReturn(Participant(id: 1, name: 'Test User', studyCode: 'TEST123'));

    app.objectbox = MockObjectBox(participantBox);
  });

  testWidgets('AppBar displays the Settings title', (tester) async {
    await tester.pumpWidget(
        createTestableWidget(mockSettingsCubit, mockSetupRepository));
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Displays section headers, permission cards, and footer image',
      (tester) async {
    await tester.pumpWidget(
        createTestableWidget(mockSettingsCubit, mockSetupRepository));
    await tester.pumpAndSettle();

    // Section headers.
    expect(find.text('Microphone'), findsOneWidget);
    expect(find.text('Study Details'), findsOneWidget);
    expect(find.text('Participant Details'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);

    // Microphone permission card (permission denied in tests).
    expect(find.text('Enable Microphone Access'), findsOneWidget);
    expect(
        find.text('You must enable microphone Access to record audio diaries.'),
        findsOneWidget);

    // Notification permission card (permission denied in tests).
    expect(find.text('Enable Notifications'), findsOneWidget);
    expect(
        find.text(
            'We will keep you in the loop on your entries and provide reminders for completion.'),
        findsOneWidget);

    // One "Open Settings" in the microphone card, one in the notification card.
    expect(find.text('Open Settings'), findsNWidgets(2));

    // Reminders action, leave-study action, and footer image.
    expect(find.text('+ Add Reminder'), findsOneWidget);
    expect(find.text('Leave Study'), findsOneWidget);
    expect(find.byKey(const Key('emory_image')), findsOneWidget);
  });

  testWidgets('Renders study details actions', (tester) async {
    await tester.pumpWidget(
        createTestableWidget(mockSettingsCubit, mockSetupRepository));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsStudyDetails), findsOneWidget);
    expect(find.text('Study Details'), findsOneWidget);

    // New design: View Details + Update Study buttons, plus Contact Researcher.
    expect(find.byKey(const Key('view_details_button')), findsOneWidget);
    expect(find.byKey(const Key('update_study')), findsOneWidget);
    expect(find.text('View Details'), findsOneWidget);
    expect(find.text('Update Study'), findsOneWidget);
    expect(find.text('Contact Researcher'), findsOneWidget);
  });

  testWidgets('Renders participant details', (tester) async {
    // Drive the loaded state so the onboarding survey tile is shown. The tile
    // is now only rendered when onboarding questions exist.
    mockSettingsCubit.stubbedState = const SettingsLoaded(
      onboardingQuestion: [
        Questions(
          id: 1,
          title: 'Sample question',
          subtitle: null,
          options: null,
          type: 'text',
          min: null,
          max: null,
          defaultValue: null,
          minLabel: null,
          maxLabel: null,
          variable: 'sample',
          answer: null,
        ),
      ],
      completedDate: '01 Jan 2025',
    );

    await tester.pumpWidget(
        createTestableWidget(mockSettingsCubit, mockSetupRepository));
    await tester.pumpAndSettle();

    expect(find.byType(ParticipantDetails), findsOneWidget);
    expect(find.text('Participant Details'), findsOneWidget);

    // Participant fields sourced from the mocked query chain.
    expect(find.text('Participant ID'), findsOneWidget);
    expect(find.text('TEST123'), findsOneWidget);
    expect(find.text('Study String'), findsOneWidget);
    expect(find.text('test-login'), findsOneWidget);

    // Onboarding survey tile.
    expect(find.text('Onboarding Survey'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    // Survey tile container styling.
    final container = tester.widget<Container>(
      find.ancestor(
        of: find.text('Onboarding Survey'),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(16));
    expect(decoration.border?.top.color, CustomColors.productBorderNormal);

    // Title styling.
    final title = tester.widget<Text>(find.text('Participant Details'));
    expect(title.style?.color, CustomColors.textNormalContent);
  });

  testWidgets('Renders the reminders section', (tester) async {
    await tester.pumpWidget(
        createTestableWidget(mockSettingsCubit, mockSetupRepository));
    await tester.pumpAndSettle();

    expect(find.byType(ActiveReminders), findsOneWidget);
    expect(find.text('+ Add Reminder'), findsOneWidget);
    expect(find.text('No Scheduled Reminder Time'), findsOneWidget);
  });
}
