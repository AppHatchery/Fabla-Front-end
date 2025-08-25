// Centralized Test Dummy Data
// -----------------------------------------------------------------------------
// This file contains factory functions for creating test entities, models, and
// data objects used across multiple test files. This centralizes test data
// creation and makes tests more maintainable.
// -----------------------------------------------------------------------------

// Core database entities
import 'dart:ui';

import 'package:audio_diaries_flutter/core/network/secrets_handler.dart';
import 'package:audio_diaries_flutter/screens/diary/data/notification.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/data/tag.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/answer.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/diary_entity.dart'
    as entity;
import 'package:audio_diaries_flutter/screens/diary/domain/entities/answer.dart'
    as entity;
import 'package:audio_diaries_flutter/screens/diary/domain/entities/prompt_entity.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/protocol_entity.dart';
import 'package:audio_diaries_flutter/screens/home/data/incentive.dart';
import 'package:audio_diaries_flutter/screens/home/data/study.dart';
import 'package:audio_diaries_flutter/screens/home/data/experiment.dart';
import 'package:audio_diaries_flutter/screens/home/domain/entities/experiment.dart';
import 'package:audio_diaries_flutter/screens/home/domain/entities/study.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/participant.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/entities/questions_entity.dart';

// Data models
import 'package:audio_diaries_flutter/screens/diary/data/diary.dart';
import 'package:audio_diaries_flutter/core/utils/statuses.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';

// Network models
import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/screens/diary/data/options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:audio_diaries_flutter/screens/onboarding/data/questions.dart';

// =============================================================================
// DATABASE ENTITIES
// =============================================================================

/// Creates a test Diary entity with optional parameters
entity.Diary createTestDiary({
  int id = 1,
  int studyID = 1,
  String name = 'Test Diary',
  DateTime? due,
  DateTime? start,
  int entries = 1,
  int currentEntry = 0,
  DateTime? end,
  String deadline = '2024-12-31',
  String notifications = '[]',
  List<int> activeDays = const [1, 2, 3],
}) {
  final now = DateTime.now();
  return entity.Diary(
    id: id,
    studyID: studyID,
    name: name,
    due: due ?? now,
    start: start ?? now,
    entries: entries,
    currentEntry: currentEntry,
    end: end ?? now.add(const Duration(days: 7)),
    deadline: deadline,
    notifications: notifications,
    activeDays: activeDays,
  );
}

/// Creates a test Answer entity with optional parameters
entity.Answer createTestAnswer({
  int id = 1,
  DateTime? date,
}) {
  return entity.Answer(
    id: id,
    date: date ?? DateTime.now(),
  );
}

/// Creates a test Prompt entity with optional parameters
Prompt createTestPrompt({
  int id = 1,
  int questionNumber = 1,
  String question = 'Test Question',
  ResponseType? responseType,
  String? option,
  String? subtitle,
  bool required = true,
  bool? multipleAnswer,
  int diaryId = 1,
}) {
  final prompt = Prompt(
    id: id,
    questionNumber: questionNumber,
    question: question,
    responseType: responseType,
    option: option,
    subtitle: subtitle,
    required: required,
    multipleAnswer: multipleAnswer,
  );

  // Mock the diary target relationship
  if (diaryId > 0) {
    prompt.diary.target = createTestDiary(id: diaryId);
  }
  return prompt;
}

/// Creates a test Experiment entity with optional parameters
Experiment createTestExperiment({
  int id = 1,
  String name = 'Test Experiment',
  String login = 'test_login',
  String researcher = 'test_researcher',
  String organization = 'test_org',
  String duration = '7 days',
  String description = 'Test description',
  String version = '1.0.0',
}) {
  return Experiment(
    id: id,
    name: name,
    login: login,
    researcher: researcher,
    organization: organization,
    duration: duration,
    description: description,
    version: version,
  );
}

