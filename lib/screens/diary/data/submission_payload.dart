class SubmissionPayload {
  final String submissionID;
  final DateTime submittedAt;
  final String environment;
  final String protocolVersion;
  final int uploadAttempts;
  final Map<String, dynamic> participant;
  final Map<String, dynamic> device;
  final Map<String, dynamic> diary;
  final List<Map<String, dynamic>> responses;

  const SubmissionPayload(
      {required this.submissionID,
      required this.submittedAt,
      required this.environment,
      required this.protocolVersion,
      required this.uploadAttempts,
      required this.participant,
      required this.device,
      required this.diary,
      required this.responses});

  Map<String, dynamic> toJson() {
    return {
      'SubmissionID': submissionID,
      'SubmittedAt': submittedAt.toUtc().toIso8601String(),
      'Environment': environment,
      'ProtocolVersion': protocolVersion,
      'UploadAttempts': uploadAttempts,
      'Participant': participant,
      'Device': device,
      'Diary': diary,
      'Responses': responses,
    };
  }
}
