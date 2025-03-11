import 'dart:developer' as dev;
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:video_compress/video_compress.dart';

class FileInformation {
  final File thumbnail;
  final Duration length;
  final String absolutePath;
  const FileInformation(
      {required this.thumbnail,
      required this.length,
      required this.absolutePath});
}

Future<FileInformation> getVideoFileInfo({required String path}) async {
  try {
    final _path = await getPath(name: path);
    final thumbnail = await VideoCompress.getFileThumbnail(_path);
    final info = await VideoCompress.getMediaInfo(_path);
    final duration = info.duration ?? 0;
    final length = Duration(milliseconds: duration.toInt());
    return FileInformation(
        thumbnail: thumbnail, length: length, absolutePath: _path);
  } catch (e) {
    dev.log(e.toString(), name: 'Video Thumbnail - Get Thumbnail');

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/assets/images/living_room.png';
    return FileInformation(
        thumbnail: File(path), length: Duration.zero, absolutePath: path);
  }
}

Future<File> getImageFile({required String path}) async {
  try {
    final _path = await getPath(name: path);
    return File(_path);
  } catch (e) {
    dev.log(e.toString(), name: 'Video Thumbnail - Get Thumbnail');

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/assets/images/living_room.png';

    return File(path);
  }
}

Future<String> getPath({required String name}) async {
  final dir = await getApplicationDocumentsDirectory();
  return p.join(dir.path, name);
}
