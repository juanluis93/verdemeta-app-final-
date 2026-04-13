/// ═══════════════════════════════════════════════════
/// MAIN - VerdeMeta Flutter App
/// Punto de entrada de la aplicación
/// ═══════════════════════════════════════════════════
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database/database_helper.dart';
import 'presentation/screens/planificar_home_screen.dart';
import 'screens/login_screen.dart';
import 'services/daily_macro_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.initializeDatabaseFactory();
  await DailyMacroNotificationService.initialize();
  runApp(const ProviderScope(child: VerdeMeta()));
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
    final activeTrackColor =
        isDark ? const Color(0xFF5FB487) : const Color(0xFF2E8A5E);
    final inactiveTrackColor =
        isDark ? const Color(0xFF59655E) : const Color(0xFFB7BFB9);
    final inactiveThumbColor =
        isDark ? const Color(0xFFE5ECE8) : const Color(0xFF4E5A53);
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2e7d52),
      brightness: brightness,
    ).copyWith(
      surface: isDark ? const Color(0xFF1A2620) : Colors.white,
      onSurface: isDark ? Colors.white : const Color(0xFF1E3428),
      onSurfaceVariant:
          isDark ? const Color(0xFFF2F2F2) : const Color(0xFF4E6A5A),
      primary: const Color(0xFF2E8A5E),
      onPrimary: Colors.white,
      secondary: isDark ? const Color(0xFF7FD3A9) : const Color(0xFF2E8A5E),
      onSecondary: isDark ? const Color(0xFF102018) : Colors.white,
      onPrimaryContainer: isDark ? Colors.white : const Color(0xFF1E3428),
      onSecondaryContainer: isDark ? Colors.white : const Color(0xFF1E3428),
      outline: isDark ? const Color(0xFF355244) : const Color(0xFFD1E4D3),
    );

    final base = ThemeData(
      primarySwatch: Colors.green,
      primaryColor: const Color(0xFF2e7d52),
      fontFamily: 'PlusJakartaSans',
      useMaterial3: true,
      colorScheme: scheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF0E1511) : const Color(0xFFF4F8F3),
      textTheme: base.textTheme.apply(
        bodyColor: isDark ? Colors.white : scheme.onSurface,
        displayColor: isDark ? Colors.white : scheme.onSurface,
      ),
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : null,
      ),
      listTileTheme: ListTileThemeData(
        textColor: isDark ? Colors.white : null,
        iconColor: isDark ? Colors.white : null,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        shadowColor: isDark ? Colors.black.withValues(alpha: 0.35) : null,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF1C2922) : Colors.white,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF17231D) : Colors.white,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? const Color(0xFF1D2A23) : Colors.white,
        textStyle: TextStyle(color: scheme.onSurface),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return inactiveThumbColor;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return activeTrackColor;
          }
          return inactiveTrackColor;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF24352D) : const Color(0xFFF4F8F3),
        hintStyle: TextStyle(
          color: isDark ? Colors.white70 : const Color(0xFF6A8D76),
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF3D614D),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF355244) : const Color(0xFFD4E4D6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF4AA372), width: 1.4),
        ),
      ),
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
      routes: {
        '/planner-v2': (_) => const PlanificarHomeScreen(),
      },
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
