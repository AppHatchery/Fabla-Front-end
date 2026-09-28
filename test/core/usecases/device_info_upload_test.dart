import 'dart:convert';

import 'package:audio_diaries_flutter/core/network/secrets_handler.dart';
import 'package:audio_diaries_flutter/core/usecases/device_info_upload.dart';
import 'package:audio_diaries_flutter/core/utils/device_info.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import '../../dummy_data.dart';

// Tests for lib/core/usecases/device_info_upload.dart.
//
// `sendDeviceInfo` runs unawaited from the Finish page, so beyond posting the
// right record it must never throw and must not post without a participant.

class MockSetupRepository extends Mock implements SetupRepository {}

class MockSecureSave extends Mock implements SecureSave {}

class MockHttpClient extends Mock implements http.Client {}

const _snapshot = DeviceSnapshot(
  manufacturer: 'Apple',
  model: 'iPhone 17 Pro Max',
  softwareVersion: '26.5',
  totalStorageMb: 948584.16015625,
  availableStorageMb: 519337.6875,
);

void main() {
  late MockSetupRepository mockSetupRepository;
  late MockSecureSave mockSecureSave;
  late MockHttpClient mockHttpClient;
  late int collectCalls;

  setUpAll(() {
    registerFallbackValue(Uri.parse(TestValues.testUrl));
  });

  setUp(() {
    mockSetupRepository = MockSetupRepository();
    mockSecureSave = MockSecureSave();
    mockHttpClient = MockHttpClient();
    collectCalls = 0;

    when(() => mockSetupRepository.getParticipant())
        .thenReturn(createTestParticipant(studyCode: '1001'));
    when(() => mockSetupRepository.getExperimentOrNull())
        .thenReturn(createTestExperimentModel(login: 'EXP001'));
    when(() => mockSecureSave.read())
        .thenAnswer((_) async => createTestCredentials());
    when(() => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response('Success', 200));
  });

  Future<bool> callWithMocks(
      {Future<DeviceSnapshot?> Function()? collect}) {
    return sendDeviceInfo(
      setupRepository: mockSetupRepository,
      collect: collect ??
          () async {
            collectCalls++;
            return _snapshot;
          },
      secureSave: mockSecureSave,
      client: mockHttpClient,
    );
  }

  void expectNoPost() => verifyNever(() => mockHttpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ));

  group('sendDeviceInfo', () {
    test('posts the participant and device as one record', () async {
      final result = await callWithMocks();

      expect(result, isTrue);
      final body = verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: captureAny(named: 'body'),
          )).captured.single as String;
      expect(json.decode(body), [
        {
          'ParticipantID': '1001',
          'ExperimentCode': 'EXP001',
          'device_manufacturer': 'Apple',
          'device_model': 'iPhone 17 Pro Max',
          'software_version': '26.5',
          'total_storage_mb': 948584.16015625,
          'available_storage_mb': 519337.6875,
          'encoding_bit_rate': 16000,
        }
      ]);
    });

    test('returns false when the backend rejects the record', () async {
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Error', 500));

      expect(await callWithMocks(), isFalse);
    });

    test('skips without a participant', () async {
      when(() => mockSetupRepository.getParticipant()).thenReturn(null);

      expect(await callWithMocks(), isFalse);
      expect(collectCalls, 0);
      expectNoPost();
    });

    test('skips without an experiment', () async {
      when(() => mockSetupRepository.getExperimentOrNull()).thenReturn(null);

      expect(await callWithMocks(), isFalse);
      expect(collectCalls, 0);
      expectNoPost();
    });

    test('skips on a platform with no snapshot', () async {
      expect(await callWithMocks(collect: () async => null), isFalse);
      expectNoPost();
    });

    // Callers don't await this, so an escaped error would surface as an
    // uncaught exception.
    test('returns false instead of throwing when collection fails', () async {
      final result = await callWithMocks(
          collect: () async => throw Exception('plugin unavailable'));

      expect(result, isFalse);
      expectNoPost();
    });
  });
}