/// Creates a test Study entity with optional parameters
Study createTestStudy({
  int id = 1,
  int studyId = 101,
  String name = 'Test Study',
  String experimentCode = 'TEST001',
  String goals = '{"goal1": "Test Goal 1", "goal2": "Test Goal 2"}',
  String incentive = '{"amount": 100, "currency": "USD"}',
}) {
  return Study(
    id: id,
    studyId: studyId,
    name: name,
    experimentCode: experimentCode,
    goals: goals,
    incentive: incentive,
  );
}

/// Creates a test Participant entity with optional parameters
Participant createTestParticipant({
  int id = 1,
  String name = 'Test User',
  String studyCode = 'TEST123',
}) {
  return Participant(
    id: id,
    name: name,
    studyCode: studyCode,
  );
}

/// Creates a test QuestionsEntity with optional parameters
QuestionsEntity createTestQuestion({
  int id = 1,
  String title = 'Test Question',
  String? subtitle = 'Test Subtitle',
  String? options,
  String type = 'text',
  int? min,
  int? max,
  int? defaultValue,
  String? minLabel,
  String? maxLabel,
  String variable = 'test_variable',
  String? answer,
}) {
  return QuestionsEntity(
    id: id,
    title: title,
    subtitle: subtitle,
    options: options,
    type: type,
    min: min,
    max: max,
    defaultValue: defaultValue,
    minLabel: minLabel,
    maxLabel: maxLabel,
    variable: variable,
    answer: answer,
  );
}

/// Creates a test ProtocolEntity with optional parameters
ProtocolEntity createTestProtocol({
  int id = 1,
  int version = 1,
  int weeklyGoal = 5,
  int dailyGoal = 1,
  List<String> diaryBlueprints = const ['blueprint1', 'blueprint2'],
}) {
  return ProtocolEntity(
    id: id,
    version: version,
    weeklyGoal: weeklyGoal,
    dailyGoal: dailyGoal,
    diaryBlueprints: diaryBlueprints,
  );
}

// =============================================================================
// DATA MODELS
// =============================================================================

/// Creates a test PromptModel with optional parameters
PromptModel createTestPromptModel({
  int id = 1,
  int questionNumber = 1,
  String question = 'Test Question',
  ResponseType responseType = ResponseType.text,
  Answer? answer,
  Options? option,
  bool required = true,
  String? subtitle,
  bool multipleAnswer = false,
}) {
  return PromptModel(
    id: id,
    questionNumber: questionNumber,
    question: question,
    responseType: responseType,
    answer: answer,
    option: option,
    required: required,
    subtitle: subtitle,
    multipleAnswer: multipleAnswer,
  );
}

/// Creates a test Notification with optional parameters
Notification createTestNotification({
  String title = 'Test Notification',
  String body = 'Test notification body',
  DateTime? date,
}) {
  return Notification(
    title: title,
    body: body,
    date: date ?? DateTime.now(),
  );
}

/// Creates a test Tag with optional parameters
Tag createTestTag({
  String text = 'Test Tag',
  TagType type = TagType.questions,
}) {
  return Tag(
    text: text,
    type: type,
  );
}

/// Creates a test Options with optional parameters
Options createTestOptions({
  OptionsType type = OptionsType.radio,
  List<String>? choices,
  String? minLabel,
  String? maxLabel,
  int? minValue,
  int? maxValue,
  int? defaultValue,
}) {
  return Options(
    type: type,
    choices: choices ?? ['Option 1', 'Option 2'],
    minLabel: minLabel,
    maxLabel: maxLabel,
    minValue: minValue,
    maxValue: maxValue,
    defaultValue: defaultValue,
  );
}

// =============================================================================
// DATA MODELS
// =============================================================================

/// Creates a test DiaryModel with optional parameters (FIXED VERSION)
DiaryModel createTestDiaryModel({
  int id = 1,
  int studyID = 1,
  String name = TestValues.testName,
  DateTime? start,
  DateTime? end,
  List<int>? activeDays,
  DiaryStatus status = DiaryStatus.complete,
  DateTime? due,
  int entries = 1,
  int currentEntry = 0,
  List<PromptModel>? prompts,
  List<Notification>? notifications,
  List<Tag>? tags,
}) {
  final now = DateTime.now();
  return DiaryModel(
    id: id,
    studyID: studyID,
    name: name,
    start: start ?? now,
    end: end ?? now.add(const Duration(hours: 1)),
    activeDays: activeDays ?? [1, 2, 3, 4, 5, 6, 7],
    status: status,
    due: due ?? now.add(const Duration(hours: 1)),
    entries: entries,
    currentEntry: currentEntry,
    prompts: prompts ?? <PromptModel>[],
    notifications: notifications ?? <Notification>[],
    tags: tags,
  );
}

