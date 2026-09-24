import 'dart:async';
import 'dart:io';

import 'package:audio_diaries_flutter/core/network/retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('isTransientNetworkError', () {
    test('is true for a connection timeout', () {
      expect(
        isTransientNetworkError(TimeoutException('timed out')),
        isTrue,
      );
    });

    test('is true for a socket failure', () {
      expect(isTransientNetworkError(const SocketException('no route')), isTrue);
    });

    test('is true for a TLS handshake failure', () {
      expect(isTransientNetworkError(const HandshakeException()), isTrue);
    });

    test('is true for a ClientException', () {
      // The native clients raise this for a dropped connection mid-request.
      expect(
        isTransientNetworkError(http.ClientException('connection closed')),
        isTrue,
      );
    });

    test('is false for a decode failure', () {
      // A malformed body is not worth re-sending — it will decode the same way.
      expect(isTransientNetworkError(const FormatException('bad json')), isFalse);
    });

    test('is false for an arbitrary object', () {
      expect(isTransientNetworkError(Object()), isFalse);
      expect(isTransientNetworkError('some error string'), isFalse);
    });
  });

  group('retryBackoff', () {
    test('grows with each retry', () {
      // Compare against the un-jittered midpoints so the ±20% band cannot
      // make this flaky.
      final first = retryBackoff(0);
      final second = retryBackoff(1);

      expect(first.inMilliseconds, lessThan(second.inMilliseconds));
    });

    test('stays within the jitter band of the exponential schedule', () {
      for (var retry = 0; retry < kMaxRetries; retry++) {
        final expected = kRetryBaseDelay.inMilliseconds * (1 << retry);
        final delay = retryBackoff(retry).inMilliseconds;

        expect(delay, greaterThanOrEqualTo((expected * 0.8).floor()));
        expect(delay, lessThanOrEqualTo((expected * 1.2).ceil()));
      }
    });

    test('is never negative', () {
      for (var retry = 0; retry < 5; retry++) {
        expect(retryBackoff(retry).inMilliseconds, greaterThanOrEqualTo(0));
      }
    });

    test('applies jitter rather than a fixed delay', () {
      // Two hundred samples of a ±20% band collapsing to one value would mean
      // the jitter was dropped, which is what causes a retry thundering herd.
      final samples = {
        for (var i = 0; i < 200; i++) retryBackoff(0).inMilliseconds,
      };

      expect(samples.length, greaterThan(1));
    });
  });

  group('retry budgets', () {
    test('the upload budget is smaller than the default', () {
      // Each S3 attempt is allowed two minutes, so it gets fewer of them.
      expect(kUploadMaxRetries, lessThan(kMaxRetries));
    });
  });
}
