import 'package:audio_diaries_flutter/core/network/secrets_handler.dart';
import 'package:audio_diaries_flutter/core/network/upload.dart';
import 'package:audio_diaries_flutter/core/utils/device_info.dart';
import 'package:audio_diaries_flutter/screens/onboarding/domain/repository/setup_repository.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:http/http.dart' as http;

import 'dart:developer' as dev;

/// Collects this device's info and posts it to the device-info table for the
/// current participant.
///
/// [setupRepository], [collect], [secureSave], and [client] can be injected
/// for testing; defaults to real instances otherwise.
///
/// Never throws, since callers fire it without awaiting. Returns `true` only
/// when the backend accepted the record.
Future<bool> sendDeviceInfo({
  SetupRepository? setupRepository,
  Future<DeviceSnapshot?> Function() collect = collectDeviceSnapshot,
  SecureSave? secureSave,
  http.Client? client,
}) async {
  try {
    final repository = setupRepository ?? SetupRepository();
    final participant = repository.getParticipant();
    final experiment = repository.getExperimentOrNull();
    if (participant == null || experiment == null) return false;

    final snapshot = await collect();
    if (snapshot == null) return false;

    return await uploadDeviceInfo(
      snapshot.toRecord(
        participantId: participant.studyCode,
        experimentCode: experiment.login,
      ),
      secureSave: secureSave,
      client: client,
    );
  } catch (e, stackTrace) {
    dev.log('Failed to send device info: $e', name: 'Device Info');
    CrashlyticsService()
        .recordError(e, stackTrace, reason: 'Failed to send device info');
    return false;
  }
}
