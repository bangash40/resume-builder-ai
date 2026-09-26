import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/resume_model.dart';
import '../services/ai_service.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/resume_service.dart';
import '../utils/ai_error.dart';
import 'linkedin_import_screen.dart';
import 'resume_preview_screen.dart';

enum _SaveStatus { idle, saved, error }

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key, this.resumeId});

  /// When set, the form loads and continues editing this existing resume
  /// instead of starting a blank one.
  final String? resumeId;

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _titleController = TextEditingController(text: 'My Resume');
  final _targetRoleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _skillController = TextEditingController();

  List<ExperienceEntry> _experience = [];
  List<EducationEntry> _education = [];
  List<String> _skills = [];
  String _templateId = 'classic';
  int _accentColor = 0xFF6750A4;
  String _fontFamily = 'Roboto';

  String? _resumeId;
  Timer? _debounce;
  _SaveStatus _saveStatus = _SaveStatus.idle;
  bool _isLoading = true;
  bool _isGeneratingSummary = false;
  bool _isSuggestingSkills = false;
  List<String> _suggestedSkills = [];

  @override
  void initState() {
    super.initState();
    _resumeId = widget.resumeId;
    _loadExistingThenListen();
  }

  Future<void> _loadExistingThenListen() async {
    if (_resumeId != null) {
      final userId = context.read<AuthService>().currentUser?.uid;
      if (userId != null) {
        final existing = await context.read<ResumeService>().getResume(
          userId,
          _resumeId!,
        );
        if (existing != null && mounted) {
          _titleController.text = existing.title;
          _targetRoleController.text = existing.targetRole;
          _summaryController.text = existing.summary;
          _experience = existing.experience;
          _education = existing.education;
          _skills = existing.skills;
          _templateId = existing.templateId;
          _accentColor = existing.accentColor;
          _fontFamily = existing.fontFamily;
        }
      }
    }
    if (!mounted) return;
    _titleController.addListener(_scheduleAutoSave);
    _targetRoleController.addListener(_scheduleAutoSave);
    _summaryController.addListener(_scheduleAutoSave);
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.dispose();
    _targetRoleController.dispose();
    _summaryController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  void _scheduleAutoSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _saveNow);
  }

  /// Flushes any pending debounced save immediately. Used before leaving the
  /// screen so a quick back-press can't silently discard unsaved edits.
  void _flushPendingSave() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      _saveNow();
    }
  }

  Future<void> _importFromLinkedIn() async {
    final imported = await Navigator.of(context).push<ImportedProfile>(
      MaterialPageRoute(builder: (_) => const LinkedInImportScreen()),
    );
    if (imported == null || !mounted) return;

    setState(() {
      if (imported.targetRole != null) {
        _targetRoleController.text = imported.targetRole!;
      }
      if (imported.summary != null) {
        _summaryController.text = imported.summary!;
      }
      if (imported.experience != null) _experience = imported.experience!;
      if (imported.education != null) _education = imported.education!;
      if (imported.skills != null) _skills = imported.skills!;
    });
    _scheduleAutoSave();
    context.read<AnalyticsService>().logLinkedInImport(
      sectionCount: [
        imported.targetRole,
        imported.summary,
        imported.experience,
        imported.education,
        imported.skills,
      ].where((section) => section != null).length,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Imported from LinkedIn. Review and edit it below.'),
      ),
    );
  }

  void _openPreview() {
    final user = context.read<AuthService>().currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email ?? 'Your Name');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResumePreviewScreen(
          initialResume: _buildResume(),
          displayName: displayName,
          contactEmail: user?.email ?? '',
          onChanged: (updated) {
            setState(() {
              _templateId = updated.templateId;
              _accentColor = updated.accentColor;
              _fontFamily = updated.fontFamily;
            });
            _scheduleAutoSave();
          },
        ),
      ),
    );
  }

  ResumeModel _buildResume() {
    return ResumeModel(
      resumeId: _resumeId ?? '',
      title: _titleController.text.trim().isEmpty
          ? 'Untitled Resume'
          : _titleController.text.trim(),
      templateId: _templateId,
      accentColor: _accentColor,
      fontFamily: _fontFamily,
      summary: _summaryController.text.trim(),
      targetRole: _targetRoleController.text.trim(),
      experience: _experience,
      education: _education,
      skills: _skills,
    );
  }

  void _saveNow() {
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) return;

    final resumeService = context.read<ResumeService>();
    // Assigned synchronously, before the write, so a save that starts while
    // this one is still in flight updates the same document.
    if (_resumeId == null) {
      _resumeId = resumeService.newResumeId(userId);
      context.read<AnalyticsService>().logResumeCreated();
    }

    // Not awaited: Firestore applies the write to the on-device cache
    // immediately, but the returned future only completes once the server
    // confirms it, which never happens while offline. Awaiting it would leave
    // "Saving…" on screen and block leaving the form until reconnecting.
    resumeService.saveResume(userId, _buildResume()).catchError((_) {
      if (mounted) setState(() => _saveStatus = _SaveStatus.error);
    });
    setState(() => _saveStatus = _SaveStatus.saved);
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isEmpty || _skills.contains(skill)) return;
    setState(() {
      _skills = [..._skills, skill];
      _skillController.clear();
    });
    _scheduleAutoSave();
  }

  void _removeSkill(String skill) {
    setState(() => _skills = _skills.where((s) => s != skill).toList());
    _scheduleAutoSave();
  }

  void _addSuggestedSkill(String skill) {
    setState(() {
      _skills = [..._skills, skill];
      _suggestedSkills = _suggestedSkills.where((s) => s != skill).toList();
    });
    _scheduleAutoSave();
  }

  String _experienceSummaryForPrompt() {
    return _experience
        .map((e) => '${e.title} at ${e.company}: ${e.bullets.join('; ')}')
        .join('\n');
  }

  Future<void> _generateSummary() async {
    setState(() => _isGeneratingSummary = true);
    try {
      final summary = await context.read<AiService>().generateSummary(
        targetRole: _targetRoleController.text.trim(),
        skills: _skills,
        rawExperience: _experienceSummaryForPrompt(),
      );
      if (!mounted) return;
      _summaryController.text = summary;
      context.read<AnalyticsService>().logAiGenerated('summary');
    } catch (e) {
      if (!mounted) return;
      _showAiError("Couldn't write your summary.", e, _generateSummary);
    } finally {
      if (mounted) setState(() => _isGeneratingSummary = false);
    }
  }

  Future<void> _suggestSkills() async {
    setState(() => _isSuggestingSkills = true);
    try {
      final suggestions = await context.read<AiService>().suggestSkills(
        targetRole: _targetRoleController.text.trim(),
        existingSkills: _skills,
      );
      if (!mounted) return;
      setState(() => _suggestedSkills = suggestions);
      context.read<AnalyticsService>().logAiGenerated('skills');
    } catch (e) {
      if (!mounted) return;
      _showAiError("Couldn't suggest skills.", e, _suggestSkills);
    } finally {
      if (mounted) setState(() => _isSuggestingSkills = false);
    }
  }

  void _showAiError(String what, Object error, VoidCallback retry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$what ${aiErrorMessage(error)}'),
        action: SnackBarAction(label: 'Retry', onPressed: retry),
      ),
    );
  }

  Future<void> _addOrEditExperience({
    ExperienceEntry? existing,
    int? index,
  }) async {
    final result = await showDialog<ExperienceEntry>(
      context: context,
      builder: (_) => _ExperienceDialog(existing: existing),
    );
    if (result == null) return;
    setState(() {
      if (index != null) {
        final updated = [..._experience];
        updated[index] = result;
        _experience = updated;
      } else {
        _experience = [..._experience, result];
      }
    });
    _scheduleAutoSave();
  }

  void _removeExperience(int index) {
    setState(() {
      final updated = [..._experience]..removeAt(index);
      _experience = updated;
    });
    _scheduleAutoSave();
  }

  Future<void> _addOrEditEducation({
    EducationEntry? existing,
    int? index,
  }) async {
    final result = await showDialog<EducationEntry>(
      context: context,
      builder: (_) => _EducationDialog(existing: existing),
    );
    if (result == null) return;
    setState(() {
      if (index != null) {
        final updated = [..._education];
        updated[index] = result;
        _education = updated;
      } else {
        _education = [..._education, result];
      }
    });
    _scheduleAutoSave();
  }

  void _removeEducation(int index) {
    setState(() {
      final updated = [..._education]..removeAt(index);
      _education = updated;
    });
    _scheduleAutoSave();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Build Your Resume')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _flushPendingSave();
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Build Your Resume'),
          actions: [
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              tooltip: 'Preview',
              onPressed: _openPreview,
            ),
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Save and close',
              onPressed: () {
                _flushPendingSave();
                Navigator.of(context).pop();
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(20),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(switch (_saveStatus) {
                _SaveStatus.idle => '',
                _SaveStatus.saved => 'Saved',
                _SaveStatus.error => 'Could not save your latest changes',
              }, style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OutlinedButton.icon(
              onPressed: _importFromLinkedIn,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Import from LinkedIn'),
            ),
            const SizedBox(height: 16),
            Text(
              'Personal details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Resume title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetRoleController,
              decoration: const InputDecoration(
                labelText: 'Target job role',
                hintText: 'e.g. Flutter Developer',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _summaryController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Professional summary',
                hintText: 'A short summary of your experience and goals',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isGeneratingSummary ? null : _generateSummary,
                icon: _isGeneratingSummary
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  _summaryController.text.isEmpty
                      ? 'Generate with AI'
                      : 'Regenerate with AI',
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Experience',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add experience',
                  onPressed: () => _addOrEditExperience(),
                ),
              ],
            ),
            if (_experience.isEmpty)
              const Text('No experience added yet.')
            else
              for (var i = 0; i < _experience.length; i++)
                Card(
                  child: ListTile(
                    title: Text(
                      '${_experience[i].title} · ${_experience[i].company}',
                    ),
                    subtitle: Text(
                      '${_experience[i].startDate} - ${_experience[i].endDate}',
                    ),
                    onTap: () => _addOrEditExperience(
                      existing: _experience[i],
                      index: i,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeExperience(i),
                    ),
                  ),
                ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Education',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add education',
                  onPressed: () => _addOrEditEducation(),
                ),
              ],
            ),
            if (_education.isEmpty)
              const Text('No education added yet.')
            else
              for (var i = 0; i < _education.length; i++)
                Card(
                  child: ListTile(
                    title: Text(
                      '${_education[i].degree} · ${_education[i].institution}',
                    ),
                    subtitle: Text(
                      '${_education[i].startDate} - ${_education[i].endDate}',
                    ),
                    onTap: () =>
                        _addOrEditEducation(existing: _education[i], index: i),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeEducation(i),
                    ),
                  ),
                ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Skills', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: _isSuggestingSkills ? null : _suggestSkills,
                  icon: _isSuggestingSkills
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Suggest skills'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _skillController,
                    decoration: const InputDecoration(hintText: 'e.g. Flutter'),
                    onSubmitted: (_) => _addSkill(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _addSkill,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final skill in _skills)
                  Chip(
                    label: Text(skill),
                    onDeleted: () => _removeSkill(skill),
                  ),
              ],
            ),
            if (_suggestedSkills.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Suggested for you — tap to add',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final skill in _suggestedSkills)
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: Text(skill),
                      onPressed: () => _addSuggestedSkill(skill),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ExperienceDialog extends StatefulWidget {
  const _ExperienceDialog({this.existing});

  final ExperienceEntry? existing;

  @override
  State<_ExperienceDialog> createState() => _ExperienceDialogState();
}

class _ExperienceDialogState extends State<_ExperienceDialog> {
  late final _titleController = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  late final _companyController = TextEditingController(
    text: widget.existing?.company ?? '',
  );
  late final _startController = TextEditingController(
    text: widget.existing?.startDate ?? '',
  );
  late final _endController = TextEditingController(
    text: widget.existing?.endDate ?? '',
  );
  late final _bulletsController = TextEditingController(
    text: widget.existing?.bullets.join('\n') ?? '',
  );

  bool _isRewriting = false;
  String? _rewriteError;

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _startController.dispose();
    _endController.dispose();
    _bulletsController.dispose();
    super.dispose();
  }

  Future<void> _rewriteWithAi() async {
    setState(() {
      _isRewriting = true;
      _rewriteError = null;
    });
    try {
      final bullets = await context.read<AiService>().generateExperienceBullets(
        jobTitle: _titleController.text.trim(),
        company: _companyController.text.trim(),
        rawDescription: _bulletsController.text.trim(),
      );
      if (!mounted) return;
      _bulletsController.text = bullets.join('\n');
      context.read<AnalyticsService>().logAiGenerated('bullets');
    } catch (e) {
      // Shown inside the dialog: a snackbar would sit behind the dialog's
      // barrier where it can't be read.
      if (mounted) setState(() => _rewriteError = aiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isRewriting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add experience' : 'Edit experience',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Job title'),
            ),
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(labelText: 'Company'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startController,
                    decoration: const InputDecoration(labelText: 'Start'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _endController,
                    decoration: const InputDecoration(labelText: 'End'),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _bulletsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Achievements (one per line)',
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isRewriting ? null : _rewriteWithAi,
                icon: _isRewriting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  _rewriteError == null ? 'Rewrite with AI' : 'Retry',
                ),
              ),
            ),
            if (_rewriteError != null)
              Text(
                _rewriteError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              ExperienceEntry(
                title: _titleController.text.trim(),
                company: _companyController.text.trim(),
                startDate: _startController.text.trim(),
                endDate: _endController.text.trim(),
                bullets: _bulletsController.text
                    .split('\n')
                    .map((b) => b.trim())
                    .where((b) => b.isNotEmpty)
                    .toList(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _EducationDialog extends StatefulWidget {
  const _EducationDialog({this.existing});

  final EducationEntry? existing;

  @override
  State<_EducationDialog> createState() => _EducationDialogState();
}

class _EducationDialogState extends State<_EducationDialog> {
  late final _institutionController = TextEditingController(
    text: widget.existing?.institution ?? '',
  );
  late final _degreeController = TextEditingController(
    text: widget.existing?.degree ?? '',
  );
  late final _startController = TextEditingController(
    text: widget.existing?.startDate ?? '',
  );
  late final _endController = TextEditingController(
    text: widget.existing?.endDate ?? '',
  );

  @override
  void dispose() {
    _institutionController.dispose();
    _degreeController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add education' : 'Edit education'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _institutionController,
              decoration: const InputDecoration(labelText: 'Institution'),
            ),
            TextField(
              controller: _degreeController,
              decoration: const InputDecoration(labelText: 'Degree'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startController,
                    decoration: const InputDecoration(labelText: 'Start'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _endController,
                    decoration: const InputDecoration(labelText: 'End'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              EducationEntry(
                institution: _institutionController.text.trim(),
                degree: _degreeController.text.trim(),
                startDate: _startController.text.trim(),
                endDate: _endController.text.trim(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
