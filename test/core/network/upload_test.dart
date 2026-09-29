import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/core/network/secrets_handler.dart';
import 'package:audio_diaries_flutter/core/utils/formatter.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/recording.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import '../../dummy_data.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockSetupRepository extends Mock implements SetupRepository {}

class MockSecureSave extends Mock implements SecureSave {}

class MockDirectory extends Mock implements Directory {}

// Initialize Flutter binding at the start
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHttpClient mockHttpClient;
  late MockSecureSave mockSecureSave;

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockSecureSave = MockSecureSave();
    registerFallbackValue(Uri.parse(TestValues.testUrl));
  });

  group('Upload Tests', () {
    test('uploadNonAudioData successfully uploads data', () async {
      // ───── Arrange ─────
      final credentials = createTestCredentials();
      final promptEntries = createTestPromptEntries(1);

      when(() => mockSecureSave.read()).thenAnswer((_) async => credentials);
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Success', 200));

      // ───── Act ─────
      final result = await uploadNonAudioData(
        promptEntries,
        secureSave: mockSecureSave,
        client: mockHttpClient,
      );

      // ───── Assert ─────
      expect(result, true);
      verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('uploadNonAudioData returns false on failed upload', () async {
      // ───── Arrange ─────
      final credentials = createTestCredentials();
      final promptEntries = createTestPromptEntries(2);

      when(() => mockSecureSave.read()).thenAnswer((_) async => credentials);
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Error', 400));

      // ───── Act ─────
      final result = await uploadNonAudioData(
        promptEntries,
        secureSave: mockSecureSave,
        client: mockHttpClient,
      );

      // ───── Assert ─────
      expect(result, false);
      verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('uploadNonAudioData returns false on network error', () async {
      // ───── Arrange ─────
      final credentials = createTestCredentials();
      final promptEntries = createTestPromptEntries(3);

      when(() => mockSecureSave.read()).thenAnswer((_) async => credentials);
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenThrow(Exception('Network error'));

      // ───── Act ─────
      final result = await uploadNonAudioData(
        promptEntries,
        secureSave: mockSecureSave,
        client: mockHttpClient,
      );

      // ───── Assert ─────
      expect(result, false);
      verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('getPresignedUrl returns URL on successful request', () async {
      // ───── Arrange ─────
      const apiUrl = TestValues.testUrl;
      const filename = 'test.txt';
      const expectedUrl = 'https://presigned-url.com/test.txt';

      final credentials = createTestCredentials();

      when(() => mockSecureSave.read()).thenAnswer((_) async => credentials);
      when(() => mockHttpClient.post(
                any(),
                headers: any(named: 'headers'),
                body: any(named: 'body'),
              ))
          .thenAnswer((_) async => http.Response(
              '{"body": "{\\"uploadURL\\": \\"$expectedUrl\\"}"}', 200));

      // ───── Act ─────
      final result = await getPresignedUrl(
        apiUrl,
        filename,
        secureSave: mockSecureSave,
        client: mockHttpClient,
      );

      // ───── Assert ─────
      expect(result, expectedUrl);
      verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('getPresignedUrl returns null on failed request', () async {
      // ───── Arrange ─────
      const apiUrl = TestValues.testUrl;
      const filename = 'test.txt';

      final credentials = createTestCredentials();

      when(() => mockSecureSave.read()).thenAnswer((_) async => credentials);
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Error', 400));

      // ───── Act ─────
      final result = await getPresignedUrl(
        apiUrl,
        filename,
        secureSave: mockSecureSave,
        client: mockHttpClient,
      );

      // ───── Assert ─────
      expect(result, null);
      verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('getPresignedUrl returns null on network error', () async {
      // ───── Arrange ─────
      const apiUrl = TestValues.testUrl;
      const filename = 'test.txt';

      final credentials = createTestCredentials();

      when(() => mockSecureSave.read()).thenAnswer((_) async => credentials);
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenThrow(Exception('Network error'));

      // ───── Act ─────
      final result = await getPresignedUrl(
        apiUrl,
        filename,
        secureSave: mockSecureSave,
        client: mockHttpClient,
      );

      // ───── Assert ─────
      expect(result, null);
      verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });
  });

  group('addFileData', () {
    // Never touched on disk: every test but the last injects `fileExists`.
    final dir = Directory('/docs');
    final diary = createTestDiaryModel(start: DateTime(2026, 9, 1));

    PromptModel promptWith(
      List<Recording> recordings, {
      ResponseType type = ResponseType.audio,
    }) =>
        createTestPromptModel(
          responseType: type,
          answer: createTestAnswer()..recordings.addAll(recordings),
        );

    Future<bool> Function(String) onDisk(Set<String> relativePaths) =>
        (path) async =>
            relativePaths.contains(p.relative(path, from: dir.path));

    Future<(List<FileData>, List<PromptEntry>)> build(
      PromptModel prompt, {
      Directory? directory,
      Future<bool> Function(String)? fileExists,
    }) async {
      final files = <FileData>[];
      final references = <PromptEntry>[];

      if (fileExists == null) {
        await addFileData('exp', prompt, 'p1', diary, null, directory ?? dir,
            files, references);
      } else {
        await addFileData('exp', prompt, 'p1', diary, null, directory ?? dir,
            files, references,
            fileExists: fileExists);
      }

      return (files, references);
    }

    String stem(FileData file) =>
        p.basenameWithoutExtension(file.awsS3Directory);

    test('a present file is queued and referenced by its S3 name', () async {
      final prompt =
          promptWith([createTestRecording(id: 7, path: 'audios/a.aac')]);

      final (files, references) =
          await build(prompt, fileExists: onDisk({'audios/a.aac'}));

      expect(files, hasLength(1));
      expect(files.single.localDirectory, '/docs/audios/a.aac');
      expect(
          files.single.awsS3Directory, startsWith('exp/Audios/p1_2026-09-01_'));
      expect(files.single.awsS3Directory, endsWith('_7.aac'));
      expect(references.single.reference, stem(files.single));
    });

    test('a missing file is not queued and is referenced as null', () async {
      final prompt = promptWith([createTestRecording(path: 'audios/gone.aac')]);

      final (files, references) = await build(prompt, fileExists: onDisk({}));

      expect(files, isEmpty);
      final entry = references.single;
      expect(entry.reference, PromptEntry.missingFileReference);
      expect(entry.reference, 'null');
      expect(entry.response, '');
      expect(entry.promptID, '1');
      expect(entry.respondedAt, DateTime(2026, 9, 1, 10).toIso8601String());
      expect(entry.questionsType, responseTypeValue(ResponseType.audio));
    });

    test('only the missing recording is nulled among present ones', () async {
      final prompt = promptWith([
        createTestRecording(id: 1, path: 'audios/a.aac'),
        createTestRecording(id: 2, path: 'audios/b.aac'),
        createTestRecording(id: 3, path: 'audios/c.aac'),
      ]);

      final (files, references) = await build(prompt,
          fileExists: onDisk({'audios/a.aac', 'audios/c.aac'}));

      expect(files.map((f) => f.localDirectory),
          ['/docs/audios/a.aac', '/docs/audios/c.aac']);
      expect(references.map((r) => r.reference),
          [stem(files[0]), 'null', stem(files[1])]);
    });

    test('every file missing leaves nothing for S3 but keeps each row',
        () async {
      final prompt = promptWith([
        createTestRecording(id: 1, date: DateTime(2026, 9, 1, 10)),
        createTestRecording(id: 2, date: DateTime(2026, 9, 1, 11)),
      ]);

      final (files, references) = await build(prompt, fileExists: onDisk({}));

      expect(files, isEmpty);
      expect(references.map((r) => r.reference), ['null', 'null']);
      expect(references.map((r) => r.respondedAt).toSet(), hasLength(2));
    });

    test('a check that throws treats the file as present', () async {
      final prompt = promptWith([createTestRecording(path: 'audios/a.aac')]);

      // A bare String, like the audio plugins throw, not an Exception.
      final (files, references) =
          await build(prompt, fileExists: (_) async => throw 'disk error');

      expect(files, hasLength(1));
      expect(
          references.single.reference, isNot(PromptEntry.missingFileReference));
    });

    test('images and videos are skipped the same way', () async {
      final prompt = promptWith([
        createTestRecording(id: 1, path: 'images/a.jpg', type: 'image'),
        createTestRecording(id: 2, path: 'videos/b.mp4', type: 'video'),
      ], type: ResponseType.imageVideo);

      final (files, references) =
          await build(prompt, fileExists: onDisk({'images/a.jpg'}));

      expect(files.single.awsS3Directory, contains('/Images/'));
      expect(references.map((r) => r.reference), [stem(files.single), 'null']);
    });

    test('a prompt without an answer adds nothing', () async {
      final prompt = createTestPromptModel(responseType: ResponseType.audio);

      final (files, references) = await build(prompt, fileExists: onDisk({}));

      expect(files, isEmpty);
      expect(references, isEmpty);
    });

    group('against the real disk', () {
      late Directory tempDir;

      setUp(() => tempDir = Directory.systemTemp.createTempSync('upload_test'));
      tearDown(() => tempDir.deleteSync(recursive: true));

      test('the default check finds real files and nulls absent ones',
          () async {
        File(p.join(tempDir.path, 'present.aac')).writeAsBytesSync([1, 2, 3]);
        final prompt = promptWith([
          createTestRecording(id: 1, path: 'present.aac'),
          createTestRecording(id: 2, path: 'absent.aac'),
        ]);

        final (files, references) = await build(prompt, directory: tempDir);

        expect(
            files.single.localDirectory, p.join(tempDir.path, 'present.aac'));
        expect(
            references.map((r) => r.reference), [stem(files.single), 'null']);
      });
    });
  });
}
