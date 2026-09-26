import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_builder_ai/models/resume_model.dart';
import 'package:resume_builder_ai/services/resume_service.dart';

void main() {
  const userId = 'user-1';
  late FakeFirebaseFirestore firestore;
  late ResumeService service;

  CollectionReference<Map<String, dynamic>> resumesRef() =>
      firestore.collection('users').doc(userId).collection('resumes');

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = ResumeService(firestore: firestore);
  });

  test('overlapping saves of a new resume create a single document', () async {
    final id = service.newResumeId(userId);
    await Future.wait([
      service.saveResume(userId, ResumeModel(resumeId: id, title: 'Draft')),
      service.saveResume(userId, ResumeModel(resumeId: id, title: 'Final')),
    ]);

    final docs = (await resumesRef().get()).docs;
    expect(docs, hasLength(1));
    expect(docs.single.id, id);
    expect(docs.single.data()['resumeId'], id);
  });

  test('watchResumes lists the most recently edited first', () async {
    Future<void> addRaw(String id, DateTime updatedAt) => resumesRef()
        .doc(id)
        .set({'title': id, 'updatedAt': Timestamp.fromDate(updatedAt)});
    await addRaw('older', DateTime(2026, 1, 1));
    await addRaw('newest', DateTime(2026, 3, 1));
    await addRaw('middle', DateTime(2026, 2, 1));

    final resumes = await service.watchResumes(userId).first;
    expect(resumes.map((r) => r.resumeId), ['newest', 'middle', 'older']);
  });

  test('duplicateResume copies content under a new id', () async {
    const original = ResumeModel(
      resumeId: 'orig',
      title: 'Flutter Developer',
      templateId: 'modern',
      summary: 'Builds apps.',
      skills: ['Dart'],
      experience: [ExperienceEntry(title: 'Dev', company: 'Acme')],
    );
    await service.saveResume(userId, original);

    final copyId = await service.duplicateResume(userId, original);

    expect(copyId, isNot('orig'));
    final copy = (await service.getResume(userId, copyId))!;
    expect(copy.title, 'Flutter Developer (copy)');
    expect(copy.templateId, 'modern');
    expect(copy.summary, 'Builds apps.');
    expect(copy.skills, ['Dart']);
    expect(copy.experience.single.company, 'Acme');
    expect((await resumesRef().doc(copyId).get()).data()!['resumeId'], copyId);
    expect(
      (await service.getResume(userId, 'orig'))!.title,
      'Flutter Developer',
    );
  });

  test('deleteResume removes only that resume', () async {
    await service.saveResume(userId, const ResumeModel(resumeId: 'a'));
    await service.saveResume(userId, const ResumeModel(resumeId: 'b'));

    await service.deleteResume(userId, 'a');

    expect(await service.getResume(userId, 'a'), isNull);
    expect(await service.getResume(userId, 'b'), isNotNull);
  });
}
