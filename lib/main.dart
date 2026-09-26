import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'services/ai_service.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/pdf_service.dart';
import 'services/resume_service.dart';
import 'widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _setUpCrashReporting();
  runApp(MainApp(isOnline: networkStatusStream()));
}

/// Sends uncaught Flutter and platform errors to Crashlytics. Collection is
/// off in debug builds so development crashes don't pollute the reports.
Future<void> _setUpCrashReporting() async {
  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
}

/// The bundled resume fonts are under the SIL Open Font License, which must
/// ship with them. This lists them in Flutter's license page.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final family in PdfService.supportedFonts) {
      final file = family.replaceAll(' ', '');
      final text = await rootBundle.loadString('assets/fonts/$file-OFL.txt');
      yield LicenseEntryWithLineBreaks([family], text);
    }
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key, required this.isOnline});

  final Stream<bool> isOnline;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ResumeService>(create: (_) => ResumeService()),
        Provider<AiService>(create: (_) => AiService()),
        Provider<PdfService>(create: (_) => PdfService()),
        Provider<AnalyticsService>(create: (_) => AnalyticsService()),
      ],
      child: MaterialApp(
        home: const AuthGate(),
        builder: (context, child) =>
            OfflineBanner(isOnline: isOnline, child: child!),
      ),
    );
  }
}
