import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/resume_model.dart';

/// Renders a [ResumeModel] using the layout identified by its `templateId`,
/// styled with its chosen accent color and font (PRD FR-5.1/5.2/5.3).
class ResumeTemplateRenderer extends StatelessWidget {
  const ResumeTemplateRenderer({
    super.key,
    required this.resume,
    required this.displayName,
    required this.contactEmail,
  });

  final ResumeModel resume;
  final String displayName;
  final String contactEmail;

  @override
  Widget build(BuildContext context) {
    final accent = Color(resume.accentColor);
    switch (resume.templateId) {
      case 'modern':
        return _ModernLayout(
          resume: resume,
          displayName: displayName,
          contactEmail: contactEmail,
          accent: accent,
        );
      case 'minimal':
        return _MinimalLayout(
          resume: resume,
          displayName: displayName,
          contactEmail: contactEmail,
          accent: accent,
        );
      case 'compact':
        return _CompactLayout(
          resume: resume,
          displayName: displayName,
          contactEmail: contactEmail,
          accent: accent,
        );
      case 'classic':
      default:
        return _ClassicLayout(
          resume: resume,
          displayName: displayName,
          contactEmail: contactEmail,
          accent: accent,
        );
    }
  }
}

TextStyle _font(String family, TextStyle base) {
  try {
    return GoogleFonts.getFont(family, textStyle: base);
  } catch (_) {
    return base;
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text, {required this.accent, required this.font});

  final String text;
  final Color accent;
  final String font;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: _font(
          font,
          TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: accent,
          ),
        ),
      ),
    );
  }
}

class _ClassicLayout extends StatelessWidget {
  const _ClassicLayout({
    required this.resume,
    required this.displayName,
    required this.contactEmail,
    required this.accent,
  });

