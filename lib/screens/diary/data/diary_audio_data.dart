import 'dart:io';

class DiaryAudioData {
  final int prompt;
  final File file;
  final DateTime date;
  const DiaryAudioData(
      {required this.prompt, required this.file, required this.date});
}
