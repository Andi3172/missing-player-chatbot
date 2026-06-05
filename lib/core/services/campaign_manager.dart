import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'file_service.dart';
import 'llm_service.dart';
import '../logic/session_engine.dart';

class CampaignManager {
  static final CampaignManager _instance = CampaignManager._internal();
  factory CampaignManager() => _instance;
  CampaignManager._internal();

  final FileService _fileService = FileService();
  final LlmService _llmService = LlmService();

  final Map<String, List<String>> _activeConditions = {};
  List<String> getActiveConditions(String name) => List.unmodifiable(_activeConditions[name] ?? []);

  // Broadcast controller to notify listeners of any state changes (sheet or log)
  final StreamController<void> _stateController = StreamController<void>.broadcast();

  /// Stream that emits whenever the campaign state (sheet or log) is updated.
  Stream<void> get onStateChanged => _stateController.stream;

  /// Helper to notify listeners of a change.
  void _notifyChange() => _stateController.add(null);

  /// Builds the character's system prompt by concatenating identity, stats, and its timeline.
  Future<String> buildCharacterSystemPrompt(String name) async {
    final identity = await _fileService.readLocalFile('characters/$name/identity.md').catchError((_) => '');
    final stats = await _fileService.readLocalFile('characters/$name/sheet.md').catchError((_) => '');
    final log = await _fileService.readLocalFile('characters/$name/current_session.md').catchError((_) => '');
    
    final conditions = _activeConditions[name] ?? [];

    // Read summary if it exists
    String summary = '';
    if (await _fileService.localFileExists('characters/$name/summary.md')) {
      summary = await _fileService.readLocalFile('characters/$name/summary.md');
    }

    return '''
## YOUR IDENTITY
$identity

## STATS
$stats

## ACTIVE CONDITIONS FOR $name
${conditions.isEmpty ? 'None' : conditions.join(', ')}

## SESSION HISTORY (TABLE TIMELINE)
${summary.isNotEmpty ? '### CAMPAIGN SUMMARY\n$summary\n\n### RECENT LOGS' : ''}
$log
''';
  }

  /// Appends a new entry to the session log files of all active characters.
  Future<void> appendToLog(String entry) async {
    final activeNames = SessionEngine().activeCharacterNames;
    final targets = activeNames.isEmpty ? ['Aladar'] : activeNames;
    for (final name in targets) {
      final path = 'characters/$name/current_session.md';
      final currentLog = await _fileService.readLocalFile(path).catchError((_) => '');
      final updatedLog = currentLog.isEmpty ? entry : '$currentLog\n\n$entry';
      await _fileService.writeLocalFile(path, updatedLog);
    }
    _notifyChange();
  }