/// Creates a test ExperimentModel with optional parameters
ExperimentModel createTestExperimentModel({
  int id = 1,
  String name = 'Test Experiment',
  String login = 'test_login',
  String researcher = 'test_researcher',
  String organization = 'test_org',
  String duration = '7 days',
  String description = 'Test description',
  String version = '1.0.0',
}) {
  return ExperimentModel(
    id: id,
    name: name,
    login: login,
    researcher: researcher,
    organization: organization,
    duration: duration,
    description: description,
    version: version,
  );
}

// =============================================================================
// BATCH HELPERS FOR DATA MODELS
// =============================================================================

/// Creates a list of test prompt models with sequential IDs
List<PromptModel> createTestPromptModels(
  int count, {
  String questionPrefix = 'Test Question',
  int startId = 1,
  ResponseType responseType = ResponseType.text,
}) {
  return List.generate(
      count,
      (index) => createTestPromptModel(
            id: startId + index,
            questionNumber: startId + index,
            question: '$questionPrefix ${startId + index}',
            responseType: responseType,
          ));
}

/// Creates a list of test notifications with sequential times
List<Notification> createTestNotifications(
  int count, {
  String titlePrefix = 'Test Notification',
  DateTime? baseDate,
}) {
  final base = baseDate ?? DateTime.now();
  return List.generate(
      count,
      (index) => createTestNotification(
            title: '$titlePrefix ${index + 1}',
            body: 'Test notification body ${index + 1}',
            date: base.add(Duration(hours: index)),
          ));
}

/// Creates a list of test tags
List<Tag> createTestTags(
  int count, {
  String textPrefix = 'Tag',
  TagType type = TagType.questions,
}) {
  return List.generate(
      count,
      (index) => createTestTag(
            text: '$textPrefix ${index + 1}',
            type: type,
          ));
}

// =============================================================================
// NETWORK MODELS
// =============================================================================

/// Creates a test CredentialsModel with optional parameters
CredentialsModel createTestCredentials({
  String authorization = 'test-auth',
  String xapikey = 'test-api-key',
  String dynamo_url = 'test-dynamo-url',
  String presigned_url = 'test-presigned-url',
}) {
  return CredentialsModel(
    authorization: authorization,
    xapikey: xapikey,
    dynamo_url: dynamo_url,
    presigned_url: presigned_url,
  );
}

/// Creates a test PromptEntry with optional parameters
PromptEntry createTestPromptEntry({
  String participantID = 'test-participant',
  String experimentCode = 'test-experiment',
  String questionTitle = 'Test Question',
  String diaryID = '1',
  String promptID = '1',
  String response = 'Test Response',
  String questionsType = 'text',
  String respondedAt = '',
  bool required = true,
}) {
  return PromptEntry(
    participantID: participantID,
    experimentCode: experimentCode,
    questionTitle: questionTitle,
    diaryID: diaryID,
    promptID: promptID,
    response: response,
    questionsType: questionsType,
    required: required,
    respondedAt: respondedAt,
  );
}

// =============================================================================
// BATCH CREATION HELPERS
// =============================================================================

/// Creates a list of test diaries with sequential IDs
List<entity.Diary> createTestDiaries(
  int count, {
  String namePrefix = 'Test Diary',
  int startId = 1,
}) {
  return List.generate(
      count,
      (index) => createTestDiary(
            id: startId + index,
            name: '$namePrefix ${startId + index}',
          ));
}

/// Creates a list of test studies with sequential IDs
List<Study> createTestStudies(
  int count, {
  String namePrefix = 'Test Study',
  int startId = 1,
  int startStudyId = 101,
}) {
  return List.generate(
      count,
      (index) => createTestStudy(
            id: startId + index,
            studyId: startStudyId + index,
            name: '$namePrefix ${startId + index}',
          ));
}

