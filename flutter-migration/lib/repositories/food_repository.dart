// ═══════════════════════════════════════════════════
// FOOD REPOSITORY
// Servicio para operaciones de alimentos, login y datos por usuario
// ═══════════════════════════════════════════════════

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/food_models.dart';

class AuthException implements Exception {
  final String code;
  final String message;

  const AuthException(this.code, this.message);

  @override
  String toString() => message;
}

class FoodRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final int? currentUserId;
  final String? currentUsername;

  FoodRepository({this.currentUserId, this.currentUsername});

  FoodRepository forUser(UserAccount account) {
    return FoodRepository(
      currentUserId: account.id,
      currentUsername: account.username,
    );
  }

  int get _requiredUserId {
    final userId = currentUserId;
    if (userId == null) {
      throw StateError('No hay un usuario autenticado en este repositorio.');
    }
    return userId;
  }

  String _dateKey(DateTime date) => date.toIso8601String().split('T')[0];

  double _asDouble(dynamic value) => (value as num?)?.toDouble() ?? 0;

  int _asInt(dynamic value) => (value as num?)?.toInt() ?? 0;

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  void _ensureCredentialsPresent(String username, String password) {
    if (username.isEmpty || password.isEmpty) {
      throw const AuthException(
        'missing-credentials',
        'Ingresa usuario y contraseña para continuar.',
      );
    }
  }

  Future<bool> _tableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  Future<bool> _columnExists(
    Database db,
    String tableName,
    String columnName,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    return columns.any((column) => column['name'] == columnName);
  }

  Future<void> _upsertDailySummary(
    DatabaseExecutor executor, {
    required int userId,
    required String date,
    required int closedAt,
  }) async {
    final totalsRows = await executor.rawQuery(
      '''
      SELECT
        COUNT(*) AS meal_count,
        COALESCE(SUM(calories), 0) AS calories,
        COALESCE(SUM(protein), 0) AS protein,
        COALESCE(SUM(carbs), 0) AS carbs,
        COALESCE(SUM(fat), 0) AS fat,
        COALESCE(SUM(fiber), 0) AS fiber,
        COALESCE(SUM(sugar), 0) AS sugar,
        COALESCE(SUM(iron), 0) AS iron,
        COALESCE(SUM(calcium), 0) AS calcium,
        COALESCE(SUM(b12), 0) AS b12,
        COALESCE(SUM(zinc), 0) AS zinc
      FROM food_log
      WHERE user_id = ? AND date = ?
      ''',
      [userId, date],
    );

    final totals = totalsRows.first;
    final waterRows = await executor.query(
      'water_log',
      columns: ['cups'],
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
      limit: 1,
    );
    final waterCups = waterRows.isEmpty ? 0 : _asInt(waterRows.first['cups']);

    await executor.insert(
      'daily_summaries',
      {
        'user_id': userId,
        'date': date,
        'calories': _asDouble(totals['calories']),
        'protein': _asDouble(totals['protein']),
        'carbs': _asDouble(totals['carbs']),
        'fat': _asDouble(totals['fat']),
        'fiber': _asDouble(totals['fiber']),
        'sugar': _asDouble(totals['sugar']),
        'iron': _asDouble(totals['iron']),
        'calcium': _asDouble(totals['calcium']),
        'b12': _asDouble(totals['b12']),
        'zinc': _asDouble(totals['zinc']),
        'meal_count': _asInt(totals['meal_count']),
        'water_cups': waterCups,
        'closed_at': closedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> ensureDailyRollover({String? todayKey}) async {
    final db = await _dbHelper.database;
    final userId = _requiredUserId;
    final today = todayKey ?? _dateKey(DateTime.now());
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await db.transaction((txn) async {
      final rows = await txn.query(
        'user_daily_state',
        columns: ['last_active_date'],
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (rows.isEmpty) {
        await txn.insert(
          'user_daily_state',
          {
            'user_id': userId,
            'last_active_date': today,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return;
      }

      final lastActiveDate =
          (rows.first['last_active_date'] as String?)?.trim() ?? today;

      if (lastActiveDate == today) {
        await txn.update(
          'user_daily_state',
          {'updated_at': now},
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        return;
      }

      if (lastActiveDate.compareTo(today) < 0) {
        await _upsertDailySummary(
          txn,
          userId: userId,
          date: lastActiveDate,
          closedAt: now,
        );
      }

      await txn.insert(
        'user_daily_state',
        {
          'user_id': userId,
          'last_active_date': today,
          'last_rollover_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> _migrateLegacySingleUserDataIfNeeded(
      Database db, int userId) async {
    final existingProfiles = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM user_profiles'),
        ) ??
        0;
    if (existingProfiles > 0) return;

    if (!await _tableExists(db, 'user_profile')) return;

    final legacyRows = await db.query('user_profile', limit: 1);
    if (legacyRows.isEmpty) return;

    final legacy = Map<String, dynamic>.from(legacyRows.first);
    legacy.remove('id');
    legacy['user_id'] = userId;

    await db.insert('user_profiles', legacy);

    if (await _columnExists(db, 'food_log', 'user_id')) {
      await db.update(
        'food_log',
        {'user_id': userId},
        where: 'user_id IS NULL',
      );
    }

    if (await _columnExists(db, 'water_log', 'user_id')) {
      await db.update(
        'water_log',
        {'user_id': userId},
        where: 'user_id IS NULL',
      );
    }
  }

  // ═══════════════════════════════════════════════════
  // OPERACIONES DE LOGIN Y USUARIOS
  // ═══════════════════════════════════════════════════

  Future<UserAccount?> getUserByUsername(String username) async {
    final normalized = username.trim();
    if (normalized.isEmpty) return null;

    final db = await _dbHelper.database;
    final maps = await db.query(
      'users',
      where: 'LOWER(username) = ?',
      whereArgs: [normalized.toLowerCase()],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return UserAccount.fromMap(maps.first);
  }

  Future<UserAccount> loginUser({
    required String username,
    required String password,
  }) async {
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();

    _ensureCredentialsPresent(cleanUsername, cleanPassword);

    final existing = await getUserByUsername(cleanUsername);
    if (existing == null) {
      throw const AuthException(
        'user-not-found',
        'No existe una cuenta con ese usuario. Regístrate primero.',
      );
    }

    final passwordHash = _hashPassword(cleanPassword);
    if (existing.passwordHash != passwordHash) {
      throw const AuthException(
        'invalid-password',
        'La contraseña no coincide con el usuario guardado.',
      );
    }

    return existing;
  }

  Future<UserAccount> registerUser({
    required String username,
    required String password,
  }) async {
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();

    _ensureCredentialsPresent(cleanUsername, cleanPassword);

    if (cleanPassword.length < 6) {
      throw const AuthException(
        'weak-password',
        'La contraseña debe tener al menos 6 caracteres.',
      );
    }

    final existing = await getUserByUsername(cleanUsername);
    if (existing != null) {
      throw const AuthException(
        'user-exists',
        'Ese usuario ya existe. Inicia sesión o usa otro nombre.',
      );
    }

    final db = await _dbHelper.database;
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final id = await db.insert('users', {
      'username': cleanUsername,
      'password_hash': _hashPassword(cleanPassword),
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    await _migrateLegacySingleUserDataIfNeeded(db, id);

    final account = await getUserByUsername(cleanUsername);
    if (account == null) {
      throw const AuthException(
        'create-failed',
        'No se pudo crear el usuario local.',
      );
    }

    return account;
  }

  @Deprecated('Usa loginUser o registerUser para flujos separados.')
  Future<({UserAccount account, bool isNewUser})> authenticateOrCreateUser({
    required String username,
    required String password,
  }) async {
    final existing = await getUserByUsername(username);
    if (existing != null) {
      final account = await loginUser(username: username, password: password);
      return (account: account, isNewUser: false);
    }

    final account = await registerUser(username: username, password: password);
    return (account: account, isNewUser: true);
  }

  // ═══════════════════════════════════════════════════
  // OPERACIONES DE ALIMENTOS
  // ═══════════════════════════════════════════════════

  Future<List<Food>> searchFoods(String query) async {
    if (query.isEmpty) return [];

    final db = await _dbHelper.database;
    final searchTerm = '%${query.toLowerCase()}%';

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT DISTINCT f.* FROM foods f
      LEFT JOIN food_aliases a ON f.id = a.food_id
      WHERE LOWER(f.name) LIKE ? OR LOWER(a.alias) LIKE ?
      ORDER BY 
        CASE 
          WHEN LOWER(f.name) = ? THEN 0
          WHEN LOWER(f.name) LIKE ? THEN 1
          ELSE 2
        END,
        f.is_quick_food DESC,
        f.name
      LIMIT 20
    ''', [
      searchTerm,
      searchTerm,
      query.toLowerCase(),
      '${query.toLowerCase()}%',
    ]);

    return results.map((map) => Food.fromMap(map)).toList();
  }

  Future<List<Food>> getQuickFoods() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'foods',
      where: 'is_quick_food = ?',
      whereArgs: [1],
      orderBy: 'name',
    );

    return maps.map((map) => Food.fromMap(map)).toList();
  }

  Future<Food?> getFoodById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'foods',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Food.fromMap(maps.first);
  }

  Future<int> addCustomFood(Food food) async {
    final db = await _dbHelper.database;
    return await db.insert('foods', food.toMap());
  }

  Future<List<Food>> getAllFoods() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'foods',
      orderBy: 'name',
    );

    return maps.map((map) => Food.fromMap(map)).toList();
  }

  // ═══════════════════════════════════════════════════
  // OPERACIONES DE LOG DE ALIMENTOS
  // ═══════════════════════════════════════════════════

  Future<int> logFood(FoodLogEntry entry) async {
    await ensureDailyRollover(todayKey: _dateKey(DateTime.now()));

    final db = await _dbHelper.database;
    final map = entry.toMap()..['user_id'] = _requiredUserId;
    return await db.insert('food_log', map);
  }

  Future<List<FoodLogEntry>> getFoodLogByDate(String date) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'food_log',
      where: 'user_id = ? AND date = ?',
      whereArgs: [_requiredUserId, date],
      orderBy: 'logged_at DESC',
    );

    return maps.map((map) => FoodLogEntry.fromMap(map)).toList();
  }

  Future<List<FoodLogEntry>> getTodayFoodLog() async {
    final today = _dateKey(DateTime.now());
    await ensureDailyRollover(todayKey: today);
    return await getFoodLogByDate(today);
  }

  Future<List<FoodLogEntry>> getFoodLogByDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'food_log',
      where: 'user_id = ? AND date BETWEEN ? AND ?',
      whereArgs: [_requiredUserId, startDate, endDate],
      orderBy: 'logged_at DESC',
    );

    return maps.map((map) => FoodLogEntry.fromMap(map)).toList();
  }

  Future<List<FoodLogEntry>> getWeekFoodLog() async {
    final today = DateTime.now();
    final weekAgo = today.subtract(const Duration(days: 7));

    return await getFoodLogByDateRange(
      weekAgo.toIso8601String().split('T')[0],
      today.toIso8601String().split('T')[0],
    );
  }

  Future<int> deleteFoodLog(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'food_log',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _requiredUserId],
    );
  }

  Future<NutritionInfo> getDailyTotals(String date) async {
    final logs = await getFoodLogByDate(date);

    if (logs.isEmpty) {
      return NutritionInfo(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
      );
    }

    return logs.fold<NutritionInfo>(
      NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0),
      (total, log) => NutritionInfo(
        calories: total.calories + log.calories,
        protein: total.protein + log.protein,
        carbs: total.carbs + log.carbs,
        fat: total.fat + log.fat,
        fiber: total.fiber + log.fiber,
        sugar: total.sugar + log.sugar,
        iron: total.iron + log.iron,
        calcium: total.calcium + log.calcium,
        b12: total.b12 + log.b12,
        zinc: total.zinc + log.zinc,
      ),
    );
  }

  Future<Map<String, NutritionInfo>> getDailyTotalsForDays(int days) async {
    final today = DateTime.now();
    final Map<String, NutritionInfo> totals = {};

    for (int i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      totals[dateStr] = await getDailyTotals(dateStr);
    }

    return totals;
  }

  // ═══════════════════════════════════════════════════
  // OPERACIONES DE AGUA
  // ═══════════════════════════════════════════════════

  Future<void> saveWaterIntake(int cups, String date) async {
    final today = _dateKey(DateTime.now());
    if (date == today) {
      await ensureDailyRollover(todayKey: today);
    }

    final db = await _dbHelper.database;

    await db.insert(
      'water_log',
      {
        'user_id': _requiredUserId,
        'cups': cups,
        'date': date,
        'logged_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getWaterIntake(String date) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'water_log',
      where: 'user_id = ? AND date = ?',
      whereArgs: [_requiredUserId, date],
      limit: 1,
    );

    if (maps.isEmpty) return 0;
    return maps.first['cups'] as int;
  }

  Future<int> getTodayWaterIntake() async {
    final today = _dateKey(DateTime.now());
    await ensureDailyRollover(todayKey: today);
    return await getWaterIntake(today);
  }

  // ═══════════════════════════════════════════════════
  // OPERACIONES DE PERFIL
  // ═══════════════════════════════════════════════════

  Future<void> saveUserProfile(UserProfile profile) async {
    final db = await _dbHelper.database;
    final existing = await getUserProfile();
    final map = profile.toMap()
      ..remove('id')
      ..['user_id'] = _requiredUserId
      ..['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (existing != null) {
      map['created_at'] = existing.createdAt;
    }

    await db.insert(
      'user_profiles',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _saveProfileRecord(db, profile);
  }

  Future<void> _saveProfileRecord(Database db, UserProfile profile) async {
    final recordCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM profile_records WHERE user_id = ?',
            [_requiredUserId],
          ),
        ) ??
        0;

    final record = ProfileRecord(
      userId: _requiredUserId,
      goal: profile.goal,
      weight: profile.weight,
      height: profile.height,
      waist: profile.waist,
      neck: profile.neck,
      hip: profile.hip,
      thigh: profile.thigh,
      arm: profile.arm,
      calf: profile.calf,
      bodyFatPct: profile.bodyFatPct,
      muscleMass: profile.muscleMass,
      recordedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      isBaseline: recordCount == 0,
    );

    await db.insert(
      'profile_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ProfileRecord>> getRecentProfileRecords({int limit = 2}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'profile_records',
      where: 'user_id = ?',
      whereArgs: [_requiredUserId],
      orderBy: 'recorded_at DESC',
      limit: limit,
    );

    return maps.map(ProfileRecord.fromMap).toList();
  }

  Future<ProfileRecord?> getBaselineProfileRecord() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'profile_records',
      where: 'user_id = ? AND is_baseline = 1',
      whereArgs: [_requiredUserId],
      orderBy: 'recorded_at ASC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ProfileRecord.fromMap(maps.first);
  }

  Future<ProfileRecord?> getLatestProfileRecord() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'profile_records',
      where: 'user_id = ?',
      whereArgs: [_requiredUserId],
      orderBy: 'recorded_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ProfileRecord.fromMap(maps.first);
  }

  Future<UserProfile?> getUserProfile() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profiles',
      where: 'user_id = ?',
      whereArgs: [_requiredUserId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return UserProfile.fromMap(maps.first);
  }

  Future<bool> hasUserProfile() async {
    final profile = await getUserProfile();
    return profile != null;
  }

  // ═══════════════════════════════════════════════════
  // OPERACIONES DE ALIMENTOS APRENDIDOS POR IA
  // ═══════════════════════════════════════════════════

  Future<int> saveAiLearnedFood(Food food, String confidence) async {
    final db = await _dbHelper.database;

    return await db.insert(
      'ai_learned_foods',
      {
        'name': food.name,
        'emoji': food.emoji,
        'calories': food.calories,
        'protein': food.protein,
        'carbs': food.carbs,
        'fat': food.fat,
        'fiber': food.fiber,
        'sugar': food.sugar,
        'iron': food.iron,
        'calcium': food.calcium,
        'b12': food.b12,
        'zinc': food.zinc,
        'confidence': confidence,
        'times_used': 1,
        'learned_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getAiLearnedFood(String name) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ai_learned_foods',
      where: 'LOWER(name) = ?',
      whereArgs: [name.toLowerCase()],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<void> incrementAiLearnedFoodUsage(String name) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE ai_learned_foods SET times_used = times_used + 1 WHERE LOWER(name) = ?',
      [name.toLowerCase()],
    );
  }
}
