import 'dart:io';

import 'package:audio_diaries_flutter/core/network/build_submission_payload.dart';
import 'package:audio_diaries_flutter/core/network/submission_models.dart';
import 'package:audio_diaries_flutter/core/utils/types.dart';
import 'package:audio_diaries_flutter/screens/diary/data/prompt.dart';
import 'package:audio_diaries_flutter/screens/diary/domain/entities/recording.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dummy_data.dart';

void main() {
  group('buildResponses', () {
    final dir = Directory('/docs');

    PromptModel promptWith({
      int id = 1,
      ResponseType type = ResponseType.audio,
      List<String>? response,
      List<Recording> recordings = const [],
    }) {
      final answer = createTestAnswer(date: DateTime.utc(2026, 9, 1, 9));
      answer.response = response;
      answer.recordings.addAll(recordings);
      return createTestPromptModel(id: id, responseType: type, answer: answer);
    }

    FileData queued(String path, String s3Key) =>
        FileData(localDirectory: '/docs/$path', awsS3Directory: s3Key);

    Future<int> sizeOf(String path) async => 2048;

    test('an unanswered prompt is left out', () async {
      final responses = await buildResponses(
          prompts: [createTestPromptModel(answer: null)],
          files: [],
          dir: dir,
          fileSize: sizeOf);

      expect(responses, isEmpty);
    });

    test('a text answer has its fields and no Files', () async {
      final responses = await buildResponses(
          prompts: [
            promptWith(id: 4, type: ResponseType.text, response: ['hi'])
          ],
          files: [],
          dir: dir,
          fileSize: sizeOf);

      final response = responses.single;
      expect(response['PromptID'], '4');
      expect(response['QuestionTitle'], 'Test Question');
      expect(response['Required'], isTrue);
      expect(response['Response'], ['hi']);
      expect(response['RespondedAt'], '2026-09-01T09:00:00.000Z');
      expect(response.containsKey('Files'), isFalse);
    });

    test('a queued recording carries its S3 details and size', () async {
      final responses = await buildResponses(
          prompts: [
            promptWith(
                recordings: [createTestRecording(id: 7, path: 'audios/a.aac')])
          ],
          files: [
            queued('audios/a.aac', 'exp/Audios/exp_p1_2026-09-01_10-00-00_7.aac')
          ],
          dir: dir,
          fileSize: sizeOf);

      final file = (responses.single['Files'] as List).single;
      expect(file['RecordingID'], '7');
      expect(file['Type'], 'audio');
      expect(file['Missing'], isFalse);
      expect(file['Reference'], 'exp_p1_2026-09-01_10-00-00_7');
      expect(file['S3Key'], 'exp/Audios/exp_p1_2026-09-01_10-00-00_7.aac');
      expect(file['MimeType'], 'audio/aac');
      expect(file['FileSizeBytes'], 2048);
    });

    test('a recording that was not queued is kept and flagged Missing',
        () async {
      final responses = await buildResponses(
          prompts: [
            promptWith(recordings: [
              createTestRecording(id: 8, path: 'audios/gone.aac')
            ])
          ],
          files: [],
          dir: dir,
          fileSize: sizeOf);

      final file = (responses.single['Files'] as List).single;
      expect(file['RecordingID'], '8');
      expect(file['Missing'], isTrue);
      expect(file['Reference'], isNull);
      expect(file['S3Key'], isNull);
      expect(file['FileSizeBytes'], isNull);
    });

    test('only the missing recording is flagged among present ones',
        () async {
      final responses = await buildResponses(
          prompts: [
            promptWith(recordings: [
              createTestRecording(id: 1, path: 'audios/a.aac'),
              createTestRecording(id: 2, path: 'audios/gone.aac'),
            ])
          ],
          files: [queued('audios/a.aac', 'exp/Audios/a_1.aac')],
          dir: dir,
          fileSize: sizeOf);

      final files = responses.single['Files'] as List;
      expect(files.map((f) => f['Missing']), [false, true]);
    });

    test('a textAudio answer keeps both its text and its recording', () async {
      final responses = await buildResponses(
          prompts: [
            promptWith(
                type: ResponseType.textAudio,
                response: ['typed'],
                recordings: [createTestRecording(path: 'audios/a.aac')])
          ],
          files: [queued('audios/a.aac', 'exp/Audios/a_1.aac')],
          dir: dir,
          fileSize: sizeOf);

      final response = responses.single;
      expect(response['Response'], ['typed']);
      expect(response['Files'], hasLength(1));
    });

    test('an audio take carries its duration and recorder settings', () async {
      final responses = await buildResponses(
          prompts: [
            promptWith(recordings: [
              createTestRecording(
                  path: 'audios/a.m4a', durationMs: 12500, peakLevel: 92.5)
            ])
          ],
          files: [queued('audios/a.m4a', 'exp/Audios/a_1.m4a')],
          dir: dir,
          fileSize: sizeOf);

      final file = (responses.single['Files'] as List).single;
      expect(file['DurationMs'], 12500);
      expect(file['PeakLevel'], 92.5);
      expect(file['Codec'], 'AAC');
      expect(file['SampleRate'], 44100);
      expect(file['Channels'], 1);
      expect(file['BitRate'], 64000);
    });

    test('audio with no duration does not claim the recorder settings',
        () async {
      // Saved by a build that left the settings to flutter_sound.
      final responses = await buildResponses(
          prompts: [
            promptWith(recordings: [createTestRecording(path: 'audios/a.m4a')])
          ],
          files: [queued('audios/a.m4a', 'exp/Audios/a_1.m4a')],
          dir: dir,
          fileSize: sizeOf);

      final file = (responses.single['Files'] as List).single;
      expect(file['DurationMs'], isNull);
      expect(file['SampleRate'], isNull);
      expect(file['BitRate'], isNull);
    });

    test('an image has no audio fields', () async {
      final responses = await buildResponses(
          prompts: [
            promptWith(
                type: ResponseType.image,
                recordings: [
                  createTestRecording(path: 'images/a.jpg', type: 'image')
                ])
          ],
          files: [queued('images/a.jpg', 'exp/Images/a_1.jpg')],
          dir: dir,
          fileSize: sizeOf);

      final file = (responses.single['Files'] as List).single;
      expect(file.containsKey('DurationMs'), isFalse);
      expect(file.containsKey('PeakLevel'), isFalse);
      expect(file.containsKey('SampleRate'), isFalse);
    });

    test('a size that cannot be read leaves FileSizeBytes null', () async {
      final responses = await buildResponses(
          prompts: [
            promptWith(recordings: [createTestRecording(path: 'audios/a.aac')])
          ],
          files: [queued('audios/a.aac', 'exp/Audios/a_1.aac')],
          dir: dir,
          fileSize: (_) async => throw const FileSystemException('gone'));

      final file = (responses.single['Files'] as List).single;
      expect(file['Missing'], isFalse);
      expect(file['FileSizeBytes'], isNull);
    });
  });
}
