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
      version: 4,
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

  /// Inserta datos iniciales desde el archivo SQL
  Future<void> _seedInitialData(Database db) async {
    // Quick foods (12 alimentos frecuentes)
    final quickFoods = [
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
        'zinc': 0.8
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
        'zinc': 1.3
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
        'zinc': 1.5
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
        'zinc': 1.1
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
        'zinc': 0.5
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
        'zinc': 0.6
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
        'zinc': 0.2
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
        'zinc': 0.3
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
        'zinc': 3.1
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
        'zinc': 0.4
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
        'zinc': 1.2
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
        'zinc': 1.7
      },
    ];

    for (var food in quickFoods) {
      await db.insert('foods', {
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
        'is_quick_food': 1,
      });
    }

    print(
        '✅ Base de datos inicializada con ${quickFoods.length} alimentos quick');
    // NOTA: Para más alimentos, puedes ejecutar el archivo seed_data.sql
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
