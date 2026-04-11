import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'file_service.dart';
import 'llm_service.dart';

class CampaignManager {
  final FileService _fileService = FileService();
  final LlmService _llmService = LlmService();

  final List<String> _activeConditions = [];
  List<String> get activeConditions => List.unmodifiable(_activeConditions);

  // Broadcast controller to notify listeners of any state changes (sheet or log)
  final StreamController<void> _stateController = StreamController<void>.broadcast();

  /// Stream that emits whenever the campaign state (sheet or log) is updated.
  Stream<void> get onStateChanged => _stateController.stream;

  /// Helper to notify listeners of a change.
  void _notifyChange() => _stateController.add(null);

  /// Builds the full system prompt by concatenating identity, stats, and session history.
  Future<String> buildFullSystemPrompt() async {
    final identity = await _fileService.readLocalFile('identity.md');
    final stats = await _fileService.readLocalFile('sheet.md');
    final log = await _fileService.readLocalFile('session_log.md');
    
    // Read summary if it exists
    String summary = '';
    if (await _fileService.localFileExists('summary.md')) {
      summary = await _fileService.readLocalFile('summary.md');
    }

    return '''
## YOUR IDENTITY
$identity

## STATS
$stats

## ACTIVE CONDITIONS
${_activeConditions.isEmpty ? 'None' : _activeConditions.join(', ')}

## SESSION HISTORY
${summary.isNotEmpty ? '### CAMPAIGN SUMMARY\n$summary\n\n### RECENT LOGS' : ''}
$log
''';
  }

  /// Appends a new entry to the session log.
  Future<void> appendToLog(String entry) async {
    final currentLog = await _fileService.readLocalFile('session_log.md');
    final updatedLog = '$currentLog\n\n$entry';
    await _fileService.writeLocalFile('session_log.md', updatedLog);
    _notifyChange();
  }

  /// Exports the current campaign data to a JSON file.
  Future<void> exportCampaign() async {
    final identity = await _fileService.readLocalFile('identity.md');
    final stats = await _fileService.readLocalFile('sheet.md');
    final log = await _fileService.readLocalFile('session_log.md');

    final campaignData = {
      'identity': identity,
      'sheet': stats,
      'log': log,
    };

    final jsonString = jsonEncode(campaignData);
    final fileName = 'campaign_export_${DateTime.now().millisecondsSinceEpoch}.json';

    // Use FilePicker.platform to save file
    String? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Select Save Location',
      fileName: fileName,
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsString(jsonString);
    }
  }

  /// Imports campaign data from a JSON file and overwrites the local .md files.
  Future<void> importCampaign() async {
    // Using pickFiles from FilePicker
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final Map<String, dynamic> campaignData = jsonDecode(content);

      if (campaignData.containsKey('identity')) {
        await _fileService.writeLocalFile('identity.md', campaignData['identity']);
      }
      if (campaignData.containsKey('sheet')) {
        await _fileService.writeLocalFile('sheet.md', campaignData['sheet']);
      }
      if (campaignData.containsKey('log')) {
        await _fileService.writeLocalFile('session_log.md', campaignData['log']);
      }
      _notifyChange();
    }
  }

  /// Updates the character's Markdown sheet based on DM narration.
  Future<void> updateStateFromNarration(String narration) async {
    try {
      final stats = await _fileService.readLocalFile('sheet.md');
      final utilityPrompt = '''
Analyze this D&D narration: [$narration]. 
Current Markdown Sheet:
$stats

Based on the narration, update the character's Markdown sheet (e.g., changes in health, items, status). 
Also, identify any NEW 'Conditions' or 'Status Effects' applied to the character (e.g., Blinded, Prone, Frightened).

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
            for (var c in newConditions) {
              if (!_activeConditions.contains(c)) {
                _activeConditions.add(c);
              }
            }
          }
        }

        // Simple heuristic to avoid overwriting with junk if AI hallucinated an error message
        if (trimmedResponse.contains('|') || trimmedResponse.contains('#')) {
          // Clean the response of the conditions line if it was part of the output
          final sheetContent = trimmedResponse
              .split('\n')
              .where((l) => !l.startsWith(conditionMarker))
              .join('\n')
              .trim();

          if (sheetContent.isNotEmpty) {
            // Backup current sheet before overwriting
            await _fileService.writeLocalFile('sheet_old.md', stats);
            await _fileService.writeLocalFile('sheet.md', sheetContent);
          }
          _notifyChange();
          print('Character sheet and conditions updated automatically.');
        } else if (trimmedResponse.contains(conditionMarker)) {
          // Only conditions were updated
          _notifyChange();
        }
      }
    } catch (e) {
      print('Error during background state update: $e');
    }
  }

  /// Saves a snapshot of the current state of sheet.md and the last 10 lines of session_log.md.
  Future<String> saveSnapshot() async {
    final stats = await _fileService.readLocalFile('sheet.md');
    final log = await _fileService.readLocalFile('session_log.md');
    
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
        await _fileService.writeLocalFile('sheet.md', snapshotData['sheet']);
      }
      if (snapshotData.containsKey('log_tail')) {
        // We append the tail as a "New Session Start" marker to maintain continuity
        await appendToLog('--- SNAPSHOT IMPORTED (${snapshotData['timestamp'] ?? 'unknown'}) ---\n${snapshotData['log_tail']}');
      }
      _notifyChange();
    } catch (e) {
      throw Exception('Failed to load snapshot: $e');
    }
  }

  /// Restores the character sheet from the previous backup (sheet_old.md).
  Future<void> undoLastStatChange() async {
    try {
      if (await _fileService.localFileExists('sheet_old.md')) {
        final oldStats = await _fileService.readLocalFile('sheet_old.md');
        await _fileService.writeLocalFile('sheet.md', oldStats);
        _notifyChange();
        print('Rollback successful: Character sheet restored to previous state.');
      } else {
        throw Exception('No rollback backup found.');
      }
    } catch (e) {
      print('Rollback failed: $e');
      rethrow;
    }
  }
}

