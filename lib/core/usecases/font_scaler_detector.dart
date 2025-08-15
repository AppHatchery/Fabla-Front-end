import 'package:flutter/material.dart';

Future<TextScaler> fontScaler(BuildContext context) async {
  final scaler = MediaQuery.of(context).textScaler;
  return scaler;
}
