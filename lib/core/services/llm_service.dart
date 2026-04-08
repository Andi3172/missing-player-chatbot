import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LlmService {
  late final GenerativeModel _model;


  LlmService(){
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(model: 'gemini-3-flash', apiKey: apiKey);
  }

  //Helper
  Future<String> _loadMdFile(String path)async {
    try{
      return await rootBundle.loadString(path);

    } catch (e){
      return "Error loading $path: $e";
    }
  }


  // main logic for missing player
  Future<String> getCharacterResponse(String dmInput) async{
    final identity = await _loadMdFile('assets/agent/personality/identity.md');
    final sheet = await _loadMdFile('assets/agent/stats/sheet.md');
    final history = await _loadMdFile('assets/agent/lore/session_log.md');

    final prompt = """
      SYSTEM INSTRUCTIONS:
      You are a player character in a D&D game. You are filling in for a player who is away. 
      Stay in character at all times. Do not narrate for others. 
      Keep responses brief and conversational, as if spoken at a physical table.

      YOUR PERSONA:
      $identity

      YOUR ABILITIES:
      $sheet

      CAMPAIGN MEMORY:
      $history

      THE SITUATION:
      The DM just said: "$dmInput"

      How do you respond in character?
    """;

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);

    return response.text ?? "The character is just spacing out at this point....";
  }


}



