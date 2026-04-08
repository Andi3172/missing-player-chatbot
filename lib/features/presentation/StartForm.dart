import 'package:flutter/material.dart';

class StartForm extends StatefulWidget {
  const StartForm({Key? key}) : super(key: key);

  @override
  State<StartForm> createState() => _StartFormState();
}

class _StartFormState extends State<StartForm> {
  final _formKey = GlobalKey<FormState>();
  final _personalityController = TextEditingController();
  final _featuresController = TextEditingController();
  final _backstoryController = TextEditingController();

  @override
  void dispose() {
    _personalityController.dispose();
    _featuresController.dispose();
    _backstoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start Form')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _personalityController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(labelText: 'Placeholder 1'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _featuresController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(labelText: 'Placeholder 2'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _backstoryController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(labelText: 'Placeholder 3'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () {}, child: const Text('Submit')),
            ],
          ),
        ),
      ),
    );
  }
}
