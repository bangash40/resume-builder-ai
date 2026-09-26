import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/resume_model.dart';

class ResumeService {
  ResumeService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _resumesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('resumes');
  }

  Stream<List<ResumeModel>> watchResumes(String userId) {
    return _resumesRef(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ResumeModel.fromJson(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<ResumeModel?> getResume(String userId, String resumeId) async {
    final doc = await _resumesRef(userId).doc(resumeId).get();
    final data = doc.data();
    if (data == null) return null;
    return ResumeModel.fromJson(doc.id, data);
  }

  /// Generates an ID for a new resume on the device, without a network
  /// round trip. Callers hold on to it before the first save completes, so
  /// overlapping saves (or saves made offline) update one document instead
  /// of each creating a new one.
  String newResumeId(String userId) => _resumesRef(userId).doc().id;

  /// Creates the resume if it doesn't exist yet, otherwise updates it.
  Future<void> saveResume(String userId, ResumeModel resume) {
    return _resumesRef(userId)
        .doc(resume.resumeId)
        .set(resume.toJson(), SetOptions(merge: true));
  }

  /// Saves a copy of [resume] under a new ID and returns that ID.
  Future<String> duplicateResume(String userId, ResumeModel resume) async {
    final copy = resume.copyWith(
      resumeId: newResumeId(userId),
      title: '${resume.title} (copy)',
    );
    await saveResume(userId, copy);
    return copy.resumeId;
  }

  Future<void> deleteResume(String userId, String resumeId) {
    return _resumesRef(userId).doc(resumeId).delete();
  }
}
