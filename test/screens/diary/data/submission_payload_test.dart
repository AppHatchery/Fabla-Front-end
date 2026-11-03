import 'package:audio_diaries_flutter/screens/diary/data/submission_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SubmissionPayload buildPayload({DateTime? submittedAt}) {
    return SubmissionPayload(
      submissionID: 'sub-123',
      submittedAt: submittedAt ?? DateTime.utc(2026, 11, 3, 14, 30),
      environment: 'Dev',
      protocolVersion: '1.2.0',
      uploadAttempts: 2,
      participant: {'ParticipantID': 'P001', 'ExperimentCode': 'TRAM'},
      device: {'Platform': 'iOS', 'Model': 'iPhone 15'},
      diary: {'DiaryID': 'd-1', 'DiaryName': 'Evening', 'EntryNumber': 3},
      responses: [
        {
          'PromptID': 'p-1',
          'Response': 'hello',
          'Files': [
            {'FileSizeBytes': 2048, 'MimeType': 'audio/aac'}
          ],
        },
      ],
    );
  }

  group('SubmissionPayload.toJson', () {
    test('uses the PascalCase top-level keys the backend expects', () {
      expect(buildPayload().toJson().keys, [
        'SubmissionID',
        'SubmittedAt',
        'Environment',
        'ProtocolVersion',
        'UploadAttempts',
        'Participant',
        'Device',
        'Diary',
        'Responses',
      ]);
    });

    test('maps scalar fields through unchanged', () {
      final json = buildPayload().toJson();

      expect(json['SubmissionID'], 'sub-123');
      expect(json['Environment'], 'Dev');
      expect(json['ProtocolVersion'], '1.2.0');
      expect(json['UploadAttempts'], 2);
    });

    test('serialises SubmittedAt as UTC ISO-8601', () {
      final json = buildPayload().toJson();

      expect(json['SubmittedAt'], '2026-11-03T14:30:00.000Z');
    });

    test('converts a local SubmittedAt to UTC', () {
      final local = DateTime(2026, 11, 3, 14, 30);
      final json = buildPayload(submittedAt: local).toJson();

      final submittedAt = json['SubmittedAt'] as String;
      expect(submittedAt, endsWith('Z'));
      expect(DateTime.parse(submittedAt), local.toUtc());
    });

    test('passes nested sections through untouched', () {
      final payload = buildPayload();
      final json = payload.toJson();

      expect(json['Participant'], payload.participant);
      expect(json['Device'], payload.device);
      expect(json['Diary'], payload.diary);
      expect(json['Responses'], payload.responses);
    });
  });
}
