import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:presence_par_qr/main.dart';

void main() {
  testWidgets('login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PresenceApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
