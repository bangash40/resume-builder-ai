import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/resume_model.dart';
import '../models/template_model.dart';
import '../services/analytics_service.dart';
import '../services/pdf_service.dart';

const List<int> _kAccentColors = [
  0xFF6750A4, // purple (app default)
  0xFF1565C0, // blue
  0xFF2E7D32, // green
  0xFFB71C1C, // red
  0xFF00838F, // teal
  0xFFEF6C00, // orange
];

/// Shows the actual exported PDF, so the preview matches the export exactly
/// (PRD FR-7.2), with controls to switch template, accent color and font
/// (FR-5.2/5.3/5.4) and share or print the PDF (FR-7.3). Customization
/// changes are reported back via [onChanged] so the caller can persist them.
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
  late final PdfService _pdfService = context.read<PdfService>();

  // PdfPreview re-renders whenever this callback changes identity, so it is
  // only recreated when the resume's appearance changes, not on every build.
  late LayoutCallback _buildPdf = _pdfBuilderFor(_resume);

  LayoutCallback _pdfBuilderFor(ResumeModel resume) =>
      (_) => _pdfService.buildResumePdf(
        resume: resume,
        displayName: widget.displayName,
        contactEmail: widget.contactEmail,
      );

  void _logExport(String method) => context
      .read<AnalyticsService>()
      .logResumeExported(templateId: _resume.templateId, method: method);

  void _update(ResumeModel Function(ResumeModel) updater) {
    setState(() {
      _resume = updater(_resume);
      _buildPdf = _pdfBuilderFor(_resume);
    });
    widget.onChanged(_resume);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Preview & export')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: kResumeTemplates.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final template = kResumeTemplates[index];
                return Tooltip(
                  message: template.description,
                  child: ChoiceChip(
                    label: Text(template.name),
                    selected: template.templateId == _resume.templateId,
                    onSelected: (_) => _update(
                      (r) => r.copyWith(templateId: template.templateId),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final colorValue in _kAccentColors)
                        Semantics(
                          button: true,
                          selected: _resume.accentColor == colorValue,
                          label: 'Accent color',
                          child: GestureDetector(
                            onTap: () => _update(
                              (r) => r.copyWith(accentColor: colorValue),
                            ),
                            child: CircleAvatar(
                              radius: 14,
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
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _resume.fontFamily,
                  underline: const SizedBox(),
                  items: [
                    for (final font in PdfService.supportedFonts)
                      DropdownMenuItem(value: font, child: Text(font)),
                  ],
                  onChanged: (font) {
                    if (font != null) {
                      _update((r) => r.copyWith(fontFamily: font));
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: PdfPreview(
              build: _buildPdf,
              initialPageFormat: PdfPageFormat.a4,
              pdfFileName: PdfService.fileNameFor(_resume),
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              scrollViewDecoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
              ),
              onShared: (_) => _logExport('share'),
              onPrinted: (_) => _logExport('print'),
              onError: (_, _) => _PdfErrorView(
                onRetry: () =>
                    setState(() => _buildPdf = _pdfBuilderFor(_resume)),
              ),
              onPrintError: (context, _) => ScaffoldMessenger.of(context)
                  .showSnackBar(
                    const SnackBar(
                      content: Text("Couldn't print your resume. Try again."),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfErrorView extends StatelessWidget {
  const _PdfErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "We couldn't create your PDF. Your resume is safe. "
              'Please try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
