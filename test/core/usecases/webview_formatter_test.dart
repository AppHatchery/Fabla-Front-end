import 'dart:convert';

import 'package:audio_diaries_flutter/core/usecases/webview_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('base64ToString', () {
    group('null and empty input', () {
      test('returns null for null input', () {
        expect(base64ToString(null), isNull);
      });

      test('returns null for empty string', () {
        expect(base64ToString(''), isNull);
      });
    });

    group('standard base64 decoding', () {
      test('decodes a simple ASCII string', () {
        // "test" → "dGVzdA==" in standard base64
        expect(base64ToString('dGVzdA=='), equals('test'));
      });

      test('decodes a string missing one padding char', () {
        // "ab" → "YWI=" — base64.normalize() restores the missing =
        expect(base64ToString('YWI'), equals('ab'));
      });

      test('decodes a string missing two padding chars', () {
        // "a" → "YQ==" — both = chars stripped
        expect(base64ToString('YQ'), equals('a'));
      });

      test('decodes UTF-8 multibyte characters', () {
        const original = 'héllo wörld';
        final encoded = base64Encode(utf8.encode(original));
        expect(base64ToString(encoded), equals(original));
      });

      test('decodes a realistic JS completion function', () {
        const jsFunction =
            '(function() { return document.querySelector(".EndOfSurvey") !== null; })()';
        final encoded = base64Encode(utf8.encode(jsFunction));
        expect(base64ToString(encoded), equals(jsFunction));
      });
    });

    group('URL-safe base64 decoding', () {
      test('decodes URL-safe base64 with _ replacing /', () {
        // "ab?" → "YWI/" standard → "YWI_" URL-safe.
        // Confirm the known encoding first so the test is self-documenting.
        expect(base64Encode(utf8.encode('ab?')), equals('YWI/'));
        expect(base64ToString('YWI_'), equals('ab?'));
      });

      test('decodes URL-safe base64 with - replacing +', () {
        // Bytes [0xE3, 0xBE, 0xBE] (U+3FBE) → "476+" standard → "476-" URL-safe.
        expect(base64Encode([0xE3, 0xBE, 0xBE]), equals('476+'));
        expect(base64ToString('476-'), equals('㾾'));
      });

      test('decodes URL-safe base64 without padding', () {
        // "ab?" URL-safe without padding — exercises both replacements and normalize().
        const original = 'ab?';
        final urlSafeNoPad = base64Encode(utf8.encode(original))
            .replaceAll('+', '-')
            .replaceAll('/', '_')
            .replaceAll('=', '');
        expect(base64ToString(urlSafeNoPad), equals(original));
      });
    });

    group('error handling', () {
      test('returns null for invalid base64 characters', () {
        expect(base64ToString('!!! not base64 !!!'), isNull);
      });

      test('returns null when decoded bytes are not valid UTF-8', () {
        // 0xFF is not a valid UTF-8 start byte, so utf8.decode must throw.
        final invalidUtf8Base64 = base64Encode([0xFF, 0xFE]);
        expect(base64ToString(invalidUtf8Base64), isNull);
      });
    });

    group('round-trip', () {
      test('round-trips with stringToBase64', () {
        const original =
            'function() { return document.querySelector(".EndOfSurvey") !== null; }';
        expect(base64ToString(stringToBase64(original)), equals(original));
      });

      test('round-trips for strings whose base64 contains + and /', () {
        // r'a+b/c' contains characters that will produce + and / in base64.
        const original = r'(function() { var x = a+b/c; return x > 0; })()';
        expect(base64ToString(stringToBase64(original)), equals(original));
      });
    });
  });

  group('stringToBase64', () {
    group('null and empty input', () {
      test('returns null for null input', () {
        expect(stringToBase64(null), isNull);
      });

      test('returns null for empty string', () {
        expect(stringToBase64(''), isNull);
      });
    });

    group('standard encoding', () {
      test('encodes a simple ASCII string to the correct base64', () {
        expect(stringToBase64('test'), equals('dGVzdA=='));
      });

      test('encoded output decodes back to the original string', () {
        const original = 'Hello, World!';
        final encoded = stringToBase64(original)!;
        expect(utf8.decode(base64Decode(encoded)), equals(original));
      });

      test('encodes UTF-8 multibyte characters', () {
        const original = 'héllo wörld';
        final encoded = stringToBase64(original)!;
        expect(utf8.decode(base64Decode(encoded)), equals(original));
      });

      test('encodes a realistic JS completion function', () {
        const jsFunction = '(function() { return true; })()';
        final encoded = stringToBase64(jsFunction);
        expect(encoded, isNotNull);
        expect(base64ToString(encoded), equals(jsFunction));
      });

      test('produces standard base64 (uses + and /, not - and _)', () {
        // "ab?" encodes to "YWI/" — the / confirms standard alphabet is used.
        expect(stringToBase64('ab?'), equals('YWI/'));
      });
    });

    group('round-trip', () {
      test('round-trips with base64ToString for strings with special chars', () {
        const original = r'arbitrary string: !@#$%^&*() héllo';
        expect(base64ToString(stringToBase64(original)), equals(original));
      });
    });
  });
}
