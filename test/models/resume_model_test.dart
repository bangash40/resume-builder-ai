import 'package:flutter_test/flutter_test.dart';
import 'package:resume_builder_ai/models/resume_model.dart';

void main() {
  group('ResumeModel', () {
    test('fromJson maps experience, education, and skills correctly', () {
      final resume = ResumeModel.fromJson('resume-1', {
        'title': 'Flutter Developer Resume',
        'templateId': 'modern',
        'summary': 'Experienced mobile developer.',
        'targetRole': 'Flutter Developer',
        'skills': ['Flutter', 'Dart'],
        'experience': [
          {
            'title': 'Mobile Developer',
            'company': 'Acme Inc',
            'startDate': '2023',
            'endDate': 'Present',
            'bullets': ['Shipped the app', 'Reduced crashes by 50%'],
          },
        ],
        'education': [
          {
            'institution': 'State University',
            'degree': 'BSc Computer Science',
            'startDate': '2019',
            'endDate': '2023',
          },
        ],
      });

      expect(resume.resumeId, 'resume-1');
      expect(resume.title, 'Flutter Developer Resume');
      expect(resume.skills, ['Flutter', 'Dart']);
      expect(resume.experience, hasLength(1));
      expect(resume.experience.first.company, 'Acme Inc');
      expect(resume.experience.first.bullets, hasLength(2));
      expect(resume.education, hasLength(1));
      expect(resume.education.first.institution, 'State University');
    });

    test('fromJson falls back to defaults for missing fields', () {
      final resume = ResumeModel.fromJson('resume-2', const {});

      expect(resume.title, 'Untitled Resume');
      expect(resume.templateId, 'default');
      expect(resume.experience, isEmpty);
      expect(resume.education, isEmpty);
      expect(resume.skills, isEmpty);
    });

    test('toJson round-trips experience and education entries', () {
      const resume = ResumeModel(
        resumeId: 'resume-3',
        title: 'My Resume',
        experience: [
          ExperienceEntry(title: 'Intern', company: 'Startup', bullets: ['Did things']),
        ],
        education: [
          EducationEntry(institution: 'University', degree: 'BSc'),
        ],
        skills: ['Testing'],
      );

      final json = resume.toJson();
      final roundTripped = ResumeModel.fromJson('resume-3', json);

      expect(roundTripped.title, resume.title);
      expect(roundTripped.experience.first.title, 'Intern');
      expect(roundTripped.education.first.degree, 'BSc');
      expect(roundTripped.skills, ['Testing']);
    });
  });
}
