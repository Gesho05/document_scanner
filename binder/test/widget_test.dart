import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:binder/main.dart'; // Ensure this matches your project name

void main() {
  testWidgets('Binder App smoke test', (WidgetTester tester) async {
    // 1. Change 'MyApp()' to 'BinderMainScreen()' or whatever your main widget is named
    // In our previous steps, we used a MaterialApp wrapping BinderMainScreen
    await tester.pumpWidget(const MaterialApp(home: BinderMainScreen()));

    // 2. Verify that the Home Page text is found
    expect(find.text('Home Page'), findsOneWidget);

    // 3. Verify the Browse Page text is NOT there yet (since we haven't clicked it)
    expect(find.text('Browse Page'), findsNothing);
  });
}