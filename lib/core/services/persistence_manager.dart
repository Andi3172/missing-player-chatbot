import 'dart:io';
import 'package:flutter_application_1/features/logic/character.dart';
import 'file_service.dart';

class PersistenceManager {
  static final FileService _fileService = FileService();
  static const String _assetPrefix = 'assets/agent/';

  /// Initializes the local persistence layer by creating directories and bootstrapping default assets.
  static Future<void> init() async {
    final rootDir = Directory('${Directory.current.path}/Saved_Prompts');
    if (!rootDir.existsSync()) {
      rootDir.createSync(recursive: true);
      print('Created Saved_Prompts directory at startup.');
    }

    // Bootstrap default character Aladar if Aladar folder is missing
    final charDir = Directory('${rootDir.path}/characters');
    final defaultCharName = 'Aladar';
    final charSubDir = Directory('${charDir.path}/$defaultCharName');
    final jsonFile = File('${charSubDir.path}/$defaultCharName.json');
    final identityFile = File('${charSubDir.path}/identity.md');
    final sheetFile = File('${charSubDir.path}/sheet.md');
    final logFile = File('${charSubDir.path}/current_session.md');

    if (!charSubDir.existsSync() ||
        !jsonFile.existsSync() ||
        !identityFile.existsSync() ||
        !sheetFile.existsSync() ||
        !logFile.existsSync()) {
      final defaultJson = Character(
        characterName: defaultCharName,
        race: 'Elf',
        level: '5',
        characterClass: 'Rogue',
        mainAbilities: '| Strength | 10 | +0 |\n| Dexterity | 18 | +4 |\n| Constitution | 12 | +1 |\n| Intelligence | 14 | +2 |\n| Wisdom | 14 | +2 |\n| Charisma | 10 | +0 |',
        armor: 'Leather Armor (AC 15)',
        weapons: 'Rapier (+7 hit, 1d8+4 piercing), Shortbow (+7 hit, 1d6+4 piercing)',
        importantItems: 'Thieves\' tools, Potion of Healing (2), Rope 50ft',
        voiceMannerisms: 'Quiet, observational, whispering, slightly sarcastic.',
        personalityTraits: 'Cautious, loyal, resource-focused.',
        fearsFlaws: 'Afraid of deep water, greedy for lore.',
        relationshipWithParty: 'Enjoys the Paladin\'s protection but mocks their piety.',
        partyRole: 'Scout and lockpicker.',
        motivation: 'To find the hidden vault of the Sorcerer-King.',
        npcsKnown: 'Grom (blacksmith), Elora (librarian).',
      );

      if (!charSubDir.existsSync()) {
        charSubDir.createSync(recursive: true);
      }

      try {
        // Save character configuration JSON
        await jsonFile.writeAsString(defaultJson.toFileContents());

        // Copy default templates
        final identityContent = await _fileService.readAssetFile('${_assetPrefix}personality/identity.md');
        await _fileService.writeLocalFile('characters/$defaultCharName/identity.md', identityContent);

        final sheetContent = await _fileService.readAssetFile('${_assetPrefix}stats/sheet.md');
        await _fileService.writeLocalFile('characters/$defaultCharName/sheet.md', sheetContent);

        // Copy default campaign log template inside Aladar folder
        final logContent = await _fileService.readAssetFile('${_assetPrefix}lore/session_log.md');
        await _fileService.writeLocalFile('characters/$defaultCharName/current_session.md', logContent);

        print('Bootstrapped default character "$defaultCharName" with isolated identity, sheet, and log.');
      } catch (e) {
        print('Error bootstrapping default character Aladar: $e');
      }
    }
  }
}
