import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/resume_model.dart';

/// Renders a resume to an A4 PDF in its selected template, accent color and
/// font. The on-screen preview displays this same PDF, so what the user sees
/// is exactly what they export (PRD FR-7.1/7.2).
class PdfService {
  static const supportedFonts = [
    'Roboto',
    'Merriweather',
    'Poppins',
    'Roboto Mono',
  ];

  Future<Uint8List> buildResumePdf({
    required ResumeModel resume,
    required String displayName,
    required String contactEmail,
  }) async {
    final theme = await _loadTheme(resume.fontFamily);
    final data = _ResumeData(
      resume: resume,
      name: displayName,
      email: contactEmail,
      accent: PdfColor.fromInt(resume.accentColor),
    );

    final doc = pw.Document(title: resume.title, author: displayName);
    switch (resume.templateId) {
      case 'modern':
        _addModern(doc, theme, data);
      case 'minimal':
        _addMinimal(doc, theme, data);
      case 'compact':
        _addCompact(doc, theme, data);
      case 'classic':
      default:
        _addClassic(doc, theme, data);
    }
    return doc.save();
  }

  /// A safe file name for sharing, based on the resume title.
  static String fileNameFor(ResumeModel resume) {
    final cleaned = resume.title
        .replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    return '${cleaned.isEmpty ? 'Resume' : cleaned}.pdf';
  }

  Future<pw.ThemeData> _loadTheme(String family) async {
    final prefix = (supportedFonts.contains(family) ? family : 'Roboto')
        .replaceAll(' ', '');
    final regular = await rootBundle.load('assets/fonts/$prefix-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/$prefix-Bold.ttf');
    return pw.ThemeData.withFont(
      base: pw.Font.ttf(regular),
      bold: pw.Font.ttf(bold),
    );
  }

