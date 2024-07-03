import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String apiURL =
    "e335ntbdo6jdh4gm2sljq6vwem0etasd.lambda-url.us-east-1.on.aws";

Future<String?> get({required String path}) async {
  try {
    final Map<String, String> headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'x-api-key': '11111'
    };

    final url = Uri.https(apiURL, path);
    final response = await http.get(url, headers: headers);
    return jsonDecode(response.body);
  } catch (e) {
    debugPrint(e.toString());
    return null;
  }
}

Future<String?> post(
    {required String path, required Map<String, dynamic> body}) async {
  try {
    // TODO: Secure this
    final Map<String, String> headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'x-api-key': '11111'
    };

    final url = Uri.https(apiURL, path);
    final response = await http.post(url, headers: headers, body: body);
    return response.body;
  } catch (e) {
    debugPrint(e.toString());
    return null;
  }
}
