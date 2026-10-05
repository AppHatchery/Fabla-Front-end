import 'dart:convert';
import 'dart:io';
import 'package:audio_diaries_flutter/core/network/http_client_factory.dart'
    as http_client_factory;
import 'package:audio_diaries_flutter/core/network/retry_policy.dart';
import 'package:audio_diaries_flutter/core/network/secrets_handler.dart';
import 'package:audio_diaries_flutter/core/network/submission_models.dart';
import 'package:audio_diaries_flutter/core/network/upload_credentials.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:audio_diaries_flutter/services/pendo_service.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'dart:developer' as dev;

/// An S3 PUT past this has burned a whole attempt and is into its retry, which
/// is the point at which a participant notices the wait.
final Duration _slowS3Threshold = http_client_factory.kUploadTimeout;

/// Retrieves a presigned URL for uploading a file to an S3 storage location.
///
/// The function takes an [apiUrl] and a [filename] as input parameters. It sends
/// a POST request to the specified API endpoint ([apiUrl]) with a JSON body
/// containing the filename. Upon successful response with status code 200,
/// it parses the response body to extract the presigned URL and returns it.
/// If there's an error during the process, or the response status code is not
/// 200, it returns null.
///
/// Example:
/// ```dart
/// String apiUrl = 'https://example.com/api/upload';
/// String filename = 'example_file.jpg';
/// String? presignedUrl = await getPresignedUrl(apiUrl, filename);
/// if (presignedUrl != null) {
///   // Use the presigned URL to upload the file to S3
/// } else {
///   // Handle error
/// }
/// ```
///
/// Throws an error if there's any issue during the process.
///
Future<String?> getPresignedUrl(
  String apiUrl,
  String filename, {
  SecureSave? secureSave,
  http.Client? client,
}) async {
  final secureStorage = secureSave ?? SecureSave();
  final bool ownClient = client == null;
  // A pure read: network errors and 5xx are both retried.
  final httpClient = client ??
      http_client_factory.httpClient(
        retries: kMaxRetries,
        retryServerErrors: true,
      );

  try {
    var cred = await secureStorage.read();

    if (cred == null) {
      dev.log('Credentials null — attempting refresh',
          name: 'Upload - Get Presigned URL');
      cred = await refreshCredentials(secureStorage);
    }

    if (cred == null) {
      CrashlyticsService()
          .log('Upload failed: credentials null after refresh attempt');
      return null;
    }

    var requestBody = jsonEncode({'filename': filename});

    var response = await httpClient.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            "${cred.authorization ?? ""}[1]", // password [ AWS ARN FOR THE CALL ]
        'x-api-key': cred.xapikey ?? ""
      },
      body: requestBody,
    );

    if (response.statusCode == 200) {
      var responseBody = response.body;
      var jsonResponse = jsonDecode(responseBody);
      var body = jsonDecode(jsonResponse['body']);
      var uploadUrl = body['uploadURL'];
      return uploadUrl;
    } else {
      CrashlyticsService().recordApiError(
          'Failed to get presigned URL: ${response.body}', apiUrl,
          statusCode: response.statusCode,
          method: 'POST',
          requestData: {'filename': filename});
      await PendoService.track('Upload Error', {
        'event': 'Get Presigned URL',
        'response': response.body,
        'status': response.statusCode
      });
      return null;
    }
  } catch (e, stackTrace) {
    dev.log('Error getting presigned URL: $e',
        name: 'Upload - Get Presigned URL');
    CrashlyticsService().recordError(e, stackTrace,
        reason: 'Error getting presigned URL in getPresignedUrl');
    await PendoService.track(
        'Upload Error', {'event': 'Get Presigned URL', 'reason': e.toString()});
    return null;
  } finally {
    if (ownClient) httpClient.close();
  }
}

