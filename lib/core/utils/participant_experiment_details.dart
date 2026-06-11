import 'package:shared_preferences/shared_preferences.dart';

import '../../screens/home/data/experiment.dart';
import '../../screens/onboarding/domain/entities/participant.dart';
import '../../screens/onboarding/domain/repository/setup_repository.dart';
import 'email_function.dart';
import 'device_appInfo.dart';

/// Immutable holder for the study dates persisted in shared preferences.
class StudyDates {
  final String? lastUpdated;
  final String? dateJoined;

  const StudyDates({this.lastUpdated, this.dateJoined});
}

/// Read-only access to the current participant, experiment and stored study
/// dates, plus a helper to launch the support email.
///
/// Pure data access: no Flutter context, no widget state, no global mutable
/// state. Each instance reads through [SetupRepository], which can be injected
/// for testing.
class ParticipantAndExperimentDetails {
  final SetupRepository _repository;

  ParticipantAndExperimentDetails({SetupRepository? repository})
      : _repository = repository ?? SetupRepository();

  /// The current experiment.
  ExperimentModel get experiment => _repository.getExperiment();

  /// The current participant, or null if none is stored.
  Participant? get participant => _repository.getParticipant();

  /// Reads the locally stored study dates. Both fields may be null.
  Future<StudyDates> getStudyDates() async {
    final prefs = await SharedPreferences.getInstance();
    return StudyDates(
      lastUpdated: prefs.getString('last_Updated'),
      dateJoined: prefs.getString('date_joined'),
    );
  }

  /// Builds and launches the prefilled support email. Consolidates the
  /// participant, experiment, date, version and device details so callers do
  /// not duplicate this logic.
  Future<void> launchSupportEmail(String subject, String body) async {
    final exp = experiment;
    final studyCode = participant?.studyCode ?? '';
    final dates = await getStudyDates();
    final appVersion = await getAppVersion();
    final deviceInfo = await getDeviceInfo();
    const String example = "The audio recording stops after 3 seconds and I'm unable to complete the task. This happens every time I try on the second task of the diary.";

    await launchEmail(
      subject: '$subject ${exp.login} $studyCode',
      body: '''
$body: e.g. "$example"

Study String: ${exp.login}
Participant ID: $studyCode
Date Joined: ${dates.dateJoined ?? ''}
Date last updated: ${dates.lastUpdated ?? ''}
App Version: $appVersion
Device and OS: $deviceInfo

Please attach screenshots of the error or the screen where you got stuck:
''',
    );
  }

  Future<void> loginSupportEmail(String subject, String body, String? example) async {
    final appVersion = await getAppVersion();
    final deviceInfo = await getDeviceInfo();

    if (subject.isEmpty) {
      subject = "Fabla Participant Login Issue";
    }

    await launchEmail(
      subject: subject,
      body: '''
$body: e.g. $example

App Version: $appVersion
Device and OS: $deviceInfo

Please attach screenshots of the error or the screen where you got stuck:
''',
    );
  }
}
