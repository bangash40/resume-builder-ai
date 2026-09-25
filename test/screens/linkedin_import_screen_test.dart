import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:resume_builder_ai/models/resume_model.dart';
import 'package:resume_builder_ai/screens/linkedin_import_screen.dart';
import 'package:resume_builder_ai/services/ai_service.dart';

class _FakeAiService extends AiService {
  int calls = 0;

  @override
  Future<ResumeModel> parseLinkedInProfile(String profileText) async {
    calls++;
    return const ResumeModel(
      resumeId: '',
      targetRole: 'Flutter Developer',
      summary: 'Builds mobile apps.',
      experience: [ExperienceEntry(title: 'Developer', company: 'Acme')],
      education: [EducationEntry(institution: 'PU', degree: 'BSCS')],
      skills: ['Flutter', 'Dart'],
    );
  }
}

void main() {
  late _FakeAiService ai;
  ImportedProfile? result;

  Future<void> openImportScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      Provider<AiService>.value(
        value: ai,
        child: MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await Navigator.of(context).push<ImportedProfile>(
                  MaterialPageRoute(
                    builder: (_) => const LinkedInImportScreen(),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    ai = _FakeAiService();
    result = null;
  });

  testWidgets('rejects text too short to be a profile without calling AI', (
    tester,
  ) async {
    await openImportScreen(tester);
    await tester.enterText(find.byType(TextField), 'too short');
    await tester.tap(find.text('Import with AI'));
    await tester.pump();

    expect(find.textContaining("doesn't look like a full profile"), findsOne);
    expect(ai.calls, 0);
  });

  testWidgets('unticked sections are left out of the imported result', (
    tester,
  ) async {
    await openImportScreen(tester);
    await tester.enterText(find.byType(TextField), 'Profile text ' * 10);
    await tester.tap(find.text('Import with AI'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Imported from LinkedIn'), findsOne);

    await tester.tap(find.text('Skills (2)'));
    await tester.pump();
    await tester.tap(find.text('Add to resume'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.skills, isNull);
    expect(result!.targetRole, 'Flutter Developer');
    expect(result!.experience!.single.company, 'Acme');
    expect(result!.education!.single.institution, 'PU');
  });
}
