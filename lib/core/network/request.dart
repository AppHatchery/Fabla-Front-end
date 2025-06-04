import 'package:audio_diaries_flutter/core/secrets/keys.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Base URLs for development and production environments
const String devURL =
    "sropo6jsmhm4hnxzlrqairw6xu0tfjcn.lambda-url.us-east-1.on.aws";
const String prodURL =
    "phy7427sobzzf3dbeevuvi6z4m0dehgx.lambda-url.us-east-1.on.aws";

/// Default headers for all requests
const Map<String, String> headers = {
  'Content-Type': 'application/x-www-form-urlencoded',
  'x-api-key': apiKey
};

/// Returns the appropriate base URL based on the current environment
String base() {
  if (kDebugMode) {
    return devURL;
  } else {
    return prodURL;
  }
}

/// Makes a GET request to the specified path.
///
/// This function handles HTTP requests with the following behavior:
/// - Returns the response body as a String for successful requests (status code 200)
/// - Returns null for any other status code or network errors
/// - Logs errors using debugPrint for debugging purposes
///
/// The [client] parameter is optional and primarily used for testing:
/// - If provided, the specified client will be used for the request
/// - If not provided, a new client will be created and automatically closed
/// - In tests, pass a MockHttpClient to verify request behavior
///
/// Example usage:
/// ```dart
/// // Normal usage
/// final response = await get(path: 'api/endpoint');
///
/// // Testing usage
/// final mockClient = MockHttpClient();
/// when(() => mockClient.get(any(), headers: any()))
///     .thenAnswer((_) async => http.Response('{"data": "test"}', 200));
/// final response = await get(path: 'api/endpoint', client: mockClient);
/// ```
Future<String?> get({required String path, http.Client? client}) async {
  final httpClient = client ?? http.Client();
  try {
    final url = Uri.https(base(), path);
    final response = await httpClient.get(url, headers: headers);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      debugPrint(response.body);
      return null;
    }
  } catch (e) {
    debugPrint(e.toString());
    return null;
  } finally {
    if (client == null) {
      httpClient.close();
    }
  }
}

/// Makes a POST request to the specified path with the given body.
///
/// This function handles HTTP requests with the following behavior:
/// - Returns the response body as a String for successful requests (status code 200)
/// - Returns null for any other status code or network errors
/// - Logs errors using debugPrint for debugging purposes
///
/// The [client] parameter is optional and primarily used for testing:
/// - If provided, the specified client will be used for the request
/// - If not provided, a new client will be created and automatically closed
/// - In tests, pass a MockHttpClient to verify request behavior
///
/// Example usage:
/// ```dart
/// // Normal usage
/// final response = await post(
///   path: 'api/endpoint',
///   body: {'key': 'value'},
/// );
///
/// // Testing usage
/// final mockClient = MockHttpClient();
/// when(() => mockClient.post(any(), headers: any(), body: any()))
///     .thenAnswer((_) async => http.Response('{"data": "test"}', 200));
/// final response = await post(
///   path: 'api/endpoint',
///   body: {'key': 'value'},
///   client: mockClient,
/// );
/// ```
Future<String?> post({
  required String path,
  required Map<String, dynamic> body,
  http.Client? client,
}) async {
  final httpClient = client ?? http.Client();
  try {
    final url = Uri.https(base(), path);
    final response = await httpClient.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      debugPrint(response.body);
      return null;
    }
  } catch (e) {
    debugPrint(e.toString());
    return null;
  } finally {
    if (client == null) {
      httpClient.close();
    }
  }
}
