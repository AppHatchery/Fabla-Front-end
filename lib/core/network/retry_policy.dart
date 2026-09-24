import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

/// Number of times a failed request is re-sent before giving up.
/// Two retries means three attempts in total.
const int kMaxRetries = 2;

/// The S3 PUT gets a single retry rather than two: each attempt is allowed a
/// two-minute timeout, so three attempts would keep a participant waiting on
/// the "Do Not Leave This Screen" spinner for six minutes on one file alone.
const int kUploadMaxRetries = 1;

/// Delay before the first retry. Each subsequent retry doubles it.
const Duration kRetryBaseDelay = Duration(milliseconds: 500);

/// Fraction of the backoff that is randomised, ± this much.
const double _jitterFactor = 0.2;

final math.Random _random = math.Random();

/// Whether [error] means the request never produced a usable response — the
/// connection timed out, DNS failed, TLS failed, or the socket dropped.
///
/// These are the only failures the network layer re-sends. Note what that does
/// *not* claim: it is not a guarantee the server never saw the request. A
/// `TimeoutException` fires on the response, after the body has been written,
/// and the native clients raise `ClientException` for a connection dropped
/// mid-request — either can follow a write the server already committed.
///
/// Safety therefore comes from the call site, not from this predicate: a
/// caller whose request is not idempotent passes `retries: 0` rather than
/// trusting the error type. [uploadNonAudioData] is the one such caller.
///
/// HTTP status codes are deliberately excluded, including 5xx. A 500 can be
/// returned *after* a write has landed, so re-sending one risks a duplicate
/// diary submission — and the DynamoDB Lambda that owns that write is not in
/// this repo, so there is no server-side dedupe to fall back on.
///
/// Takes an [Object] rather than an [Exception] on purpose: the native HTTP
/// clients and some plugins raise types that an `on Exception` clause would
/// silently skip.
bool isTransientNetworkError(Object error) {
  return error is TimeoutException ||
      error is SocketException ||
      error is HandshakeException ||
      error is http.ClientException;
}

/// Whether [statusCode] is a server-side failure worth re-sending.
///
/// Unlike [isTransientNetworkError], this is **not** safe to apply everywhere.
/// A 5xx can be returned after the server has already acted, so re-sending one
/// is only sound when the request is idempotent — a read, or a write that
/// lands on the same state however many times it arrives. Callers assert that
/// by passing `retryServerErrors: true`; the default is off.
///
/// 4xx is excluded throughout: a client error will not fix itself on a second
/// identical attempt.
bool isRetryableServerError(int statusCode) =>
    statusCode >= 500 && statusCode < 600;

/// Delay before the retry numbered [retryCount] (zero-based).
///
/// Exponential — 500ms, then 1s — with ±20% jitter. The jitter matters: a
/// study cohort that all lose connectivity at the same moment would otherwise
/// retry in lockstep and hit the Lambda as a thundering herd.
Duration retryBackoff(int retryCount) {
  final base = kRetryBaseDelay.inMilliseconds * math.pow(2, retryCount);
  final jitter = base * _jitterFactor * (_random.nextDouble() * 2 - 1);
  return Duration(milliseconds: (base + jitter).round());
}
