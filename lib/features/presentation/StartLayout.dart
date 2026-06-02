import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/presentation/CharacterList.dart';
import 'package:flutter_application_1/features/presentation/StartForm.dart';

class StartLayout extends StatefulWidget {
  const StartLayout({Key? key}) : super(key: key);

  @override
  State<StartLayout> createState() => _StartLayoutState();
}

class _StartLayoutState extends State<StartLayout> {
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(width: 250, child: CharacterList()),

          const VerticalDivider(width: 1),

          Expanded(child: StartForm()),
        ],
      ),
    );
  }
}
