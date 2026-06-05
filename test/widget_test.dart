import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Start layout smoke test', (WidgetTester tester) async {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });

    FlutterError.onError = (FlutterErrorDetails details) {
      print('FLUTTER ERROR IN TEST: ${details.exception}');
    };

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Print all text widgets found in the tree
    for (final widget in tester.allWidgets) {
      if (widget is Text) {
        print('Found text widget: "${widget.data}"');
      }
    }

    // Verify that the setup layout elements are displayed
    expect(find.text('Character Name'), findsOneWidget);
    expect(find.text('Race'), findsOneWidget);
  });
}
