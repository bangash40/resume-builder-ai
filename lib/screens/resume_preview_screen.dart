import 'package:flutter/material.dart';

import '../models/resume_model.dart';
import '../models/template_model.dart';
import '../widgets/resume_template_renderer.dart';

const List<int> _kAccentColors = [
  0xFF6750A4, // purple (app default)
  0xFF1565C0, // blue
  0xFF2E7D32, // green
  0xFFB71C1C, // red
  0xFF00838F, // teal
  0xFFEF6C00, // orange
];

const List<String> _kFontFamilies = [
  'Roboto',
  'Merriweather',
  'Poppins',
  'Roboto Mono',
];

/// Live preview of the resume in its selected template, with controls to
/// switch template, accent color, and font (PRD FR-5.2/5.3/5.4). Changes are
/// reported back via [onChanged] so the caller can persist them.
class ResumePreviewScreen extends StatefulWidget {
  const ResumePreviewScreen({
    super.key,
    required this.initialResume,
    required this.displayName,
    required this.contactEmail,
    required this.onChanged,
  });

  final ResumeModel initialResume;
  final String displayName;
  final String contactEmail;
  final ValueChanged<ResumeModel> onChanged;

  @override
  State<ResumePreviewScreen> createState() => _ResumePreviewScreenState();
}

class _ResumePreviewScreenState extends State<ResumePreviewScreen> {
  late ResumeModel _resume = widget.initialResume;

  void _update(ResumeModel Function(ResumeModel) updater) {
    setState(() => _resume = updater(_resume));
    widget.onChanged(_resume);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Template', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kResumeTemplates.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final template = kResumeTemplates[index];
                final selected = template.templateId == _resume.templateId;
                return _TemplateCard(
                  template: template,
                  selected: selected,
                  onTap: () => _update(
                    (r) => r.copyWith(templateId: template.templateId),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text('Accent color', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final colorValue in _kAccentColors)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () =>
                        _update((r) => r.copyWith(accentColor: colorValue)),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(colorValue),
                      child: _resume.accentColor == colorValue
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Font', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: _resume.fontFamily,
            isExpanded: true,
            items: [
              for (final font in _kFontFamilies)
                DropdownMenuItem(value: font, child: Text(font)),
            ],
            onChanged: (font) {
              if (font != null) _update((r) => r.copyWith(fontFamily: font));
            },
          ),
          const SizedBox(height: 20),
          Text('Preview', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ResumeTemplateRenderer(
              resume: _resume,
              displayName: widget.displayName,
              contactEmail: widget.contactEmail,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final TemplateModel template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: selected ? colorScheme.primary.withValues(alpha: 0.08) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.name, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            // Expanded so the description truncates within the card's fixed
            // height instead of overflowing at larger system font sizes.
            Expanded(
              child: Text(
                template.description,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.fade,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
