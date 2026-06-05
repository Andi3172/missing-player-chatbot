import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/logic/characterSaveManagement.dart';

class CharacterList extends StatefulWidget {
  final Set<File> selectedFiles;
  final Function(Set<File>) onSelectionChanged;
  final Function(File) onCharacterEdit;

  const CharacterList({
    Key? key,
    required this.selectedFiles,
    required this.onSelectionChanged,
    required this.onCharacterEdit,
  }) : super(key: key);

  @override
  State<CharacterList> createState() => CharacterListState();
}

class CharacterListState extends State<CharacterList> {
  List<FileSystemEntity> _savedCharacters = [];

  @override
  void initState() {
    super.initState();
    refreshCharacterList();
  }

  Future<void> refreshCharacterList() async {
    final files = await loadCharacterFiles();

    setState(() {
      _savedCharacters = files;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_savedCharacters.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No saved characters',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _savedCharacters.length,
      itemBuilder: (context, index) {
        final file = File(_savedCharacters[index].path);

        final name = file.path
            .split(Platform.pathSeparator)
            .last
            .replaceAll('.json', '');

        final isSelected = widget.selectedFiles.any((f) => f.path == file.path);

        return CheckboxListTile(
          title: Text(name),
          value: isSelected,
          onChanged: (bool? checked) {
            final updated = Set<File>.from(widget.selectedFiles);
            if (checked == true) {
              updated.add(file);
            } else {
              updated.removeWhere((f) => f.path == file.path);
            }
            widget.onSelectionChanged(updated);
          },
          secondary: IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => widget.onCharacterEdit(file),
            tooltip: 'Edit Details',
          ),
        );
      },
    );
  }
}
