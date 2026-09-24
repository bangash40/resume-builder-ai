class TemplateModel {
  const TemplateModel({
    required this.templateId,
    required this.name,
    required this.description,
    this.isPremium = false,
  });

  final String templateId;
  final String name;
  final String description;
  final bool isPremium;
}

/// The resume templates available in v1.0 (PRD FR-5.1: at least 4
/// pre-designed templates). Layouts are implemented as widgets in
/// `resume_template_renderer.dart`, keyed by `templateId`.
const List<TemplateModel> kResumeTemplates = [
  TemplateModel(
    templateId: 'classic',
    name: 'Classic',
    description: 'Traditional single-column layout with clear section headers.',
  ),
  TemplateModel(
    templateId: 'modern',
    name: 'Modern',
    description: 'Bold accent-colored header with a clean, contemporary feel.',
  ),
  TemplateModel(
    templateId: 'minimal',
    name: 'Minimal',
    description: 'Understated typography with generous whitespace.',
  ),
  TemplateModel(
    templateId: 'compact',
    name: 'Compact',
    description: 'Dense layout that fits more content on a single page.',
  ),
];
