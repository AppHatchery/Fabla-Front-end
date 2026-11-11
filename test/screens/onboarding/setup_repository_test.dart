import 'dart:convert';

import 'package:audio_diaries_flutter/core/database/dao/experiment_dao.dart';
import 'package:audio_diaries_flutter/screens/home/domain/entities/experiment.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../dummy_data.dart';

class MockExperimentDAO extends Mock implements ExperimentDAO {}

void main() {
  late MockExperimentDAO mockDao;
  late List<Map<String, dynamic>> postedBodies;

  setUpAll(() => registerFallbackValue(createTestExperiment()));

  setUp(() {
    mockDao = MockExperimentDAO();
    postedBodies = [];
  });

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

  /// A well-formed `getstudyinfo` response; override fields via [overrides].
  String studyInfo({Map<String, Object?> overrides = const {}}) => jsonEncode({
        'data': {
          'login_code': 'test_login',
          'researcher': 'New Researcher',
          'organisation': 'New Org',
          'name': 'New Name',
          'duration': '14 days',
          'description': 'New description',
          'owner_email': 'new@test.com',
          'version': '2.0.0',
          ...overrides,
        },
      });

  void storedExperiment([String login = 'test_login']) => when(
        () => mockDao.getExperiment(),
      ).thenReturn(createTestExperiment(login: login));

  group('SetupRepository.updateExperiment', () {
    test('returns false without a request when no experiment is stored',
        () async {
      when(() => mockDao.getExperiment()).thenReturn(null);

      expect(await buildRepository().updateExperiment(), isFalse);
      expect(postedBodies, isEmpty);
    });

    test('returns false without a request when the login code is empty',
        () async {
      storedExperiment('');

      expect(await buildRepository().updateExperiment(), isFalse);
      expect(postedBodies, isEmpty);
    });

    test('sends the stored login code', () async {
      storedExperiment('ABC123');
      when(() => mockDao.updateExperiment(any(), any())).thenReturn(true);

      await buildRepository(
        response: studyInfo(overrides: {'login_code': 'ABC123'}),
      ).updateExperiment();

      expect(postedBodies, [
        {'login_code': 'ABC123'}
      ]);
    });

    test('replaces the whole experiment with the response and returns true',
        () async {
      storedExperiment();
      when(() => mockDao.updateExperiment(any(), any())).thenReturn(true);

      final result =
          await buildRepository(response: studyInfo()).updateExperiment();

      expect(result, isTrue);
      final updated = verify(
        () => mockDao.updateExperiment('test_login', captureAny()),
      ).captured.single as Experiment;
      expect(updated.login, 'test_login');
      expect(updated.researcher, 'New Researcher');
      expect(updated.organization, 'New Org');
      expect(updated.name, 'New Name');
      expect(updated.duration, '14 days');
      expect(updated.description, 'New description');
      expect(updated.ownerEmail, 'new@test.com');
      expect(updated.version, '2.0.0');
    });

    test('accepts a response whose login code differs only by case', () async {
      storedExperiment('ABC123');
      when(() => mockDao.updateExperiment(any(), any())).thenReturn(true);

      final result = await buildRepository(
        response: studyInfo(overrides: {'login_code': 'abc123'}),
      ).updateExperiment();

      expect(result, isTrue);
      verify(() => mockDao.updateExperiment('ABC123', any())).called(1);
    });

    test('ignores a response for a different login code', () async {
      storedExperiment('ABC123');

      final result = await buildRepository(
        response: studyInfo(overrides: {'login_code': 'OTHER'}),
      ).updateExperiment();

      expect(result, isFalse);
      verifyNever(() => mockDao.updateExperiment(any(), any()));
    });

    test('ignores a response with no usable login code (would blank the row)',
        () async {
      storedExperiment();

      for (final loginCode in [null, '', 42]) {
        expect(
          await buildRepository(
            response: studyInfo(overrides: {'login_code': loginCode}),
          ).updateExperiment(),
          isFalse,
          reason: 'login_code: $loginCode',
        );
      }
      verifyNever(() => mockDao.updateExperiment(any(), any()));
    });

    test('returns false when a field has an unexpected type', () async {
      storedExperiment();

      final result = await buildRepository(
        response: studyInfo(overrides: {'duration': 7}),
      ).updateExperiment();

      expect(result, isFalse);
      verifyNever(() => mockDao.updateExperiment(any(), any()));
    });

    test('returns false when the request fails (null response)', () async {
      storedExperiment();

      expect(await buildRepository().updateExperiment(), isFalse);
      verifyNever(() => mockDao.updateExperiment(any(), any()));
    });

    test('returns false for malformed JSON or a non-object payload', () async {
      storedExperiment();

      for (final response in [
        'not json',
        jsonEncode([]),
        jsonEncode({'data': null}),
        jsonEncode({'data': []}),
        jsonEncode({'status': 'error'}),
      ]) {
        expect(
          await buildRepository(response: response).updateExperiment(),
          isFalse,
          reason: response,
        );
      }
      verifyNever(() => mockDao.updateExperiment(any(), any()));
    });

    test('returns false when the stored study changed during the request',
        () async {
      storedExperiment();
      // The DAO re-checks the login and refuses to write.
      when(() => mockDao.updateExperiment(any(), any())).thenReturn(false);

      expect(
        await buildRepository(response: studyInfo()).updateExperiment(),
        isFalse,
      );
    });

    test('returns false instead of throwing when the request throws', () async {
      storedExperiment();

      final result = await buildRepository(error: Exception('network down'))
          .updateExperiment();

      expect(result, isFalse);
      verifyNever(() => mockDao.updateExperiment(any(), any()));
    });

    test('returns false instead of throwing when reading the experiment throws',
        () async {
      when(() => mockDao.getExperiment()).thenThrow(StateError('store closed'));

      expect(await buildRepository().updateExperiment(), isFalse);
      expect(postedBodies, isEmpty);
    });
  });
}
