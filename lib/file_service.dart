import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileService {
  static Future<String> getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> getLocalFile(String filename) async {
    final path = await getLocalPath();
    return File('$path/$filename');
  }

  static Future<File> writeData(String filename, String data) async {
    final file = await getLocalFile(filename);
    return file.writeAsString(data, mode: FileMode.writeOnlyAppend);
  }

  static Future<String> readData(String filename) async {
    try {
      final file = await getLocalFile(filename);
      return await file.readAsString();
    } catch (e) {
      print('Error reading file: $e');
      return '';
    }
  }

  static Future<void> exportData(String filename) async {
    try {
      final file = await getLocalFile(filename);
      await Share.shareXFiles([XFile(file.path)], text: 'BLE Data Export');
    } catch (e) {
      print('Error exporting file: $e');
    }
  }
}