/// Creates a list of test experiments with sequential IDs
List<Experiment> createTestExperiments(
  int count, {
  String namePrefix = 'Test Experiment',
  int startId = 1,
}) {
  return List.generate(
      count,
      (index) => createTestExperiment(
            id: startId + index,
            name: '$namePrefix ${startId + index}',
          ));
}

/// Creates a list of test prompts with sequential IDs
List<Prompt> createTestPrompts(
  int count, {
  String questionPrefix = 'Test Question',
  int startId = 1,
  int diaryId = 1,
}) {
  return List.generate(
      count,
      (index) => createTestPrompt(
            id: startId + index,
            questionNumber: startId + index,
            question: '$questionPrefix ${startId + index}',
            diaryId: diaryId,
          ));
}

/// Creates a list of test answers with sequential IDs
List<entity.Answer> createTestAnswers(
  int count, {
  int startId = 1,
}) {
  return List.generate(
      count,
      (index) => createTestAnswer(
            id: startId + index,
          ));
}

/// Creates a list of test prompt entries for upload testing
List<PromptEntry> createTestPromptEntries(
  int count, {
  String participantID = 'test-participant',
  String experimentCode = 'test-experiment',
}) {
  return List.generate(
      count,
      (index) => createTestPromptEntry(
            participantID: participantID,
            experimentCode: experimentCode,
            questionTitle: 'Test Question ${index + 1}',
            diaryID: '${index + 1}',
            promptID: '${index + 1}',
            response: 'Test Response ${index + 1}',
          ));
}

// =============================================================================
// NETWORK RESPONSE HELPERS
// =============================================================================

/// Creates a generic test API response
String createTestApiResponse({
  String data = 'test',
  String? message,
}) {
  return message != null
      ? '{"data": "$data", "message": "$message"}'
      : '{"data": "$data"}';
}

/// Creates a generic test POST body
Map<String, dynamic> createTestPostBody({
  String key = 'key',
  String value = 'value',
}) {
  return {key: value};
}

/// Creates test API response body for credentials endpoint
String createTestCredentialsApiResponse() {
  return '''
{
  "message": {
    "Authorization": "${TestValues.testAuth}",
    "x-api-key": "${TestValues.testApiKey}",
    "dynamo_url": "${TestValues.testDynamoUrl}",
    "presigned_url": "${TestValues.testPresignedUrl}"
  }
}
''';
}

/// Creates test stored credentials JSON string
String createTestStoredCredentialsJson() {
  return '''
{
  "authorization": "${TestValues.testAuth}",
  "x-api-key": "${TestValues.testApiKey}",
  "dynamo_url": "${TestValues.testDynamoUrl}",
  "presigned_url": "${TestValues.testPresignedUrl}"
}
''';
}

/// Creates test error response for API calls
String createTestErrorResponse({
  String message = TestValues.testErrorMessage,
  String? code,
}) {
  return code != null
      ? '{"error": "$message", "code": "$code"}'
      : '{"error": "$message"}';
}

// =============================================================================
// COMMON TEST DATES
// =============================================================================

/// Common test dates for consistent testing
class TestDates {
  static final DateTime now = DateTime.now();
  static final DateTime today = DateTime(now.year, now.month, now.day);
  static final DateTime yesterday = today.subtract(const Duration(days: 1));
  static final DateTime tomorrow = today.add(const Duration(days: 1));
  static final DateTime oneWeekAgo = today.subtract(const Duration(days: 7));
  static final DateTime oneWeekLater = today.add(const Duration(days: 7));
  static final DateTime testDate = DateTime(2024, 3, 15, 10, 0);
  static final DateTime testEndDate = DateTime(2024, 3, 15, 11, 0);
}

// =============================================================================
// COMMON TEST VALUES
// =============================================================================

