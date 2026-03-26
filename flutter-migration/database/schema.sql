-- ═══════════════════════════════════════════════════
-- SCHEMA SQL PARA VERDEMETA
-- Base de datos SQLite para Flutter + Sqflite
-- ═══════════════════════════════════════════════════

-- Tabla principal de alimentos veganos
CREATE TABLE IF NOT EXISTS foods (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    emoji TEXT NOT NULL DEFAULT '🍽️',
    
    -- Macronutrientes (por 100g)
    calories REAL NOT NULL,
    protein REAL NOT NULL,
    carbs REAL NOT NULL,
    fat REAL NOT NULL,
    
    -- Micronutrientes (por 100g)
    fiber REAL DEFAULT 0,
    sugar REAL DEFAULT 0,
    iron REAL DEFAULT 0,
    calcium REAL DEFAULT 0,
    b12 REAL DEFAULT 0,
    zinc REAL DEFAULT 0,
    
    -- Metadata
    is_quick_food INTEGER DEFAULT 0, -- 1 = aparece en quick foods, 0 = no
    created_at INTEGER DEFAULT (strftime('%s', 'now')),
    
    -- Índices para búsqueda rápida
    UNIQUE(name)
);

CREATE INDEX idx_foods_name ON foods(name);
CREATE INDEX idx_foods_quick ON foods(is_quick_food) WHERE is_quick_food = 1;

-- Tabla de alias/sinónimos para búsqueda inteligente
CREATE TABLE IF NOT EXISTS food_aliases (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    food_id INTEGER NOT NULL,
    alias TEXT NOT NULL,
    FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE CASCADE,
    UNIQUE(alias)
);

CREATE INDEX idx_aliases_name ON food_aliases(alias);

-- Tabla de perfil del usuario
CREATE TABLE IF NOT EXISTS user_profile (
    id INTEGER PRIMARY KEY CHECK (id = 1), -- Solo un perfil
    name TEXT NOT NULL,
    age INTEGER NOT NULL,
    gender TEXT NOT NULL CHECK (gender IN ('male', 'female', 'other')),
    weight REAL NOT NULL, -- kg
    height REAL NOT NULL, -- cm
    activity_level REAL NOT NULL DEFAULT 1.55, -- multiplicador de actividad
    goal TEXT NOT NULL CHECK (goal IN ('deficit', 'maintain', 'gain', 'health')),
    
    -- Medidas corporales
    waist REAL, -- cm
    neck REAL, -- cm
    hip REAL, -- cm
    thigh REAL, -- cm
    arm REAL, -- cm
    calf REAL, -- cm
    
    -- Metas calculadas (kcal, g)
    calorie_target REAL NOT NULL,
    protein_target REAL NOT NULL,
    carbs_target REAL NOT NULL,
    fat_target REAL NOT NULL,
    
    -- Composición corporal estimada
    body_fat_pct REAL,
    muscle_pct REAL,
    lean_body_mass REAL,
    muscle_mass REAL,
    bone_mass REAL,
    water_mass REAL,
    
    created_at INTEGER DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER DEFAULT (strftime('%s', 'now'))
);

-- Tabla de registro de alimentos consumidos
CREATE TABLE IF NOT EXISTS food_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    food_id INTEGER NOT NULL,
    food_name TEXT NOT NULL, -- Desnormalizado para alimentos personalizados/IA
    
    -- Momento del día
    meal_time TEXT NOT NULL CHECK (meal_time IN ('Desayuno', 'Almuerzo', 'Cena', 'Merienda')),
    
    -- Cantidad consumida
    quantity REAL NOT NULL, -- gramos/ml
    
    -- Macros consumidos (calculados)
    calories REAL NOT NULL,
    protein REAL NOT NULL,
    carbs REAL NOT NULL,
    fat REAL NOT NULL,
    
    -- Micros consumidos
    fiber REAL DEFAULT 0,
    sugar REAL DEFAULT 0,
    iron REAL DEFAULT 0,
    calcium REAL DEFAULT 0,
    b12 REAL DEFAULT 0,
    zinc REAL DEFAULT 0,
    
    -- Metadata
    is_ai_estimated INTEGER DEFAULT 0, -- 1 = estimado por IA
    logged_at INTEGER DEFAULT (strftime('%s', 'now')), -- timestamp
    date TEXT NOT NULL, -- YYYY-MM-DD para consultas por día
    
    FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE SET NULL
);

CREATE INDEX idx_food_log_date ON food_log(date);
CREATE INDEX idx_food_log_meal ON food_log(meal_time);

-- Tabla de consumo de agua
CREATE TABLE IF NOT EXISTS water_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cups INTEGER NOT NULL DEFAULT 1, -- vasos de agua (250ml cada uno)
    date TEXT NOT NULL, -- YYYY-MM-DD
    logged_at INTEGER DEFAULT (strftime('%s', 'now')),
    
    UNIQUE(date) -- Solo un registro por día
);

CREATE INDEX idx_water_log_date ON water_log(date);

-- Tabla de alimentos aprendidos por IA (cache)
CREATE TABLE IF NOT EXISTS ai_learned_foods (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    emoji TEXT DEFAULT '🍽️',
    
    -- Macros estimados por IA (por 100g)
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
    
    -- Metadata de IA
    confidence TEXT, -- respuesta de la IA sobre confiabilidad
    times_used INTEGER DEFAULT 1,
    learned_at INTEGER DEFAULT (strftime('%s', 'now'))
);

CREATE INDEX idx_ai_foods_name ON ai_learned_foods(name);
