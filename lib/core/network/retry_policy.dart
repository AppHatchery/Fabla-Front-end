import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

/// Number of times a failed request is re-sent before giving up.
/// Two retries means three attempts in total.
const int kMaxRetries = 2;

/// One retry for the S3 PUT: at two minutes per attempt, three attempts would
/// hold the submit spinner for six minutes on a single file.
const int kUploadMaxRetries = 1;

/// Delay before the first retry. Each subsequent retry doubles it.
const Duration kRetryBaseDelay = Duration(milliseconds: 500);

/// Fraction of the backoff that is randomised, ± this much.
const double _jitterFactor = 0.2;

final math.Random _random = math.Random();

/// Whether [error] is a connection-level failure: timeout, socket, TLS, or a
/// native client's `ClientException`. These can follow a write the server
/// already committed, so a non-idempotent caller passes `retries: 0`. Takes
/// [Object] because native clients throw types `on Exception` would miss.
bool isTransientNetworkError(Object error) {
  return error is TimeoutException ||
      error is SocketException ||
      error is HandshakeException ||
      error is http.ClientException;
}

/// Whether [statusCode] is a 5xx. A 5xx can follow a committed write, so only
/// idempotent callers retry it, by passing `retryServerErrors: true`.
bool isRetryableServerError(int statusCode) =>
    statusCode >= 500 && statusCode < 600;

/// Delay before zero-based retry [retryCount]: 500ms, 1s, … with ±20% jitter
/// so clients that lose connectivity together don't retry in lockstep.
Duration retryBackoff(int retryCount) {
  final base = kRetryBaseDelay.inMilliseconds * math.pow(2, retryCount);
  final jitter = base * _jitterFactor * (_random.nextDouble() * 2 - 1);
  return Duration(milliseconds: (base + jitter).round());
}
