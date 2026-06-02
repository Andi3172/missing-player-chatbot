import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/logic/characterSaveManagement.dart';
import 'package:flutter_application_1/features/presentation/StartForm.dart';

class CharacterList extends StatefulWidget {
  const CharacterList({Key? key}) : super(key: key);

  @override
  State<CharacterList> createState() => _CharacterListState();
}

class _CharacterListState extends State<CharacterList> {
  final _formKey = GlobalKey<FormState>();
  List<FileSystemEntity> _savedCharacters = [];

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _refreshCharacterList();
  }

  Future<void> _refreshCharacterList() async {
    final files = await loadCharacterFiles();

    setState(() {
      _savedCharacters = files;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _savedCharacters.length,
      itemBuilder: (context, index) {
        final file = File(_savedCharacters[index].path);

        final name = file.path
            .split(Platform.pathSeparator)
            .last
            .replaceAll('.json', '');

        //return ListTile(title: Text(name), onTap: () => _loadCharacter(file));
      },
    );
  }
}
