import 'package:audio_diaries_flutter/core/secrets/keys.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String devURL =
    "sropo6jsmhm4hnxzlrqairw6xu0tfjcn.lambda-url.us-east-1.on.aws";
const String prodURL =
    "phy7427sobzzf3dbeevuvi6z4m0dehgx.lambda-url.us-east-1.on.aws";

const Map<String, String> headers = {
  'Content-Type': 'application/x-www-form-urlencoded',
  'x-api-key': apiKey
};

String base() {
  if (kDebugMode) {
    print("Using dev URL");
    return devURL;
  } else {
    print("Using prod URL");
    return prodURL;
  }
}

Future<String?> get({required String path}) async {
  try {
    final url = Uri.https(base(), path);
    final response = await http.get(url, headers: headers);
    return response.body;
  } catch (e) {
    debugPrint(e.toString());
    return null;
  }
}

Future<String?> post(
    {required String path, required Map<String, dynamic> body}) async {
  try {
    final url = Uri.https(base(), path);
    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      debugPrint(response.body);
      throw Exception("Failed to post");
    }
  } catch (e) {
    debugPrint(e.toString());
    return null;
  }
}
