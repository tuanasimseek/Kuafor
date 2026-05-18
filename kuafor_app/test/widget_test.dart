import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuafor_app/widgets/app_widgets.dart';

void main() {
  testWidgets('PrimaryButton renders and handles taps',
      (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Devam Et',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Devam Et'), findsOneWidget);
    await tester.tap(find.text('Devam Et'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