  void _addClassic(pw.Document doc, pw.ThemeData theme, _ResumeData d) {
    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (_) => [
          pw.Text(d.name, style: _bold(24, PdfColors.grey900)),
          if (d.subtitle(' · ').isNotEmpty)
            pw.Text(d.subtitle(' · '), style: _regular(10, PdfColors.grey700)),
          ..._standardSections(d, bulletIndent: 10),
        ],
      ),
    );
  }

  void _addModern(pw.Document doc, pw.ThemeData theme, _ResumeData d) {
    const side = 40.0;
    pw.Widget padded(pw.Widget child) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: side),
      child: child,
    );

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        // The header band is full-bleed, so page margins are added manually.
        header: (ctx) =>
            ctx.pageNumber > 1 ? pw.SizedBox(height: side) : pw.SizedBox(),
        footer: (_) => pw.SizedBox(height: side),
        build: (_) => [
          pw.Container(
            width: double.infinity,
            color: d.accent,
            padding: const pw.EdgeInsets.fromLTRB(side, 32, side, 24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(d.name, style: _bold(26, PdfColors.white)),
                if (d.resume.targetRole.isNotEmpty)
                  pw.Text(
                    d.resume.targetRole,
                    style: _regular(12, _tint(d.accent, 0.8)),
                  ),
                if (d.email.isNotEmpty)
                  pw.Text(d.email, style: _regular(10, _tint(d.accent, 0.8))),
              ],
            ),
          ),
          for (final w in _standardSections(
            d,
            bulletIndent: 10,
            skillsAsChips: true,
          ))
            padded(w),
        ],
      ),
    );
  }

  void _addMinimal(pw.Document doc, pw.ThemeData theme, _ResumeData d) {
    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (_) => [
          pw.Center(
            child: pw.Text(
              d.name,
              style: _regular(22, PdfColors.grey900, letterSpacing: 1),
            ),
          ),
          if (d.subtitle('   |   ').isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Center(
                child: pw.Text(
                  d.subtitle('   |   '),
                  style: _regular(10, d.accent),
                ),
              ),
            ),
          pw.Divider(height: 28, color: PdfColors.grey300),
          ..._standardSections(d, bulletIndent: 0, bulletPrefix: ''),
        ],
      ),
    );
  }

  void _addCompact(pw.Document doc, pw.ThemeData theme, _ResumeData d) {
    pw.Widget heading(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8, bottom: 2),
      child: pw.Text(text, style: _bold(9, d.accent)),
    );
    final body = _regular(9.5, PdfColors.grey900);

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: pw.Text(d.name, style: _bold(16, d.accent))),
              if (d.email.isNotEmpty && d.email != d.name) ...[
                pw.SizedBox(width: 8),
                pw.Flexible(
                  child: pw.Text(
                    d.email,
                    textAlign: pw.TextAlign.right,
                    style: _regular(9, PdfColors.grey700),
                  ),
                ),
              ],
            ],
          ),
          if (d.resume.targetRole.isNotEmpty)
            pw.Text(
              d.resume.targetRole,
              style: _regular(10, PdfColors.grey700),
            ),
          pw.Divider(height: 12, color: PdfColors.grey400),
          if (d.resume.summary.isNotEmpty)
            pw.Text(d.resume.summary, style: body.copyWith(lineSpacing: 1.5)),
          if (d.resume.experience.isNotEmpty) ...[
            heading('EXPERIENCE'),
            for (final e in d.resume.experience)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(
                  '${e.title}, ${e.company} (${d.dates(e.startDate, e.endDate)})'
                  '${e.bullets.isEmpty ? '' : ': ${e.bullets.join('; ')}'}',
                  style: body,
                ),
              ),
          ],
          if (d.resume.education.isNotEmpty) ...[
            heading('EDUCATION'),
            for (final ed in d.resume.education)
              pw.Text('${ed.degree}, ${ed.institution}', style: body),
          ],
          if (d.resume.skills.isNotEmpty) ...[
            heading('SKILLS'),
            pw.Text(d.resume.skills.join(', '), style: body),
          ],
        ],
      ),
    );
  }

  /// Summary, experience, education and skills, shared by the Classic,
  /// Modern and Minimal templates. Returned as separate widgets so
  /// [pw.MultiPage] can break pages between them.
  List<pw.Widget> _standardSections(
    _ResumeData d, {
    required double bulletIndent,
    String bulletPrefix = '•  ',
    bool skillsAsChips = false,
  }) {
    final r = d.resume;
    final body = _regular(10.5, PdfColors.grey900);
    final muted = _regular(9.5, PdfColors.grey600);

    pw.Widget heading(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
      child: pw.Text(
        text.toUpperCase(),
        style: _bold(10.5, d.accent, letterSpacing: 1.2),
      ),
    );

    return [
      if (r.summary.isNotEmpty) ...[
        heading('Summary'),
        pw.Text(r.summary, style: body.copyWith(lineSpacing: 2)),
      ],
      if (r.experience.isNotEmpty) ...[
        heading('Experience'),
        for (final e in r.experience) ...[
          pw.Text(
            '${e.title} · ${e.company}',
            style: _bold(11, PdfColors.grey900),
          ),
          if (d.dates(e.startDate, e.endDate).isNotEmpty)
            pw.Text(d.dates(e.startDate, e.endDate), style: muted),
          for (final b in e.bullets)
            pw.Padding(
              padding: pw.EdgeInsets.only(left: bulletIndent, top: 2),
              child: pw.Text('$bulletPrefix$b', style: body),
            ),
          pw.SizedBox(height: 8),
        ],
      ],
      if (r.education.isNotEmpty) ...[
        heading('Education'),
        for (final ed in r.education)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              [
                '${ed.degree} · ${ed.institution}',
                if (d.dates(ed.startDate, ed.endDate).isNotEmpty)
                  '(${d.dates(ed.startDate, ed.endDate)})',
              ].join(' '),
              style: body,
            ),
          ),
      ],
      if (r.skills.isNotEmpty) ...[
        heading('Skills'),
        if (skillsAsChips)
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in r.skills)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: pw.BoxDecoration(
                    color: _tint(d.accent, 0.9),
                    border: pw.Border.all(color: _tint(d.accent, 0.6)),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Text(s, style: _regular(9.5, PdfColors.grey900)),
                ),
            ],
          )
        else
          pw.Text(r.skills.join(' · '), style: body),
      ],
    ];
  }

  static pw.TextStyle _regular(
    double size,
    PdfColor color, {
    double? letterSpacing,
  }) => pw.TextStyle(
    fontSize: size,
    color: color,
    fontWeight: pw.FontWeight.normal,
    letterSpacing: letterSpacing,
  );

  static pw.TextStyle _bold(
    double size,
    PdfColor color, {
    double? letterSpacing,
  }) => pw.TextStyle(
    fontSize: size,
    color: color,
    fontWeight: pw.FontWeight.bold,
    letterSpacing: letterSpacing,
  );

  /// Mixes [color] toward white by [amount] (0 = unchanged, 1 = white).
  /// Used instead of transparency, which PDF viewers render inconsistently.
  static PdfColor _tint(PdfColor color, double amount) => PdfColor(
    color.red + (1 - color.red) * amount,
    color.green + (1 - color.green) * amount,
    color.blue + (1 - color.blue) * amount,
  );
}

class _ResumeData {
  const _ResumeData({
    required this.resume,
    required this.name,
    required this.email,
    required this.accent,
  });

  final ResumeModel resume;
  final String name;
  final String email;
  final PdfColor accent;

  String subtitle(String separator) => [
    if (resume.targetRole.isNotEmpty) resume.targetRole,
    if (email.isNotEmpty && email != name) email,
  ].join(separator);

  String dates(String start, String end) =>
      [start, end].where((s) => s.isNotEmpty).join(' - ');
}
