import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/presentation/CharacterList.dart';
import 'package:flutter_application_1/features/presentation/StartForm.dart';
import 'package:flutter_application_1/features/logic/character.dart';
import 'package:flutter_application_1/features/logic/characterSaveManagement.dart';
import 'package:flutter_application_1/core/services/persistence_manager.dart';
import 'package:flutter_application_1/core/logic/session_engine.dart';
import 'package:flutter_application_1/features/presentation/AiChatPage.dart';

class StartLayout extends StatefulWidget {
  const StartLayout({Key? key}) : super(key: key);

  @override
  State<StartLayout> createState() => _StartLayoutState();
}

class _StartLayoutState extends State<StartLayout> {
  final GlobalKey<StartFormState> _startFormKey = GlobalKey<StartFormState>();
  final GlobalKey<CharacterListState> _characterListKey = GlobalKey<CharacterListState>();
  final Set<File> _selectedCharacters = {};

  Future<void> _initializeMultiSession(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await PersistenceManager.init();

      final List<String> activeNames = [];

      if (_selectedCharacters.isEmpty) {
        // Use the character currently in the form!
        final formChar = _startFormKey.currentState?.buildCharacter();
        if (formChar == null || formChar.characterName.trim().isEmpty) {
          throw Exception('No characters selected and form name is empty.');
        }
        final name = formChar.characterName.trim();
        // Save form character first to ensure directory exists
        await saveCharacter(formChar);
        // Update its files
        await SessionEngine().updateCharacter(
          name,
          race: formChar.race,
          level: formChar.level,
          charClass: formChar.characterClass,
          abilities: formChar.mainAbilities,
          armor: formChar.armor,
          weapons: formChar.weapons,
          items: formChar.importantItems,
          voice: formChar.voiceMannerisms,
          personality: formChar.personalityTraits,
          fears: formChar.fearsFlaws,
          relationships: formChar.relationshipWithParty,
          role: formChar.partyRole,
          motivation: formChar.motivation,
          npcs: formChar.npcsKnown,
        );
        activeNames.add(name);
      } else {
        // Load the names of all selected characters
        for (final file in _selectedCharacters) {
          final content = await file.readAsString();
          final char = Character.fromFileContents(content);
          activeNames.add(char.characterName);
        }
      }

      // Initialize the session engine for these characters
      await SessionEngine().startCharacterSession(activeNames);

      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AiChatPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Initialization failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚔️ Character Setup & Campaign Sync'),
        backgroundColor: Colors.deepPurple.shade900,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          SizedBox(
            width: 320, 
            child: CharacterList(
              key: _characterListKey,
              selectedFiles: _selectedCharacters,
              onSelectionChanged: (files) {
                setState(() {
                  _selectedCharacters.clear();
                  _selectedCharacters.addAll(files);
                });
              },
              onCharacterEdit: (file) {
                _startFormKey.currentState?.loadCharacter(file);
              },
            ),
          ),

          const VerticalDivider(width: 1),

          Expanded(
            child: StartForm(
              key: _startFormKey,
              selectedCharactersCount: _selectedCharacters.length,
              onCharacterSaved: () {
                _characterListKey.currentState?.refreshCharacterList();
              },
              onUseSelected: () => _initializeMultiSession(context),
            ),
          ),
        ],
      ),
    );
  }
}
