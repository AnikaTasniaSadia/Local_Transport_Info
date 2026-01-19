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

  static const Color _primary = Color(0xFF1B5E20);
  static const Color _primaryVariant = Color(0xFF2E7D32);
  static const Color _accent = Color(0xFF00897B);
  static const Color _background = Color(0xFFF9FAF9);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF263238);
  static const Color _textSecondary = Color(0xFF607D8B);

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: _primary,
          secondary: _accent,
          tertiary: _accent,
          surface: _card,
          background: _background,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: _textPrimary,
          onBackground: _textPrimary,
        );

    return MaterialApp(
      title: 'Local Transport Info',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _background,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: _textPrimary,
          displayColor: _textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: _card,
          elevation: 2,
          margin: EdgeInsets.zero,
          shadowColor: _textSecondary.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          labelStyle: const TextStyle(color: _textSecondary),
          hintStyle: const TextStyle(color: _textSecondary),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _background,
          indicatorColor: _primary.withOpacity(0.12),
          labelTextStyle: MaterialStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(MaterialState.selected)
                  ? _primary
                  : _textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconTheme: MaterialStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(MaterialState.selected)
                  ? _primary
                  : _textSecondary,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _card,
          selectedColor: _primary.withOpacity(0.12),
          secondarySelectedColor: _primary.withOpacity(0.12),
          labelStyle: const TextStyle(color: _textPrimary),
          secondaryLabelStyle: const TextStyle(color: _textPrimary),
          side: BorderSide(color: _textSecondary.withOpacity(0.3)),
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
