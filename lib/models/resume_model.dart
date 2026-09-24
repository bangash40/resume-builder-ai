import 'package:cloud_firestore/cloud_firestore.dart';

class ExperienceEntry {
  const ExperienceEntry({
    required this.title,
    required this.company,
    this.startDate = '',
    this.endDate = '',
    this.bullets = const [],
  });

  final String title;
  final String company;
  final String startDate;
  final String endDate;
  final List<String> bullets;

  factory ExperienceEntry.fromJson(Map<String, dynamic> json) {
    return ExperienceEntry(
      title: json['title'] as String? ?? '',
      company: json['company'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      bullets: List<String>.from(json['bullets'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'company': company,
      'startDate': startDate,
      'endDate': endDate,
      'bullets': bullets,
    };
  }
}

class EducationEntry {
  const EducationEntry({
    required this.institution,
    required this.degree,
    this.startDate = '',
    this.endDate = '',
  });

  final String institution;
  final String degree;
  final String startDate;
  final String endDate;

  factory EducationEntry.fromJson(Map<String, dynamic> json) {
    return EducationEntry(
      institution: json['institution'] as String? ?? '',
      degree: json['degree'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'institution': institution,
      'degree': degree,
      'startDate': startDate,
      'endDate': endDate,
    };
  }
}

class ResumeModel {
  const ResumeModel({
    required this.resumeId,
    this.title = 'Untitled Resume',
    this.templateId = 'classic',
    this.accentColor = 0xFF6750A4,
    this.fontFamily = 'Roboto',
    this.summary = '',
    this.experience = const [],
    this.education = const [],
    this.skills = const [],
    this.targetRole = '',
    this.updatedAt,
  });

  final String resumeId;
  final String title;
  final String templateId;

  /// ARGB color value, e.g. `0xFF6750A4`.
  final int accentColor;
  final String fontFamily;
  final String summary;
  final List<ExperienceEntry> experience;
  final List<EducationEntry> education;
  final List<String> skills;
  final String targetRole;
  final DateTime? updatedAt;

  factory ResumeModel.fromJson(String resumeId, Map<String, dynamic> json) {
    return ResumeModel(
      resumeId: resumeId,
      title: json['title'] as String? ?? 'Untitled Resume',
      templateId: json['templateId'] as String? ?? 'classic',
      accentColor: json['accentColor'] as int? ?? 0xFF6750A4,
      fontFamily: json['fontFamily'] as String? ?? 'Roboto',
      summary: json['summary'] as String? ?? '',
      experience: (json['experience'] as List? ?? const [])
          .map(
            (e) =>
                ExperienceEntry.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      education: (json['education'] as List? ?? const [])
          .map(
            (e) => EducationEntry.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      skills: List<String>.from(json['skills'] as List? ?? const []),
      targetRole: json['targetRole'] as String? ?? '',
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resumeId': resumeId,
      'title': title,
      'templateId': templateId,
      'accentColor': accentColor,
      'fontFamily': fontFamily,
      'summary': summary,
      'experience': experience.map((e) => e.toJson()).toList(),
      'education': education.map((e) => e.toJson()).toList(),
      'skills': skills,
      'targetRole': targetRole,
      // A client-generated Timestamp (rather than FieldValue.serverTimestamp())
      // so the field is immediately concrete in the local cache and usable in
      // orderBy queries even while offline.
      'updatedAt': Timestamp.now(),
    };
  }

  ResumeModel copyWith({
    String? title,
    String? templateId,
    int? accentColor,
    String? fontFamily,
    String? summary,
    List<ExperienceEntry>? experience,
    List<EducationEntry>? education,
    List<String>? skills,
    String? targetRole,
  }) {
    return ResumeModel(
      resumeId: resumeId,
      title: title ?? this.title,
      templateId: templateId ?? this.templateId,
      accentColor: accentColor ?? this.accentColor,
      fontFamily: fontFamily ?? this.fontFamily,
      summary: summary ?? this.summary,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      skills: skills ?? this.skills,
      targetRole: targetRole ?? this.targetRole,
      updatedAt: updatedAt,
    );
  }
}
