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

  Future<String> createResume(String userId, ResumeModel resume) async {
    final docRef = await _resumesRef(userId).add(resume.toJson());
    return docRef.id;
  }

  Future<void> updateResume(String userId, ResumeModel resume) {
    return _resumesRef(userId)
        .doc(resume.resumeId)
        .set(resume.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteResume(String userId, String resumeId) {
    return _resumesRef(userId).doc(resumeId).delete();
  }
}
