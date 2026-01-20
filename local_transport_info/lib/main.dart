import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/root_screen.dart';
import 'supabase/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final startupErrors = <String>[];
  String? startupWarning;

  try {
    SupabaseConfig.assertValid();
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    final message = 'Supabase initialize() failed: $e';
    startupErrors.add(message);
    debugPrint(message);
  }

  final String? startupError = startupErrors.isEmpty
      ? null
      : startupErrors.join('\n\n');

  runApp(
    LocalTransportInfoApp(
      startupError: startupError,
      startupWarning: startupWarning,
    ),
  );
}

class LocalTransportInfoApp extends StatelessWidget {
  const LocalTransportInfoApp({
    super.key,
    this.startupError,
    this.startupWarning,
  });

  final String? startupError;
  final String? startupWarning;

  static const Color _primary = Color(0xFF00A86B);
  static const Color _secondary = Color(0xFF1E3A8A);
  static const Color _accentBlue = Color(0xFF38BDF8);
  static const Color _accentAmber = Color(0xFFF59E0B);
  static const Color _accentCoral = Color(0xFFFB7185);
  static const Color _background = Color(0xFFF8FAFC);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme(
          brightness: Brightness.light,
          primary: _primary,
          onPrimary: Colors.white,
          secondary: _secondary,
          onSecondary: Colors.white,
          tertiary: _accentBlue,
          onTertiary: Colors.white,
          error: const Color(0xFFEF4444),
          onError: Colors.white,
          surface: _card,
          onSurface: _textPrimary,
        ).copyWith(
          surfaceContainerHighest: _background,
          outline: _textSecondary.withValues(alpha: 0.4),
          outlineVariant: _textSecondary.withValues(alpha: 0.25),
        );

    return MaterialApp(
      title: 'Local Transport Info',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        splashFactory: InkSparkle.splashFactory,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
        scaffoldBackgroundColor: _background,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: _textPrimary,
          displayColor: _textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _card,
          foregroundColor: _textPrimary,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: _card,
          elevation: 2,
          margin: EdgeInsets.zero,
          shadowColor: _textSecondary.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: _textSecondary.withValues(alpha: 0.25),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: _textSecondary.withValues(alpha: 0.18),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _primary, width: 1.4),
          ),
          labelStyle: const TextStyle(color: _textSecondary),
          hintStyle: const TextStyle(color: _textSecondary),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style:
              FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.pressed)
                      ? _primary.withValues(alpha: 0.12)
                      : null,
                ),
              ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.pressed)
                  ? _primary.withValues(alpha: 0.12)
                  : null,
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _background,
          indicatorColor: _primary.withValues(alpha: 0.15),
          indicatorShape: const StadiumBorder(),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? _primary
                  : _textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? _primary
                  : _textSecondary,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _card,
          selectedColor: _primary.withValues(alpha: 0.12),
          secondarySelectedColor: _primary.withValues(alpha: 0.12),
          labelStyle: const TextStyle(color: _textPrimary),
          secondaryLabelStyle: const TextStyle(color: _textPrimary),
          side: BorderSide(color: _textSecondary.withValues(alpha: 0.22)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: startupError == null
          ? RootScreen(startupWarning: startupWarning)
          : _StartupErrorScreen(message: startupError!),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outlineVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Startup Error')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App failed to start',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Common fixes:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1) Run with Supabase credentials using --dart-define\n'
                      '   or --dart-define-from-file=supabase.env.json\n'
                      '2) If running on Web, ensure your Supabase URL/key are correct',
                    ),
                    const SizedBox(height: 14),
                    if (kIsWeb)
                      Text(
                        'Tip: Open DevTools Console for details.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
