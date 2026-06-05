import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/campaign_manager.dart';
import '../services/llm_service.dart';
import '../services/file_service.dart';

class SessionEngine {
  static final SessionEngine _instance = SessionEngine._internal();
  factory SessionEngine() => _instance;
  SessionEngine._internal();

  final CampaignManager _campaignManager = CampaignManager();
  final LlmService _llmService = LlmService();
  final FileService _fileService = FileService();

  final List<String> _activeCharacterNames = [];
  List<String> get activeCharacterNames => List.unmodifiable(_activeCharacterNames);

  final Map<String, ChatSession> _chatSessions = {};
  static const int _wordLimit = 2000;

  /// Notifier to identify when the DM is asking for a check or roll.
  final ValueNotifier<String?> currentIntent = ValueNotifier<String?>(null);

  /// Starts multi-character sessions by compiling prompts and initializing Gemini instances.
  Future<void> startCharacterSession(List<String> characterNames) async {
    _activeCharacterNames.clear();
    _activeCharacterNames.addAll(characterNames);
    _chatSessions.clear();

    for (final name in characterNames) {
      final systemPrompt = await _campaignManager.buildCharacterSystemPrompt(name);
      final session = _llmService.createChatSession(systemPrompt: systemPrompt);
      _chatSessions[name] = session;
    }
  }

  /// Handles DM narration, sequential character prompts, and log writes.
  Future<String> handleNarrative(String bigPrompt, {String speaker = 'DM'}) async {
    if (_activeCharacterNames.isEmpty) {
      return "No active characters selected.";
    }

    // Append DM/Player input once to the shared campaign log
    final taggedPrompt = '[$speaker]: $bigPrompt';
    await _campaignManager.appendToLog(taggedPrompt);

    // Trigger intent analysis once
    analyzeIntent(bigPrompt);

    final List<String> characterResponses = [];

    // Prompt each character sequentially
    for (final name in _activeCharacterNames) {
      // Background stat extraction for this specific character
      _campaignManager.updateCharacterStateFromNarration(bigPrompt, name).catchError((e) {
        print('Background state update failed for $name: $e');
      });

      // Background logs summarization if context limits are exceeded
      summarizeOldHistory(name).catchError((e) {
        print('Background summarization failed for $name: $e');
      });

      try {
        // Build updated prompt with latest stats and session history
        final systemPrompt = await _campaignManager.buildCharacterSystemPrompt(name);
        final session = _llmService.createChatSession(systemPrompt: systemPrompt);
        _chatSessions[name] = session; // update cache

        final response = await session.sendMessage(Content.text(bigPrompt));
        final responseText = response.text ?? "spaces out...";

        // Append this character's dialogue to the shared session log
        final taggedResponse = '[$name]: $responseText';
        await _campaignManager.appendToLog(taggedResponse);

        characterResponses.add('$name: $responseText');
      } catch (e) {
        final errorResponse = '[$name]: Error: $e';
        await _campaignManager.appendToLog(errorResponse);
        characterResponses.add('$name: Error getting response: $e');
      }
    }

    return characterResponses.join('\n\n');
  }

  /// Analyzes narration for roll/check intents.
  Future<void> analyzeIntent(String narration) async {
    final intentPrompt = '''
Analyze this D&D narration. Is a roll or specific action required from the character? 
(e.g., Initiative, Perception check, Saving throw, Attack roll).

If yes, return ONLY the type of check/roll. 
If no, return "NONE".

Narration:
$narration
''';

    try {
      final response = await _llmService.chat(intentPrompt);
      final trimmed = response.trim().toUpperCase();
      
      if (trimmed != 'NONE' && trimmed.isNotEmpty) {
        currentIntent.value = trimmed;
        print('Detected Character Intent: $trimmed');
        
        Future.delayed(const Duration(minutes: 1), () {
          if (currentIntent.value == trimmed) currentIntent.value = null;
        });
      } else {
        currentIntent.value = null;
      }
    } catch (e) {
      print('Error during intent analysis: $e');
    }
  }

  /// Summarizes character history if memory threshold is reached.
  Future<void> summarizeOldHistory(String name) async {
    final log = await _fileService.readLocalFile('characters/$name/current_session.md').catchError((_) => '');
    final words = log.split(RegExp(r'\s+'));

    if (words.length > _wordLimit) {
      final splitIndex = (words.length * 0.7).toInt();
      final oldHistory = words.sublist(0, splitIndex).join(' ');
      final remainingHistory = words.sublist(splitIndex).join(' ');

      final summaryPrompt = '''
Summarize the events of this D&D campaign so far into a 3-paragraph executive summary. 
The input contains text wrapped in speaker tags like [DM], [Character], or [Player]. 
Ensure the summary accurately reflects WHO performed which actions.

Events to summarize:
$oldHistory
''';

      try {
        final summaryResponse = await _llmService.chat(summaryPrompt);
        
        await _fileService.writeLocalFile('characters/$name/summary.md', summaryResponse.trim());
        await _fileService.writeLocalFile('characters/$name/current_session.md', remainingHistory.trim());
        print('Campaign history summarized for $name.');
      } catch (e) {
        print('Error during summarization for $name: $e');
      }
    }
  }

  Stream<void> get onStateChanged => _campaignManager.onStateChanged;
  List<String> getActiveConditions(String name) => _campaignManager.getActiveConditions(name);

  Future<List<Map<String, String>>> getSessionMessages() => _campaignManager.getSessionMessages();
  Future<String> getCharacterSheet(String name) => _fileService.readLocalFile('characters/$name/sheet.md');

  Future<void> undoLastStatChange(String name) => _campaignManager.undoLastStatChange(name);
  Future<void> exportCampaign() => _campaignManager.exportCampaign();
  Future<void> importCampaign() => _campaignManager.importCampaign();

  Future<void> updateCharacter(
    String name, {
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
  }) => _campaignManager.updateCharacterFiles(
    name,
    race: race,
    level: level,
    charClass: charClass,
    abilities: abilities,
    armor: armor,
    weapons: weapons,
    items: items,
    voice: voice,
    personality: personality,
    fears: fears,
    relationships: relationships,
    role: role,
    motivation: motivation,
    npcs: npcs,
  );
}
