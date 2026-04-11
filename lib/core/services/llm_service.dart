import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LlmService {
  late final String _apiKey;

  LlmService() {
    _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  /// Creates a new chat session with a system instruction.
  ChatSession createChatSession({String? systemPrompt}) {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      systemInstruction: systemPrompt != null ? Content.system(systemPrompt) : null,
    );
    return model.startChat();
  }

  /// Sends a message to the AI with an optional system prompt.
  Future<String> chat(String message, {String? systemPrompt}) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      systemInstruction: systemPrompt != null ? Content.system(systemPrompt) : null,
    );

    final content = [Content.text(message)];
    try {
      final response = await model.generateContent(content);
      return response.text ?? "The character is spacing out...";
    } catch (e) {
      return "Error: $e";
    }
  }

  // legacy method for compatibility if needed, but updated for local persistence
  Future<String> getCharacterResponse(String dmInput, {String? systemPrompt}) async {
    return chat(dmInput, systemPrompt: systemPrompt);
  }
}