/// Common test values for consistent testing
class TestValues {
  static const String testName = 'Test Item';
  static const String testDescription = 'Test Description';
  static const String testResponse = 'Test Response';
  static const String testStudyCode = 'TEST123';
  static const String testExperimentCode = 'TEST001';
  static const String testParticipantId = 'test-participant';
  static const String testOrganization = 'Test Organization';
  static const String testResearcher = 'Test Researcher';
  static const String testVersion = '1.0.0';
  static const List<int> testActiveDays = [1, 2, 3];
  static const String testNotifications = '[]';
  static const String testGoals =
      '{"goal1": "Test Goal 1", "goal2": "Test Goal 2"}';
  static const String testIncentive = '{"amount": 100, "currency": "USD"}';
  // Network-specific values
  static const String testAuth = 'test-auth';
  static const String testApiKey = 'test-api-key';
  static const String testDynamoUrl = 'test-dynamo-url';
  static const String testPresignedUrl = 'test-presigned-url';
  static const String testErrorMessage = 'Bad Request Error';
  static const String testSuccessMessage = 'Success';
  static const String testUrl = 'https://test-api.example.com';
  static const String testEndpoint = '/api/v1/test';
  static const int testStatusOk = 200;
  static const int testStatusError = 400;
  static const int testStatusServerError = 500;

  // Add ONLY notification-specific values (no duplicates)
  static const String testToken = 'test-token';
  static const String testPayload = 'test-payload';
  static const String testImagePath = '/test/path/bigPicture';
  static const String testAppPath = '/test/path';
  static const String testImageBytes = 'fake_image_bytes';
  static const String testIcon = '@mipmap/ic_launcher';
  static const String testChannelId = 'channelId';
  static const String testChannelName = 'channelName';

  // Add ONLY usecase-specific values (no duplicates)
  // Location-specific
  static const double testLatitude = 37.7749;
  static const double testLongitude = -122.4194;
  static const String testLocationTitle = 'Current location';
  static const String testLocationPermissionDenied =
      'Location permission not granted';
  static const String testLocationType = 'location';
  static const String testLocationPermissionKey = 'extra_permissions';

  // Timer-specific
  static const int testTimerDuration = 2100; // milliseconds
  static const int testTimerLongDuration = 3200; // milliseconds
  static const int testTimerMinExpected = 1; // seconds
  static const int testTimerMaxExpected = 3; // seconds

  // Diary layer specific values
  static const String testDiaryOngoing = 'Ongoing Diary';
  static const String testDiarySubmitted = 'Submitted Diary';
  static const String testDiaryEmpty = 'Empty Diary';
  static const String testDiaryNullActive = 'Null Active Days Diary';

  // Study specific values
  static const String testStudyName = 'Test Study';
  static const String testStudyNameNumbered =
      'Test Study 1'; 
  static const String testStudyExperimentCode = 'EXP001';

  // Goal and Incentive values
  static const int testGoalDaily = 3;
  static const int testGoalWeekly = 21;
  static const double testIncentiveAmount = 10.0;
  static const double testIncentiveBonus = 5.0;
  static const String testIncentiveCurrency = '\$';
  static const int testIncentiveThreshold = 80;

  // Completion error messages
  static const String testCompletionError = 'Test completion error';
  static const String testQueryBuilderError = 'QueryBuilder';
}

/// Creates a test RemoteMessage for notification testing
RemoteMessage createTestRemoteMessage({
  String? title,
  String? body,
  String? imageUrl,
}) {
  return RemoteMessage(
    notification: RemoteNotification(
      title: title ?? TestValues.testName,
      body: body ?? TestValues.testResponse,
      android:
          imageUrl != null ? AndroidNotification(imageUrl: imageUrl) : null,
    ),
  );
}

// =============================================================================
// USECASE HELPERS
// =============================================================================

/// Creates test location data for location usecase
Map<String, double> createTestLocationData({
  double? latitude,
  double? longitude,
}) {
  return {
    'latitude': latitude ?? TestValues.testLatitude,
    'longitude': longitude ?? TestValues.testLongitude,
  };
}

// =============================================================================
// DIARY LAYER HELPERS
// =============================================================================

/// Creates a test Goal with optional parameters
Goal createTestGoal({
  int daily = TestValues.testGoalDaily,
  int weekly = TestValues.testGoalWeekly,
}) {
  return Goal(daily: daily, weekly: weekly);
}

