import 'dart:io';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/logic/session_engine.dart';
import 'package:flutter_application_1/features/presentation/StartLayout.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  String _currentSpeaker = 'DM';
  late StreamSubscription<void> _stateSubscription;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _stateSubscription = SessionEngine().onStateChanged.listen((_) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    _stateSubscription.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final msgs = await SessionEngine().getSessionMessages();
    if (mounted) {
      setState(() {
        _messages = msgs;
      });
      // Scroll to the bottom of the list
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _isLoading = true;
    });

    try {
      await SessionEngine().handleNarrative(text, speaker: _currentSpeaker);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("⚔️ Campaign Chat"),
        backgroundColor: Colors.deepPurple.shade900,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StartLayout()),
            );
          },
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: 'Open Dashboard',
            ),
          ),
        ],
      ),
      endDrawer: const CharacterSheetDrawer(),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.casino, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          "The campaign log is empty.\nType DM narration to begin the journey!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return ChatBubble(
                        speaker: msg['speaker'] ?? 'Unknown',
                        text: msg['text'] ?? '',
                      );
                    },
                  ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Active characters are responding...",
                      style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          
          // Contextual Roll Action Button Panel via ValueListenableBuilder
          ValueListenableBuilder<String?>(
            valueListenable: SessionEngine().currentIntent,
            builder: (context, intent, child) {
              if (intent == null || intent.isEmpty || intent == 'NONE') {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.casino, color: Colors.amber),
                        label: Text('Roll for $intent'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade900,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () async {
                          final roll = Random().nextInt(20) + 1;
                          final rollMsg = "I roll for $intent and get a $roll.";
                          SessionEngine().currentIntent.value = null; // Clear intent
                          setState(() {
                            _isLoading = true;
                          });
                          try {
                            await SessionEngine().handleNarrative(rollMsg, speaker: 'Player');
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Roll failed: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          SessionEngine().currentIntent.value = null;
                        },
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Speaker selection toggle chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('🎙️ DM (Narration)'),
                  selected: _currentSpeaker == 'DM',
                  selectedColor: Colors.deepPurple.shade100,
                  onSelected: (selected) {
                    if (selected) setState(() => _currentSpeaker = 'DM');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('👤 Player (Action/Dialog)'),
                  selected: _currentSpeaker == 'Player',
                  selectedColor: Colors.deepPurple.shade100,
                  onSelected: (selected) {
                    if (selected) setState(() => _currentSpeaker = 'Player');
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: _currentSpeaker == 'DM'
                          ? "Enter DM narrative description..."
                          : "Enter what you do or say...",
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade900,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String speaker;
  final String text;

  const ChatBubble({Key? key, required this.speaker, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDM = speaker == 'DM';
    final isPlayer = speaker == 'Player';

    Color bubbleColor;
    Alignment alignment;
    EdgeInsets margin;
    BorderRadius borderRadius;

    if (isPlayer) {
      bubbleColor = Colors.deepPurple;
      alignment = Alignment.centerRight;
      margin = const EdgeInsets.only(left: 60, right: 8, top: 4, bottom: 4);
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      );
    } else if (isDM) {
      bubbleColor = Colors.grey.shade100;
      alignment = Alignment.center;
      margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      borderRadius = BorderRadius.circular(12);
    } else {
      bubbleColor = Colors.amber.shade100;
      alignment = Alignment.centerLeft;
      margin = const EdgeInsets.only(left: 8, right: 60, top: 4, bottom: 4);
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomRight: Radius.circular(16),
      );
    }

    return Align(
      alignment: alignment,
      child: Container(
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
          border: isDM ? Border.all(color: Colors.grey.shade300) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isPlayer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              speaker,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isPlayer ? Colors.white70 : (isDM ? Colors.black54 : Colors.amber.shade900),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                color: isPlayer ? Colors.white : Colors.black87,
                fontSize: 15,
                fontStyle: isDM ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CharacterSheetDrawer extends StatefulWidget {
  const CharacterSheetDrawer({Key? key}) : super(key: key);

  @override
  State<CharacterSheetDrawer> createState() => _CharacterSheetDrawerState();
}

class _CharacterSheetDrawerState extends State<CharacterSheetDrawer> {
  String _sheetContent = 'Loading character sheet...';
  List<String> _conditions = [];
  late StreamSubscription<void> _sub;
  String? _selectedCharacterName;

  @override
  void initState() {
    super.initState();
    final names = SessionEngine().activeCharacterNames;
    if (names.isNotEmpty) {
      _selectedCharacterName = names.first;
    }
    _loadSheetData();
    _sub = SessionEngine().onStateChanged.listen((_) {
      _loadSheetData();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Future<void> _loadSheetData() async {
    if (_selectedCharacterName == null) {
      if (mounted) {
        setState(() {
          _sheetContent = 'No active character selected.';
          _conditions = [];
        });
      }
      return;
    }
    try {
      final sheet = await SessionEngine().getCharacterSheet(_selectedCharacterName!);
      if (mounted) {
        setState(() {
          _sheetContent = sheet;
          _conditions = SessionEngine().getActiveConditions(_selectedCharacterName!);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sheetContent = 'Error loading character sheet: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final names = SessionEngine().activeCharacterNames;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.deepPurple.shade900,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📜 Campaign Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Character Stats & Actions',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  if (names.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCharacterName,
                          dropdownColor: Colors.deepPurple.shade900,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          items: names.map((name) => DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          )).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCharacterName = val;
                            });
                            _loadSheetData();
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_selectedCharacterName != null) ...[
                    Text(
                      'Active Status Effects / Conditions: $_selectedCharacterName',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    _conditions.isEmpty
                        ? const Text('None (Healthy)', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                        : Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _conditions
                                .map((c) => Chip(
                                      label: Text(c),
                                      backgroundColor: Colors.amber.shade100,
                                      labelStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                    ))
                                .toList(),
                          ),
                    const Divider(height: 32),
                    Text(
                      'Character Stats & Equipment: $_selectedCharacterName',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SelectableText(
                        _sheetContent,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                    const Divider(height: 32),
                  ],
                  const Text(
                    'Campaign Actions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedCharacterName != null) ...[
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await SessionEngine().undoLastStatChange(_selectedCharacterName!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Stat rollback successful for $_selectedCharacterName.')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Rollback failed: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.undo),
                      label: Text('Undo Last Stat Change ($_selectedCharacterName)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await SessionEngine().exportCampaign();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Campaign exported successfully!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Export failed: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Export Campaign'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await SessionEngine().importCampaign();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Campaign imported successfully!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Import failed: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.file_download),
                    label: const Text('Import Campaign'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
