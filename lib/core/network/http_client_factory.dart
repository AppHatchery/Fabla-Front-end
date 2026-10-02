import 'dart:async';
import 'dart:io';

import 'package:audio_diaries_flutter/core/network/retry_policy.dart';
import 'package:audio_diaries_flutter/services/crashlytics_service.dart';
import 'package:cronet_http/cronet_http.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:cupertino_http/cupertino_http.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:http/retry.dart';

const _maxCacheSize = 2 * 1024 * 1024;
const _userAgent = 'Fabla/edu.emory.audio.diaries';

/// Applies to the small JSON calls: credential fetch, presigned-URL fetch and
/// the DynamoDB POST.
const kDefaultTimeout = Duration(seconds: 30);

/// The S3 PUT sends the whole file inside `send()`, so it gets more time.
const kUploadTimeout = Duration(minutes: 2);

/// A notification's big-picture image is cosmetic — fail fast rather than
/// delay the notification itself.
const kImageDownloadTimeout = Duration(seconds: 15);

/// Returns a [Client] backed by the platform's native network stack
/// (Cronet on Android, NSURLSession on iOS/macOS) so TLS validation honors
/// the OS certificate trust store instead of Dart's own bundled root store.
/// See [wrapClient] for the timeout and what is retried.
Client httpClient({
  Duration timeout = kDefaultTimeout,
  int retries = kMaxRetries,
  bool retryServerErrors = false,
}) =>
    wrapClient((debugPlatformClientBuilder ?? _platformClient)(),
        timeout: timeout,
        retries: retries,
        retryServerErrors: retryServerErrors);

/// Test-only override for the platform client [httpClient] wraps, so a test
/// can exercise a call site's own timeout and retries. Reset it in tearDown.
@visibleForTesting
Client Function()? debugPlatformClientBuilder;

Client _platformClient() {
  if (Platform.isAndroid) {
    final engine = CronetEngine.build(
      cacheMode: CacheMode.memory,
      cacheMaxSize: _maxCacheSize,
      userAgent: _userAgent,
    );
    return CronetClient.fromCronetEngine(engine);
  }
  if (Platform.isIOS || Platform.isMacOS) {
    final config = URLSessionConfiguration.ephemeralSessionConfiguration()
      ..cache = URLCache.withCapacity(memoryCapacity: _maxCacheSize)
      ..httpAdditionalHeaders = {'User-Agent': _userAgent};
    return CupertinoClient.fromSessionConfiguration(config);
  }
  return IOClient(HttpClient()..userAgent = _userAgent);
}

/// Wraps [inner] with a per-attempt [timeout] and up to [retries] re-sends of
/// [isTransientNetworkError] failures, plus 5xx when [retryServerErrors] is
/// set, which only an idempotent caller may do. Retry sits outside the timeout
/// so each attempt gets the full budget. [delay] replaces [retryBackoff] in
/// tests.
Client wrapClient(
  Client inner, {
  Duration timeout = kDefaultTimeout,
  int retries = kMaxRetries,
  bool retryServerErrors = false,
  Duration Function(int)? delay,
}) {
  final timeoutClient = _TimeoutClient(inner, timeout);
  if (retries <= 0) return timeoutClient;

  return RetryClient(
    timeoutClient,
    retries: retries,
    when: retryServerErrors
        ? (response) => isRetryableServerError(response.statusCode)
        : (_) => false,
    whenError: (error, _) => isTransientNetworkError(error),
    delay: delay ?? retryBackoff,
    onRetry: (request, _, retryCount) {
      CrashlyticsService().log(
          'Network retry ${retryCount + 1}/$retries — '
          '${request.method} ${request.url.path}');
    },
  );
}

/// Bounds each attempt: the wait for headers, and every gap in the body, which
/// `get`/`post` drain after `send()` returns and Cronet never times out.
///
/// A header timeout aborts the native request instead of abandoning it:
/// `CupertinoClient.close()` throws while a task runs, which would turn the
/// caller's `finally { close(); }` into a `StateError` even after a successful
/// retry. The cancel lands asynchronously, so [close] waits for aborted
/// attempts. A body stall is not retried, since the request is already
/// written; the caller cancelling the stream cancels the request.
class _TimeoutClient extends BaseClient {
  _TimeoutClient(this._inner, this._timeout);

  final Client _inner;
  final Duration _timeout;

  /// Aborted attempts that the inner client may still count as running.
  final _settling = <Future<void>>{};
  bool _closeRequested = false;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final abort = Completer<void>();
    void abortAttempt() {
      if (!abort.isCompleted) abort.complete();
    }

    // The copy below replaces the request, so forward a caller's own trigger.
    if (request case Abortable(:final abortTrigger?)) {
      unawaited(abortTrigger.whenComplete(abortAttempt));
    }

    final pending = _inner.send(_withAbortTrigger(request, abort.future));
    final response = await pending.timeout(_timeout, onTimeout: () {
      abortAttempt();
      _trackSettling(pending);
      throw TimeoutException('No response within $_timeout', _timeout);
    });
    // Stream.timeout measures the gap between chunks, not the total.
    return StreamedResponse(
      response.stream.timeout(_timeout),
      response.statusCode,
      contentLength: response.contentLength,
      // The caller's request, not the abortable copy the inner client saw.
      request: request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  void _trackSettling(Future<StreamedResponse> aborted) {
    final settled = _settle(aborted);
    _settling.add(settled);
    unawaited(settled.whenComplete(() {
      _settling.remove(settled);
      if (_closeRequested && _settling.isEmpty) _inner.close();
    }));
  }

  static Future<void> _settle(Future<StreamedResponse> aborted) async {
    try {
      // Headers can land just before the abort does; cancelling the body is
      // then what releases the native task.
      final orphan = await aborted;
      await orphan.stream.listen(null).cancel();
    } catch (_) {
      // Normally the abort itself, as a RequestAbortedException. The caller
      // has already been handed the TimeoutException.
    }
  }

  @override
  void close() {
    if (_settling.isEmpty) {
      _inner.close();
    } else {
      _closeRequested = true;
    }
  }
}

/// Copies [request] into its abortable counterpart, fired by [trigger].
BaseRequest _withAbortTrigger(BaseRequest request, Future<void> trigger) {
  // Finalize first: a MultipartRequest only sets its content-type here.
  final body = request.finalize();
  if (request is Request) {
    // Only `retries: 0` clients see a Request (RetryClient streams them all);
    // keeping it lets CupertinoClient send the body as one NSData.
    return AbortableRequest(request.method, request.url, abortTrigger: trigger)
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection
      ..headers.addAll(request.headers)
      ..bodyBytes = request.bodyBytes;
  }
  final copy = AbortableStreamedRequest(request.method, request.url,
      abortTrigger: trigger)
    ..contentLength = request.contentLength
    ..followRedirects = request.followRedirects
    ..maxRedirects = request.maxRedirects
    ..persistentConnection = request.persistentConnection
    ..headers.addAll(request.headers);
  body.listen(copy.sink.add,
      onError: copy.sink.addError,
      onDone: copy.sink.close,
      cancelOnError: true);
  return copy;
}