/// Creates a test Incentive with optional parameters
Incentive createTestIncentive({
  double amount = TestValues.testIncentiveAmount,
  double bonus = TestValues.testIncentiveBonus,
  String currency = TestValues.testIncentiveCurrency,
  int threshold = TestValues.testIncentiveThreshold,
}) {
  return Incentive(
    amount: amount,
    bonus: bonus,
    currency: currency,
    threshold: threshold,
  );
}

/// Creates a test StudyModel with optional parameters
StudyModel createTestStudyModel({
  int id = 1,
  int studyId = 1,
  String? name,
  String? experimentCode,
  Color color = const Color.fromARGB(255, 68, 97, 228),
  Goal? goals,
  Incentive? incentive,
}) {
  return StudyModel(
    id: id,
    studyId: studyId,
    name: name ?? TestValues.testStudyName,
    experimentCode: experimentCode ?? TestValues.testStudyExperimentCode,
    color: color,
    goals: goals ?? createTestGoal(),
    incentive: incentive ?? createTestIncentive(),
  );
}

/// Creates diary variations for different test scenarios
Map<String, DiaryModel> createTestDiaryVariations() {
  final baseDate = TestDates.testDate;

  return {
    'ongoing': createTestDiaryModel(
      id: 2,
      name: TestValues.testDiaryOngoing,
      status: DiaryStatus.ongoing,
      start: baseDate.subtract(const Duration(hours: 1)),
      due: baseDate.add(const Duration(hours: 1)),
      end: baseDate.add(const Duration(hours: 1)),
      activeDays: TestValues.testActiveDays,
    ),
    'submitted': createTestDiaryModel(
      id: 3,
      studyID: 2,
      name: TestValues.testDiarySubmitted,
      status: DiaryStatus.submitted,
      start: baseDate.subtract(const Duration(days: 1)),
      due: baseDate.subtract(const Duration(hours: 1)),
      end: baseDate.subtract(const Duration(hours: 1)),
      activeDays: [6, 7],
      entries: 2,
      currentEntry: 1,
    ),
    'empty': createTestDiaryModel(
      id: 99,
      name: TestValues.testDiaryEmpty,
      status: DiaryStatus.idle,
      start: baseDate,
      due: baseDate.add(const Duration(hours: 2)),
      end: baseDate.add(const Duration(hours: 2)),
      activeDays: [],
      entries: 0,
    ),
    'nullActive': createTestDiaryModel(
      id: 100,
      name: TestValues.testDiaryNullActive,
      status: DiaryStatus.idle,
      start: baseDate,
      due: baseDate.add(const Duration(hours: 2)),
      end: baseDate.add(const Duration(hours: 2)),
      activeDays: null,
      tags: null,
    ),
  };
}

/// Creates multiple test diaries for sequential testing
List<DiaryModel> createTestDiariesSequence(int count,
    {String namePrefix = 'Test Diary'}) {
  final baseDate = TestDates.testDate;

  return List.generate(
      count,
      (index) => createTestDiaryModel(
            id: index,
            name: '$namePrefix $index',
            status: DiaryStatus.complete,
            start: baseDate,
            due: baseDate.add(const Duration(hours: 2)),
            end: baseDate.add(const Duration(hours: 2)),
            activeDays: TestValues.testActiveDays,
          ));
}

/// Creates a test Questions model with optional parameters
Questions createTestQuestionsModel({
  int id = 1,
  String title = 'Test Question',
  String? subtitle = 'Test Subtitle',
  List<Option>? options,
  String type = 'text',
  int? min,
  int? max,
  int? defaultValue,
  String? minLabel,
  String? maxLabel,
  String variable = 'test_variable',
  String? answer,
}) {
  return Questions(
    id: id,
    title: title,
    subtitle: subtitle,
    options: options,
    type: type,
    min: min,
    max: max,
    defaultValue: defaultValue,
    minLabel: minLabel,
    maxLabel: maxLabel,
    variable: variable,
    answer: answer,
  );
}
