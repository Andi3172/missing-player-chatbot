import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/logic/character.dart';
import 'package:flutter_application_1/features/logic/characterSaveManagement.dart';
import 'package:flutter_application_1/features/presentation/aiChatPage.dart';

class StartForm extends StatefulWidget {
  const StartForm({Key? key}) : super(key: key);

  @override
  State<StartForm> createState() => _StartFormState();
}

class _StartFormState extends State<StartForm> {
  final _formKey = GlobalKey<FormState>();

  final _characterNameController = TextEditingController();
  final _raceController = TextEditingController();
  final _levelController = TextEditingController();
  final _classController = TextEditingController();
  final _mainAbilitiesController = TextEditingController();
  final _armorController = TextEditingController();
  final _weaponsController = TextEditingController();
  final _importantItemsController = TextEditingController();
  final _voiceMannerismsController = TextEditingController();
  final _personalityTraitsController = TextEditingController();
  final _fearsFlawsController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _partyRoleController = TextEditingController();
  final _motivationController = TextEditingController();
  final _knownNpcsController = TextEditingController();

  Future<void> _loadCharacter(File file) async {
    final text = await file.readAsString();

    final character = Character.fromFileContents(text);

    setState(() {
      _characterNameController.text = character.characterName;

      _raceController.text = character.race;

      _levelController.text = character.level;

      _classController.text = character.characterClass;

      _mainAbilitiesController.text = character.mainAbilities;

      _armorController.text = character.armor;

      _weaponsController.text = character.weapons;

      _importantItemsController.text = character.importantItems;

      _voiceMannerismsController.text = character.voiceMannerisms;

      _personalityTraitsController.text = character.personalityTraits;

      _fearsFlawsController.text = character.fearsFlaws;

      _relationshipController.text = character.relationshipWithParty;

      _partyRoleController.text = character.partyRole;

      _motivationController.text = character.motivation;

      _knownNpcsController.text = character.npcsKnown;
    });
  }

  Character _buildCharacter() {
    return Character(
      characterName: _characterNameController.text,
      race: _raceController.text,
      level: _levelController.text,
      characterClass: _classController.text,
      mainAbilities: _mainAbilitiesController.text,
      armor: _armorController.text,
      weapons: _weaponsController.text,
      importantItems: _importantItemsController.text,
      voiceMannerisms: _voiceMannerismsController.text,
      personalityTraits: _personalityTraitsController.text,
      fearsFlaws: _fearsFlawsController.text,
      relationshipWithParty: _relationshipController.text,
      partyRole: _partyRoleController.text,
      motivation: _motivationController.text,
      npcsKnown: _knownNpcsController.text,
    );
  }

  @override
  void dispose() {
    _characterNameController.dispose();
    _raceController.dispose();
    _levelController.dispose();
    _classController.dispose();
    _mainAbilitiesController.dispose();
    _armorController.dispose();
    _weaponsController.dispose();
    _importantItemsController.dispose();
    _voiceMannerismsController.dispose();
    _personalityTraitsController.dispose();
    _fearsFlawsController.dispose();
    _relationshipController.dispose();
    _partyRoleController.dispose();
    _motivationController.dispose();
    _knownNpcsController.dispose();

    super.dispose();
  }

  Widget _buildField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text('Character Creation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildField(_characterNameController, 'Character Name'),
              _buildField(_raceController, 'Race'),
              _buildField(_levelController, 'Level'),
              _buildField(_classController, 'Class'),
              _buildField(_mainAbilitiesController, 'Main Abilities'),
              _buildField(_armorController, 'Armor'),
              _buildField(_weaponsController, 'Weapons'),
              _buildField(_importantItemsController, 'Important Items'),
              _buildField(_voiceMannerismsController, 'Voice & Mannerisms'),
              _buildField(_personalityTraitsController, 'Personality Traits'),
              _buildField(_fearsFlawsController, 'Fears & Flaws'),
              _buildField(
                _relationshipController,
                'Relationship with Party Members',
              ),
              _buildField(_partyRoleController, 'Party Role'),
              _buildField(_motivationController, 'Motivation'),
              _buildField(_knownNpcsController, 'NPCs Known'),

              const SizedBox(height: 8),

              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      //await saveCharacter(_buildCharacter());

                      //await _refreshCharacterList();
                    },
                    child: const Text('Save'),
                  ),

                  const SizedBox(width: 16),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const AiChatPage()),
                      );
                    },
                    child: const Text('Use'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
