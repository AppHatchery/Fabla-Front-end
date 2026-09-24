import 'package:audio_diaries_flutter/core/network/http_client_factory.dart'
    as http_client_factory;
import 'package:audio_diaries_flutter/core/network/retry_policy.dart';
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
  'x-api-key': dotenv.env['APIKEY'] ?? ''
};

/// Returns the Lambda base URL for the current build mode.
///
/// Debug builds use [devURL]; all other builds (profile, release) use [prodURL].
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
  http.Client? client,
}) async {
  final bool ownClient = client == null;
  // A GET changes nothing, so re-sending one is always safe — including after
  // a 5xx, which a non-idempotent caller could not assume.
  final httpClient = client ??
      http_client_factory.httpClient(
        retries: kMaxRetries,
        retryServerErrors: true,
      );

  try {
    final url = Uri.https(base(), path);
    final response = await httpClient.get(url, headers: headers);
    return response.body;
  } catch (e, stackTrace) {
    CrashlyticsService().recordApiError(e, path,
        stackTrace: stackTrace, method: 'GET', requestData: null);
    debugPrint(e.toString());
    return null;
  } finally {
    if (ownClient) httpClient.close();
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
///
/// [retries] defaults to none. A POST is not idempotent by definition and this
/// helper is generic — it cannot see which endpoint it is pointed at, so it
/// cannot judge whether a re-send is safe, and the unsafe default is the one
/// that silently corrupts data. A caller that knows its endpoint is a read or
/// an overwrite opts in by passing [kMaxRetries]; a caller that appends must
/// leave this alone. Passing it also enables 5xx retry, since both rest on the
/// same assertion. The timeout applies either way, so a hung request always
/// fails rather than hanging.
Future<String?> post({
  required String path,
  required Map<String, dynamic> body,
  http.Client? client,
  int retries = 0,
}) async {
  final bool ownClient = client == null;
  // 5xx retry follows the same opt-in rather than adding a second flag: a
  // caller passing [retries] on a POST has already asserted that re-sending
  // this endpoint is safe, which is the one thing that licenses either.
  final httpClient = client ??
      http_client_factory.httpClient(
        retries: retries,
        retryServerErrors: retries > 0,
      );

  try {
    final url = Uri.https(base(), path);
    final response = await httpClient.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      return response.body;
    }
    // Reported here and returned directly — throwing would only be caught by
    // the clause below and reported a second time for the same failure.
    CrashlyticsService().recordApiError(response.body, path,
        statusCode: response.statusCode, method: 'POST', requestData: body);
    return null;
  } catch (e, stackTrace) {
    debugPrint(e.toString());
    CrashlyticsService().recordApiError(e, path,
        stackTrace: stackTrace, method: 'POST', requestData: body);
    return null;
  } finally {
    if (ownClient) httpClient.close();
  }
}
