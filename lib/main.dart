import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'utils/perf_diagnostics.dart';

void main() async {
  final bootstrapTrace = PerfDiagnostics.startTrace('app_bootstrap');
  bootstrapTrace.mark('main_entered');
  WidgetsFlutterBinding.ensureInitialized();
  bootstrapTrace.mark('bindings_ready');

  await bootstrapTrace.measureAsync('supabase_initialize', () async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  });

  bootstrapTrace.mark(
    'run_app',
    data: {'sinceAppStartMs': PerfDiagnostics.appStart.elapsedMilliseconds},
  );
  runApp(const MyApp());
  bootstrapTrace.finish();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static bool _loggedFirstBuild = false;

  @override
  Widget build(BuildContext context) {
    if (!_loggedFirstBuild) {
      _loggedFirstBuild = true;
      PerfDiagnostics.log(
        'app_bootstrap',
        'material_app_built',
        data: {'sinceAppStartMs': PerfDiagnostics.appStart.elapsedMilliseconds},
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PerfDiagnostics.log(
          'app_bootstrap',
          'first_frame',
          data: {'sinceAppStartMs': PerfDiagnostics.appStart.elapsedMilliseconds},
        );
      });
    }

    return MaterialApp(
      title: 'Qr Asistencia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppTheme.bg,
        colorScheme: ColorScheme.light(
          primary: AppTheme.primary,
          secondary: AppTheme.accent2,
          surface: AppTheme.surface,
          error: AppTheme.error,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme)
            .apply(
              bodyColor: AppTheme.textPrimary,
              displayColor: AppTheme.textPrimary,
            ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppTheme.primaryButton,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppTheme.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
