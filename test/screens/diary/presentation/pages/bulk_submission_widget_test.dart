import 'package:audio_diaries_flutter/core/database/object_box.dart';
import 'package:audio_diaries_flutter/main.dart' as app;
import 'package:audio_diaries_flutter/objectbox.g.dart';
import 'package:audio_diaries_flutter/screens/diary/data/bulk_submission.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/cubit/bulk_submission/bulk_submission_cubit.dart';
import 'package:audio_diaries_flutter/screens/diary/presentation/pages/bulk_submission.dart';
import 'package:audio_diaries_flutter/screens/hub/presentation/cubit/hub_cubit.dart';
import 'package:audio_diaries_flutter/theme/components/buttons.dart';
import 'package:audio_diaries_flutter/theme/components/cards.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../dummy_data.dart';
import '../../../../mock_classes.mocks.dart';


class MockBulkSubmissionCubit extends Mock implements BulkSubmissionCubit {}
class MockHubCubit extends Mock implements HubCubit {}
class MockObjectBox extends Mock implements ObjectBox { // mock class from mock_classes.dart
@override
late final Store store = MockStore();
}

void main() {
  late MockBulkSubmissionCubit mockBulkSubmissionCubit;
  late MockHubCubit mockHubCubit;

  List<DiarySubmission> createTestSubmissions(
      int count, {
        SubmissionStatus? status,
      }) {
    final study = createTestStudyModel(); // study data from dummy_data.dart
    return List.generate(count, (index) {
      final diary = createTestDiaryModel( // diary data from dummy_data.dart
        id: index + 1,
        studyID: study.id,
        name: '${TestValues.testDiaryOngoing} ${index + 1}',
      );
      return DiarySubmission(
        diary: diary,
        study: study,
        status: status ?? SubmissionStatus.pending,
      );
    });
  }

  Widget createTestableWidget({
    required List<DiarySubmission> submissions,
    BulkSubmissionCubit? bulkCubit,
    HubCubit? hubCubit,
  }) {
    return ScreenUtilInit(
      minTextAdapt: true,
      designSize: const Size(1080, 1920),
      builder: (context, child) => MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<BulkSubmissionCubit>.value(
              value: bulkCubit ?? mockBulkSubmissionCubit,
            ),
            BlocProvider<HubCubit>.value(
              value: hubCubit ?? mockHubCubit,
            ),
          ],
          child: BulkSubmissionPage(submissions: submissions),
        ),
      ),
    );
  }

  setUpAll(() {
    app.objectbox = MockObjectBox();
    registerFallbackValue(createTestDiaryModel());
    registerFallbackValue(createTestSubmissions(1));
  });

  setUp(() {
    mockBulkSubmissionCubit = MockBulkSubmissionCubit();
    mockHubCubit = MockHubCubit();

    // Default mock behavior
    when(() => mockBulkSubmissionCubit.stream)
        .thenAnswer((_) => Stream.fromIterable([BulkSubmissionInitial()]));
    when(() => mockBulkSubmissionCubit.state)
        .thenReturn(BulkSubmissionInitial());
    when(() => mockBulkSubmissionCubit.startBulkSubmission(any()))
        .thenReturn(null);
    when(() => mockBulkSubmissionCubit.retryFailedSubmissions(any()))
        .thenReturn(null);
    when(() => mockBulkSubmissionCubit.close())
        .thenAnswer((_) async {});

    when(() => mockHubCubit.stream)
        .thenAnswer((_) => Stream.empty());
    when(() => mockHubCubit.refresh()).thenReturn(null);
    when(() => mockHubCubit.close()).thenAnswer((_) async {});
  });

  group('BulkSubmissionPage Widget Tests', () {
    testWidgets('displays correct app bar title', (WidgetTester tester) async {
      final submissions = createTestSubmissions(2);

      await tester.pumpWidget(createTestableWidget(submissions: submissions));

      expect(find.text('Entries to be uploaded'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows Return Home button initially disabled', (WidgetTester tester) async {
      final submissions = createTestSubmissions(2);

      await tester.pumpWidget(createTestableWidget(submissions: submissions));

      expect(find.text('Return Home'), findsOneWidget);

      final button = tester.widget<CustomFlatButton>(
        find.byType(CustomFlatButton),
      );
      expect(button.isDisabled, isTrue);
    });

    testWidgets('shows circular progress indicator initially', (WidgetTester tester) async {
      final submissions = createTestSubmissions(2);

      await tester.pumpWidget(createTestableWidget(submissions: submissions));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('calls startBulkSubmission on init', (WidgetTester tester) async {
      final submissions = createTestSubmissions(2);

      await tester.pumpWidget(createTestableWidget(submissions: submissions));

      verify(() => mockBulkSubmissionCubit.startBulkSubmission(submissions))
          .called(1);
    });

    testWidgets('displays submission cards when in progress', (WidgetTester tester) async {
      final submissions = createTestSubmissions(3);

      when(() => mockBulkSubmissionCubit.state)
          .thenReturn(BulkSubmissionInProgress(submissions));
      when(() => mockBulkSubmissionCubit.stream)
          .thenAnswer((_) => Stream.fromIterable([
        BulkSubmissionInProgress(submissions),
      ]));

      await tester.pumpWidget(createTestableWidget(submissions: submissions));
      await tester.pump();

      expect(find.byType(PendingSubmissionSmallCard), findsNWidgets(3));
    });

    testWidgets('shows uploading progress banner', (WidgetTester tester) async {
      final submissions = createTestSubmissions(2);

      when(() => mockBulkSubmissionCubit.state)
          .thenReturn(BulkSubmissionInProgress(submissions));
      when(() => mockBulkSubmissionCubit.stream)
          .thenAnswer((_) => Stream.fromIterable([
        BulkSubmissionInProgress(submissions),
      ]));

      await tester.pumpWidget(createTestableWidget(submissions: submissions));
      await tester.pump();

      expect(find.text('Uploading in Progress'), findsOneWidget);
      expect(
        find.text('Please wait until all your submissions are uploaded.'),
        findsOneWidget,
      );
    });

    testWidgets('shows upload failed banner on failure', (WidgetTester tester) async {
      final submissions = createTestSubmissions(2);

      when(() => mockBulkSubmissionCubit.state)
          .thenReturn(BulkSubmissionFailed(submissions, 2));
      when(() => mockBulkSubmissionCubit.stream)
          .thenAnswer((_) => Stream.fromIterable([
        BulkSubmissionFailed(submissions, 2),
      ]));

      await tester.pumpWidget(createTestableWidget(submissions: submissions));
      await tester.pump();

      expect(find.text('Upload Failed'), findsOneWidget);
      expect(find.text('Retry Upload'), findsOneWidget);
      expect(
        find.text('2 diary submissions could not be uploaded and are still pending'),
        findsOneWidget,
      );
    });

    testWidgets('enables Return Home button after failure', (WidgetTester tester) async {
      final submissions = createTestSubmissions(2);

      when(() => mockBulkSubmissionCubit.state)
          .thenReturn(BulkSubmissionFailed(submissions, 2));
      when(() => mockBulkSubmissionCubit.stream)
          .thenAnswer((_) => Stream.fromIterable([
        BulkSubmissionFailed(submissions, 2),
      ]));

      await tester.pumpWidget(createTestableWidget(submissions: submissions));
      await tester.pump();

      final button = tester.widget<CustomFlatButton>(
        find.byType(CustomFlatButton),
      );
      expect(button.isDisabled, isFalse);
    });

    testWidgets('retry button calls retryFailedSubmissions', (WidgetTester tester) async {
      final submissions = createTestSubmissions(2);

      when(() => mockBulkSubmissionCubit.state)
          .thenReturn(BulkSubmissionFailed(submissions, 2));
      when(() => mockBulkSubmissionCubit.stream)
          .thenAnswer((_) => Stream.fromIterable([
        BulkSubmissionFailed(submissions, 2),
      ]));

      await tester.pumpWidget(createTestableWidget(submissions: submissions));
      await tester.pump();

      await tester.tap(find.text('Retry Upload'));

      verify(() => mockBulkSubmissionCubit.retryFailedSubmissions(any()))
          .called(1);
    });

    testWidgets('shows singular text for single failed submission', (WidgetTester tester) async {
      final submissions = createTestSubmissions(1);

      when(() => mockBulkSubmissionCubit.state)
          .thenReturn(BulkSubmissionFailed(submissions, 1));
      when(() => mockBulkSubmissionCubit.stream)
          .thenAnswer((_) => Stream.fromIterable([
        BulkSubmissionFailed(submissions, 1),
      ]));

      await tester.pumpWidget(createTestableWidget(submissions: submissions));
      await tester.pump();

      expect(
        find.text('1 diary submission could not be uploaded and is still pending'),
        findsOneWidget,
      );
    });

    testWidgets('handles empty submissions list', (WidgetTester tester) async {
      final submissions = <DiarySubmission>[];

      when(() => mockBulkSubmissionCubit.state)
          .thenReturn(BulkSubmissionInProgress(submissions));
      when(() => mockBulkSubmissionCubit.stream)
          .thenAnswer((_) => Stream.fromIterable([
        BulkSubmissionInProgress(submissions),
      ]));

      await tester.pumpWidget(createTestableWidget(submissions: submissions));
      await tester.pump();

      expect(find.byType(PendingSubmissionSmallCard), findsNothing);
      expect(find.text('Uploading in Progress'), findsOneWidget);
    });


    testWidgets('prevents back navigation when not complete', (WidgetTester tester) async {
      final submissions = createTestSubmissions(2);

      when(() => mockBulkSubmissionCubit.state)
          .thenReturn(BulkSubmissionInProgress(submissions));
      when(() => mockBulkSubmissionCubit.stream)
          .thenAnswer((_) => Stream.fromIterable([
        BulkSubmissionInProgress(submissions),
      ]));

      await tester.pumpWidget(createTestableWidget(submissions: submissions));
      await tester.pump();

      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse);
    });

    testWidgets('handles large number of submissions', (WidgetTester tester) async {
      final submissions = createTestSubmissions(10);

      when(() => mockBulkSubmissionCubit.state)
          .thenReturn(BulkSubmissionInProgress(submissions));
      when(() => mockBulkSubmissionCubit.stream)
          .thenAnswer((_) => Stream.fromIterable([
        BulkSubmissionInProgress(submissions),
      ]));

      await tester.pumpWidget(createTestableWidget(submissions: submissions));
      await tester.pump();

      expect(find.byType(PendingSubmissionSmallCard), findsNWidgets(10));
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('verifies basic button styling properties', (WidgetTester tester) async {
      final submissions = createTestSubmissions(2);

      when(() => mockBulkSubmissionCubit.state)
          .thenReturn(BulkSubmissionFailed(submissions, 2));
      when(() => mockBulkSubmissionCubit.stream)
          .thenAnswer((_) => Stream.fromIterable([
        BulkSubmissionFailed(submissions, 2),
      ]));

      await tester.pumpWidget(createTestableWidget(submissions: submissions));
      await tester.pump();

      // Check that both button types are present
      expect(find.byType(CustomFlatButton), findsOneWidget);
      expect(find.byType(CustomOutlineButton), findsOneWidget);
    });
  });
}