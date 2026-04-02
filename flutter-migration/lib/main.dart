/// ═══════════════════════════════════════════════════
/// MAIN - VerdeMeta Flutter App
/// Punto de entrada de la aplicación
/// ═══════════════════════════════════════════════════
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database/database_helper.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.initializeDatabaseFactory();
  runApp(const VerdeMeta());
}

class VerdeMeta extends StatefulWidget {
  const VerdeMeta({super.key});

  @override
  State<VerdeMeta> createState() => _VerdeMetaState();
}

class _VerdeMetaState extends State<VerdeMeta> {
  static const _localeCodeKey = 'app_locale_code';
  static const _themeModeKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('es', 'ES');

  @override
  void initState() {
    super.initState();
    _restoreDisplayPreferences();
  }

  Future<void> _restoreDisplayPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocaleCode = prefs.getString(_localeCodeKey);
    final savedThemeMode = prefs.getString(_themeModeKey);

    final restoredLocale = savedLocaleCode == 'en'
        ? const Locale('en', 'US')
        : const Locale('es', 'ES');

    final restoredThemeMode = savedThemeMode == ThemeMode.dark.name
        ? ThemeMode.dark
        : ThemeMode.light;

    if (!mounted) return;
    setState(() {
      _locale = restoredLocale;
      _themeMode = restoredThemeMode;
    });
  }

  void _setLocale(Locale locale) {
    final normalized = locale.languageCode == 'es'
        ? const Locale('es', 'ES')
        : const Locale('en', 'US');

    if (_locale == normalized) return;
    setState(() => _locale = normalized);
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString(_localeCodeKey, normalized.languageCode),
    );
  }

  void _setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    setState(() => _themeMode = mode);
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString(_themeModeKey, mode.name),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      primarySwatch: Colors.green,
      primaryColor: const Color(0xFF2e7d52),
      fontFamily: 'PlusJakartaSans',
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2e7d52),
        brightness: brightness,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF0E1511) : const Color(0xFFF4F8F3),
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? const Color(0xFF284736) : const Color(0xFF2E8A5E),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VerdeMeta',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: _themeMode,
      home: LoginScreen(
        locale: _locale,
        onLanguageChanged: _setLocale,
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