  /// Exports the current campaign data (all characters and their session logs) to a JSON file.
  Future<void> exportCampaign() async {
    final Map<String, dynamic> campaignData = {};
    
    // Export all character files (including their session logs)
    final baseDir = Directory('${Directory.current.path}/Saved_Prompts/characters');
    final List<Map<String, String>> charDataList = [];
    if (baseDir.existsSync()) {
      for (var entity in baseDir.listSync()) {
        if (entity is Directory) {
          final name = entity.path.split(Platform.pathSeparator).last;
          final idPath = 'characters/$name/identity.md';
          final shPath = 'characters/$name/sheet.md';
          final logPath = 'characters/$name/current_session.md';
          final jsonPath = 'characters/$name/$name.json';

          final charMap = {'name': name};
          if (await _fileService.localFileExists(idPath)) {
            charMap['identity'] = await _fileService.readLocalFile(idPath);
          }
          if (await _fileService.localFileExists(shPath)) {
            charMap['sheet'] = await _fileService.readLocalFile(shPath);
          }
          if (await _fileService.localFileExists(logPath)) {
            charMap['current_session'] = await _fileService.readLocalFile(logPath);
          }
          if (await _fileService.localFileExists(jsonPath)) {
            charMap['json'] = await _fileService.readLocalFile(jsonPath);
          }
          charDataList.add(charMap);
        }
      }
    }
    campaignData['characters'] = charDataList;

    final jsonString = jsonEncode(campaignData);
    final fileName = 'campaign_export_${DateTime.now().millisecondsSinceEpoch}.json';

    String? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Select Save Location',
      fileName: fileName,
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsString(jsonString);
    }
  }

  /// Imports campaign data and restores character subdirectories and session logs.
  Future<void> importCampaign() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final Map<String, dynamic> campaignData = jsonDecode(content);

      if (campaignData.containsKey('characters')) {
        final List<dynamic> chars = campaignData['characters'];
        for (var char in chars) {
          final name = char['name'];
          if (name != null) {
            if (char.containsKey('identity')) {
              await _fileService.writeLocalFile('characters/$name/identity.md', char['identity']);
            }
            if (char.containsKey('sheet')) {
              await _fileService.writeLocalFile('characters/$name/sheet.md', char['sheet']);
            }
            if (char.containsKey('current_session')) {
              await _fileService.writeLocalFile('characters/$name/current_session.md', char['current_session']);
            }
            if (char.containsKey('json')) {
              await _fileService.writeLocalFile('characters/$name/$name.json', char['json']);
            }
          }
        }
      }
      _notifyChange();
    }
  }

  /// Updates the character's Markdown sheet based on DM narration.
  Future<void> updateCharacterStateFromNarration(String narration, String name) async {
    try {
      final stats = await _fileService.readLocalFile('characters/$name/sheet.md');
      final utilityPrompt = '''
Analyze this D&D narration: [$narration]. 
Current Markdown Sheet for $name:
$stats

Based on the narration, update the character's Markdown sheet (e.g., changes in health, items, status). 
Also, identify any NEW 'Conditions' or 'Status Effects' applied to this character (e.g., Blinded, Prone, Frightened).

If stats or items changed, return the ENTIRE updated Markdown sheet. 
If new conditions were applied, list them on a new line starting with "CONDITIONS: [comma separated list]".
If nothing changed, return "NO_CHANGE". 

Do not include any conversational text or explanation, only the Markdown, the CONDITIONS line, or "NO_CHANGE".
''';

      final response = await _llmService.chat(utilityPrompt);
      final trimmedResponse = response.trim();

      if (trimmedResponse != "NO_CHANGE" && trimmedResponse.isNotEmpty) {
        // Parse conditions if present
        final conditionMarker = 'CONDITIONS:';
        if (trimmedResponse.contains(conditionMarker)) {
          final lines = trimmedResponse.split('\n');
          final conditionLine = lines.firstWhere((l) => l.startsWith(conditionMarker));
          final conditionsText = conditionLine.replaceFirst(conditionMarker, '').trim();
          if (conditionsText.isNotEmpty) {
            final newConditions = conditionsText.split(',').map((e) => e.trim()).toList();
            final currentList = _activeConditions[name] ?? [];
            for (var c in newConditions) {
              if (!currentList.contains(c)) {
                currentList.add(c);
              }
            }
            _activeConditions[name] = currentList;
          }
        }

        // Simple heuristic to avoid overwriting with junk if AI hallucinated an error message
        if (trimmedResponse.contains('|') || trimmedResponse.contains('#')) {
          final sheetContent = trimmedResponse
              .split('\n')
              .where((l) => !l.startsWith(conditionMarker))
              .join('\n')
              .trim();

          if (sheetContent.isNotEmpty) {
            // Backup current sheet before overwriting
            await _fileService.writeLocalFile('characters/$name/sheet_old.md', stats);
            await _fileService.writeLocalFile('characters/$name/sheet.md', sheetContent);
          }
          _notifyChange();
          print('Character sheet and conditions updated automatically for $name.');
        } else if (trimmedResponse.contains(conditionMarker)) {
          _notifyChange();
        }
      }
    } catch (e) {
      print('Error during background state update for $name: $e');
    }
  }

  /// Restores the character sheet from the previous backup (sheet_old.md).
  Future<void> undoLastStatChange(String name) async {
    try {
      final oldPath = 'characters/$name/sheet_old.md';
      final curPath = 'characters/$name/sheet.md';
      if (await _fileService.localFileExists(oldPath)) {
        final oldStats = await _fileService.readLocalFile(oldPath);
        await _fileService.writeLocalFile(curPath, oldStats);
        _notifyChange();
        print('Rollback successful: Character sheet restored to previous state for $name.');
      } else {
        throw Exception('No rollback backup found for $name.');
      }
    } catch (e) {
      print('Rollback failed for $name: $e');
      rethrow;
    }
  }

  /// Parses the session log into a list of messages with speaker and text.
  Future<List<Map<String, String>>> getSessionMessages({String? characterName}) async {
    final name = characterName ?? (SessionEngine().activeCharacterNames.isNotEmpty 
        ? SessionEngine().activeCharacterNames.first 
        : 'Aladar');
    final path = 'characters/$name/current_session.md';
    if (!await _fileService.localFileExists(path)) {
      return [];
    }
    final logContent = await _fileService.readLocalFile(path);
    final List<Map<String, String>> messages = [];
    final lines = logContent.split('\n');

    String? currentSpeaker;
    StringBuffer currentText = StringBuffer();

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('[') && trimmed.contains(']:')) {
        if (currentSpeaker != null) {
          messages.add({
            'speaker': currentSpeaker,
            'text': currentText.toString().trim(),
          });
        }
        final index = trimmed.indexOf(']:');
        currentSpeaker = trimmed.substring(1, index);
        currentText = StringBuffer(trimmed.substring(index + 2).trim());
      } else {
        if (currentSpeaker != null) {
          if (trimmed.isNotEmpty) {
            currentText.write(currentText.isEmpty ? trimmed : '\n$trimmed');
          }
        }
      }
    }
    if (currentSpeaker != null) {
      messages.add({
        'speaker': currentSpeaker,
        'text': currentText.toString().trim(),
      });
    }
    return messages;
  }

  /// Updates the character files based on frontend values.
  Future<void> updateCharacterFiles(String name, {
    required String race,
    required String level,
    required String charClass,
    required String abilities,
    required String armor,
    required String weapons,
    required String items,
    required String voice,
    required String personality,
    required String fears,
    required String relationships,
    required String role,
    required String motivation,
    required String npcs,
  }) async {
    final identityContent = '''
# Character Identity

## Basic Information

### Name
$name

### Race
$race

### Class
$charClass

### Level
$level

---

## Speaking Style & Personality

### Voice & Mannerisms
$voice

### Personality Traits
$personality

### Fears & Flaws
$fears

---

## Party Bond

### Relationship to Party Members
$relationships

### Party Role & Motivation
$role
$motivation

---

## Known NPCs
$npcs

---

## Behavioral Directives

When responding in-character:
1. Maintain the speaking style and personality traits above
2. Reference party bonds when making decisions
3. Act consistently with your character's fears and flaws
4. Remain focused on supporting the party's goals while pursuing your own agenda
''';

    final sheetContent = '''
# Character Stats & Equipment

## Ability Scores
$abilities

---

## Combat Stats

### Hit Points
**Current HP:** 10 / 10

### Armor Class (AC)
$armor

---

## Current Equipment

### Weapons
$weapons

### Inventory Items
$items
''';

    await _fileService.writeLocalFile('characters/$name/identity.md', identityContent.trim());
    await _fileService.writeLocalFile('characters/$name/sheet.md', sheetContent.trim());
    _notifyChange();
  }

  /// Saves a snapshot of Aladar's sheet and logs.
  Future<String> saveSnapshot() async {
    final stats = await _fileService.readLocalFile('characters/Aladar/sheet.md');
    final log = await _fileService.readLocalFile('characters/Aladar/current_session.md');
    
    final logLines = log.trim().split('\n');
    final lastTenLines = logLines.length > 10 
        ? logLines.sublist(logLines.length - 10).join('\n') 
        : logLines.join('\n');

    final snapshotData = {
      'sheet': stats,
      'log_tail': lastTenLines,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return base64Encode(utf8.encode(jsonEncode(snapshotData)));
  }

  /// Loads a snapshot from a Base64 encoded JSON string.
  Future<void> loadSnapshot(String data) async {
    try {
      final decodedJson = utf8.decode(base64Decode(data));
      final Map<String, dynamic> snapshotData = jsonDecode(decodedJson);

      if (snapshotData.containsKey('sheet')) {
        await _fileService.writeLocalFile('characters/Aladar/sheet.md', snapshotData['sheet']);
      }
      if (snapshotData.containsKey('log_tail')) {
        await appendToLog('--- SNAPSHOT IMPORTED (${snapshotData['timestamp'] ?? 'unknown'}) ---\n${snapshotData['log_tail']}');
      }
      _notifyChange();
    } catch (e) {
      throw Exception('Failed to load snapshot: $e');
    }
  }
}
