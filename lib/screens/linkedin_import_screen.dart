import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/resume_model.dart';
import '../services/ai_service.dart';

const _minProfileLength = 50;
const _maxProfileLength = 20000;

/// The sections the user chose to apply from an import. A null field means
/// that section was not selected and the resume's current value is kept.
class ImportedProfile {
  const ImportedProfile({
    this.targetRole,
    this.summary,
    this.experience,
    this.education,
    this.skills,
  });

  final String? targetRole;
  final String? summary;
  final List<ExperienceEntry>? experience;
  final List<EducationEntry>? education;
  final List<String>? skills;
}

/// User-assisted LinkedIn import (PRD FR-6.1/6.2): the user pastes their
/// profile text, Gemini extracts the sections, and the user reviews and picks
/// which sections to apply before anything is saved. Pops with an
/// [ImportedProfile], or null if cancelled.
class LinkedInImportScreen extends StatefulWidget {
  const LinkedInImportScreen({super.key});

  @override
  State<LinkedInImportScreen> createState() => _LinkedInImportScreenState();
}

class _LinkedInImportScreenState extends State<LinkedInImportScreen> {
  final _textController = TextEditingController();

  bool _isParsing = false;
  String? _errorMessage;
  ResumeModel? _parsed;

  bool _includeRole = true;
  bool _includeSummary = true;
  bool _includeExperience = true;
  bool _includeEducation = true;
  bool _includeSkills = true;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _parse() async {
    final text = _textController.text.trim();
    if (text.length < _minProfileLength) {
      setState(
        () => _errorMessage =
            "That doesn't look like a full profile. Paste all of the text "
            'from your LinkedIn profile.',
      );
      return;
    }
    if (text.length > _maxProfileLength) {
      setState(
        () => _errorMessage =
            'That text is too long. Paste only your profile, not the whole '
            'page.',
      );
      return;
    }

    setState(() {
      _isParsing = true;
      _errorMessage = null;
    });
    try {
      final parsed = await context.read<AiService>().parseLinkedInProfile(text);
      if (!mounted) return;
      setState(() => _parsed = parsed);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'Could not read that profile. Check your internet connection and '
            'try again.',
      );
    } finally {
      if (mounted) setState(() => _isParsing = false);
    }
  }

  void _apply() {
    final p = _parsed!;
    Navigator.of(context).pop(
      ImportedProfile(
        targetRole: _includeRole && p.targetRole.isNotEmpty
            ? p.targetRole
            : null,
        summary: _includeSummary && p.summary.isNotEmpty ? p.summary : null,
        experience: _includeExperience && p.experience.isNotEmpty
            ? p.experience
            : null,
        education: _includeEducation && p.education.isNotEmpty
            ? p.education
            : null,
        skills: _includeSkills && p.skills.isNotEmpty ? p.skills : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import from LinkedIn')),
      body: SafeArea(
        child: _parsed == null ? _buildPasteStep() : _buildReviewStep(),
      ),
    );
  }

  Widget _buildPasteStep() {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Paste your LinkedIn profile', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Open your LinkedIn profile in a browser and copy all of its text, '
          'or use More → Save to PDF and copy the text from the PDF. Paste it '
          'below and we will fill in your resume. You can review everything '
          'before it is added.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _textController,
          minLines: 8,
          maxLines: 16,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Paste your profile text here',
            alignLabelWithHint: true,
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _isParsing ? null : _parse,
          icon: _isParsing
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(_isParsing ? 'Reading your profile…' : 'Import with AI'),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final p = _parsed!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final nothingFound =
        p.targetRole.isEmpty &&
        p.summary.isEmpty &&
        p.experience.isEmpty &&
        p.education.isEmpty &&
        p.skills.isEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: colorScheme.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nothingFound
                      ? "We couldn't find any resume details in that text."
                      : 'Imported from LinkedIn. Check each section. Ticked '
                            'sections will replace the matching sections of '
                            'your resume.',
                  style: TextStyle(color: colorScheme.onSecondaryContainer),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (p.targetRole.isNotEmpty)
          _ReviewSection(
            title: 'Target role',
            value: _includeRole,
            onChanged: (v) => setState(() => _includeRole = v),
            children: [Text(p.targetRole)],
          ),
        if (p.summary.isNotEmpty)
          _ReviewSection(
            title: 'Summary',
            value: _includeSummary,
            onChanged: (v) => setState(() => _includeSummary = v),
            children: [Text(p.summary)],
          ),
        if (p.experience.isNotEmpty)
          _ReviewSection(
            title: 'Experience (${p.experience.length})',
            value: _includeExperience,
            onChanged: (v) => setState(() => _includeExperience = v),
            children: [
              for (final e in p.experience)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${e.title} · ${e.company}\n${e.startDate} - ${e.endDate}',
                  ),
                ),
            ],
          ),
        if (p.education.isNotEmpty)
          _ReviewSection(
            title: 'Education (${p.education.length})',
            value: _includeEducation,
            onChanged: (v) => setState(() => _includeEducation = v),
            children: [
              for (final ed in p.education)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('${ed.degree} · ${ed.institution}'),
                ),
            ],
          ),
        if (p.skills.isNotEmpty)
          _ReviewSection(
            title: 'Skills (${p.skills.length})',
            value: _includeSkills,
            onChanged: (v) => setState(() => _includeSkills = v),
            children: [Text(p.skills.join(', '))],
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _parsed = null),
                child: const Text('Start over'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: nothingFound ? null : _apply,
                child: const Text('Add to resume'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'You can still edit everything after adding it.',
          style: textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.children,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              title: Text(title, style: Theme.of(context).textTheme.titleSmall),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
