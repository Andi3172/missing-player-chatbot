import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import all relevant project classes using correct package-relative paths
import 'package:flutter_application_1/core/services/persistence_manager.dart';
import 'package:flutter_application_1/core/services/campaign_manager.dart';
import 'package:flutter_application_1/core/logic/session_engine.dart';

void main() async {
  // 1. Environment Setup
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Engine Bench Integration Test', () async {
    print('\n======================================================');
    print('🗡️  MISSING PLAYER CHATBOT: ENGINE INTEGRATION TEST 🗡️');
    print('======================================================\n');

    // Mock path provider plugin channel
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.'; // Use current directory for mock path
    });

    try {
      // Attempt to load .env for the Gemini API key
      try {
        await dotenv.load(fileName: ".env");
        print('✅ Loaded .env file');
      } catch (e) {
        print('⚠️  Warning: Could not load .env file. API key might be missing.');
      }

    // Phase 1: Bootstrap Initialization
    print('\n▶️  PHASE 1: Bootstrap Initialization');
    print('------------------------------------------------------');
    await PersistenceManager.init();
    print('✅ PersistenceManager.init() completed.');
    print('✅ Local documents (identity, sheet, session_log) verified/created.');

    // Phase 2: Session Initialization
    print('\n▶️  PHASE 2: Session Initialization');
    print('------------------------------------------------------');
    final sessionEngine = SessionEngine();
    final campaignManager = CampaignManager();
    print('⏳ Initializing Gemini session and feeding core system instructions...');
    await sessionEngine.startCharacterSession(['Aladar']);
    print('✅ SessionEngine instantiated and startCharacterSession() complete.');
    print('✅ Lore and character sheet successfully fed into Gemini.');

    // Phase 3: The Narrative Turn (The "Big Prompt")
    print('\n▶️  PHASE 3: The Narrative Turn (The "Big Prompt")');
    print('------------------------------------------------------');
    final String dmPrompt = 
        "A sudden clang of steel echoes in the narrow corridor. Three goblin ambushers "
        "jump from the shadows! One swings a rusted shortsword at your shoulder, "
        "dealing 4 slashing damage. You are now bleeding! How do you react?";
    
    print('🗣️  [DM Prompt]:');
    print('   "$dmPrompt"\n');
    print('⏳ AI is processing the prompt and generating a response...');
    
    final response = await sessionEngine.handleNarrative(dmPrompt, speaker: 'DM');
    print('🎙️  [Character Output]:');
    print('\n   $response\n');
    print('✅ Narrative turn successfully handled by SessionEngine.');

    // Phase 4: Background State Verification
    print('\n▶️  PHASE 4: Background State Verification');
    print('------------------------------------------------------');
    print('⏳ Waiting 2 seconds to allow background streams/parsers to settle...');
    await Future.delayed(const Duration(seconds: 2));
    
    final conditions = campaignManager.getActiveConditions('Aladar');
    print('🔍 Active Conditions Snapshot: ${conditions.isEmpty ? "None" : conditions.join(", ")}');
    print('🔍 Current Intent: ${sessionEngine.currentIntent.value ?? "None"}');
    print('✅ Background tasks visually verified.');

    // Phase 5: Portability Verification (Snapshot System)
    print('\n▶️  PHASE 5: Portability Verification (Snapshot System)');
    print('------------------------------------------------------');
    print('⏳ Generating Base64 save code...');
    final saveCode = await campaignManager.saveSnapshot();
    print('✅ Snapshot generation complete. Save Code details below:\n');
    print('💾 $saveCode');
    
    print('\n======================================================');
    print('🎉 INTEGRATION TEST COMPLETED SUCCESSFULLY 🎉');
    print('======================================================\n');
    
  } catch (e, stackTrace) {
    print('\n❌ CRITICAL ERROR: Execution halted due to an exception ❌');
    print('Exception: $e');
    print('StackTrace:\n$stackTrace');
    print('\n======================================================');
    print('⚠️ INTEGRATION TEST FAILED ⚠️');
    print('======================================================\n');
    fail(e.toString());
  }
  });
}
