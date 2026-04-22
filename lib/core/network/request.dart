import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

const String devURL =
    "sropo6jsmhm4hnxzlrqairw6xu0tfjcn.lambda-url.us-east-1.on.aws";
const String prodURL =
    "phy7427sobzzf3dbeevuvi6z4m0dehgx.lambda-url.us-east-1.on.aws";

final Map<String, String> headers = {
  'Content-Type': 'application/x-www-form-urlencoded',
  'x-api-key': dotenv.env['APIKEY']!
};

String base() {
  if (kDebugMode) {
    return devURL;
  } else {
    return prodURL;
  }
}

/// Performs an HTTP GET request to the specified path.
///
/// The [client] parameter is optional and used primarily for testing.
/// When [client] is provided, it will be used instead of the default http.Client.
/// This enables dependency injection for unit testing with mock HTTP clients.
/// In production, this parameter should be omitted to use the default client.
///
/// Returns the response body as a String on success, or null on failure.
Future<String?> get({
  required String path,
  http.Client? client, // Optional parameter for dependency injection (testing)
}) async {
  try {
    // Using injected client for testing, or default client for production
    final httpClient = client ?? http.Client();
    final url = Uri.https(base(), path);
    final response = await httpClient.get(url, headers: headers);
    return response.body;
  } catch (e, stackTrace) {
    CrashlyticsService().recordApiError(e, path,
        stackTrace: stackTrace, method: 'GET', requestData: null);
    debugPrint(e.toString());
    return null;
  }
}

/// Performs an HTTP POST request to the specified path with the given body.
///
/// The [client] parameter is optional and used primarily for testing.
/// When [client] is provided, it will be used instead of the default http.Client.
/// This enables dependency injection for unit testing with mock HTTP clients.
/// In production, this parameter should be omitted to use the default client.
///
/// Returns the response body as a String on success (status 200), or null on failure.
Future<String?> post({
  required String path,
  required Map<String, dynamic> body,
  http.Client? client, // Optional parameter for dependency injection (testing)
}) async {
  try {
    // Use injected client for testing, or default client for production
    final httpClient = client ?? http.Client();
    final url = Uri.https(base(), path);
    final response = await httpClient.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      debugPrint(response.body);
      CrashlyticsService().recordApiError(response.body, path,
          statusCode: response.statusCode, method: 'POST', requestData: body);
      throw Exception("Failed to post");
    }
  } catch (e, stackTrace) {
    debugPrint(e.toString());
    CrashlyticsService().recordApiError(e, path,
        stackTrace: stackTrace, method: 'POST', requestData: body);
    return null;
  }
}
