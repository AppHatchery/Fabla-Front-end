import 'package:material_ui/material_ui.dart';

Future<TextScaler> fontScaler(BuildContext context) async {
  final scaler = MediaQuery.of(context).textScaler;
  return scaler;
}
