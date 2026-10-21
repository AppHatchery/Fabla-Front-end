import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

Future<Map<String, dynamic>> getSubmissionMetadata() async {
  try {
    final setupRepository = SetupRepository();

    final experiment = setupRepository.getExperiment();
    final environment = kDebugMode ? 'Dev' : 'Prod';

    return {
      'Environment': environment,
      'ProtocolVersion': experiment.version,
    };
  } catch (e, stackTrace) {
    CrashlyticsService().recordError(e, stackTrace,
        reason: "Failed to retrieve experiment version and environment");
    return {};
  }
}

String getSubmissionID() => _uuid.v4();
