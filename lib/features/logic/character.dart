import 'dart:convert';

class Character {
  final String characterName;
  final String race;
  final String level;
  final String characterClass;
  final String mainAbilities;
  final String armor;
  final String weapons;
  final String importantItems;
  final String voiceMannerisms;
  final String personalityTraits;
  final String fearsFlaws;
  final String relationshipWithParty;
  final String partyRole;
  final String motivation;
  final String npcsKnown;

  Character({
    required this.characterName,
    required this.race,
    required this.level,
    required this.characterClass,
    required this.mainAbilities,
    required this.armor,
    required this.weapons,
    required this.importantItems,
    required this.voiceMannerisms,
    required this.personalityTraits,
    required this.fearsFlaws,
    required this.relationshipWithParty,
    required this.partyRole,
    required this.motivation,
    required this.npcsKnown,
  });

  Map<String, dynamic> toJson() => {
    'characterName': characterName,
    'race': race,
    'level': level,
    'characterClass': characterClass,
    'mainAbilities': mainAbilities,
    'armor': armor,
    'weapons': weapons,
    'importantItems': importantItems,
    'voiceMannerisms': voiceMannerisms,
    'personalityTraits': personalityTraits,
    'fearsFlaws': fearsFlaws,
    'relationshipWithParty': relationshipWithParty,
    'partyRole': partyRole,
    'motivation': motivation,
    'npcsKnown': npcsKnown,
  };

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      characterName: json['characterName'] ?? '',
      race: json['race'] ?? '',
      level: json['level'] ?? '',
      characterClass: json['characterClass'] ?? '',
      mainAbilities: json['mainAbilities'] ?? '',
      armor: json['armor'] ?? '',
      weapons: json['weapons'] ?? '',
      importantItems: json['importantItems'] ?? '',
      voiceMannerisms: json['voiceMannerisms'] ?? '',
      personalityTraits: json['personalityTraits'] ?? '',
      fearsFlaws: json['fearsFlaws'] ?? '',
      relationshipWithParty: json['relationshipWithParty'] ?? '',
      partyRole: json['partyRole'] ?? '',
      motivation: json['motivation'] ?? '',
      npcsKnown: json['npcsKnown'] ?? '',
    );
  }

  String toFileContents() => jsonEncode(toJson());

  static Character fromFileContents(String text) =>
      Character.fromJson(jsonDecode(text));
}
