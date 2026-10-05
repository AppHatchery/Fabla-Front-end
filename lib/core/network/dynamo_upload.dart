import 'dart:convert';
import 'package:audio_diaries_flutter/core/network/http_client_factory.dart'
    as http_client_factory;
import 'package:audio_diaries_flutter/core/network/secrets_handler.dart';
import 'package:audio_diaries_flutter/core/network/submission_models.dart';
import 'package:audio_diaries_flutter/core/network/upload_credentials.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as dev;

/// A DynamoDB POST slower than one attempt's timeout is worth reporting.
final Duration _slowDynamoThreshold = http_client_factory.kDefaultTimeout;

Future<bool> uploadNonAudioData(
  List<PromptEntry> promptEntryList, {
  SecureSave? secureSave,
  http.Client? client,
}) async {
  final secureStorage = secureSave ?? SecureSave();
  final bool ownClient = client == null;
  // No retry: this POST appends and the Lambda has no dedupe, and a timeout or
  // dropped connection can follow a write the server already committed.
  final httpClient = client ?? http_client_factory.httpClient(retries: 0);

  try {
    var cred = await secureStorage.read();

    if (cred == null) {
      dev.log('Credentials null — attempting refresh',
          name: 'Upload - Non-Audio Data');
      cred = await refreshCredentials(secureStorage);
    }

    if (cred == null) {
      CrashlyticsService()
          .log('Upload failed: credentials null after refresh attempt');
      return false;
    }
    List<Map<String, dynamic>> promptListItems =
        PromptEntry.promptListToMap(promptEntryList);
    String jsonBody = json.encode(promptListItems);

    var url = Uri.parse(cred.dynamoUrl ?? "");

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': "${cred.authorization ?? ""}[0]",
      'x-api-key': cred.xapikey ?? ""
    };

    final stopwatch = Stopwatch()..start();
    try {
      var response =
          await httpClient.post(url, headers: headers, body: jsonBody);

      if (response.statusCode == 200) {
        return true;
      } else {
        dev.log(
            'DynamoDB upload failed: status=${response.statusCode} body=${response.body}',
            name: 'Upload - Non-Audio Data');
        CrashlyticsService().recordApiError(
            'DynamoDB upload failed: ${response.body}', url.toString(),
            statusCode: response.statusCode,
            method: 'POST',
            requestData: {'prompt_count': promptEntryList.length.toString()});
        await PendoService.track('Upload Error', {
          'event': 'Upload to DynamoDB',
          'response': response.body,
          'status': response.statusCode
        });
        return false;
      }
    } catch (e, stackTrace) {
      dev.log('Error sending request: $e', name: 'Upload - Non-Audio Data');
      CrashlyticsService().recordError(e, stackTrace,
          reason: 'Error sending request in uploadNonAudioData');
      await PendoService.track('Upload Error',
          {'event': 'Upload to DynamoDB', 'reason': e.toString()});
      return false;
    } finally {
      // In finally so timed-out calls, the slowest, are reported too.
      stopwatch.stop();
      if (stopwatch.elapsed > _slowDynamoThreshold) {
        CrashlyticsService().log(
            'Slow DynamoDB upload: ${stopwatch.elapsedMilliseconds}ms | prompts=${promptEntryList.length}');
        await PendoService.track('Slow Upload', {
          'event': 'Upload to DynamoDB',
          'duration_ms': stopwatch.elapsedMilliseconds.toString(),
          'prompt_count': promptEntryList.length.toString(),
        });
      }
    }
  } finally {
    if (ownClient) httpClient.close();
  }
}
