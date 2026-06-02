import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/presentation/StartForm.dart';
import 'package:flutter_application_1/features/presentation/startLayout.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/persistence_manager.dart';
import 'core/logic/session_engine.dart'; // Added engine import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from the root-mapped asset
  await dotenv.load(fileName: ".env");
  await PersistenceManager.init();

  // ========================================================
  // 🔥 LIVE ENGINE TEST BLOCK
  // ========================================================
  print("\n⚔️  [LIVE TEST] Bootstrapping Engine & Syncing Lore...");
  try {
    final session = SessionEngine();
    await session.startCharacterSession();
    print(
      "🧠 [LIVE TEST] Lore & Character Sheet loaded into system instructions.",
    );
    print("🔌 [LIVE TEST] Connecting to Gemini API...");

    String testPrompt =
        "A heavy stone trap slams down on your path! You take 6 bludgeoning damage.";
    print("🎙️  [LIVE TEST] Sending DM Narration: '$testPrompt'");

    // Hits the live API
    String aiResponse = await session.handleNarrative(
      testPrompt,
      speaker: "DM",
    );

    print("\n🎭 [LIVE TEST] LIVE CHARACTER RESPONSE:");
    print(aiResponse);
    print("========================================================\n");
  } catch (e) {
    print("\n❌ [LIVE TEST] API OR LOGIC ERROR:");
    print(e);
    print("========================================================\n");
  }
  // ========================================================

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // Fixed: Added ColorScheme prefix
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const StartLayout(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          // Fixed: Added MainAxisAlignment prefix
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
