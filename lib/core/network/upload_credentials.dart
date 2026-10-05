import 'package:audio_diaries_flutter/core/network/secrets_handler.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';

/// Re-fetches credentials from the backend using the locally-stored participant
/// and experiment records, then returns the newly-saved [CredentialsModel].
///
/// Returns `null` if local data is unavailable or the request fails, so callers
/// can treat a null return as a permanent failure rather than retrying.
Future<CredentialsModel?> refreshCredentials(SecureSave secureStorage) async {
  try {
    final setup = SetupRepository();
    final participant = setup.getParticipant();
    final experiment = setup.getExperiment();
    if (participant == null) return null;
    await secureStorage.getCredentials(
      study: experiment.login,
      participant: participant.studyCode,
    );
    return await secureStorage.read();
  } catch (e, stackTrace) {
    CrashlyticsService().recordError(e, stackTrace,
        reason: 'Failed to refresh credentials in refreshCredentials');
    await PendoService.track('Upload Error', {
      'event': 'Refresh Credentials',
      'reason': e.toString(),
    });
    return null;
  }
}
