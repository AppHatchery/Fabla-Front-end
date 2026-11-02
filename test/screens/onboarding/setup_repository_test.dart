import 'dart:convert';

import 'package:audio_diaries_flutter/core/database/dao/experiment_dao.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../dummy_data.dart';

class MockExperimentDAO extends Mock implements ExperimentDAO {}

void main() {
  late MockExperimentDAO mockDao;
  late List<Map<String, dynamic>> postedBodies;

  /// Builds a repository whose network call returns [response] (or throws
  /// [error]) and records every request body.
  SetupRepository buildRepository({String? response, Object? error}) {
    return SetupRepository(
      experimentDao: mockDao,
      postRequest: ({required path, required body}) async {
        expect(path, '/fabla/getstudyinfo');
        postedBodies.add(body);
        if (error != null) throw error;
        return response;
      },
    );
  }

  String studyInfo(Object? ownerEmail, {String? loginCode}) => jsonEncode({
        'data': {
          if (ownerEmail != null) 'owner_email': ownerEmail,
          if (loginCode != null) 'login_code': loginCode,
        },
      });

  setUp(() {
    mockDao = MockExperimentDAO();
    postedBodies = [];
  });

  group('SetupRepository.updateExperimentOwnerEmail', () {
    test('returns false without a request when no experiment is stored',
        () async {
      when(() => mockDao.getExperiment()).thenReturn(null);

      final result = await buildRepository().updateExperimentOwnerEmail();

      expect(result, isFalse);
      expect(postedBodies, isEmpty);
    });

    test('returns false without a request when the login code is empty',
        () async {
      when(() => mockDao.getExperiment())
          .thenReturn(createTestExperiment(login: ''));

      final result = await buildRepository().updateExperimentOwnerEmail();

      expect(result, isFalse);
      expect(postedBodies, isEmpty);
    });

    test('sends the stored login code', () async {
      when(() => mockDao.getExperiment())
          .thenReturn(createTestExperiment(login: 'ABC123'));

      await buildRepository(response: studyInfo('a@test.com'))
          .updateExperimentOwnerEmail();

      expect(postedBodies, [
        {'login_code': 'ABC123'}
      ]);
    });

    test('saves a new, trimmed owner email and returns true', () async {
      when(() => mockDao.getExperiment())
          .thenReturn(createTestExperiment(ownerEmail: 'old@test.com'));
      when(() => mockDao.updateOwnerEmail(any(), any())).thenReturn(true);

      final result =
          await buildRepository(response: studyInfo('  new@test.com '))
              .updateExperimentOwnerEmail();

      expect(result, isTrue);
      verify(() => mockDao.updateOwnerEmail('test_login', 'new@test.com'))
          .called(1);
    });

    test('returns true without writing when the email is unchanged', () async {
      when(() => mockDao.getExperiment())
          .thenReturn(createTestExperiment(ownerEmail: 'same@test.com'));

      final result = await buildRepository(response: studyInfo('same@test.com'))
          .updateExperimentOwnerEmail();

      expect(result, isTrue);
      verifyNever(() => mockDao.updateOwnerEmail(any(), any()));
    });

    test('never overwrites with a missing, null, blank or non-string email',
        () async {
      when(() => mockDao.getExperiment()).thenReturn(createTestExperiment());

      for (final response in [
        studyInfo(null),
        jsonEncode({
          'data': {'owner_email': null}
        }),
        studyInfo('   '),
        studyInfo(42),
      ]) {
        expect(
            await buildRepository(response: response)
                .updateExperimentOwnerEmail(),
            isFalse,
            reason: response);
      }
      verifyNever(() => mockDao.updateOwnerEmail(any(), any()));
    });

    test('returns false when the request fails (null response)', () async {
      when(() => mockDao.getExperiment()).thenReturn(createTestExperiment());

      final result = await buildRepository().updateExperimentOwnerEmail();

      expect(result, isFalse);
      verifyNever(() => mockDao.updateOwnerEmail(any(), any()));
    });

    test('returns false for malformed JSON or a non-object data field',
        () async {
      when(() => mockDao.getExperiment()).thenReturn(createTestExperiment());

      for (final response in [
        'not json',
        jsonEncode({'data': null}),
        jsonEncode({'data': []}),
        jsonEncode({'status': 'error'}),
      ]) {
        expect(
            await buildRepository(response: response)
                .updateExperimentOwnerEmail(),
            isFalse,
            reason: response);
      }
      verifyNever(() => mockDao.updateOwnerEmail(any(), any()));
    });

    test('accepts a response whose login code matches, ignoring case',
        () async {
      when(() => mockDao.getExperiment())
          .thenReturn(createTestExperiment(login: 'ABC123'));
      when(() => mockDao.updateOwnerEmail(any(), any())).thenReturn(true);

      final result = await buildRepository(
              response: studyInfo('new@test.com', loginCode: 'abc123'))
          .updateExperimentOwnerEmail();

      expect(result, isTrue);
      verify(() => mockDao.updateOwnerEmail('ABC123', 'new@test.com'))
          .called(1);
    });

    test('ignores a response for a different login code', () async {
      when(() => mockDao.getExperiment())
          .thenReturn(createTestExperiment(login: 'ABC123'));

      final result = await buildRepository(
              response: studyInfo('other@test.com', loginCode: 'OTHER'))
          .updateExperimentOwnerEmail();

      expect(result, isFalse);
      verifyNever(() => mockDao.updateOwnerEmail(any(), any()));
    });

    test('returns false when the stored study changed during the request',
        () async {
      when(() => mockDao.getExperiment()).thenReturn(
          createTestExperiment(login: 'OLD', ownerEmail: 'a@test.com'));
      // The DAO re-checks the login and refuses to write.
      when(() => mockDao.updateOwnerEmail(any(), any())).thenReturn(false);

      final result = await buildRepository(response: studyInfo('new@test.com'))
          .updateExperimentOwnerEmail();

      expect(result, isFalse);
    });

    test('returns false instead of throwing when reading the experiment throws',
        () async {
      when(() => mockDao.getExperiment()).thenThrow(StateError('store closed'));

      final result = await buildRepository().updateExperimentOwnerEmail();

      expect(result, isFalse);
      expect(postedBodies, isEmpty);
    });

    test('returns false instead of throwing when the request throws', () async {
      when(() => mockDao.getExperiment()).thenReturn(createTestExperiment());

      final result = await buildRepository(error: Exception('network down'))
          .updateExperimentOwnerEmail();

      expect(result, isFalse);
      verifyNever(() => mockDao.updateOwnerEmail(any(), any()));
    });
  });
}
