import 'dart:convert';
import 'dart:developer' as dev;

// Decodes a base64-encoded string to UTF-8 text.
// The result is used as a JS completion-check function executed in the WebView —
//! only pass values sourced from your own backend, never from user input.
String? base64ToString(String? base64String) {
  if (base64String == null || base64String.isEmpty) return null;

  try {
    // Normalize URL-safe alphabet (- _) to standard (+ /) before decoding,
    // then let base64.normalize() add any missing = padding — both variants
    // are common in web/server contexts and base64Decode rejects them otherwise.
    final normalized = base64.normalize(
      base64String.replaceAll('-', '+').replaceAll('_', '/'),
    );
    final bytes = base64Decode(normalized);
    // utf8.decode throws FormatException on invalid sequences (allowMalformed
    // defaults to false), which surfaces a clear error rather than silent corruption.
    return utf8.decode(bytes);
  } catch (e) {
    dev.log('Error decoding base64 string: $e', name: 'base64ToString');
    return null;
  }
}

// Encodes a UTF-8 string to standard base64.
// utf8.encode and base64Encode don't throw for valid Dart strings, so the
// catch is a safety net for any unexpected edge cases.
String? stringToBase64(String? normalString) {
  if (normalString == null || normalString.isEmpty) return null;

  try {
    // utf8.encode converts Dart's internal UTF-16 representation to UTF-8 bytes
    // before base64Encode packs them into a printable ASCII string.
    final bytes = utf8.encode(normalString);
    return base64Encode(bytes);
  } catch (e) {
    dev.log('Error encoding string to base64: $e', name: 'stringToBase64');
    return null;
  }
}
