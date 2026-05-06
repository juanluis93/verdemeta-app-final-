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
      version: 9,
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

    if (oldVersion < 7) {
      await db.execute('DELETE FROM food_aliases');
      await db.execute('DELETE FROM foods');
      await _seedInitialData(db);
    }

    if (oldVersion < 8) {
      await db.execute('DELETE FROM food_aliases');
      await db.execute('DELETE FROM foods');
      await _seedInitialData(db);
    }

    if (oldVersion < 9) {
      // Agregar columnas para recetas detalladas
      if (!await _columnExists(db, 'foods', 'ingredientes')) {
        await db.execute(
          "ALTER TABLE foods ADD COLUMN ingredientes TEXT",
        );
      }
      if (!await _columnExists(db, 'foods', 'preparacion')) {
        await db.execute(
          "ALTER TABLE foods ADD COLUMN preparacion TEXT",
        );
      }
      // Limpiar y recargar datos con recetas mejoradas
      await db.execute('DELETE FROM food_aliases');
      await db.execute('DELETE FROM foods');
      await _seedInitialData(db);
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

    final seedFoods = [
      {'name': 'Bowl de avena con frutas del bosque', 'emoji': '🥣', 'cal': 380, 'prot': 12, 'carb': 62, 'fat': 8, 'quick': 1},
      {'name': 'Pancakes de banana y avena', 'emoji': '🥞', 'cal': 320, 'prot': 9, 'carb': 58, 'fat': 6, 'quick': 1},
      {'name': 'Tostada de aguacate y tomate', 'emoji': '🥑', 'cal': 310, 'prot': 8, 'carb': 35, 'fat': 16, 'quick': 1},
      {'name': 'Smoothie bowl de açaí', 'emoji': '🫐', 'cal': 340, 'prot': 7, 'carb': 58, 'fat': 10, 'quick': 1},
      {'name': 'Granola casera con frutos secos', 'emoji': '🥜', 'cal': 290, 'prot': 8, 'carb': 38, 'fat': 13, 'quick': 1},
      {'name': 'Batido verde energizante', 'emoji': '🍌', 'cal': 220, 'prot': 5, 'carb': 42, 'fat': 4, 'quick': 1},
      {'name': 'Tortitas de espinaca y maíz', 'emoji': '🫓', 'cal': 260, 'prot': 7, 'carb': 40, 'fat': 8, 'quick': 1},
      {'name': 'Chia pudding de fresa', 'emoji': '🍓', 'cal': 250, 'prot': 6, 'carb': 30, 'fat': 12, 'quick': 1},
      {'name': 'Muffins de arándano veganos', 'emoji': '🥐', 'cal': 195, 'prot': 4, 'carb': 32, 'fat': 6, 'quick': 1},
      {'name': 'Porridge de zanahoria y canela', 'emoji': '🥕', 'cal': 310, 'prot': 9, 'carb': 52, 'fat': 7, 'quick': 1},
      {'name': 'Parfait de frutas y yogur de coco', 'emoji': '🍇', 'cal': 280, 'prot': 5, 'carb': 42, 'fat': 10, 'quick': 1},
      {'name': 'Arepas veganas rellenas', 'emoji': '🌽', 'cal': 350, 'prot': 12, 'carb': 55, 'fat': 10, 'quick': 1},
      {'name': 'Tofu revuelto con verduras', 'emoji': '🫘', 'cal': 280, 'prot': 18, 'carb': 12, 'fat': 16, 'quick': 1},
      {'name': 'Smoothie tropical de mango', 'emoji': '🥭', 'cal': 240, 'prot': 3, 'carb': 48, 'fat': 5, 'quick': 1},
      {'name': 'Avena horneada con manzana', 'emoji': '🫕', 'cal': 330, 'prot': 8, 'carb': 56, 'fat': 9, 'quick': 1},
      {'name': 'French toast vegano', 'emoji': '🍞', 'cal': 340, 'prot': 9, 'carb': 48, 'fat': 12, 'quick': 1},
      {'name': 'Bowl verde de quinoa', 'emoji': '🥒', 'cal': 420, 'prot': 16, 'carb': 52, 'fat': 16, 'quick': 1},
      {'name': 'Bowl de açaí tropical', 'emoji': '🥝', 'cal': 300, 'prot': 6, 'carb': 50, 'fat': 10, 'quick': 1},
      {'name': 'Ramen de miso con tofu crujiente', 'emoji': '🍜', 'cal': 520, 'prot': 28, 'carb': 65, 'fat': 14, 'quick': 0},
      {'name': 'Tacos de jackfruit al pastor', 'emoji': '🌮', 'cal': 380, 'prot': 8, 'carb': 62, 'fat': 10, 'quick': 0},
      {'name': 'Buddha bowl mediterráneo', 'emoji': '🥗', 'cal': 560, 'prot': 24, 'carb': 72, 'fat': 18, 'quick': 0},
      {'name': 'Dahl de lentejas rojas', 'emoji': '🍛', 'cal': 380, 'prot': 20, 'carb': 58, 'fat': 6, 'quick': 0},
      {'name': 'Wrap de hummus y vegetales', 'emoji': '🥙', 'cal': 380, 'prot': 14, 'carb': 48, 'fat': 14, 'quick': 0},
      {'name': 'Sopa de calabaza y jengibre', 'emoji': '🍲', 'cal': 220, 'prot': 4, 'carb': 38, 'fat': 7, 'quick': 0},
      {'name': 'Arroz frito vegano con tofu', 'emoji': '🍚', 'cal': 420, 'prot': 16, 'carb': 62, 'fat': 12, 'quick': 0},
      {'name': 'Pimientos rellenos de quinoa', 'emoji': '🫑', 'cal': 340, 'prot': 14, 'carb': 52, 'fat': 8, 'quick': 0},
      {'name': 'Pizza vegana con vegetales', 'emoji': '🍕', 'cal': 380, 'prot': 12, 'carb': 52, 'fat': 14, 'quick': 0},
      {'name': 'Curry de garbanzos y espinaca', 'emoji': '🥘', 'cal': 360, 'prot': 16, 'carb': 48, 'fat': 12, 'quick': 0},
      {'name': 'Burrito bowl de frijoles', 'emoji': '🌯', 'cal': 480, 'prot': 18, 'carb': 68, 'fat': 14, 'quick': 0},
      {'name': 'Salteado de brócoli y sésamo', 'emoji': '🥦', 'cal': 220, 'prot': 10, 'carb': 22, 'fat': 10, 'quick': 0},
      {'name': 'Pasta primavera vegana', 'emoji': '🍝', 'cal': 420, 'prot': 12, 'carb': 62, 'fat': 14, 'quick': 0},
      {'name': 'Ensalada César vegana', 'emoji': '🥬', 'cal': 320, 'prot': 10, 'carb': 28, 'fat': 18, 'quick': 0},
      {'name': 'Berenjenas a la parmesana vegana', 'emoji': '🍆', 'cal': 380, 'prot': 12, 'carb': 42, 'fat': 18, 'quick': 0},
      {'name': 'Sopa de zanahoria y coco', 'emoji': '🥕', 'cal': 200, 'prot': 4, 'carb': 30, 'fat': 8, 'quick': 0},
      {'name': 'Tamales veganos de rajas', 'emoji': '🫔', 'cal': 320, 'prot': 8, 'carb': 48, 'fat': 12, 'quick': 0},
      {'name': 'Quiche vegano de espinaca', 'emoji': '🥧', 'cal': 280, 'prot': 14, 'carb': 28, 'fat': 12, 'quick': 0},
      {'name': 'Pasta al pesto de espinaca', 'emoji': '🍝', 'cal': 520, 'prot': 16, 'carb': 70, 'fat': 20, 'quick': 0},
      {'name': 'Curry verde thai con tofu', 'emoji': '🫕', 'cal': 445, 'prot': 19, 'carb': 38, 'fat': 22, 'quick': 0},
      {'name': 'Estofado de lentejas y vegetales', 'emoji': '🍲', 'cal': 360, 'prot': 18, 'carb': 56, 'fat': 6, 'quick': 0},
      {'name': 'Chili sin carne', 'emoji': '🌶️', 'cal': 320, 'prot': 16, 'carb': 52, 'fat': 6, 'quick': 0},
      {'name': 'Gyozas veganas de verduras', 'emoji': '🥟', 'cal': 280, 'prot': 8, 'carb': 42, 'fat': 8, 'quick': 0},
      {'name': 'Tikka masala de coliflor', 'emoji': '🍛', 'cal': 320, 'prot': 10, 'carb': 38, 'fat': 14, 'quick': 0},
      {'name': 'Tagine marroquí de garbanzos', 'emoji': '🥘', 'cal': 390, 'prot': 14, 'carb': 58, 'fat': 12, 'quick': 0},
      {'name': 'Hamburguesas de frijol negro', 'emoji': '🫘', 'cal': 340, 'prot': 16, 'carb': 48, 'fat': 10, 'quick': 0},
      {'name': 'Pad thai vegano', 'emoji': '🍜', 'cal': 480, 'prot': 18, 'carb': 62, 'fat': 16, 'quick': 0},
      {'name': 'Bowl de batata asada y tahini', 'emoji': '🥗', 'cal': 420, 'prot': 14, 'carb': 58, 'fat': 16, 'quick': 0},
      {'name': 'Pizza de masa de coliflor', 'emoji': '🍕', 'cal': 320, 'prot': 12, 'carb': 36, 'fat': 14, 'quick': 0},
      {'name': 'Polenta cremosa con setas', 'emoji': '🌽', 'cal': 380, 'prot': 10, 'carb': 52, 'fat': 14, 'quick': 0},
      {'name': "Shepherd's pie vegano", 'emoji': '🥕', 'cal': 380, 'prot': 16, 'carb': 56, 'fat': 10, 'quick': 0},
      {'name': 'Naan con curry de verduras', 'emoji': '🫓', 'cal': 440, 'prot': 12, 'carb': 62, 'fat': 16, 'quick': 0},
      {'name': 'Lasaña vegana de berenjena', 'emoji': '🍆', 'cal': 380, 'prot': 18, 'carb': 42, 'fat': 16, 'quick': 0},
      {'name': 'Fideos con salsa de cacahuete', 'emoji': '🥜', 'cal': 460, 'prot': 16, 'carb': 58, 'fat': 18, 'quick': 0},
      {'name': 'Fajitas veganas de portobello', 'emoji': '🫑', 'cal': 340, 'prot': 10, 'carb': 42, 'fat': 14, 'quick': 0},
      {'name': 'Risotto de champiñones', 'emoji': '🥣', 'cal': 420, 'prot': 10, 'carb': 62, 'fat': 14, 'quick': 0},
      {'name': 'Falafel horneado con tzatziki', 'emoji': '🧆', 'cal': 285, 'prot': 14, 'carb': 38, 'fat': 8, 'quick': 1},
      {'name': 'Barritas energéticas de dátiles', 'emoji': '🥜', 'cal': 180, 'prot': 5, 'carb': 28, 'fat': 7, 'quick': 1},
      {'name': 'Hummus clásico con crudités', 'emoji': '🥕', 'cal': 180, 'prot': 8, 'carb': 22, 'fat': 7, 'quick': 1},
      {'name': 'Palomitas con levadura nutricional', 'emoji': '🍿', 'cal': 150, 'prot': 5, 'carb': 22, 'fat': 5, 'quick': 1},
      {'name': 'Rollitos de pepino con hummus', 'emoji': '🥒', 'cal': 120, 'prot': 5, 'carb': 14, 'fat': 5, 'quick': 1},
      {'name': 'Edamame con sal de mar', 'emoji': '🫘', 'cal': 190, 'prot': 17, 'carb': 8, 'fat': 8, 'quick': 1},
      {'name': 'Chips de batata al horno', 'emoji': '🍠', 'cal': 160, 'prot': 2, 'carb': 30, 'fat': 4, 'quick': 1},
      {'name': 'Guacamole con totopos', 'emoji': '🥑', 'cal': 220, 'prot': 3, 'carb': 18, 'fat': 16, 'quick': 1},
      {'name': 'Mix de frutos secos especiados', 'emoji': '🌰', 'cal': 200, 'prot': 6, 'carb': 10, 'fat': 16, 'quick': 1},
      {'name': 'Bruschetta de tomate', 'emoji': '🍅', 'cal': 160, 'prot': 4, 'carb': 24, 'fat': 5, 'quick': 1},
      {'name': 'Pretzels suaves veganos', 'emoji': '🥨', 'cal': 220, 'prot': 6, 'carb': 42, 'fat': 3, 'quick': 1},
      {'name': 'Chips de kale crujientes', 'emoji': '🥬', 'cal': 110, 'prot': 4, 'carb': 10, 'fat': 6, 'quick': 1},
      {'name': 'Crackers de semillas', 'emoji': '🫓', 'cal': 140, 'prot': 5, 'carb': 12, 'fat': 8, 'quick': 1},
      {'name': 'Banana con mantequilla de maní', 'emoji': '🍌', 'cal': 260, 'prot': 8, 'carb': 32, 'fat': 12, 'quick': 1},
      {'name': 'Dip de queso vegano con nachos', 'emoji': '🧀', 'cal': 240, 'prot': 6, 'carb': 24, 'fat': 14, 'quick': 1},
      {'name': 'Rollitos de arroz con mango', 'emoji': '🥭', 'cal': 160, 'prot': 3, 'carb': 28, 'fat': 4, 'quick': 1},
      {'name': 'Tapenade de aceitunas', 'emoji': '🫒', 'cal': 150, 'prot': 2, 'carb': 8, 'fat': 12, 'quick': 1},
      {'name': 'Mousse de chocolate y aguacate', 'emoji': '🍫', 'cal': 290, 'prot': 4, 'carb': 28, 'fat': 19, 'quick': 0},
      {'name': 'Galletas de avena y chocolate', 'emoji': '🍪', 'cal': 160, 'prot': 3, 'carb': 22, 'fat': 7, 'quick': 0},
      {'name': 'Nice cream de banana', 'emoji': '🍌', 'cal': 180, 'prot': 2, 'carb': 42, 'fat': 1, 'quick': 0},
      {'name': 'Tarta de manzana vegana', 'emoji': '🥧', 'cal': 280, 'prot': 3, 'carb': 42, 'fat': 12, 'quick': 0},
      {'name': 'Panna cotta de coco y mango', 'emoji': '🍮', 'cal': 240, 'prot': 2, 'carb': 28, 'fat': 14, 'quick': 0},
      {'name': 'Cupcakes de vainilla veganos', 'emoji': '🧁', 'cal': 220, 'prot': 3, 'carb': 32, 'fat': 9, 'quick': 0},
      {'name': 'Cheesecake vegano de arándanos', 'emoji': '🫐', 'cal': 320, 'prot': 6, 'carb': 28, 'fat': 22, 'quick': 0},
      {'name': 'Brownies veganos de chocolate', 'emoji': '🍫', 'cal': 250, 'prot': 4, 'carb': 32, 'fat': 13, 'quick': 0},
      {'name': 'Fresas con chocolate fundido', 'emoji': '🍓', 'cal': 180, 'prot': 2, 'carb': 24, 'fat': 10, 'quick': 0},
      {'name': 'Bolitas de coco y limón', 'emoji': '🥥', 'cal': 120, 'prot': 2, 'carb': 14, 'fat': 7, 'quick': 0},
      {'name': 'Pastel de zanahoria vegano', 'emoji': '🎂', 'cal': 310, 'prot': 5, 'carb': 42, 'fat': 14, 'quick': 0},
      {'name': 'Helado de mango y coco', 'emoji': '🍨', 'cal': 210, 'prot': 2, 'carb': 34, 'fat': 8, 'quick': 0},
      {'name': 'Donas veganas glaseadas', 'emoji': '🍩', 'cal': 240, 'prot': 4, 'carb': 36, 'fat': 9, 'quick': 0},
      {'name': 'Crumble de frutas del bosque', 'emoji': '🫐', 'cal': 260, 'prot': 4, 'carb': 40, 'fat': 10, 'quick': 0},
      {'name': 'Tarta de limón vegana', 'emoji': '🍋', 'cal': 270, 'prot': 3, 'carb': 36, 'fat': 13, 'quick': 0},
      {'name': 'Compota de frutas con granola', 'emoji': '🍑', 'cal': 220, 'prot': 4, 'carb': 38, 'fat': 6, 'quick': 0},
      {'name': 'Trufas de chocolate y maní', 'emoji': '🥜', 'cal': 140, 'prot': 3, 'carb': 14, 'fat': 9, 'quick': 0},
      {'name': 'Golden latte de cúrcuma', 'emoji': '🥤', 'cal': 120, 'prot': 3, 'carb': 10, 'fat': 7, 'quick': 1},
      {'name': 'Matcha latte con leche de avena', 'emoji': '🍵', 'cal': 130, 'prot': 3, 'carb': 14, 'fat': 5, 'quick': 1},
      {'name': 'Smoothie de coco y piña', 'emoji': '🥥', 'cal': 200, 'prot': 2, 'carb': 32, 'fat': 8, 'quick': 1},
      {'name': 'Limonada de fresa', 'emoji': '🍓', 'cal': 90, 'prot': 1, 'carb': 22, 'fat': 0, 'quick': 1},
      {'name': 'Jugo de zanahoria y naranja', 'emoji': '🥕', 'cal': 120, 'prot': 2, 'carb': 28, 'fat': 0, 'quick': 1},
      {'name': 'Chai latte vegano', 'emoji': '🫖', 'cal': 110, 'prot': 2, 'carb': 16, 'fat': 4, 'quick': 1},
      {'name': 'Chocolate caliente vegano', 'emoji': '🍫', 'cal': 200, 'prot': 4, 'carb': 28, 'fat': 8, 'quick': 1},
      {'name': 'Agua fresca de sandía', 'emoji': '🍉', 'cal': 60, 'prot': 1, 'carb': 14, 'fat': 0, 'quick': 1},
      {'name': 'Jugo verde detox', 'emoji': '🥬', 'cal': 80, 'prot': 2, 'carb': 18, 'fat': 0, 'quick': 1},
      {'name': 'Té de jengibre y limón', 'emoji': '🫚', 'cal': 40, 'prot': 0, 'carb': 10, 'fat': 0, 'quick': 1},
      {'name': 'Smoothie de durazno y vainilla', 'emoji': '🍑', 'cal': 160, 'prot': 3, 'carb': 30, 'fat': 3, 'quick': 1},
      {'name': 'Agua de jamaica', 'emoji': '🍇', 'cal': 70, 'prot': 0, 'carb': 18, 'fat': 0, 'quick': 1},
      {'name': 'Agua de pepino y limón', 'emoji': '🥒', 'cal': 15, 'prot': 0, 'carb': 4, 'fat': 0, 'quick': 1},
      {'name': 'Smoothie de arándanos y avena', 'emoji': '🫐', 'cal': 240, 'prot': 8, 'carb': 40, 'fat': 5, 'quick': 1},
      {'name': 'Café helado con leche de coco', 'emoji': '☕', 'cal': 100, 'prot': 1, 'carb': 12, 'fat': 5, 'quick': 1},
      {'name': 'Zumo de naranja y remolacha', 'emoji': '🍊', 'cal': 110, 'prot': 2, 'carb': 26, 'fat': 0, 'quick': 1},
      {'name': 'Infusión de menta y hierba luisa', 'emoji': '🌿', 'cal': 5, 'prot': 0, 'carb': 1, 'fat': 0, 'quick': 1},
    ];

    await db.execute('DELETE FROM food_aliases');
    await db.execute('DELETE FROM foods');

    for (final food in seedFoods) {
      final carbs = (food['carb'] as num).toDouble();
      final protein = (food['prot'] as num).toDouble();
      final fat = (food['fat'] as num).toDouble();
      final name = (food['name'] as String).toLowerCase();
      final quick = (food['quick'] as num).toInt();

      final fiber = (carbs * 0.14).clamp(1.0, 14.0).toDouble();
      final sugar = (carbs * 0.22).clamp(0.4, 18.0).toDouble();
      final iron = (protein * 0.16 + (quick == 1 ? 0.35 : 0.55))
          .clamp(0.8, 6.5)
          .toDouble();
      final calcium = (protein * 9 + fat * 2 + (quick == 1 ? 20 : 12))
          .clamp(30.0, 280.0)
          .toDouble();
      final zinc = (protein * 0.14 + (quick == 0 ? 0.2 : 0.1))
          .clamp(0.4, 4.5)
          .toDouble();

      final hasFortifiedProfile = name.contains('latte') ||
          name.contains('smoothie') ||
          name.contains('tofu') ||
          name.contains('yogur') ||
          name.contains('queso') ||
          name.contains('chocolate caliente') ||
          name.contains('cafe helado') ||
          name.contains('café helado') ||
          name.contains('golden');
      final b12 = hasFortifiedProfile
          ? 0.35
          : (quick == 1 ? 0.12 : 0.06);

      await db.insert(
        'foods',
        {
          'name': food['name'],
          'emoji': food['emoji'],
          'calories': food['cal'],
          'protein': food['prot'],
          'carbs': food['carb'],
          'fat': food['fat'],
          'fiber': fiber,
          'sugar': sugar,
          'iron': iron,
          'calcium': calcium,
          'b12': b12,
          'zinc': zinc,
          'is_quick_food': food['quick'],
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await _seedHealthConditions(db);

    print(
      '✅ Catálogo SQL actualizado con ${seedFoods.length} recetas y micronutrientes estimados');
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
