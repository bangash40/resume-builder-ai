import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resume_builder_ai/models/resume_model.dart';
import 'package:resume_builder_ai/models/template_model.dart';
import 'package:resume_builder_ai/widgets/resume_template_renderer.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const longEmail = 'a.very.long.email.address.for.testing@example-company.com';
  const resume = ResumeModel(
    resumeId: 'r1',
    targetRole: 'Senior Cross-Platform Mobile Application Developer',
    summary: 'Experienced developer with a long summary that wraps.',
    experience: [
      ExperienceEntry(
        title: 'Principal Mobile Engineer',
        company: 'An Extremely Long Company Name Incorporated',
        startDate: 'January 2020',
        endDate: 'Present',
        bullets: ['Shipped a very long bullet point that should wrap nicely'],
      ),
    ],
    education: [
      EducationEntry(
        institution: 'A University With A Remarkably Long Official Name',
        degree: 'Bachelor of Science in Computer Science',
        startDate: '2015',
        endDate: '2019',
      ),
    ],
    skills: ['Flutter', 'Dart', 'Firebase', 'State Management', 'CI/CD'],
  );

  for (final template in kResumeTemplates) {
    testWidgets('${template.name} template does not overflow on a narrow '
        'screen when the name falls back to a long email', (tester) async {
      tester.view.physicalSize = const Size(360, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ResumeTemplateRenderer(
                resume: resume.copyWith(templateId: template.templateId),
                displayName: longEmail,
                contactEmail: longEmail,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  }
}