  final ResumeModel resume;
  final String displayName;
  final String contactEmail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayName,
            style: _font(
              resume.fontFamily,
              const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          if (contactEmail.isNotEmpty || resume.targetRole.isNotEmpty)
            Text(
              [
                if (resume.targetRole.isNotEmpty) resume.targetRole,
                if (contactEmail.isNotEmpty) contactEmail,
              ].join(' · '),
              style: _font(
                resume.fontFamily,
                const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
          if (resume.summary.isNotEmpty) ...[
            _SectionHeading('Summary', accent: accent, font: resume.fontFamily),
            Text(
              resume.summary,
              style: _font(
                resume.fontFamily,
                const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ],
          if (resume.experience.isNotEmpty) ...[
            _SectionHeading(
              'Experience',
              accent: accent,
              font: resume.fontFamily,
            ),
            for (final e in resume.experience) ...[
              Text(
                '${e.title} · ${e.company}',
                style: _font(
                  resume.fontFamily,
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${e.startDate} - ${e.endDate}',
                style: _font(
                  resume.fontFamily,
                  const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
              for (final b in e.bullets)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 2),
                  child: Text(
                    '•  $b',
                    style: _font(
                      resume.fontFamily,
                      const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ],
          if (resume.education.isNotEmpty) ...[
            _SectionHeading(
              'Education',
              accent: accent,
              font: resume.fontFamily,
            ),
            for (final ed in resume.education)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${ed.degree} · ${ed.institution} (${ed.startDate} - ${ed.endDate})',
                  style: _font(
                    resume.fontFamily,
                    const TextStyle(fontSize: 13),
                  ),
                ),
              ),
          ],
          if (resume.skills.isNotEmpty) ...[
            _SectionHeading('Skills', accent: accent, font: resume.fontFamily),
            Text(
              resume.skills.join(' · '),
              style: _font(resume.fontFamily, const TextStyle(fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModernLayout extends StatelessWidget {
  const _ModernLayout({
    required this.resume,
    required this.displayName,
    required this.contactEmail,
    required this.accent,
  });

  final ResumeModel resume;
  final String displayName;
  final String contactEmail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: accent,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: _font(
                    resume.fontFamily,
                    const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (resume.targetRole.isNotEmpty)
                  Text(
                    resume.targetRole,
                    style: _font(
                      resume.fontFamily,
                      const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ),
                if (contactEmail.isNotEmpty)
                  Text(
                    contactEmail,
                    style: _font(
                      resume.fontFamily,
                      const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (resume.summary.isNotEmpty) ...[
                  _SectionHeading(
                    'Summary',
                    accent: accent,
                    font: resume.fontFamily,
                  ),
                  Text(
                    resume.summary,
                    style: _font(
                      resume.fontFamily,
                      const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
                if (resume.experience.isNotEmpty) ...[
                  _SectionHeading(
                    'Experience',
                    accent: accent,
                    font: resume.fontFamily,
                  ),
                  for (final e in resume.experience) ...[
                    Text(
                      '${e.title} · ${e.company}',
                      style: _font(
                        resume.fontFamily,
                        const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${e.startDate} - ${e.endDate}',
                      style: _font(
                        resume.fontFamily,
                        const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                    for (final b in e.bullets)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 2),
                        child: Text(
                          '•  $b',
                          style: _font(
                            resume.fontFamily,
                            const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ],
                if (resume.education.isNotEmpty) ...[
                  _SectionHeading(
                    'Education',
                    accent: accent,
                    font: resume.fontFamily,
                  ),
                  for (final ed in resume.education)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${ed.degree} · ${ed.institution} (${ed.startDate} - ${ed.endDate})',
                        style: _font(
                          resume.fontFamily,
                          const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                ],
                if (resume.skills.isNotEmpty) ...[
                  _SectionHeading(
                    'Skills',
                    accent: accent,
                    font: resume.fontFamily,
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in resume.skills)
                        Chip(
                          label: Text(s, style: const TextStyle(fontSize: 11)),
                          backgroundColor: accent.withValues(alpha: 0.1),
                          side: BorderSide(
                            color: accent.withValues(alpha: 0.3),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalLayout extends StatelessWidget {
  const _MinimalLayout({
    required this.resume,
    required this.displayName,
    required this.contactEmail,
    required this.accent,
  });

  final ResumeModel resume;
  final String displayName;
  final String contactEmail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            displayName,
            style: _font(
              resume.fontFamily,
              const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (resume.targetRole.isNotEmpty) resume.targetRole,
              if (contactEmail.isNotEmpty) contactEmail,
            ].join('   |   '),
            style: _font(
              resume.fontFamily,
              TextStyle(fontSize: 12, color: accent),
            ),
          ),
          const Divider(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (resume.summary.isNotEmpty) ...[
                  _SectionHeading(
                    'Summary',
                    accent: accent,
                    font: resume.fontFamily,
                  ),
                  Text(
                    resume.summary,
                    style: _font(
                      resume.fontFamily,
                      const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
                if (resume.experience.isNotEmpty) ...[
                  _SectionHeading(
                    'Experience',
                    accent: accent,
                    font: resume.fontFamily,
                  ),
                  for (final e in resume.experience) ...[
                    Text(
                      '${e.title}, ${e.company}',
                      style: _font(
                        resume.fontFamily,
                        const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${e.startDate} – ${e.endDate}',
                      style: _font(
                        resume.fontFamily,
                        const TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ),
                    for (final b in e.bullets)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          b,
                          style: _font(
                            resume.fontFamily,
                            const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                  ],
                ],
                if (resume.education.isNotEmpty) ...[
                  _SectionHeading(
                    'Education',
                    accent: accent,
                    font: resume.fontFamily,
                  ),
                  for (final ed in resume.education)
                    Text(
                      '${ed.degree}, ${ed.institution}',
                      style: _font(
                        resume.fontFamily,
                        const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
                if (resume.skills.isNotEmpty) ...[
                  _SectionHeading(
                    'Skills',
                    accent: accent,
                    font: resume.fontFamily,
                  ),
                  Text(
                    resume.skills.join('  ·  '),
                    style: _font(
                      resume.fontFamily,
                      const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({
    required this.resume,
    required this.displayName,
    required this.contactEmail,
    required this.accent,
  });

  final ResumeModel resume;
  final String displayName;
  final String contactEmail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: _font(
                    resume.fontFamily,
                    TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ),
              ),
              if (contactEmail.isNotEmpty && contactEmail != displayName) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    contactEmail,
                    textAlign: TextAlign.end,
                    style: _font(
                      resume.fontFamily,
                      const TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (resume.targetRole.isNotEmpty)
            Text(
              resume.targetRole,
              style: _font(
                resume.fontFamily,
                const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          const Divider(height: 12),
          if (resume.summary.isNotEmpty)
            Text(
              resume.summary,
              style: _font(
                resume.fontFamily,
                const TextStyle(fontSize: 11, height: 1.3),
              ),
            ),
          if (resume.experience.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'EXPERIENCE',
              style: _font(
                resume.fontFamily,
                TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ),
            for (final e in resume.experience)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${e.title}, ${e.company} (${e.startDate}-${e.endDate}): ${e.bullets.join('; ')}',
                  style: _font(
                    resume.fontFamily,
                    const TextStyle(fontSize: 10.5),
                  ),
                ),
              ),
          ],
          if (resume.education.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'EDUCATION',
              style: _font(
                resume.fontFamily,
                TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ),
            for (final ed in resume.education)
              Text(
                '${ed.degree}, ${ed.institution}',
                style: _font(
                  resume.fontFamily,
                  const TextStyle(fontSize: 10.5),
                ),
              ),
          ],
          if (resume.skills.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'SKILLS',
              style: _font(
                resume.fontFamily,
                TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ),
            Text(
              resume.skills.join(', '),
              style: _font(resume.fontFamily, const TextStyle(fontSize: 10.5)),
            ),
          ],
        ],
      ),
    );
  }
}
