import 'dart:io';
import 'package:flutter_application_1/features/logic/character.dart';
import 'package:flutter_application_1/core/services/file_service.dart';

Future<Directory> getCharacterDirectory() async {
  final dir = Directory('${Directory.current.path}/Saved_Prompts/characters');

  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  return dir;
}

Future<void> saveCharacter(Character character) async {
  final baseDir = await getCharacterDirectory();
  final charDir = Directory('${baseDir.path}/${character.characterName}');
  if (!await charDir.exists()) {
    await charDir.create(recursive: true);
  }
  final file = File('${charDir.path}/${character.characterName}.json');
  await file.writeAsString(character.toFileContents());

  // Copy default templates if they do not exist in the character subdirectory
  final identityFile = File('${charDir.path}/identity.md');
  if (!await identityFile.exists()) {
    final content = await FileService().readAssetFile('assets/agent/personality/identity.md');
    await identityFile.writeAsString(content);
  }
  final sheetFile = File('${charDir.path}/sheet.md');
  if (!await sheetFile.exists()) {
    final content = await FileService().readAssetFile('assets/agent/stats/sheet.md');
    await sheetFile.writeAsString(content);
  }
}

Future<List<FileSystemEntity>> loadCharacterFiles() async {
  final dir = await getCharacterDirectory();
  if (!await dir.exists()) {
    return [];
  }
  final List<FileSystemEntity> jsonFiles = [];
  for (var entity in dir.listSync()) {
    if (entity is Directory) {
      for (var subEntity in entity.listSync()) {
        if (subEntity is File && subEntity.path.endsWith('.json')) {
          jsonFiles.add(subEntity);
        }
      }
    }
  }
  return jsonFiles;
}
