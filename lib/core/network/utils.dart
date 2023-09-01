import 'dart:io';
///Organised of audio response with its data ready for upload, nomally collected as a list. As this List<DiaryAudioData>


//Note: You can move this class to its intended directory to mantain consistency this was done for convenience

class DiaryAudioData{
  int prompt;
  File file;
  DateTime date;
  DiaryAudioData(this.prompt, this.file, this.date);
}