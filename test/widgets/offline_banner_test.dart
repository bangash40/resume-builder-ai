import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_builder_ai/widgets/offline_banner.dart';

void main() {
  late StreamController<bool> online;

  setUp(() => online = StreamController<bool>());
  tearDown(() => online.close());

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: const Scaffold(body: TextField()),
      builder: (context, child) =>
          OfflineBanner(isOnline: online.stream, child: child!),
    ),
  );

  testWidgets('shows the banner only while offline', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining("You're offline"), findsNothing);

    online.add(false);
    await tester.pumpAndSettle();
    expect(find.textContaining("You're offline"), findsOne);

    online.add(true);
    await tester.pumpAndSettle();
    expect(find.textContaining("You're offline"), findsNothing);
  });

  testWidgets('keeps what the user was typing when the connection changes', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'unsaved draft');

    online.add(false);
    await tester.pumpAndSettle();
    expect(find.text('unsaved draft'), findsOne);

    online.add(true);
    await tester.pumpAndSettle();
    expect(find.text('unsaved draft'), findsOne);
  });
}
