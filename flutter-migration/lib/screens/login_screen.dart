import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/food_repository.dart';
import 'home_screen.dart';
import 'profile_measurements_screen.dart';

class LoginScreen extends StatefulWidget {
  final Locale locale;
  final ValueChanged<Locale> onLanguageChanged;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const LoginScreen({
    super.key,
    required this.locale,
    required this.onLanguageChanged,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _AuthMode { login, register }

class _LoginScreenState extends State<LoginScreen> {
  static const _sessionUserIdKey = 'session_user_id';
  static const _loginBuildStamp = 'MANUAL-D-20260405';

  final FoodRepository _repo = FoodRepository();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  late Locale _currentLocale;
  late ThemeMode _currentThemeMode;

  bool _submitting = false;
  bool _restoringSession = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  _AuthMode _mode = _AuthMode.login;

  bool get _isSpanish => _currentLocale.languageCode == 'es';

  bool get _isRegisterMode => _mode == _AuthMode.register;

  String _t(String es, String en) => _isSpanish ? es : en;

  String get _headerDescription {
    if (_isRegisterMode) {
      return _t(
        'Crea tu cuenta local para comenzar a guardar tus mediciones y tus comidas.',
        'Create your local account to start saving your measurements and meals.',
      );
    }
    return _t(
      'Inicia sesión con tu usuario para continuar con tu progreso.',
      'Sign in with your account to continue your progress.',
    );
  }

  @override
  void initState() {
    super.initState();
    _currentLocale = widget.locale;
    _currentThemeMode = widget.themeMode;
    _restoreSession();
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locale != widget.locale) {
      _currentLocale = widget.locale;
    }
    if (oldWidget.themeMode != widget.themeMode) {
      _currentThemeMode = widget.themeMode;
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _switchAuthMode(_AuthMode nextMode) {
    if (_submitting || _mode == nextMode) return;

    setState(() {
      _mode = nextMode;
      _passwordCtrl.clear();
      _confirmPasswordCtrl.clear();
      _obscurePassword = true;
      _obscureConfirmPassword = true;
    });
  }

  Future<void> _openHome(FoodRepository scopedRepo) async {
    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          repository: scopedRepo,
          onLogoutRequested: _handleLogout,
          locale: _currentLocale,
          onLanguageChanged: widget.onLanguageChanged,
          themeMode: _currentThemeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
        ),
      ),
    );
  }

  Future<void> _persistSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionUserIdKey, userId);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionUserIdKey);
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getInt(_sessionUserIdKey);

      if (savedUserId == null) return;

      final account = await _repo.getUserById(savedUserId);
      if (account == null) {
        await _clearSession();
        return;
      }

      final scopedRepo = _repo.forUser(account);
      final hasProfile = await scopedRepo.hasUserProfile();
      if (!mounted) return;

      if (hasProfile) {
        await _openHome(scopedRepo);
        return;
      }

      if (!mounted) return;

      final result = await Navigator.of(context).push<dynamic>(
        MaterialPageRoute(
          builder: (_) => ProfileMeasurementsScreen(repository: scopedRepo),
        ),
      );

      final saved = switch (result) {
        true => true,
        {'saved': true} => true,
        _ => false,
      };

      if (!mounted) return;
      if (saved) {
        await _openHome(scopedRepo);
      }
    } catch (_) {
      await _clearSession();
    } finally {
      if (mounted) {
        setState(() => _restoringSession = false);
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    await _clearSession();
    if (!context.mounted) return;
    _passwordCtrl.clear();
    _confirmPasswordCtrl.clear();
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          locale: _currentLocale,
          onLanguageChanged: widget.onLanguageChanged,
          themeMode: _currentThemeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _openDisplaySettings() async {
    String selectedLanguage = _currentLocale.languageCode;
    bool darkMode = _currentThemeMode == ThemeMode.dark;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDarkSheet = Theme.of(context).brightness == Brightness.dark;
            const switchActiveTrack = Color(0xFF2E8A5E);
            final switchInactiveTrack =
                isDarkSheet ? const Color(0xFF6F7A74) : const Color(0xFFB9C4BE);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedLanguage == 'es' ? 'Apariencia' : 'Appearance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedLanguage,
                      decoration: InputDecoration(
                        labelText:
                            selectedLanguage == 'es' ? 'Idioma' : 'Language',
                        prefixIcon: const Icon(Icons.language_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'es',
                          child: Text('Español'),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text('English'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => selectedLanguage = value);
                        final nextLocale = value == 'es'
                            ? const Locale('es', 'ES')
                            : const Locale('en', 'US');

                        setState(() => _currentLocale = nextLocale);
                        widget.onLanguageChanged(nextLocale);
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.white,
                      activeTrackColor: switchActiveTrack,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: switchInactiveTrack,
                      title: Row(
                        children: [
                          Text(
                            darkMode ? '🌙' : '☀️',
                            style: const TextStyle(
                              fontSize: 18,
                              fontFamilyFallback: [
                                'Noto Color Emoji',
                                'Segoe UI Emoji',
                                'Apple Color Emoji',
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selectedLanguage == 'es'
                                ? 'Tema oscuro'
                                : 'Dark mode',
                          ),
                        ],
                      ),
                      value: darkMode,
                      onChanged: (value) {
                        setModalState(() => darkMode = value);
                        final nextMode =
                            value ? ThemeMode.dark : ThemeMode.light;

                        setState(() => _currentThemeMode = nextMode);
                        widget.onThemeModeChanged(nextMode);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();

    if (username.isEmpty ||
        password.isEmpty ||
        (_isRegisterMode && confirmPassword.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isRegisterMode
                ? _t(
                    'Completa usuario, contraseña y confirmación.',
                    'Complete username, password, and confirmation.',
                  )
                : _t(
                    'Ingresa usuario y contraseña para continuar.',
                    'Enter username and password to continue.',
                  ),
          ),
        ),
      );
      return;
    }

    if (_isRegisterMode && password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'La confirmación no coincide con la contraseña.',
              'Password confirmation does not match.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final account = _isRegisterMode
          ? await _repo.registerUser(username: username, password: password)
          : await _repo.loginUser(username: username, password: password);

      await _persistSession(account.id);

      final scopedRepo = _repo.forUser(account);
      final hasProfile = await scopedRepo.hasUserProfile();

      if (!mounted) return;

      if (_isRegisterMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'Cuenta creada. Completa tus mediciones para iniciar.',
                'Account created. Complete your measurements to start.',
              ),
            ),
          ),
        );
      }

      if (hasProfile) {
        await _openHome(scopedRepo);
        return;
      }

      final result = await Navigator.of(context).push<dynamic>(
        MaterialPageRoute(
          builder: (_) => ProfileMeasurementsScreen(repository: scopedRepo),
        ),
      );

      final saved = switch (result) {
        true => true,
        {'saved': true} => true,
        _ => false,
      };

      if (!mounted) return;

      if (saved == true) {
        await _openHome(scopedRepo);
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;

      final message = kIsWeb
          ? _t(
              'SQLite no esta disponible en la vista web. Prueba en Android o escritorio.',
              'SQLite is not available in web preview. Try Android or desktop.',
            )
          : _t(
              'No se pudo abrir la base local: $error',
              'Could not open the local database: $error',
            );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_restoringSession) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1B2722) : Colors.white;
    final pageColor =
        isDark ? const Color(0xFF0E1612) : const Color(0xFFF3F8F2);
    final fieldColor =
        isDark ? const Color(0xFF24332C) : const Color(0xFFF4F8F3);
    final infoColor =
        isDark ? const Color(0xFF22352B) : const Color(0xFFF8FCF8);
    final headingColor = isDark ? Colors.white : const Color(0xFF214734);
    final bodyColor = isDark ? Colors.white : const Color(0xFF6A8D76);

    return Scaffold(
      backgroundColor: pageColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? const Color(0x44000000)
                          : const Color(0x142E8A5E),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Transform.scale(
                              scale: 1.6,
                              alignment: Alignment.centerLeft,
                              child: Image.asset(
                                'assets/images/VerdeMeta - Iconografia.png',
                                fit: BoxFit.cover,
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _openDisplaySettings,
                          tooltip: _t('Idioma y tema', 'Language and theme'),
                          icon: const Icon(Icons.tune_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _t('Bienvenida a VerdeMeta', 'Welcome to VerdeMeta'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: headingColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A3A31)
                            : const Color(0xFFEAF7EE),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF476756)
                              : const Color(0xFFB8DABA),
                        ),
                      ),
                      child: Text(
                        'Build $_loginBuildStamp',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF2E8A5E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _headerDescription,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: bodyColor,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<_AuthMode>(
                      segments: [
                        ButtonSegment<_AuthMode>(
                          value: _AuthMode.login,
                          icon: const Icon(Icons.login_rounded),
                          label: Text(_t('Iniciar sesión', 'Sign in')),
                        ),
                        ButtonSegment<_AuthMode>(
                          value: _AuthMode.register,
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: Text(_t('Registrarse', 'Sign up')),
                        ),
                      ],
                      selected: {_mode},
                      showSelectedIcon: false,
                      onSelectionChanged: _submitting
                          ? null
                          : (selection) => _switchAuthMode(selection.first),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _usernameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: _t('Usuario o correo', 'Username or email'),
                        hintText: _t('Ejemplo: juan@email.com',
                            'Example: juan@email.com'),
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        filled: true,
                        fillColor: fieldColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: _isRegisterMode
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onSubmitted: (_) {
                        if (!_isRegisterMode) {
                          _submit();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: _t('Contraseña', 'Password'),
                        hintText: _t('Tu contraseña', 'Your password'),
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(
                                () => _obscurePassword = !_obscurePassword);
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                        filled: true,
                        fillColor: fieldColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (_isRegisterMode) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: _confirmPasswordCtrl,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText:
                              _t('Confirmar contraseña', 'Confirm password'),
                          hintText: _t(
                              'Repite tu contraseña', 'Repeat your password'),
                          prefixIcon: const Icon(Icons.verified_user_outlined),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                          ),
                          filled: true,
                          fillColor: fieldColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: infoColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF345744)
                              : const Color(0xFFD7EAD8),
                        ),
                      ),
                      child: Text(
                        _isRegisterMode
                            ? _t(
                                'La contraseña debe tener al menos 6 caracteres. Tus cuentas, mediciones y registros se guardan en SQLite local por usuario.',
                                'Password must have at least 6 characters. Your accounts, measurements, and logs are stored in local SQLite by user.',
                              )
                            : _t(
                                'Tus cuentas, mediciones y registros se guardan en SQLite local del dispositivo, separadas por usuario.',
                                'Your accounts, measurements, and logs are stored in local SQLite on this device, separated by user.',
                              ),
                        style: TextStyle(
                          fontSize: 12.5,
                          color:
                              isDark ? Colors.white : const Color(0xFF5A7B65),
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2E8A5E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isRegisterMode
                                    ? _t('Crear cuenta', 'Create account')
                                    : _t('Entrar', 'Sign in'),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: _submitting
                            ? null
                            : () => _switchAuthMode(
                                  _isRegisterMode
                                      ? _AuthMode.login
                                      : _AuthMode.register,
                                ),
                        child: Text(
                          _isRegisterMode
                              ? _t(
                                  '¿Ya tienes cuenta? Inicia sesión',
                                  'Already have an account? Sign in',
                                )
                              : _t(
                                  '¿No tienes cuenta? Regístrate',
                                  'No account yet? Sign up',
                                ),
                        ),
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
