import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:resume_builder_ai/models/resume_model.dart';
import 'package:resume_builder_ai/services/resume_service.dart';
import 'package:resume_builder_ai/widgets/resume_list.dart';

void main() {
  const userId = 'user-1';
  late ResumeService service;
  String? openedId;
  var createTapped = false;

  setUp(() {
    service = ResumeService(firestore: FakeFirebaseFirestore());
    openedId = null;
    createTapped = false;
  });

  Future<void> pumpList(WidgetTester tester) async {
    await tester.pumpWidget(
      Provider<ResumeService>.value(
        value: service,
        child: MaterialApp(
          home: Scaffold(
            body: ResumeList(
              userId: userId,
              onOpen: (id) => openedId = id,
              onCreate: () => createTapped = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> chooseMenuAction(WidgetTester tester, String action) async {
    await tester.tap(find.byTooltip('More actions').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(action));
    await tester.pumpAndSettle();
  }

  testWidgets('shows an empty state that starts a new resume', (tester) async {
    await pumpList(tester);

    expect(find.text('No resumes yet'), findsOne);
    await tester.tap(find.text('Create a resume'));
    expect(createTapped, isTrue);
  });

  testWidgets('lists resumes and opens the one tapped', (tester) async {
    await service.saveResume(
      userId,
      const ResumeModel(resumeId: 'r1', title: 'Flutter Dev'),
    );
    await pumpList(tester);

    expect(find.text('Flutter Dev'), findsOne);
    await tester.tap(find.text('Flutter Dev'));
    expect(openedId, 'r1');
  });

  testWidgets('duplicate adds a copy to the list', (tester) async {
    await service.saveResume(
      userId,
      const ResumeModel(resumeId: 'r1', title: 'Flutter Dev'),
    );
    await pumpList(tester);

    await chooseMenuAction(tester, 'Duplicate');

    expect(find.text('Flutter Dev'), findsOne);
    expect(find.text('Flutter Dev (copy)'), findsOne);
  });

  testWidgets('delete asks for confirmation and cancel keeps the resume', (
    tester,
  ) async {
    await service.saveResume(
      userId,
      const ResumeModel(resumeId: 'r1', title: 'Flutter Dev'),
    );
    await pumpList(tester);

    await chooseMenuAction(tester, 'Delete');
    expect(find.text('Delete resume?'), findsOne);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Flutter Dev'), findsOne);

    await chooseMenuAction(tester, 'Delete');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Flutter Dev'), findsNothing);
    expect(find.text('No resumes yet'), findsOne);
  });

  group('describeEditedDate', () {
    final now = DateTime(2026, 9, 26, 15);

    test('uses relative labels for the last week', () {
      expect(describeEditedDate(DateTime(2026, 9, 26, 1), now), 'today');
      expect(describeEditedDate(DateTime(2026, 9, 25, 23), now), 'yesterday');
      expect(describeEditedDate(DateTime(2026, 9, 21), now), '5 days ago');
    });

    test('uses a date for older edits', () {
      expect(describeEditedDate(DateTime(2026, 8, 12), now), '12 Aug 2026');
    });
  });
}