/// Uploads [filePath] to S3 using a previously-minted [presignedUrl].
///
/// Retrying is safe here: the presigned URL points at a fixed S3 key, so a
/// re-sent PUT overwrites rather than creating a second object.
Future<bool> uploadFileToS3(
  String presignedUrl,
  String filePath, {
  http.Client? client,
}) async {
  try {
    var file = File(filePath);
    var fileStream = file.openRead();

    var request = http.Request('PUT', Uri.parse(presignedUrl))
      ..headers['Content-Type'] = extensionToContentType(p.extension(filePath));

    // Collect bytes from the file stream into a single list
    List<int> bytes = [];
    await for (var chunk in fileStream) {
      bytes.addAll(chunk);
    }

    // Set the body bytes of the request
    request.bodyBytes = bytes;

    final bool ownClient = client == null;
    final s3Client = client ??
        http_client_factory.httpClient(
          timeout: http_client_factory.kUploadTimeout,
          retries: kUploadMaxRetries,
          retryServerErrors: true,
        );
    try {
      final response = await s3Client.send(request);
      // Drain the response stream so the underlying native client considers
      // the request complete before we close it below.
      await response.stream.drain();
      if (response.statusCode == 200) {
        return true;
      } else {
        dev.log(
            'S3 upload failed: status=${response.statusCode} file=$filePath',
            name: 'Upload - S3 Storage');
        CrashlyticsService().recordApiError(
            'S3 upload failed with status ${response.statusCode}', presignedUrl,
            statusCode: response.statusCode,
            method: 'PUT',
            requestData: {'file_path': filePath});
        await PendoService.track('Upload Error', {
          'event': 'Upload to S3',
          'reason': response.reasonPhrase ?? 'unknown',
          'status': response.statusCode
        });
        return false;
      }
    } finally {
      if (ownClient) s3Client.close();
    }
  } catch (e, stackTrace) {
    dev.log('S3 Storage: Error uploading file: $e',
        name: 'Upload - S3 Storage');
    CrashlyticsService().recordError(e, stackTrace,
        context: {'file_path': filePath},
        reason: 'Error uploading file in uploadFileToS3');
    await PendoService.track(
        'Upload Error', {'event': 'Upload to S3', 'reason': e.toString()});
    return false; // Return false if an error occurred
  }
}

String extensionToContentType(String extension) {
  final type = {
    '.aac': 'audio/aac',
    '.m4a': 'audio/mp4',
    '.jpg': 'image/jpeg',
    '.mp4': 'video/mp4',
  };

  return type[extension] ?? 'audio/mpeg';
}

Future<bool> uploadFiles(List<FileData> files) async {
  final secureStorage = SecureSave();
  var cred = await secureStorage.read();

  if (cred == null) {
    dev.log('Credentials null — attempting refresh',
        name: 'Upload - Upload Files');
    cred = await refreshCredentials(secureStorage);
  }

  if (cred == null) {
    CrashlyticsService()
        .log('Upload failed: credentials null after refresh attempt');
    return false;
  }

  final apiUrl = cred.presignedUrl ?? "";
  // List to store the results of each file upload
  final results = <bool>[];
  dev.log('Starting Files Upload - ${DateTime.now()}');
  for (var file in files) {
    var presignedUrl = await getPresignedUrl(apiUrl, file.awsS3Directory,
        secureSave: secureStorage);
    if (presignedUrl != null) {
      final stopwatch = Stopwatch()..start();
      final result = await uploadFileToS3(presignedUrl, file.localDirectory);
      stopwatch.stop();

      dev.log(
          'File uploaded: $result | Duration: ${stopwatch.elapsedMilliseconds}ms | File: ${file.awsS3Directory}',
          name: 'Upload - Upload Files');

      if (stopwatch.elapsed > _slowS3Threshold) {
        CrashlyticsService().log(
            'Slow S3 upload: ${file.awsS3Directory} took ${stopwatch.elapsedMilliseconds}ms');
        await PendoService.track('Slow Upload', {
          'event': 'Upload to S3',
          'file': file.awsS3Directory,
          'duration_ms': stopwatch.elapsedMilliseconds.toString(),
        });
      }

      results.add(result);
    } else {
      dev.log('Failed to get presigned URL for: ${file.awsS3Directory}',
          name: 'Upload - Upload Files');
      CrashlyticsService().recordApiError('Presigned URL returned null', apiUrl,
          method: 'POST', requestData: {'filename': file.awsS3Directory});
      results.add(false);
    }
  }
  // Return false explicitly if no files were processed (guards against vacuous truth on empty list)
  if (results.isEmpty) return false;
  return results.every((element) => element);
}
