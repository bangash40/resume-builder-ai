import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:resume_builder_ai/models/resume_model.dart';
import 'package:resume_builder_ai/models/template_model.dart';
import 'package:resume_builder_ai/services/pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const longEmail = 'a.very.long.email.address.for.testing@example-company.com';
  final service = PdfService();

  ResumeModel resumeWithJobs(int jobCount) => ResumeModel(
    resumeId: 'r1',
    title: 'Flutter Developer Resume',
    targetRole: 'Senior Cross-Platform Mobile Application Developer',
    summary: 'Experienced developer • builds apps – ships fast · ' * 6,
    experience: [
      for (var i = 0; i < jobCount; i++)
        ExperienceEntry(
          title: 'Principal Mobile Engineer $i',
          company: 'An Extremely Long Company Name Incorporated',
          startDate: 'January 2020',
          endDate: 'Present',
          bullets: [
            'Shipped a very long bullet point that should wrap across '
                'multiple lines without any trouble at all',
            'Cut crash rate by 50% and load time by 35%',
          ],
        ),
    ],
    education: const [
      EducationEntry(
        institution: 'A University With A Remarkably Long Official Name',
        degree: 'Bachelor of Science in Computer Science',
        startDate: '2015',
        endDate: '2019',
      ),
    ],
    skills: const ['Flutter', 'Dart', 'Firebase', 'State Management', 'CI/CD'],
  );

  bool isPdf(List<int> bytes) =>
      bytes.length > 1000 && ascii.decode(bytes.sublist(0, 5)) == '%PDF-';

  for (final template in kResumeTemplates) {
    for (final font in PdfService.supportedFonts) {
      test('${template.name} template renders with $font', () async {
        final bytes = await service.buildResumePdf(
          resume: resumeWithJobs(2)
              .copyWith(templateId: template.templateId, fontFamily: font),
          displayName: longEmail,
          contactEmail: longEmail,
        );
        expect(isPdf(bytes), isTrue);
      });
    }

    test('${template.name} template flows onto extra pages', () async {
      final bytes = await service.buildResumePdf(
        resume: resumeWithJobs(40).copyWith(templateId: template.templateId),
        displayName: 'Ayesha Khan',
        contactEmail: 'ayesha@example.com',
      );
      final pageCount = RegExp(r'/Type\s*/Page\b')
          .allMatches(latin1.decode(bytes))
          .length;
      expect(pageCount, greaterThan(1));
    });
  }

  test('an empty resume still renders', () async {
    final bytes = await service.buildResumePdf(
      resume: const ResumeModel(resumeId: 'r2'),
      displayName: 'Ayesha Khan',
      contactEmail: '',
    );
    expect(isPdf(bytes), isTrue);
  });

  test('file names are safe for sharing', () {
    expect(
      PdfService.fileNameFor(
        const ResumeModel(resumeId: 'r', title: 'Flutter Dev / 2026: v2!'),
      ),
      'Flutter_Dev_2026_v2.pdf',
    );
    expect(
      PdfService.fileNameFor(const ResumeModel(resumeId: 'r', title: '???')),
      'Resume.pdf',
    );
  });
}
