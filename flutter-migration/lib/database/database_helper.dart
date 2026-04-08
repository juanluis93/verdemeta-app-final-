/// ═══════════════════════════════════════════════════
/// DATABASE HELPER - Sqflite
/// Maneja todas las operaciones de base de datos SQLite
/// ═══════════════════════════════════════════════════
library;

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _isDbFactoryReady = false;

  DatabaseHelper._init();

  /// Configura el databaseFactory para escritorio (Windows/Linux/macOS).
  /// En Android/iOS lo maneja sqflite automaticamente.
  static Future<void> initializeDatabaseFactory() async {
    if (_isDbFactoryReady) return;

    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      ffi.sqfliteFfiInit();
      databaseFactory = ffi.databaseFactoryFfi;
    }

    _isDbFactoryReady = true;
  }

  /// Obtiene la instancia de la base de datos (Singleton)
  Future<Database> get database async {
    if (_database != null) return _database!;
    await initializeDatabaseFactory();
    _database = await _initDB('verdemeta.db');
    return _database!;
  }

  /// Inicializa la base de datos
  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'SQLite no esta disponible en web preview. Usa Android, iOS o escritorio.',
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: (db) async {
        // Habilita foreign keys
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createUserTables(db);

      if (!await _columnExists(db, 'food_log', 'user_id')) {
        await db.execute('ALTER TABLE food_log ADD COLUMN user_id INTEGER');
      }

      if (await _tableExists(db, 'water_log')) {
        await db.execute('ALTER TABLE water_log RENAME TO water_log_legacy');
      }

      await db.execute('''
        CREATE TABLE IF NOT EXISTS water_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          cups INTEGER NOT NULL DEFAULT 1,
          date TEXT NOT NULL,
          logged_at INTEGER DEFAULT (strftime('%s', 'now')),
          
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
          UNIQUE(user_id, date)
        )
      ''');

      if (await _tableExists(db, 'water_log_legacy')) {
        await db.execute('''
          INSERT INTO water_log (id, cups, date, logged_at)
          SELECT id, cups, date, logged_at
          FROM water_log_legacy
        ''');
        await db.execute('DROP TABLE water_log_legacy');
      }

      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_food_log_user_date ON food_log(user_id, date)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_water_log_user_date ON water_log(user_id, date)');
    }

    if (oldVersion < 3) {
      await _createDailyResetTables(db);
    }

    if (oldVersion < 4) {
      await _createProfileRecordsTable(db);
    }

    if (oldVersion < 5) {
      await _seedInitialData(db);
    }

    if (oldVersion < 6) {
      await _createHealthConditionTables(db);
      if (!await _columnExists(db, 'user_profiles', 'selected_disease_ids')) {
        await db.execute(
          "ALTER TABLE user_profiles ADD COLUMN selected_disease_ids TEXT NOT NULL DEFAULT '[]'",
        );
      }
      await _seedHealthConditions(db);
    }
  }

  Future<bool> _columnExists(
    Database db,
    String tableName,
    String columnName,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    return columns.any((column) => column['name'] == columnName);
  }

  Future<bool> _tableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  /// Crea las tablas de la base de datos
  Future<void> _createDB(Database db, int version) async {
    // Tabla de alimentos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS foods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL DEFAULT '🍽️',
        
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        
        fiber REAL DEFAULT 0,
        sugar REAL DEFAULT 0,
        iron REAL DEFAULT 0,
        calcium REAL DEFAULT 0,
        b12 REAL DEFAULT 0,
        zinc REAL DEFAULT 0,
        
        is_quick_food INTEGER DEFAULT 0,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        
        UNIQUE(name)
      )
    ''');

    await db.execute('CREATE INDEX idx_foods_name ON foods(name)');
    await db.execute(
        'CREATE INDEX idx_foods_quick ON foods(is_quick_food) WHERE is_quick_food = 1');

    // Tabla de alias
    await db.execute('''
      CREATE TABLE IF NOT EXISTS food_aliases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        food_id INTEGER NOT NULL,
        alias TEXT NOT NULL,
        FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE CASCADE,
        UNIQUE(alias)
      )
    ''');

    await db.execute('CREATE INDEX idx_aliases_name ON food_aliases(alias)');

    await _createUserTables(db);

    // Tabla de registro de alimentos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS food_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        food_id INTEGER,
        food_name TEXT NOT NULL,
        
        meal_time TEXT NOT NULL CHECK (meal_time IN ('Desayuno', 'Almuerzo', 'Cena', 'Merienda')),
        
        quantity REAL NOT NULL,
        
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        
        fiber REAL DEFAULT 0,
        sugar REAL DEFAULT 0,
        iron REAL DEFAULT 0,
        calcium REAL DEFAULT 0,
        b12 REAL DEFAULT 0,
        zinc REAL DEFAULT 0,
        
        is_ai_estimated INTEGER DEFAULT 0,
        logged_at INTEGER DEFAULT (strftime('%s', 'now')),
        date TEXT NOT NULL,
        
        FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE SET NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_food_log_date ON food_log(date)');
    await db.execute('CREATE INDEX idx_food_log_meal ON food_log(meal_time)');
    await db.execute(
        'CREATE INDEX idx_food_log_user_date ON food_log(user_id, date)');

    // Tabla de consumo de agua
    await db.execute('''
      CREATE TABLE IF NOT EXISTS water_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        cups INTEGER NOT NULL DEFAULT 1,
        date TEXT NOT NULL,
        logged_at INTEGER DEFAULT (strftime('%s', 'now')),
        
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(user_id, date)
      )
    ''');

    await db.execute('CREATE INDEX idx_water_log_date ON water_log(date)');
    await db.execute(
        'CREATE INDEX idx_water_log_user_date ON water_log(user_id, date)');

    await _createDailyResetTables(db);

    // Tabla de alimentos aprendidos por IA
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_learned_foods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        emoji TEXT DEFAULT '🍽️',
        
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        
        fiber REAL DEFAULT 0,
        sugar REAL DEFAULT 0,
        iron REAL DEFAULT 0,
        calcium REAL DEFAULT 0,
        b12 REAL DEFAULT 0,
        zinc REAL DEFAULT 0,
        
        confidence TEXT,
        times_used INTEGER DEFAULT 1,
        learned_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    ''');

    await db
        .execute('CREATE INDEX idx_ai_foods_name ON ai_learned_foods(name)');

    // Insertar datos iniciales (seed data)
    await _seedInitialData(db);
  }

  Future<void> _createUserTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL COLLATE NOCASE UNIQUE,
        password_hash TEXT NOT NULL,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL CHECK (gender IN ('male', 'female', 'other')),
        weight REAL NOT NULL,
        height REAL NOT NULL,
        activity_level REAL NOT NULL DEFAULT 1.55,
        goal TEXT NOT NULL CHECK (goal IN ('deficit', 'maintain', 'gain', 'health')),
        selected_disease_ids TEXT NOT NULL DEFAULT '[]',
        
        waist REAL,
        neck REAL,
        hip REAL,
        thigh REAL,
        arm REAL,
        calf REAL,
        
        calorie_target REAL NOT NULL,
        protein_target REAL NOT NULL,
        carbs_target REAL NOT NULL,
        fat_target REAL NOT NULL,
        
        body_fat_pct REAL,
        muscle_pct REAL,
        lean_body_mass REAL,
        muscle_mass REAL,
        bone_mass REAL,
        water_mass REAL,
        
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now')),

        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await _createProfileRecordsTable(db);
  }

  Future<void> _createProfileRecordsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS profile_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        goal TEXT NOT NULL CHECK (goal IN ('deficit', 'maintain', 'gain', 'health')),
        weight REAL NOT NULL,
        height REAL NOT NULL,
        waist REAL,
        neck REAL,
        hip REAL,
        thigh REAL,
        arm REAL,
        calf REAL,
        body_fat_pct REAL,
        muscle_mass REAL,
        recorded_at INTEGER DEFAULT (strftime('%s', 'now')),
        is_baseline INTEGER NOT NULL DEFAULT 0,

        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_profile_records_user_recorded_at ON profile_records(user_id, recorded_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_profile_records_user_baseline ON profile_records(user_id, is_baseline)',
    );
  }

  Future<void> _createDailyResetTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_daily_state (
        user_id INTEGER PRIMARY KEY,
        last_active_date TEXT NOT NULL,
        last_rollover_at INTEGER,
        updated_at INTEGER DEFAULT (strftime('%s', 'now')),

        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_summaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,

        calories REAL NOT NULL DEFAULT 0,
        protein REAL NOT NULL DEFAULT 0,
        carbs REAL NOT NULL DEFAULT 0,
        fat REAL NOT NULL DEFAULT 0,
        fiber REAL NOT NULL DEFAULT 0,
        sugar REAL NOT NULL DEFAULT 0,
        iron REAL NOT NULL DEFAULT 0,
        calcium REAL NOT NULL DEFAULT 0,
        b12 REAL NOT NULL DEFAULT 0,
        zinc REAL NOT NULL DEFAULT 0,

        water_cups INTEGER NOT NULL DEFAULT 0,
        meal_count INTEGER NOT NULL DEFAULT 0,
        closed_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),

        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(user_id, date)
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_daily_summaries_user_date ON daily_summaries(user_id, date)',
    );
  }

  Future<void> _createHealthConditionTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS enfermedades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        descripcion TEXT NOT NULL,
        ajuste_calorias REAL NOT NULL DEFAULT 0,
        ajuste_proteinas REAL NOT NULL DEFAULT 0,
        ajuste_carbohidratos REAL NOT NULL DEFAULT 0,
        ajuste_grasas REAL NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Inserta datos iniciales desde el archivo SQL
  Future<void> _seedInitialData(Database db) async {
    await _createHealthConditionTables(db);

    // Catalogo base para planner y registro (se mantiene idempotente con UNIQUE(name)).
    final seedFoods = [
      {
        'name': 'Tofu firme',
        'emoji': '🧊',
        'cal': 80,
        'prot': 8.5,
        'carb': 1.9,
        'fat': 4.8,
        'fiber': 0.3,
        'sugar': 0.6,
        'iron': 1.3,
        'calcium': 200,
        'b12': 0,
        'zinc': 0.8,
        'quick': 1,
      },
      {
        'name': 'Lentejas cocidas',
        'emoji': '🫘',
        'cal': 116,
        'prot': 9,
        'carb': 20,
        'fat': 0.4,
        'fiber': 8,
        'sugar': 1.8,
        'iron': 3.3,
        'calcium': 19,
        'b12': 0,
        'zinc': 1.3,
        'quick': 1,
      },
      {
        'name': 'Garbanzos',
        'emoji': '🫙',
        'cal': 164,
        'prot': 8.9,
        'carb': 27,
        'fat': 2.6,
        'fiber': 7.6,
        'sugar': 4.8,
        'iron': 2.9,
        'calcium': 49,
        'b12': 0,
        'zinc': 1.5,
        'quick': 1,
      },
      {
        'name': 'Quinoa cocida',
        'emoji': '🌾',
        'cal': 120,
        'prot': 4.4,
        'carb': 21.3,
        'fat': 1.9,
        'fiber': 2.8,
        'sugar': 0.9,
        'iron': 1.5,
        'calcium': 17,
        'b12': 0,
        'zinc': 1.1,
        'quick': 1,
      },
      {
        'name': 'Espinaca',
        'emoji': '🥬',
        'cal': 23,
        'prot': 2.9,
        'carb': 3.6,
        'fat': 0.4,
        'fiber': 2.2,
        'sugar': 0.4,
        'iron': 2.7,
        'calcium': 99,
        'b12': 0,
        'zinc': 0.5,
        'quick': 1,
      },
      {
        'name': 'Aguacate',
        'emoji': '🥑',
        'cal': 160,
        'prot': 2,
        'carb': 9,
        'fat': 14.7,
        'fiber': 6.7,
        'sugar': 0.7,
        'iron': 0.6,
        'calcium': 12,
        'b12': 0,
        'zinc': 0.6,
        'quick': 1,
      },
      {
        'name': 'Plátano',
        'emoji': '🍌',
        'cal': 89,
        'prot': 1.1,
        'carb': 23,
        'fat': 0.3,
        'fiber': 2.6,
        'sugar': 12,
        'iron': 0.3,
        'calcium': 5,
        'b12': 0,
        'zinc': 0.2,
        'quick': 1,
      },
      {
        'name': 'Leche de soja',
        'emoji': '🥛',
        'cal': 54,
        'prot': 3.3,
        'carb': 6.3,
        'fat': 1.8,
        'fiber': 0.6,
        'sugar': 4.8,
        'iron': 0.4,
        'calcium': 120,
        'b12': 1.2,
        'zinc': 0.3,
        'quick': 1,
      },
      {
        'name': 'Nueces',
        'emoji': '🥜',
        'cal': 654,
        'prot': 15,
        'carb': 14,
        'fat': 65,
        'fiber': 6.7,
        'sugar': 2.6,
        'iron': 2.9,
        'calcium': 98,
        'b12': 0,
        'zinc': 3.1,
        'quick': 1,
      },
      {
        'name': 'Brócoli',
        'emoji': '🥦',
        'cal': 34,
        'prot': 2.8,
        'carb': 7,
        'fat': 0.4,
        'fiber': 2.6,
        'sugar': 1.7,
        'iron': 0.7,
        'calcium': 47,
        'b12': 0,
        'zinc': 0.4,
        'quick': 1,
      },
      {
        'name': 'Arroz integral',
        'emoji': '🍚',
        'cal': 216,
        'prot': 5,
        'carb': 45,
        'fat': 1.8,
        'fiber': 3.5,
        'sugar': 0.7,
        'iron': 1.1,
        'calcium': 20,
        'b12': 0,
        'zinc': 1.2,
        'quick': 1,
      },
      {
        'name': 'Tempeh',
        'emoji': '🟫',
        'cal': 195,
        'prot': 20,
        'carb': 7.6,
        'fat': 11,
        'fiber': 5,
        'sugar': 0,
        'iron': 2.7,
        'calcium': 184,
        'b12': 0,
        'zinc': 1.7,
        'quick': 1,
      },
      {
        'name': 'Avena',
        'emoji': '🥣',
        'cal': 389,
        'prot': 17,
        'carb': 66,
        'fat': 7,
        'fiber': 10,
        'sugar': 1,
        'iron': 4.7,
        'calcium': 54,
        'b12': 0,
        'zinc': 4,
        'quick': 0,
      },
      {
        'name': 'Frijoles negros',
        'emoji': '🫘',
        'cal': 132,
        'prot': 8.9,
        'carb': 24,
        'fat': 0.5,
        'fiber': 8.7,
        'sugar': 0.3,
        'iron': 2.1,
        'calcium': 27,
        'b12': 0,
        'zinc': 1,
        'quick': 0,
      },
      {
        'name': 'Edamame',
        'emoji': '💚',
        'cal': 121,
        'prot': 11.9,
        'carb': 8.9,
        'fat': 5.2,
        'fiber': 5,
        'sugar': 2.2,
        'iron': 2.3,
        'calcium': 63,
        'b12': 0,
        'zinc': 1.4,
        'quick': 0,
      },
      {
        'name': 'Almendras',
        'emoji': '🌰',
        'cal': 579,
        'prot': 21,
        'carb': 22,
        'fat': 49,
        'fiber': 12.5,
        'sugar': 4.4,
        'iron': 3.7,
        'calcium': 264,
        'b12': 0,
        'zinc': 3.1,
        'quick': 0,
      },
      {
        'name': 'Manzana',
        'emoji': '🍎',
        'cal': 52,
        'prot': 0.3,
        'carb': 14,
        'fat': 0.2,
        'fiber': 2.4,
        'sugar': 10,
        'iron': 0.1,
        'calcium': 6,
        'b12': 0,
        'zinc': 0.04,
        'quick': 0,
      },
      {
        'name': 'Naranja',
        'emoji': '🍊',
        'cal': 47,
        'prot': 0.9,
        'carb': 12,
        'fat': 0.1,
        'fiber': 2.4,
        'sugar': 9,
        'iron': 0.1,
        'calcium': 40,
        'b12': 0,
        'zinc': 0.1,
        'quick': 0,
      },
      {
        'name': 'Zanahoria',
        'emoji': '🥕',
        'cal': 41,
        'prot': 0.9,
        'carb': 10,
        'fat': 0.2,
        'fiber': 2.8,
        'sugar': 4.7,
        'iron': 0.3,
        'calcium': 33,
        'b12': 0,
        'zinc': 0.2,
        'quick': 0,
      },
      {
        'name': 'Tomate',
        'emoji': '🍅',
        'cal': 18,
        'prot': 0.9,
        'carb': 3.9,
        'fat': 0.2,
        'fiber': 1.2,
        'sugar': 2.6,
        'iron': 0.3,
        'calcium': 10,
        'b12': 0,
        'zinc': 0.2,
        'quick': 0,
      },
      {
        'name': 'Lechuga',
        'emoji': '🥗',
        'cal': 15,
        'prot': 1.4,
        'carb': 2.9,
        'fat': 0.2,
        'fiber': 1.3,
        'sugar': 1,
        'iron': 0.9,
        'calcium': 36,
        'b12': 0,
        'zinc': 0.2,
        'quick': 0,
      },
      {
        'name': 'Pepino',
        'emoji': '🥒',
        'cal': 16,
        'prot': 0.7,
        'carb': 3.6,
        'fat': 0.1,
        'fiber': 0.5,
        'sugar': 1.7,
        'iron': 0.3,
        'calcium': 16,
        'b12': 0,
        'zinc': 0.2,
        'quick': 0,
      },
      {
        'name': 'Papa',
        'emoji': '🥔',
        'cal': 77,
        'prot': 2,
        'carb': 17,
        'fat': 0.1,
        'fiber': 2.2,
        'sugar': 0.8,
        'iron': 0.8,
        'calcium': 12,
        'b12': 0,
        'zinc': 0.3,
        'quick': 0,
      },
      {
        'name': 'Camote',
        'emoji': '🍠',
        'cal': 86,
        'prot': 1.6,
        'carb': 20,
        'fat': 0.1,
        'fiber': 3,
        'sugar': 4.2,
        'iron': 0.6,
        'calcium': 30,
        'b12': 0,
        'zinc': 0.3,
        'quick': 0,
      },
      {
        'name': 'Apio',
        'emoji': '🥬',
        'cal': 16,
        'prot': 0.7,
        'carb': 3,
        'fat': 0.2,
        'fiber': 1.6,
        'sugar': 1.3,
        'iron': 0.2,
        'calcium': 40,
        'b12': 0,
        'zinc': 0.1,
        'quick': 0,
      },
      {
        'name': 'Col rizada',
        'emoji': '🥬',
        'cal': 49,
        'prot': 4.3,
        'carb': 8.8,
        'fat': 0.9,
        'fiber': 3.6,
        'sugar': 2.3,
        'iron': 1.5,
        'calcium': 150,
        'b12': 0,
        'zinc': 0.4,
        'quick': 0,
      },
      {
        'name': 'Repollo',
        'emoji': '🥬',
        'cal': 25,
        'prot': 1.3,
        'carb': 6,
        'fat': 0.1,
        'fiber': 2.5,
        'sugar': 3.2,
        'iron': 0.5,
        'calcium': 40,
        'b12': 0,
        'zinc': 0.2,
        'quick': 0,
      },
      {
        'name': 'Berenjena',
        'emoji': '🍆',
        'cal': 25,
        'prot': 1,
        'carb': 6,
        'fat': 0.2,
        'fiber': 3,
        'sugar': 3.5,
        'iron': 0.2,
        'calcium': 9,
        'b12': 0,
        'zinc': 0.2,
        'quick': 0,
      },
      {
        'name': 'Pimientos',
        'emoji': '🫑',
        'cal': 31,
        'prot': 1,
        'carb': 6,
        'fat': 0.3,
        'fiber': 2.1,
        'sugar': 4.2,
        'iron': 0.4,
        'calcium': 7,
        'b12': 0,
        'zinc': 0.2,
        'quick': 0,
      },
      {
        'name': 'Champiñones',
        'emoji': '🍄',
        'cal': 22,
        'prot': 3.1,
        'carb': 3.3,
        'fat': 0.3,
        'fiber': 1,
        'sugar': 2,
        'iron': 0.5,
        'calcium': 3,
        'b12': 0,
        'zinc': 0.5,
        'quick': 0,
      },
      {
        'name': 'Maíz',
        'emoji': '🌽',
        'cal': 96,
        'prot': 3.4,
        'carb': 21,
        'fat': 1.5,
        'fiber': 2.4,
        'sugar': 4.5,
        'iron': 0.5,
        'calcium': 2,
        'b12': 0,
        'zinc': 0.5,
        'quick': 0,
      },
      {
        'name': 'Arvejas',
        'emoji': '🫛',
        'cal': 81,
        'prot': 5.4,
        'carb': 14,
        'fat': 0.4,
        'fiber': 5.1,
        'sugar': 5.6,
        'iron': 1.5,
        'calcium': 25,
        'b12': 0,
        'zinc': 1.2,
        'quick': 0,
      },
      {
        'name': 'Fresa',
        'emoji': '🍓',
        'cal': 32,
        'prot': 0.7,
        'carb': 7.7,
        'fat': 0.3,
        'fiber': 2,
        'sugar': 4.9,
        'iron': 0.4,
        'calcium': 16,
        'b12': 0,
        'zinc': 0.1,
        'quick': 0,
      },
      {
        'name': 'Mango',
        'emoji': '🥭',
        'cal': 60,
        'prot': 0.8,
        'carb': 15,
        'fat': 0.4,
        'fiber': 1.6,
        'sugar': 13.7,
        'iron': 0.2,
        'calcium': 11,
        'b12': 0,
        'zinc': 0.1,
        'quick': 0,
      },
      {
        'name': 'Piña',
        'emoji': '🍍',
        'cal': 50,
        'prot': 0.5,
        'carb': 13,
        'fat': 0.1,
        'fiber': 1.4,
        'sugar': 9.9,
        'iron': 0.3,
        'calcium': 13,
        'b12': 0,
        'zinc': 0.1,
        'quick': 0,
      },
      {
        'name': 'Arroz blanco',
        'emoji': '🍚',
        'cal': 130,
        'prot': 2.7,
        'carb': 28,
        'fat': 0.3,
        'fiber': 0.4,
        'sugar': 0,
        'iron': 0.2,
        'calcium': 10,
        'b12': 0,
        'zinc': 0.5,
        'quick': 0,
      },
    ];

    for (var food in seedFoods) {
      await db.insert(
          'foods',
          {
            'name': food['name'],
            'emoji': food['emoji'],
            'calories': food['cal'],
            'protein': food['prot'],
            'carbs': food['carb'],
            'fat': food['fat'],
            'fiber': food['fiber'],
            'sugar': food['sugar'],
            'iron': food['iron'],
            'calcium': food['calcium'],
            'b12': food['b12'],
            'zinc': food['zinc'],
            'is_quick_food': food['quick'],
          },
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    final aliasPairs = {
      'Aguacate': ['palta', 'avocado'],
      'Arroz integral': ['arroz moreno'],
      'Arroz blanco': ['arroz'],
      'Brócoli': ['brocoli'],
      'Leche de soja': ['leche soya', 'bebida soja'],
      'Frijoles negros': ['caraotas', 'judias negras'],
      'Plátano': ['banana', 'cambur'],
      'Champiñones': ['hongos', 'setas'],
    };

    for (final entry in aliasPairs.entries) {
      final rows = await db.query(
        'foods',
        columns: ['id'],
        where: 'name = ?',
        whereArgs: [entry.key],
        limit: 1,
      );
      if (rows.isEmpty) continue;
      final foodId = rows.first['id'] as int;

      for (final alias in entry.value) {
        await db.insert(
          'food_aliases',
          {'food_id': foodId, 'alias': alias},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }

    await _seedHealthConditions(db);

    print(
        '✅ Catálogo SQL inicializado/actualizado con ${seedFoods.length} alimentos base');
  }

  Future<void> _seedHealthConditions(Database db) async {
    final seedConditions = [
      {
        'nombre': 'Diabetes',
        'descripcion':
            'Reduce carbohidratos de absorcion rapida y sube ligeramente proteinas.',
        'ajuste_calorias': -5.0,
        'ajuste_proteinas': 10.0,
        'ajuste_carbohidratos': -20.0,
        'ajuste_grasas': 5.0,
      },
      {
        'nombre': 'Hipertension',
        'descripcion':
            'Ligera reduccion calorica y prioridad a alimentos bajos en sodio.',
        'ajuste_calorias': -8.0,
        'ajuste_proteinas': 5.0,
        'ajuste_carbohidratos': -5.0,
        'ajuste_grasas': 0.0,
      },
      {
        'nombre': 'Obesidad',
        'descripcion':
            'Reduccion moderada de calorias totales para perdida gradual.',
        'ajuste_calorias': -15.0,
        'ajuste_proteinas': 8.0,
        'ajuste_carbohidratos': -10.0,
        'ajuste_grasas': -5.0,
      },
      {
        'nombre': 'Insuficiencia renal',
        'descripcion':
            'Control de carga proteica y energia estable segun tolerancia clinica.',
        'ajuste_calorias': -5.0,
        'ajuste_proteinas': -20.0,
        'ajuste_carbohidratos': 5.0,
        'ajuste_grasas': 5.0,
      },
    ];

    for (final condition in seedConditions) {
      await db.insert(
        'enfermedades',
        condition,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  /// Cierra la base de datos
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  /// Resetea completamente la base de datos
  Future<void> resetDatabase() async {
    await initializeDatabaseFactory();

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'verdemeta.db');

    await deleteDatabase(path);
    _database = null;

    // Reinicializa
    _database = await _initDB('verdemeta.db');
  }
}
