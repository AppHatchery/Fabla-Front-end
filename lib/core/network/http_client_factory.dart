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

/// The S3 PUT pushes the whole file inside `send()`, so it needs a far more
/// generous ceiling than a JSON round trip. The "Slow Upload" telemetry takes
/// its threshold from this value rather than repeating it as a literal, so the
/// two cannot drift apart.
const kUploadTimeout = Duration(minutes: 2);

/// A notification's big-picture image is cosmetic — fail fast rather than
/// delay the notification itself.
const kImageDownloadTimeout = Duration(seconds: 15);

/// Returns a [Client] backed by the platform's native network stack
/// (Cronet on Android, NSURLSession on iOS/macOS) so TLS validation honors
/// the OS certificate trust store instead of Dart's own bundled root store.
///
/// The returned client applies [timeout] to each attempt and automatically
/// re-sends up to [retries] times on connection-level failures. See
/// [wrapClient] for what does and does not get retried.
Client httpClient({
  Duration timeout = kDefaultTimeout,
  int retries = kMaxRetries,
  bool retryServerErrors = false,
}) =>
    wrapClient((debugPlatformClientBuilder ?? _platformClient)(),
        timeout: timeout,
        retries: retries,
        retryServerErrors: retryServerErrors);

/// Replaces the platform client [httpClient] wraps, for tests only.
///
/// Without this seam a call site's chosen timeout and retry budget cannot be
/// reached from a test: the config lives in the `client ?? httpClient(...)`
/// branch that runs only when nothing is injected, and that branch builds a
/// native client with no host binding under `flutter test`. Injecting a client
/// at the call site skips the very line under test, so dropping a `retries:`
/// argument would go unnoticed.
///
/// Production never assigns this. A test that sets it must clear it again —
/// `addTearDown(() => debugPlatformClientBuilder = null)`.
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

/// Wraps [inner] with a per-attempt [timeout] and, when [retries] is greater
/// than zero, automatic re-send on connection-level failures.
///
/// Retry sits *outside* the timeout so each attempt gets its own full budget
/// rather than all attempts sharing one.
///
/// [isTransientNetworkError] failures are always retried. Status codes are not,
/// unless [retryServerErrors] is set — which only an idempotent caller may do,
/// because a 5xx can arrive after the server has already acted. A 4xx is never
/// retried. See [isRetryableServerError].
///
/// [delay] overrides the backoff schedule; it defaults to [retryBackoff] and
/// exists so tests can run without real waits.
///
/// Exposed separately from [httpClient] so a test can wrap a client of its own
/// directly. To exercise a *call site's* chosen budget instead — the code that
/// actually ships — override [debugPlatformClientBuilder] and let [httpClient]
/// run.
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

/// Bounds how long a single attempt may take, covering both the wait for
/// response headers and the body that follows.
///
/// The body needs its own guard because [BaseClient.get]/[BaseClient.post]
/// drain it in `Response.fromStream`, *after* `send()` has already completed —
/// so a server that returns headers and then stalls mid-body would otherwise
/// hang forever. Cronet exposes no timeout of its own, so on Android nothing
/// underneath would ever break that hang.
///
/// A body timeout is deliberately not retried: [RetryClient] wraps `send()`
/// only, and by the time the body stalls the request has been fully written,
/// so re-sending it risks duplicating a write the server may have committed.
///
/// A timeout while waiting for headers aborts the native request instead of
/// abandoning it. `CupertinoClient.close()` throws while any of its tasks is
/// still running, so an abandoned attempt would turn the caller's
/// `finally { client.close(); }` into a `StateError`, replacing even a
/// successful retry's result. On Cronet an abandoned S3 PUT would keep
/// uploading alongside its own retry. The native cancel lands asynchronously,
/// so [close] defers closing the inner client until aborted attempts settle.
/// A body stall needs no abort of its own: the caller cancels the stream on
/// the error, and both native clients cancel the request when that happens.
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
    // `Stream.timeout` fires on the gap *between* chunks, not on total
    // duration, so a large-but-progressing download is never punished — only a
    // stall longer than [_timeout] aborts.
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
    // Stay non-streaming: CupertinoClient sends a Request body as one NSData
    // rather than through an NSInputStream.
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
