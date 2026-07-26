import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Persian interface uses RTL direction', (tester) async {
    TextDirection? detectedDirection;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fa'),
        supportedLocales: const [
          Locale('fa'),
          Locale('en'),
        ],
        home: Builder(
          builder: (context) {
            detectedDirection = Directionality.of(context);

            return const Scaffold(
              body: Text('رها لایف'),
            );
          },
        ),
      ),
    );

    expect(find.text('رها لایف'), findsOneWidget);
    expect(detectedDirection, TextDirection.rtl);
  });

  testWidgets('English interface uses LTR direction', (tester) async {
    TextDirection? detectedDirection;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [
          Locale('fa'),
          Locale('en'),
        ],
        home: Builder(
          builder: (context) {
            detectedDirection = Directionality.of(context);

            return const Scaffold(
              body: Text('Raha Life'),
            );
          },
        ),
      ),
    );

    expect(find.text('Raha Life'), findsOneWidget);
    expect(detectedDirection, TextDirection.ltr);
  });
}
