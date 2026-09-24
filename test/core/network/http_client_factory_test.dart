import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_diaries_flutter/core/network/http_client_factory.dart';
import 'package:audio_diaries_flutter/core/network/retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// No real waiting between attempts — the backoff schedule itself is covered
/// in retry_policy_test.dart.
Duration _noDelay(int _) => Duration.zero;

/// A client that records every request it is asked to send.
///
/// [MockClient] is used here rather than the repo's usual mocktail mocks
/// because the wrappers under test call `send()`, and this is the clean way to
/// count sends and script a different response per attempt. It ships inside
/// the existing `http` dependency.
class _RecordingClient {
  _RecordingClient(this._respond);

  final Future<http.Response> Function(http.Request request, int attempt)
      _respond;
  final List<http.Request> requests = [];

  int get sends => requests.length;

  MockClient get client => MockClient((request) {
        requests.add(request);
        return _respond(request, requests.length - 1);
      });
}

/// Tracks running requests the way `CupertinoClient` tracks its NSURLSession
/// tasks: a request stays live until its abortTrigger lands, and [close]
/// throws while any is still live.
///
/// [MockClient.close] does nothing, which is how a timed-out request left
/// running slipped past the rest of this file.
class _NativeLikeClient extends http.BaseClient {
  /// A null response leaves that attempt hanging until it is aborted.
  _NativeLikeClient(this._respond);

  final http.StreamedResponse? Function(int attempt) _respond;

  int sends = 0;
  int aborts = 0;
  int _live = 0;
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final attempt = sends++;
    await request.finalize().drain<void>();
    final response = _respond(attempt);
    if (response != null) return response;

    _live++;
    if (request case http.Abortable(:final abortTrigger?)) {
      await abortTrigger;
      // NSURLSession confirms a cancel on a later turn of the event loop.
      await Future<void>.delayed(Duration.zero);
      _live--;
      aborts++;
      throw http.RequestAbortedException(request.url);
    }
    return Completer<http.StreamedResponse>().future;
  }

  @override
  void close() {
    if (_live > 0) throw StateError('cannot close with running requests');
    closed = true;
  }
}

http.StreamedResponse _ok() =>
    http.StreamedResponse(Stream.value(utf8.encode('ok')), 200);

