import 'dart:io';
import 'package:flutter_application_1/features/logic/character.dart';
import 'package:path_provider/path_provider.dart';

// Future<Directory> getCharacterDirectory() async {
//   final appDir = "../../../characters";

//   final dir = Directory('$appDir/characters');

//   if (!await dir.exists()) {
//     await dir.create(recursive: true);
//   }

//   return dir;
// }

// Future<void> saveCharacter(Character character) async {
//   //final dir = await getCharacterDirectory();

//   final file = File('${dir.path}/${character.characterName}.json');

//   await file.writeAsString(character.toFileContents());
// }

Future<List<FileSystemEntity>> loadCharacterFiles() async {
  //final dir = await getCharacterDirectory();

  //return dir.listSync().where((e) => e.path.endsWith('.json')).toList();
  return new List.empty();
}
