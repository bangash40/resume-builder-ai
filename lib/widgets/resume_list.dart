import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/resume_model.dart';
import '../services/resume_service.dart';

enum _ResumeAction { duplicate, delete }

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// A short, human-friendly "last edited" label, e.g. "today",
/// "3 days ago" or "12 Aug 2026".
String describeEditedDate(DateTime? edited, DateTime now) {
  if (edited == null) return 'just now';
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(edited.year, edited.month, edited.day)).inDays;
  if (days <= 0) return 'today';
  if (days == 1) return 'yesterday';
  if (days < 7) return '$days days ago';
  return '${edited.day} ${_months[edited.month - 1]} ${edited.year}';
}

/// The signed-in user's saved resumes, most recently edited first
/// (PRD FR-8.1), with duplicate and delete actions (FR-8.2).
class ResumeList extends StatelessWidget {
  const ResumeList({
    super.key,
    required this.userId,
    required this.onOpen,
    required this.onCreate,
  });

  final String userId;
  final ValueChanged<String> onOpen;
  final VoidCallback onCreate;

  Future<void> _duplicate(BuildContext context, ResumeModel resume) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<ResumeService>().duplicateResume(userId, resume);
      messenger.showSnackBar(
        SnackBar(content: Text('Duplicated "${resume.title}"')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not duplicate that resume.')),
      );
    }
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    ResumeModel resume,
  ) async {
    final service = context.read<ResumeService>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete resume?'),
        content: Text(
          '"${resume.title}" will be permanently deleted. '
          "This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Not awaited: the list updates from the local cache immediately, while
    // the server write may wait for connectivity.
    service.deleteResume(userId, resume.resumeId).catchError((_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not delete that resume.')),
      );
    });
    messenger.showSnackBar(
      SnackBar(content: Text('Deleted "${resume.title}"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ResumeModel>>(
      stream: context.read<ResumeService>().watchResumes(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Could not load your resumes. Check your connection and try '
                'again.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final resumes = snapshot.data!;
        if (resumes.isEmpty) return _EmptyState(onCreate: onCreate);

        final now = DateTime.now();
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
          itemCount: resumes.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final resume = resumes[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(resume.accentColor),
                child: const Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                ),
              ),
              title: Text(
                resume.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                [
                  if (resume.targetRole.isNotEmpty) resume.targetRole,
                  'Edited ${describeEditedDate(resume.updatedAt, now)}',
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => onOpen(resume.resumeId),
              trailing: PopupMenuButton<_ResumeAction>(
                tooltip: 'More actions',
                onSelected: (action) => switch (action) {
                  _ResumeAction.duplicate => _duplicate(context, resume),
                  _ResumeAction.delete => _confirmAndDelete(context, resume),
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _ResumeAction.duplicate,
                    child: ListTile(
                      leading: Icon(Icons.copy_outlined),
                      title: Text('Duplicate'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _ResumeAction.delete,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Delete'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('No resumes yet', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Create your first resume. You can have AI write it with you or '
              'import it from LinkedIn.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create a resume'),
            ),
          ],
        ),
      ),
    );
  }
}
