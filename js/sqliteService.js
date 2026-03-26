(function () {
  const DB_STORAGE_KEY = 'vm_sqlite_db';
  const AI_META_KEY = 'ai_learned_foods';
  const textEncoder = new TextEncoder();

  const schema = `
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      profile_json TEXT,
      targets_json TEXT,
      food_log_json TEXT NOT NULL DEFAULT '[]',
      water_json TEXT NOT NULL DEFAULT '{}',
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS app_meta (
      key TEXT PRIMARY KEY,
      value_json TEXT NOT NULL,
      updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
  `;

  let SQL = null;
  let db = null;
  let initPromise = null;

  function toBase64(bytes) {
    let binary = '';
    const chunkSize = 0x8000;

    for (let index = 0; index < bytes.length; index += chunkSize) {
      const chunk = bytes.subarray(index, index + chunkSize);
      binary += String.fromCharCode.apply(null, chunk);
    }

    return btoa(binary);
  }

  function fromBase64(base64Value) {
    const binary = atob(base64Value);
    const bytes = new Uint8Array(binary.length);

    for (let index = 0; index < binary.length; index += 1) {
      bytes[index] = binary.charCodeAt(index);
    }

    return bytes;
  }

  function safeParse(rawValue, fallbackValue) {
    if (!rawValue) return fallbackValue;

    try {
      return JSON.parse(rawValue);
    } catch (error) {
      return fallbackValue;
    }
  }

  function ensureDatabase() {
    if (!db) {
      throw new Error('SQLite no inicializado');
    }
  }

  function runQuery(sql, params = []) {
    ensureDatabase();
    db.run(sql, params);
    persistDatabase();
  }

  function queryOne(sql, params = []) {
    ensureDatabase();
    const stmt = db.prepare(sql, params);

    try {
      return stmt.step() ? stmt.getAsObject() : null;
    } finally {
      stmt.free();
    }
  }

  function persistDatabase() {
    ensureDatabase();
    const exported = db.export();
    localStorage.setItem(DB_STORAGE_KEY, toBase64(exported));
  }

  function normalizeUserRow(row) {
    if (!row) return null;

    return {
      id: Number(row.id),
      username: row.username,
      passwordHash: row.password_hash,
      profile: safeParse(row.profile_json, null),
      targets: safeParse(row.targets_json, {}),
      foodLog: safeParse(row.food_log_json, []),
      waterByDate: safeParse(row.water_json, {})
    };
  }

  async function hashPassword(password) {
    if (window.crypto && window.crypto.subtle) {
      const digest = await window.crypto.subtle.digest('SHA-256', textEncoder.encode(password));
      return Array.from(new Uint8Array(digest))
        .map(byte => byte.toString(16).padStart(2, '0'))
        .join('');
    }

    return 'plain:' + password;
  }

  async function init() {
    if (initPromise) return initPromise;

    initPromise = (async () => {
      if (typeof initSqlJs !== 'function') {
        throw new Error('No se pudo cargar sql.js');
      }

      SQL = await initSqlJs({
        locateFile: fileName => 'https://cdnjs.cloudflare.com/ajax/libs/sql.js/1.10.3/' + fileName
      });

      const stored = localStorage.getItem(DB_STORAGE_KEY);
      db = stored ? new SQL.Database(fromBase64(stored)) : new SQL.Database();
      db.run(schema);
      persistDatabase();
    })();

    return initPromise;
  }

  async function findUserByUsername(username) {
    await init();
    const normalized = username.trim();
    return normalizeUserRow(
      queryOne('SELECT * FROM users WHERE lower(username) = lower(?)', [normalized])
    );
  }

  async function getUserById(userId) {
    await init();
    return normalizeUserRow(queryOne('SELECT * FROM users WHERE id = ?', [userId]));
  }

  async function registerUser(username, password) {
    await init();
    const normalized = username.trim();
    const passwordHash = await hashPassword(password);

    runQuery(
      'INSERT INTO users (username, password_hash) VALUES (?, ?)',
      [normalized, passwordHash]
    );

    return findUserByUsername(normalized);
  }

  async function authenticateUser(username, password) {
    const account = await findUserByUsername(username);
    if (!account) return { status: 'missing' };

    const passwordHash = await hashPassword(password);
    if (account.passwordHash !== passwordHash) {
      return { status: 'invalid' };
    }

    return { status: 'ok', account };
  }

  async function saveUserProfile(userId, profile, targets) {
    await init();
    runQuery(
      'UPDATE users SET profile_json = ?, targets_json = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [JSON.stringify(profile), JSON.stringify(targets), userId]
    );
    return getUserById(userId);
  }

  async function saveUserFoodLog(userId, foodLog) {
    await init();
    runQuery(
      'UPDATE users SET food_log_json = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [JSON.stringify(foodLog), userId]
    );
    return getUserById(userId);
  }

  async function saveUserWater(userId, waterByDate) {
    await init();
    runQuery(
      'UPDATE users SET water_json = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [JSON.stringify(waterByDate), userId]
    );
    return getUserById(userId);
  }

  async function clearUserData(userId) {
    await init();
    runQuery(
      "UPDATE users SET profile_json = NULL, targets_json = NULL, food_log_json = '[]', water_json = '{}', updated_at = CURRENT_TIMESTAMP WHERE id = ?",
      [userId]
    );
    return getUserById(userId);
  }

  async function saveLearnedFoods(foods) {
    await init();
    runQuery(
      'INSERT INTO app_meta (key, value_json, updated_at) VALUES (?, ?, CURRENT_TIMESTAMP) ' +
        'ON CONFLICT(key) DO UPDATE SET value_json = excluded.value_json, updated_at = CURRENT_TIMESTAMP',
      [AI_META_KEY, JSON.stringify(foods)]
    );
  }

  async function loadLearnedFoods() {
    await init();
    const row = queryOne('SELECT value_json FROM app_meta WHERE key = ?', [AI_META_KEY]);
    return safeParse(row && row.value_json, []);
  }

  window.sqliteService = {
    init,
    findUserByUsername,
    getUserById,
    registerUser,
    authenticateUser,
    saveUserProfile,
    saveUserFoodLog,
    saveUserWater,
    clearUserData,
    saveLearnedFoods,
    loadLearnedFoods
  };
})();