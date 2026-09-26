import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/resume_model.dart';
import '../secrets.dart';
import '../utils/ai_error.dart';

/// Per-attempt limit so a stalled request fails with a clear message instead
/// of spinning forever (TRD §8, §9).
const _requestTimeout = Duration(seconds: 30);

/// Wraps the Gemini API for resume content generation (TRD §6.2, Approach A:
/// calling Gemini directly from the app using the free-tier API key).
class AiService {
  AiService({GenerativeModel? model})
    : _model =
          model ??
          GenerativeModel(
            // An alias that always points to Google's current recommended
            // lightweight flash model, so this doesn't need updating as
            // models are deprecated and replaced over time. Well suited to
            // these short, structured JSON generation tasks.
            model: 'gemini-flash-lite-latest',
            apiKey: geminiApiKey,
            generationConfig: GenerationConfig(
              responseMimeType: 'application/json',
            ),
          );

  final GenerativeModel _model;

  Future<String> _generateWithRetry(
    String prompt, {
    int maxAttempts = 3,
  }) async {
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        final response = await _model
            .generateContent([Content.text(prompt)])
            .timeout(_requestTimeout);
        final text = response.text;
        if (text == null || text.trim().isEmpty) {
          throw const FormatException('Gemini returned an empty response.');
        }
        return text;
      } catch (e) {
        final retryable = isTransientAiError(e.toString().toLowerCase());
        if (attempt >= maxAttempts || !retryable) rethrow;
        await Future.delayed(Duration(seconds: pow(2, attempt).toInt()));
      }
    }
  }

  Map<String, dynamic> _decodeJsonObject(String raw) {
    final cleaned = raw
        .trim()
        .replaceAll(RegExp(r'^```json|^```|```$', multiLine: true), '')
        .trim();
    return jsonDecode(cleaned) as Map<String, dynamic>;
  }

  Future<String> generateSummary({
    required String targetRole,
    required List<String> skills,
    required String rawExperience,
  }) async {
    final prompt =
        '''
You are a professional resume writer. Write a concise, ATS-friendly professional
summary (2-4 sentences, no bullet points) for a candidate targeting the role of
"${targetRole.isEmpty ? 'a relevant role' : targetRole}".

Candidate skills: ${skills.isEmpty ? 'not specified' : skills.join(', ')}
Candidate experience: ${rawExperience.isEmpty ? 'not specified' : rawExperience}

Respond ONLY with JSON in this exact shape: {"summary": "..."}
''';
    final raw = await _generateWithRetry(prompt);
    final json = _decodeJsonObject(raw);
    return (json['summary'] as String? ?? '').trim();
  }

  Future<List<String>> generateExperienceBullets({
    required String jobTitle,
    required String company,
    required String rawDescription,
  }) async {
    final prompt =
        '''
You are a professional resume writer. Rewrite the following work experience into
3-5 concise, achievement-focused bullet points suitable for a resume. Use strong
action verbs, quantify impact where plausible, and avoid personal pronouns.

Job title: ${jobTitle.isEmpty ? 'not specified' : jobTitle}
Company: ${company.isEmpty ? 'not specified' : company}
Raw description: ${rawDescription.isEmpty ? 'not specified' : rawDescription}

Respond ONLY with JSON in this exact shape: {"bullets": ["...", "..."]}
''';
    final raw = await _generateWithRetry(prompt);
    final json = _decodeJsonObject(raw);
    return List<String>.from(json['bullets'] as List? ?? const []);
  }

  Future<List<String>> suggestSkills({
    required String targetRole,
    required List<String> existingSkills,
  }) async {
    final prompt =
        '''
Suggest up to 8 relevant skills and keywords for a resume targeting the role of
"${targetRole.isEmpty ? 'a relevant role' : targetRole}" that are not already in
this list: ${existingSkills.isEmpty ? 'none' : existingSkills.join(', ')}.
Keep each skill short (1-3 words).

Respond ONLY with JSON in this exact shape: {"skills": ["...", "..."]}
''';
    final raw = await _generateWithRetry(prompt);
    final json = _decodeJsonObject(raw);
    return List<String>.from(json['skills'] as List? ?? const []);
  }

  /// Extracts resume sections from text the user copied from their LinkedIn
  /// profile. LinkedIn's public API doesn't expose experience, education or
  /// skills, so import is user-assisted (TRD §6.3, §11.3).
  Future<ResumeModel> parseLinkedInProfile(String profileText) async {
    final prompt =
        '''
Extract resume data from the LinkedIn profile text below. Use only information
present in the text and never invent anything. Use empty strings or empty lists
for anything missing. Keep dates as written (for example "Jan 2022" or
"Present"). Turn each job's description into up to 5 concise bullet points.

Respond ONLY with JSON in this exact shape:
{"targetRole": "the person's headline or current job title",
 "summary": "their About section, or an empty string",
 "experience": [{"title": "", "company": "", "startDate": "", "endDate": "", "bullets": [""]}],
 "education": [{"institution": "", "degree": "", "startDate": "", "endDate": ""}],
 "skills": [""]}

LinkedIn profile text:
"""
$profileText
"""
''';
    final raw = await _generateWithRetry(prompt);
    try {
      return ResumeModel.fromJson('', _decodeJsonObject(raw));
    } catch (_) {
      throw const FormatException(
        'The AI returned the profile in an unexpected format.',
      );
    }
  }
}
