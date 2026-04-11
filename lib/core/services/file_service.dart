import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileService {
  /// Reads a file from the app's assets.
  Future<String> readAssetFile(String assetPath) async {
    try {
      return await rootBundle.loadString(assetPath);
    } catch (e) {
      throw Exception('Failed to read asset file: $assetPath, error: $e');
    }
  }

  /// Gets the local documents directory path.
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Gets a [File] object for a given filename in the local documents directory.
  Future<File> _getLocalFile(String fileName) async {
    final path = await _localPath;
    final filePath = p.join(path, fileName);
    return File(filePath);
  }

  /// Reads a file from the local documents directory.
  Future<String> readLocalFile(String fileName) async {
    try {
      final file = await _getLocalFile(fileName);
      if (await file.exists()) {
        return await file.readAsString();
      } else {
        throw Exception('File does not exist: $fileName');
      }
    } catch (e) {
      throw Exception('Failed to read local file: $fileName, error: $e');
    }
  }

  /// Writes content to a file in the local documents directory.
  Future<void> writeLocalFile(String fileName, String content) async {
    try {
      final file = await _getLocalFile(fileName);
      await file.writeAsString(content);
    } catch (e) {
      throw Exception('Failed to write local file: $fileName, error: $e');
    }
  }

  /// Checks if a file exists in the local documents directory.
  Future<bool> localFileExists(String fileName) async {
    try {
      final file = await _getLocalFile(fileName);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}

