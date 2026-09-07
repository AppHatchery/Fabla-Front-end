import 'dart:io';

import 'package:cronet_http/cronet_http.dart';
import 'package:cupertino_http/cupertino_http.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';

const _maxCacheSize = 2 * 1024 * 1024;
const _userAgent = 'Fabla/edu.emory.audio.diaries';

/// Returns an [Client] backed by the platform's native network stack
/// (Cronet on Android, NSURLSession on iOS/macOS) so TLS validation honors
/// the OS certificate trust store instead of Dart's own bundled root store.
Client httpClient() {
  if (Platform.isAndroid) {
    final engine = CronetEngine.build(
        cacheMode: CacheMode.memory,
        cacheMaxSize: _maxCacheSize,
        userAgent: _userAgent);
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
