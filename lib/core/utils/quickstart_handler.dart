import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:developer' show log;

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class QuickstartHandler {
  /// Lambda function URL that serves presigned links to the quickstart
  /// videos stored in S3. The `key` query parameter is the S3 prefix; each
  /// video's filename is appended to it in [getVideoUrl].
  final baseUrl =
      "https://rni3xlmdeyk4mk4tqab6mudmwa0bpais.lambda-url.us-east-1.on.aws/?key=amazon-fabla-videos/";

  /// Maps a short video name to its filename in the S3 bucket.
  static final videos = {
    'walkThrough': '0_full_walkthrough.mp4',
    'study': '1_study_page.mp4',
    'history': '2_history.mp4',
    'incentives': '3_incentives.mp4',
    'calendar': '4_calendar.mp4',
    'settings': '5_settings.mp4',
    'skip': 'skip_sheet_hint_help_on_settings.mp4',
  };

  static const _requestTimeout = Duration(seconds: 10);
  static const _cacheKey = 'videoUrls';

  /// Presigned S3 URLs returned by the Lambda are only valid for 10 hours;
  /// a cache older than this is treated as missing so callers refetch
  /// instead of using dead links.
  static const _cacheTtl = Duration(hours: 10);

  /// Builds the request URL for [videoName] by appending its filename to
  /// the existing `key` query parameter on [baseUrl].
  Uri getVideoUrl(String videoName) {
    final video = videos[videoName];
    if (video == null) {
      throw Exception("Video not found");
    }
    final base = Uri.parse(baseUrl);
    return base.replace(
      queryParameters: {
        ...base.queryParameters,
        'key': '${base.queryParameters['key']}$video',
      },
    );
  }

  /// Fetches the presigned S3 URL for [videoName] from the Lambda endpoint.
  ///
  /// [client] can be provided to reuse a connection across multiple calls
  /// (see [getVideos]). If not provided, a client is created and closed
  /// for this call only.
  Future<String> getVideo(
    String videoName, {
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();

    try {
      final url = getVideoUrl(videoName);
      final response = await httpClient.post(url).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        throw Exception(
            "Failed to fetch video. Status code: ${response.statusCode}");
      }

      final body = jsonDecode(response.body);
      if (body is! Map || body['url'] is! String) {
        throw Exception("Unexpected response shape: ${response.body}");
      }
      return body['url'] as String;
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// Fetches presigned URLs for all [videos] and caches them in
  /// [SharedPreferences] under the `videoUrls` key.
  ///
  /// Videos that fail to fetch are logged and skipped rather than aborting
  /// the whole batch, so a partial cache is still saved. [client] follows
  /// the same reuse-or-create convention as [getVideo].
  Future<void> getVideos({http.Client? client}) async {
    final videoUrls = <String, String>{};
    final httpClient = client ?? http.Client();
    try {
      for (var videoName in videos.keys) {
        try {
          final videoUrl = await getVideo(videoName, client: httpClient);
          videoUrls[videoName] = videoUrl;
        } catch (e) {
          log('Error fetching video $videoName: $e',
              name: 'QuickstartHandler - getVideos');
        }
      }
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }

    final payload = {
      'fetchedAt': DateTime.now().millisecondsSinceEpoch,
      'urls': videoUrls,
    };
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(payload));
  }

  /// Reads the video URLs cached by [getVideos], keyed the same way as
  /// [videos]. Returns an empty map if nothing has been cached yet, or if
  /// the cache is older than [_cacheTtl].
  Future<Map<String, String>> getCachedVideoUrls() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached == null) return {};

    final decoded = jsonDecode(cached);
    if (decoded is! Map) return {};

    final fetchedAt = decoded['fetchedAt'];
    final urls = decoded['urls'];
    if (fetchedAt is! int || urls is! Map) return {};

    final age = DateTime.now().millisecondsSinceEpoch - fetchedAt;
    if (age > _cacheTtl.inMilliseconds) return {};

    return urls.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  /// Fetches and caches video URLs only if the cache is missing any of
  /// [videos] (including if it has expired past [_cacheTtl]). Safe to call
  /// speculatively without awaiting — failures are logged inside
  /// [getVideos] rather than thrown.
  Future<void> ensureVideosCached({http.Client? client}) async {
    final cached = await getCachedVideoUrls();
    final hasAllVideos = videos.keys.every(cached.containsKey);
    if (hasAllVideos) return;

    await getVideos(client: client);
  }
}
