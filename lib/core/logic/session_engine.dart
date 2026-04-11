import 'package:flutter/foundation.dart'; // Added for ValueNotifier
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/campaign_manager.dart';
import '../services/llm_service.dart';
import '../services/file_service.dart';

class SessionEngine {
  final CampaignManager _campaignManager = CampaignManager();
  final LlmService _llmService = LlmService();
  final FileService _fileService = FileService();

  ChatSession? _chatSession;
  final List<String> _narrativeHistory = [];
  static const int _maxHistory = 5;
  static const int _wordLimit = 2000;

  /// Notifier to identify when the DM is asking for a check or roll.
  final ValueNotifier<String?> currentIntent = ValueNotifier<String?>(null);

  /// Starts a character session by building the system prompt and initializing Gemini.
  Future<void> startCharacterSession() async {
    final systemPrompt = await _campaignManager.buildFullSystemPrompt();
    
    // Initialize the Gemini chat with the entire lore in systemInstruction.
    _chatSession = _llmService.createChatSession(systemPrompt: systemPrompt);
    _narrativeHistory.clear();
  }

  /// Handles DM's narration, sends it to the model, and manages history.
  Future<String> handleNarrative(String bigPrompt, {String speaker = 'DM'}) async {
    if (_chatSession == null) {
      await startCharacterSession();
    }

    // Keep history limited to the last 5 'Big Prompts'
    final taggedPrompt = '[$speaker]: $bigPrompt';
    _narrativeHistory.add(taggedPrompt);
    if (_narrativeHistory.length > _maxHistory) {
      _narrativeHistory.removeAt(0);
    }

    // Append to local session_log.md for permanent storage with speaker tag
    await _campaignManager.appendToLog(taggedPrompt);

    // Trigger background intent analysis to detect if rolls are needed
    analyzeIntent(bigPrompt);

    // Trigger background state and condition update based on DM narration
    // We don't await this to keep it "background" and responsive
    _campaignManager.updateStateFromNarration(bigPrompt).catchError((e) {
      print('Background update failed: $e');
    });

    // Check for context overflow and summarize if necessary
    summarizeOldHistory().catchError((e) {
      print('Background summarization failed: $e');
    });

    try {
      final response = await _chatSession!.sendMessage(Content.text(bigPrompt));
      final responseText = response.text ?? "The character is spacing out...";
      
      // Also log the AI's response with speaker tag
      await _campaignManager.appendToLog('[Character]: $responseText');
      
      return responseText;
    } catch (e) {
      return "Error in narrative: $e";
    }
  }

  /// Analyzes DM narration for rolls, checks, or saving throws.
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
        
        // Reset intent after a short period (e.g., 60s) or until the next turn
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

  /// Optional: Get the current narrative history
  List<String> get narrativeHistory => List.unmodifiable(_narrativeHistory);

  /// Summarizes the oldest 70% of the log if it exceeds the word limit.
  Future<void> summarizeOldHistory() async {
    final log = await _fileService.readLocalFile('session_log.md');
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
        
        // Save the new summary
        await _fileService.writeLocalFile('summary.md', summaryResponse.trim());
        
        // Overwrite log with the remaining 30% to keep context window small
        await _fileService.writeLocalFile('session_log.md', remainingHistory.trim());
        
        print('Campaign history summarized and purged. Persistent core saved to summary.md');
      } catch (e) {
        print('Error during summarization: $e');
      }
    }
  }
}