void main() {
  const shortTimeout = Duration(milliseconds: 50);
  final url = Uri.parse('https://example.com/upload');

  group('timeouts', () {
    test('a request that never completes fails with a TimeoutException', () {
      final inner = MockClient((_) => Completer<http.Response>().future);
      final client = wrapClient(inner, timeout: shortTimeout, retries: 0);

      expect(
        () => client.get(url),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('a request that completes in time is returned untouched', () async {
      final inner = MockClient((_) async => http.Response('ok', 200));
      final client = wrapClient(inner, timeout: shortTimeout, retries: 0);

      final response = await client.get(url);

      expect(response.statusCode, 200);
      expect(response.body, 'ok');
    });

    test('each attempt gets its own timeout budget', () async {
      // Two attempts at 50ms each must not share a single 50ms budget, or the
      // second would be dead on arrival.
      var attempt = 0;
      final inner = MockClient((_) async {
        if (attempt++ == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        return http.Response('ok', 200);
      });

      final client = wrapClient(
        inner,
        timeout: shortTimeout,
        retries: 1,
        delay: _noDelay,
      );

      final response = await client.get(url);

      expect(response.statusCode, 200);
      expect(attempt, 2);
    });
  });

  group('retry on connection failures', () {
    test('a timeout triggers a retry', () async {
      final recorder = _RecordingClient((_, attempt) async {
        if (attempt == 0) throw TimeoutException('timed out');
        return http.Response('ok', 200);
      });

      final response = await wrapClient(
        recorder.client,
        retries: kMaxRetries,
        delay: _noDelay,
      ).get(url);

      expect(response.statusCode, 200);
      expect(recorder.sends, 2);
    });

    test('gives up after the capped number of attempts', () async {
      final recorder = _RecordingClient(
        (_, __) async => throw const SocketException('no route to host'),
      );

      await expectLater(
        wrapClient(recorder.client, retries: kMaxRetries, delay: _noDelay)
            .get(url),
        throwsA(isA<SocketException>()),
      );

      // Retries are *additional* attempts, hence the + 1.
      expect(recorder.sends, kMaxRetries + 1);
    });

    test('a socket failure is retried', () async {
      final recorder = _RecordingClient((_, attempt) async {
        if (attempt < 2) throw const SocketException('connection reset');
        return http.Response('ok', 200);
      });

      final response = await wrapClient(
        recorder.client,
        retries: kMaxRetries,
        delay: _noDelay,
      ).get(url);

      expect(response.statusCode, 200);
      expect(recorder.sends, 3);
    });

    test('retries: 0 never re-sends, even on a timeout', () async {
      final recorder = _RecordingClient(
        (_, __) async => throw TimeoutException('timed out'),
      );

      await expectLater(
        wrapClient(recorder.client, retries: 0, delay: _noDelay).get(url),
        throwsA(isA<TimeoutException>()),
      );

      expect(recorder.sends, 1);
    });

    test('a non-transient error is not retried', () async {
      final recorder = _RecordingClient(
        (_, __) async => throw const FormatException('bad json'),
      );

      await expectLater(
        wrapClient(recorder.client, retries: kMaxRetries, delay: _noDelay)
            .get(url),
        throwsA(isA<FormatException>()),
      );

      expect(recorder.sends, 1);
    });
  });

  group('status codes are not retried by default', () {
    // This is the guard that keeps a retry from writing a diary response
    // twice: a 5xx can be returned *after* the write has landed. Only a caller
    // that knows its request is idempotent may opt out of this, by passing
    // `retryServerErrors` — see the group below.
    for (final status in [500, 502, 503, 504, 408, 429]) {
      test('$status is returned to the caller after exactly one send',
          () async {
        final recorder = _RecordingClient(
          (_, __) async => http.Response('server said $status', status),
        );

        final response = await wrapClient(
          recorder.client,
          retries: kMaxRetries,
          delay: _noDelay,
        ).post(url, body: 'diary responses');

        expect(response.statusCode, status);
        expect(recorder.sends, 1);
      });
    }

    test('a 4xx is not retried', () async {
      final recorder = _RecordingClient(
        (_, __) async => http.Response('nope', 403),
      );

      final response = await wrapClient(
        recorder.client,
        retries: kMaxRetries,
        delay: _noDelay,
      ).get(url);

      expect(response.statusCode, 403);
      expect(recorder.sends, 1);
    });
  });

  group('server errors, when the caller opts in', () {
    test('a 500 is re-sent and can still succeed', () async {
      final recorder = _RecordingClient((_, attempt) async => attempt == 0
          ? http.Response('overloaded', 500)
          : http.Response('{"uploadURL":"..."}', 200));

      final response = await wrapClient(
        recorder.client,
        retries: kMaxRetries,
        retryServerErrors: true,
        delay: _noDelay,
      ).post(url, body: 'mint me a url');

      expect(response.statusCode, 200);
      expect(recorder.sends, 2);
    });

    test('the 5xx is returned once the budget is spent', () async {
      final recorder = _RecordingClient(
        (_, __) async => http.Response('still overloaded', 503),
      );

      final response = await wrapClient(
        recorder.client,
        retries: kMaxRetries,
        retryServerErrors: true,
        delay: _noDelay,
      ).get(url);

      // The caller sees the real status, not a synthesized failure.
      expect(response.statusCode, 503);
      expect(recorder.sends, kMaxRetries + 1);
    });

    test('a 4xx is still not retried', () async {
      // Opting in covers server faults only — a client error will not fix
      // itself on an identical second attempt.
      final recorder = _RecordingClient(
        (_, __) async => http.Response('nope', 403),
      );

      final response = await wrapClient(
        recorder.client,
        retries: kMaxRetries,
        retryServerErrors: true,
        delay: _noDelay,
      ).get(url);

      expect(response.statusCode, 403);
      expect(recorder.sends, 1);
    });

    for (final status in [408, 429]) {
      test('$status is still not retried', () async {
        // Deliberately out of scope: the ticket asks for 5xx. 429 in
        // particular wants Retry-After handling rather than blind backoff.
        final recorder = _RecordingClient(
          (_, __) async => http.Response('', status),
        );

        final response = await wrapClient(
          recorder.client,
          retries: kMaxRetries,
          retryServerErrors: true,
          delay: _noDelay,
        ).get(url);

        expect(response.statusCode, status);
        expect(recorder.sends, 1);
      });
    }
  });

  group('request replay', () {
    test('a retried PUT re-sends an identical body', () async {
      // The S3 upload case. A finalized http.Request cannot be re-sent, so
      // this asserts the wrapper really does buffer and replay the body.
      final recorder = _RecordingClient((_, attempt) async {
        if (attempt == 0) throw TimeoutException('timed out');
        return http.Response('', 200);
      });

      final request = http.Request('PUT', url)
        ..headers['Content-Type'] = 'audio/mp4'
        ..bodyBytes = List<int>.generate(2048, (i) => i % 256);

      final response = await wrapClient(
        recorder.client,
        retries: kUploadMaxRetries,
        delay: _noDelay,
      ).send(request);
      await response.stream.drain<void>();

      expect(response.statusCode, 200);
      expect(recorder.sends, 2);
      expect(recorder.requests[1].bodyBytes, recorder.requests[0].bodyBytes);
      expect(recorder.requests[1].bodyBytes.length, 2048);
      expect(recorder.requests[1].method, 'PUT');
      expect(recorder.requests[1].headers['Content-Type'], 'audio/mp4');
    });

    test('a retried PUT targets the same URL, so S3 overwrites one key',
        () async {
      final recorder = _RecordingClient((_, attempt) async {
        if (attempt == 0) throw const SocketException('reset');
        return http.Response('', 200);
      });

      await wrapClient(
        recorder.client,
        retries: kUploadMaxRetries,
        delay: _noDelay,
      ).put(url, body: 'audio');

      expect(recorder.sends, 2);
      expect(recorder.requests[1].url, recorder.requests[0].url);
    });
  });

  group('body drain', () {
    // BaseClient.get/post drain the body in Response.fromStream, after send()
    // has already completed. Without an explicit guard the timeout would only
    // cover the headers, and a server that sends headers then stalls would
    // hang the caller forever — Cronet has no timeout of its own to stop it.
    test('a stalled response body times out rather than hanging', () {
      final inner = MockClient.streaming(
        (_, __) async => http.StreamedResponse(
          StreamController<List<int>>().stream,
          200,
        ),
      );
      final client = wrapClient(inner, timeout: shortTimeout, retries: 0);

      expect(() => client.get(url), throwsA(isA<TimeoutException>()));
    });

    test('a body that keeps arriving is not cut off by the timeout', () async {
      // Four chunks, each a hair inside the budget, totalling well past it.
      // The guard is on the gap between chunks, so this must survive.
      final gap = Duration(milliseconds: shortTimeout.inMilliseconds ~/ 2);
      final inner = MockClient.streaming(
        (_, __) async => http.StreamedResponse(
          Stream.periodic(gap, (i) => [0x61]).take(4),
          200,
        ),
      );
      final client = wrapClient(inner, timeout: shortTimeout, retries: 0);

      final response = await client.get(url);

      expect(response.body, 'aaaa');
    });

    test('a stalled body is not re-sent', () async {
      // RetryClient wraps send() only, so by the time the body stalls the
      // request has been fully written. Re-sending could duplicate a write the
      // server already committed.
      var sends = 0;
      final inner = MockClient.streaming((_, __) async {
        sends++;
        return http.StreamedResponse(
          StreamController<List<int>>().stream,
          200,
        );
      });

      await expectLater(
        wrapClient(inner,
                timeout: shortTimeout, retries: kMaxRetries, delay: _noDelay)
            .get(url),
        throwsA(isA<TimeoutException>()),
      );
      expect(sends, 1);
    });
  });

  group('a timed-out attempt is aborted', () {
    // Every call site closes its client in a `finally`. On iOS that close
    // throws while a request is still running, and the throw replaces
    // whatever the call site was about to return.
    test('a retry that succeeds after a timeout leaves the client closable',
        () async {
      final inner = _NativeLikeClient((attempt) => attempt == 0 ? null : _ok());
      final client = wrapClient(
        inner,
        timeout: shortTimeout,
        retries: 1,
        delay: _noDelay,
      );

      final response = await client.get(url);

      expect(response.statusCode, 200);
      expect(client.close, returnsNormally);
      await pumpEventQueue();
      expect(inner.aborts, 1);
      expect(inner.closed, isTrue);
    });

    test('closing before the abort has landed does not throw', () async {
      // The DynamoDB POST case: no retry, so the caller's `finally` runs before
      // the abort has even reached the native client.
      final inner = _NativeLikeClient((_) => null);
      final client = wrapClient(inner, timeout: shortTimeout, retries: 0);

      await expectLater(client.get(url), throwsA(isA<TimeoutException>()));

      expect(inner.aborts, 0);
      expect(client.close, returnsNormally);
      expect(inner.closed, isFalse, reason: 'closing waits for the abort');
      await pumpEventQueue();
      expect(inner.aborts, 1);
      expect(inner.closed, isTrue);
    });

    test("a caller's own abortTrigger still reaches the inner client",
        () async {
      final inner = _NativeLikeClient((_) => null);
      final client = wrapClient(
        inner,
        timeout: const Duration(seconds: 5),
        retries: 0,
      );
      final cancel = Completer<void>();

      final sent = client
          .send(http.AbortableRequest('GET', url, abortTrigger: cancel.future));
      cancel.complete();

      // A TimeoutException here would mean the trigger was dropped and only
      // the timeout ended the request.
      await expectLater(sent, throwsA(isA<http.RequestAbortedException>()));
      expect(inner.aborts, 1);
    });
  });

  group('timeout constants', () {
    test('the upload ceiling is more generous than the default', () {
      // The S3 PUT pushes the whole file inside send(), so it cannot share the
      // budget sized for a JSON round trip.
      expect(kUploadTimeout, greaterThan(kDefaultTimeout));
    });

    test('the notification image download fails faster than the default', () {
      expect(kImageDownloadTimeout, lessThan(kDefaultTimeout));
    });
  });
}
