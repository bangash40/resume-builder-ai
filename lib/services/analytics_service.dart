import 'package:firebase_analytics/firebase_analytics.dart';

/// Logs the usage events behind the PRD's success metrics (§10): sign-ups and
/// logins (retention), resumes created and exported (completion rate), and
/// AI feature use (regeneration rate). Failures are swallowed so analytics
/// can never break the app.
class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics}) : _injected = analytics;

  final FirebaseAnalytics? _injected;

  // Resolved lazily so constructing the service doesn't require Firebase.
  FirebaseAnalytics get _analytics => _injected ?? FirebaseAnalytics.instance;

  Future<void> logLogin(String method) =>
      _safely(() => _analytics.logLogin(loginMethod: method));

  Future<void> logSignUp(String method) =>
      _safely(() => _analytics.logSignUp(signUpMethod: method));

  Future<void> logResumeCreated() =>
      _safely(() => _analytics.logEvent(name: 'resume_created'));

  /// [feature] is `summary`, `bullets` or `skills`.
  Future<void> logAiGenerated(String feature) => _safely(
    () => _analytics.logEvent(
      name: 'ai_generated',
      parameters: {'feature': feature},
    ),
  );

  Future<void> logLinkedInImport({required int sectionCount}) => _safely(
    () => _analytics.logEvent(
      name: 'linkedin_imported',
      parameters: {'section_count': sectionCount},
    ),
  );

  /// [method] is `share` or `print`.
  Future<void> logResumeExported({
    required String templateId,
    required String method,
  }) => _safely(
    () => _analytics.logEvent(
      name: 'resume_exported',
      parameters: {'template': templateId, 'method': method},
    ),
  );

  Future<void> _safely(Future<void> Function() log) async {
    try {
      await log();
    } catch (_) {}
  }
}
