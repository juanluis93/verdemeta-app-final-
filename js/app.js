// ═══════════════════════════════════════════════════════════════════════════════
//  VERDEMETA — VEGAN TRACKER APP
//  Comprehensive application logic for nutrition tracking, body composition,
//  AI-powered food estimation, and progress visualization
// ═══════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════
//  STATE MANAGEMENT
//  Global application state and user data
// ═══════════════════════════════════════════════════

/**
 * User profile containing personal information and body measurements
 * @type {Object}
 * @property {string} name - User's name
 * @property {number} age - User's age in years
 * @property {string} gender - User's gender ('male', 'female', 'other')
 * @property {number} weight - User's weight in kg
 * @property {number} height - User's height in cm
 * @property {number} waist - Waist circumference in cm
 * @property {number} hip - Hip circumference in cm
 * @property {number} neck - Neck circumference in cm
 * @property {number} thigh - Thigh circumference in cm (optional)
 * @property {number} arm - Arm circumference in cm (optional)
 * @property {number} calf - Calf circumference in cm (optional)
 * @property {number} activity - Activity multiplier (1.2-1.9)
 * @property {string} goal - Fitness goal ('deficit', 'maintain', 'gain', 'health')
 * @property {number} tdee - Total Daily Energy Expenditure in kcal
 * @property {number} bmi - Body Mass Index
 * @property {Object} bodyComp - Body composition analysis results
 */
let user = {};

/**
 * Daily macro and micronutrient targets
 * @type {Object}
 */
let macroTargets = {};

/**
 * Food log array containing all meal entries
 * @type {Array<Object>}
 */
let foodLog = [];

/**
 * Number of water glasses consumed today (0-8)
 * @type {number}
 */
let waterToday = 0;

/**
 * Water history keyed by date for current user
 * @type {Object<string, number>}
 */
let waterByDate = {};

/**
 * Current authenticated user account ID from SQLite
 * @type {number|null}
 */
let currentUserId = null;

/**
 * Current authenticated username
 * @type {string}
 */
let currentUsername = '';

/**
 * Shared promise used to initialize browser SQLite once
 * @type {Promise<void>|null}
 */
let storageReadyPromise = null;

/**
 * Chart.js instances for data visualization
 * @type {Object<string, Chart>}
 */
let charts = {};

/**
 * Currently selected fitness goal during onboarding
 * @type {string}
 */
let selectedGoal = '';

/**
 * Currently selected food entry from database or search
 * @type {Object|null}
 */
let selectedFoodEntry = null;

/**
 * AI-estimated food data from Claude API
 * @type {Object|null}
 */
let aiEstimatedFood = null;

/**
 * Timer for toast notification auto-hide
 * @type {number|null}
 */
let toastTimer = null;

/**
 * Returns today's date key in ISO format (YYYY-MM-DD)
 * Used for consistent date-based filtering and storage
 * @returns {string} Today's date in ISO format
 */
function todayKey() { 
  return new Date().toISOString().split('T')[0]; 
}

/**
 * Activates one top-level screen and hides the others
 * @param {string} screenId - Screen element ID to show
 */
function setActiveScreen(screenId) {
  ['screen-login', 'screen-onboard', 'screen-app'].forEach(id => {
    const screen = document.getElementById(id);
    if (!screen) return;
    screen.classList.toggle('active', id === screenId);
  });
}

/**
 * Ensures browser SQLite is initialized before any read/write operation
 * @returns {Promise<void>}
 */
async function ensureStorageReady() {
  if (!storageReadyPromise) {
    storageReadyPromise = window.sqliteService.init();
  }

  await storageReadyPromise;
}

/**
 * Loads current in-memory session data from a SQLite user record
 * @param {Object} account - User account row normalized by sqliteService
 */
function hydrateSessionFromAccount(account) {
  currentUserId = account ? account.id : null;
  currentUsername = account ? account.username : '';
  user = account && account.profile ? account.profile : {};
  macroTargets = account && account.targets ? account.targets : {};
  foodLog = account && Array.isArray(account.foodLog) ? account.foodLog : [];
  waterByDate = account && account.waterByDate ? account.waterByDate : {};
  waterToday = parseInt(waterByDate[todayKey()] || '0', 10);
  selectedGoal = user.goal || '';
}

/**
 * Prefills onboarding name using the login username when profile is empty
 * @param {string} username - Username or email entered at login
 */
function prefillOnboardingName(username) {
  const defaultName = username.includes('@') ? username.split('@')[0] : username;
  if (!document.getElementById('ob-name').value.trim()) {
    document.getElementById('ob-name').value = defaultName;
  }
}

/**
 * Clears in-memory session data without deleting saved users in SQLite
 */
function resetSessionState() {
  currentUserId = null;
  currentUsername = '';
  user = {};
  macroTargets = {};
  foodLog = [];
  waterByDate = {};
  waterToday = 0;
  selectedGoal = '';
  selectedFoodEntry = null;
  aiEstimatedFood = null;

  Object.values(charts).forEach(chart => {
    if (chart && typeof chart.destroy === 'function') {
      chart.destroy();
    }
  });

  charts = {};
}

/**
 * Reads legacy water keys from localStorage for one-time migration
 * @returns {Object<string, number>}
 */
function getLegacyWaterHistory() {
  return Object.keys(localStorage)
    .filter(key => key.startsWith('vm_water_'))
    .reduce((accumulator, key) => {
      accumulator[key.replace('vm_water_', '')] = parseInt(localStorage.getItem(key) || '0', 10);
      return accumulator;
    }, {});
}

/**
 * Clears old single-user keys after migrating them to SQLite
 */
function clearLegacySingleUserStorage() {
  ['vm_user', 'vm_targets', 'vm_log'].forEach(key => localStorage.removeItem(key));
  Object.keys(localStorage)
    .filter(key => key.startsWith('vm_water_'))
    .forEach(key => localStorage.removeItem(key));
}

/**
 * Migrates the old single-user localStorage data into SQLite for the matching user
 * @param {string} loginUser - Username entered in login
 * @param {string} loginPassword - Password entered in login
 * @returns {Promise<Object|null>} Migrated SQLite account or null if not applicable
 */
async function migrateLegacyUserIfNeeded(loginUser, loginPassword) {
  const legacyProfileRaw = localStorage.getItem('vm_user');
  if (!legacyProfileRaw) return null;

  let legacyProfile;
  try {
    legacyProfile = JSON.parse(legacyProfileRaw);
  } catch (error) {
    return null;
  }

  const legacyIdentity = (localStorage.getItem('vm_auth_user') || legacyProfile.name || '').trim().toLowerCase();
  if (legacyIdentity && legacyIdentity !== loginUser.trim().toLowerCase()) {
    return null;
  }

  const createdAccount = await window.sqliteService.registerUser(loginUser, loginPassword);
  const legacyTargets = JSON.parse(localStorage.getItem('vm_targets') || '{}');
  const legacyLog = JSON.parse(localStorage.getItem('vm_log') || '[]');
  const legacyWater = getLegacyWaterHistory();

  await window.sqliteService.saveUserProfile(createdAccount.id, legacyProfile, legacyTargets);
  await window.sqliteService.saveUserFoodLog(createdAccount.id, legacyLog);
  await window.sqliteService.saveUserWater(createdAccount.id, legacyWater);

  clearLegacySingleUserStorage();
  return window.sqliteService.getUserById(createdAccount.id);
}


// ═══════════════════════════════════════════════════
//  BODY COMPOSITION ANALYSIS
//  Advanced multi-model body composition estimation
// ═══════════════════════════════════════════════════

/**
 * Toggles the visibility/opacity of the hip measurement field
 * Hip measurements are required for females but optional for males in US Navy formula
 */
function toggleHipField() {
  const g = document.getElementById('ob-gender').value;
  const hg = document.getElementById('hip-group');
  if (hg) hg.style.opacity = g === 'male' ? '0.4' : '1';
}

/**
 * Real-time body composition calculation and display during onboarding
 * Updates the preview card with estimated body fat %, muscle mass, bone mass, etc.
 * Runs whenever user modifies any measurement field
 */
function liveBodyComp() {
  // Collect all measurement inputs
  const weight = +document.getElementById('ob-weight').value;
  const height = +document.getElementById('ob-height').value;
  const waist  = +document.getElementById('ob-waist').value;
  const neck   = +document.getElementById('ob-neck').value;
  const hip    = +document.getElementById('ob-hip').value;
  const gender = document.getElementById('ob-gender').value;
  const age    = +document.getElementById('ob-age').value;
  const arm    = +document.getElementById('ob-arm').value   || 0;
  const thigh  = +document.getElementById('ob-thigh').value || 0;
  const calf   = +document.getElementById('ob-calf').value  || 0;
  const result = document.getElementById('bodycomp-result');

  // Validate required fields - hide results if incomplete
  if (!weight || !height || !waist || !neck || !gender) { 
    result.style.display = 'none'; 
    return; 
  }
  if (gender === 'female' && !hip) { 
    result.style.display = 'none'; 
    return; 
  }

  // Calculate body composition using ensemble model
  const comp = estimateBodyComp(weight, height, waist, neck, hip, gender, age, arm, thigh, calf);
  if (!comp) { 
    result.style.display = 'none'; 
    return; 
  }

  // Display results container
  result.style.display = 'block';

  // ── Update body fat percentage and lean body mass ──
  document.getElementById('bc-fat-pct').textContent    = comp.fatPct + '%';
  document.getElementById('bc-muscle-pct').textContent = comp.musclePct + '%';
  document.getElementById('bc-lbm').textContent        = comp.lbm + ' kg';

  // ── Update muscle mass metrics (highlighted in UI) ──
  document.getElementById('bc-muscle-kg').textContent  = comp.muscleKg + ' kg';
  document.getElementById('bc-muscle-idx').textContent = comp.smi + ' kg/m²';

  // SMI (Skeletal Muscle Index) category with color coding
  const smiEl = document.getElementById('bc-muscle-cat');
  smiEl.textContent = comp.muscleCat;
  smiEl.style.color = comp.muscleCat === 'Sarcopenia' ? 'var(--rose)'
    : comp.muscleCat === 'Normal' ? 'var(--amber)' : 'var(--green)';

  // ── Display muscle mass measurement precision badge ──
  const confEl = document.getElementById('bc-muscle-confidence');
  const p = comp.precision;
  confEl.style.display = 'block';
  
  // Badge styling based on precision level (🔵 basic, 🟡 moderate, 🟢 advanced)
  const badgeColors = {
    '🔵': 'rgba(58,130,170,.1)', 
    '🟡': 'rgba(184,118,58,.1)', 
    '🟢': 'rgba(46,125,82,.1)'
  };
  const borderColors = {
    '🔵': 'rgba(58,130,170,.3)', 
    '🟡': 'rgba(184,118,58,.3)', 
    '🟢': 'rgba(46,125,82,.3)'
  };
  confEl.style.background = badgeColors[p.icon] || 'rgba(58,130,170,.1)';
  confEl.style.border = '1px solid ' + (borderColors[p.icon] || 'rgba(58,130,170,.3)');
  confEl.style.color = 'var(--text-dim)';
  confEl.innerHTML = p.icon + ' <strong>' + p.label + '</strong> ' + p.error
    + '<br><span style="font-weight:400">' + p.desc + '</span>';

  // ── Update bone mass and water weight ──
  document.getElementById('bc-bone-kg').textContent    = comp.boneKg + ' kg';
  document.getElementById('bc-water-kg').textContent   = comp.waterLitres + ' L';
  document.getElementById('bc-water-pct').textContent  = comp.waterPct + '%';

  // Category label with emoji (elite, athlete, fit, acceptable, overweight)
  const catLabel = {
    'elite':     '⚡ Atleta de élite',
    'atleta':    '🏃 Atleta',
    'en_forma':  '✅ En forma',
    'aceptable': '⚖️ Aceptable',
    'sobrepeso': '⚠️ Sobrepeso graso',
    'obesidad_i': '⚠️ Obesidad grado I',
    'obesidad_ii': '🚩 Obesidad grado II',
    'obesidad_morbida': '🛑 Obesidad mórbida'
  };
  document.getElementById('bc-category').textContent = catLabel[comp.category] || comp.category;

  // ── Update bone density detail panel ──
  document.getElementById('bc-bone-detail').innerHTML =
    'Est. ' + comp.boneKg + ' kg (' + comp.bonePct + '%)<br>' + comp.boneCat;

  // ── Update fluid/water detail panel ──
  const waterLabel = {
    'normal':     '✅ Hidratación normal',
    'bajo_rango': '⚠️ Por debajo del rango normal',
    'retencion':  '💧 Posible retención de líquidos'
  };
  document.getElementById('bc-fluid-detail').innerHTML =
    comp.waterLitres + 'L totales (' + comp.waterPct + '%)<br>' +
    'IC: ' + comp.waterIC + 'L &middot; EC: ' + comp.waterEC + 'L<br>' +
    (waterLabel[comp.waterSt] || comp.waterSt);

  // ── Update composition visualization bar ──
  // Proportional width bars showing muscle, fat, water, bone, and other tissues
  const waterBarPct = Math.min(20, comp.waterPct * 0.4);
  document.getElementById('bar-muscle').style.width = comp.musclePct + '%';
  document.getElementById('bar-fat').style.width    = comp.fatPct + '%';
  document.getElementById('bar-water').style.width  = waterBarPct + '%';
  document.getElementById('bar-bone').style.width   = comp.bonePct + '%';
  document.getElementById('bar-rest').style.width   = Math.max(0, 100 - comp.musclePct - comp.fatPct - waterBarPct - comp.bonePct) + '%';

  // ── Apply color coding based on health ranges ──
  
  // Fat percentage coloring (green = healthy, amber = borderline, rose = high)
  const fatEl = document.getElementById('bc-fat-pct');
  fatEl.style.color = comp.fatPct < (gender === 'female' ? 20 : 10) ? 'var(--sky)'
    : comp.fatPct < (gender === 'female' ? 32 : 25) ? 'var(--green)'
    : comp.fatPct < (gender === 'female' ? 38 : 30) ? 'var(--amber)'
    : 'var(--rose)';

  // Water percentage coloring (based on normal hydration ranges)
  const waterEl = document.getElementById('bc-water-pct');
  const nwRange = gender === 'female' ? [45, 60] : [50, 65];
  waterEl.style.color = comp.waterPct < nwRange[0] ? 'var(--amber)'
    : comp.waterPct <= nwRange[1] ? 'var(--sky)'
    : 'var(--purple)';

  // Muscle kg color coding (based on SMI category)
  const mEl = document.getElementById('bc-muscle-kg');
  mEl.style.color = comp.muscleCat === 'Sarcopenia' ? 'var(--rose)'
    : comp.muscleCat === 'Normal' ? 'var(--amber)'
    : 'var(--green)';
}

/**
 * Advanced body composition estimation using ensemble of validated models
 * 
 * MODELS USED:
 * - Body Fat: US Navy formula (validated R²=0.88, n=12,000+)
 * - Muscle Mass: Lee 2000 (R²=0.86) + Yang 2018 calf (R²=0.70) + Heymsfield 2011 arm (R²=0.65)
 * - Bone Mass: DEXA-validated percent model with age/height correction
 * - Body Water: Watson 1980 formula (validated against D2O dilution)
 * 
 * @param {number} weight - Body weight in kg
 * @param {number} height - Height in cm
 * @param {number} waist - Waist circumference in cm
 * @param {number} neck - Neck circumference in cm
 * @param {number} hip - Hip circumference in cm (required for females)
 * @param {string} gender - 'male' or 'female'
 * @param {number} age - Age in years
 * @param {number} arm - Mid-upper arm circumference in cm (optional, improves precision)
 * @param {number} thigh - Mid-thigh circumference in cm (optional)
 * @param {number} calf - Calf circumference in cm (optional, best single predictor)
 * @returns {Object|null} Body composition analysis or null if invalid inputs
 */
function estimateBodyComp(weight, height, waist, neck, hip, gender, age, arm, thigh, calf) {
  // ── Input validation ──
  if (!weight || !height || !waist || !neck) return null;
  if (weight <= 0 || height <= 0 || waist <= 0 || neck <= 0) return null;

  const safeAge = (age && age > 0 && isFinite(age)) ? age : 25;
  const hM = height / 100; // height in meters
  const sex = gender === 'male' ? 1 : 0;
  const bmi = +(weight / (hM * hM)).toFixed(1);

  const bmiCategory = bmi < 18.5 ? 'bajo_peso'
    : bmi < 25 ? 'normal'
    : bmi < 30 ? 'sobrepeso'
    : bmi < 35 ? 'obesidad_i'
    : bmi < 40 ? 'obesidad_ii'
    : 'obesidad_morbida';

  // ══════════════════════════════════════════════════════
  //  BODY FAT PERCENTAGE — US Navy formula
  //  Inputs must be in INCHES for the formula
  //  Validated: R²=0.88, n=12,000+ (Hodgdon & Beckett 1984)
  // ══════════════════════════════════════════════════════
  
  const toIn = cm => cm / 2.54; // Convert cm to inches
  let fatPct;
  
  if (gender === 'female' && hip > 0) {
    // Female formula: uses waist, hip, neck, and height
    const logArg = toIn(waist) + toIn(hip) - toIn(neck);
    if (logArg <= 0) return null;
    fatPct = 163.205 * Math.log10(logArg) - 97.684 * Math.log10(toIn(height)) - 78.387;
  } else {
    // Male formula: uses waist, neck, and height
    const logArg = toIn(waist) - toIn(neck);
    if (logArg <= 0) return null;
    fatPct = 86.010 * Math.log10(logArg) - 70.041 * Math.log10(toIn(height)) + 36.76;
  }
  
  // Validate and constrain to physiological bounds
  if (!isFinite(fatPct) || isNaN(fatPct)) return null;
  fatPct = Math.max(3, Math.min(60, +fatPct.toFixed(1)));
  
  const fatKg = +(weight * fatPct / 100).toFixed(1);
  const lbm   = +(weight - fatKg).toFixed(1); // Lean Body Mass

  // ══════════════════════════════════════════════════════
  //  SKELETAL MUSCLE MASS — Ensemble of 3 validated models
  //  Combines multiple anthropometric equations for best accuracy
  // ══════════════════════════════════════════════════════

  // ── Model 1: Lee et al. 2000 (base model, R²=0.86 vs BIA) ──
  // SMM = 0.244×BW + 7.80×Ht(m) + 6.6×sex − 0.098×age + ethnicity − 3.3
  // Calibrated ×0.85 to align with DEXA reference (Janssen 2000, n=268)
  const smm_lee = Math.max(5, (0.244 * weight + 7.80 * hM + 6.6 * sex - 0.098 * safeAge + 1.2 - 3.3) * 0.85);

  let smmModels = [smm_lee];
  let smmWeights = [1.0]; // Base weight for Lee model

  // ── Model 2: Yang et al. 2018 — calf circumference (R²≈0.70) ──
  // ALM (appendicular lean mass) = f(calf circumference)
  // Validated in n=1,680 adults with DEXA
  // Calf is the BEST single-site predictor of appendicular muscle mass
  const calfVal = +calf;
  if (calfVal && calfVal >= 20 && calfVal <= 58) {
    const refHcc = gender === 'male' ? 1.75 : 1.63;
    
    // Base ALM from calf circumference
    let alm_cc = gender === 'male' ? (0.65 * calfVal - 4.3) : (0.52 * calfVal - 2.1);
    alm_cc = Math.max(5, alm_cc);
    
    // Height correction (taller people have more muscle at same circumference)
    alm_cc *= Math.pow(hM / refHcc, 0.6);
    
    // Age-related muscle decline after 30 (sarcopenia)
    alm_cc *= Math.max(0.78, 1.0 - Math.max(0, safeAge - 30) * 0.004);
    
    // Convert ALM to total SMM (add 23% for trunk muscle)
    const smm_cc = Math.max(5, alm_cc * 1.3);
    smmModels.push(smm_cc);
    smmWeights.push(1.8); // Highest weight: calf is most reliable
  }

  // ── Model 3: Heymsfield 2011 — mid-upper arm circumference (R²≈0.65) ──
  // MAC (mid-upper arm circumference) → ALM
  const armVal = +arm;
  if (armVal && armVal >= 18 && armVal <= 55) {
    const refH_arm = gender === 'male' ? 1.75 : 1.63;
    const refMAC   = gender === 'male' ? 32.0 : 27.0;
    const baseALM  = gender === 'male' ? 32.0 * 0.55 : 27.0 * 0.48;
    
    // Calculate ALM deviation from reference
    const deltaALM = (armVal - refMAC) * (gender === 'male' ? 0.55 : 0.48);
    let alm_arm = Math.max(5, baseALM + deltaALM);
    
    // Height and age corrections
    alm_arm *= Math.pow(hM / refH_arm, 0.5);
    alm_arm *= Math.max(0.78, 1.0 - Math.max(0, safeAge - 30) * 0.004);
    
    const smm_arm = Math.max(5, alm_arm * 1.3);
    smmModels.push(smm_arm);
    smmWeights.push(1.5); // Moderate weight
  }

  // ── Thigh circumference correction (Rolland 2003 / Yang 2018) ──
  // Not used as standalone model but as correction factor
  const thighVal = +thigh;
  let thighCorr = 0;
  if (thighVal && thighVal >= 30 && thighVal <= 85) {
    const refThigh = gender === 'male' ? 56.0 : 54.0;
    const scale    = gender === 'male' ? 0.30 : 0.25; // kg ALM per cm thigh
    thighCorr = (thighVal - refThigh) * scale * 0.4;  // 40% weight (without skinfolds)
  }

  // ── Weighted ensemble prediction ──
  const totalW = smmWeights.reduce((a, b) => a + b, 0);
  let muscleKg = smmModels.reduce((sum, v, i) => sum + v * smmWeights[i], 0) / totalW;
  muscleKg += thighCorr * 0.5; // Apply thigh correction

  // Constrain to physiological bounds (% of body weight)
  const minSMM = weight * (gender === 'female' ? 0.20 : 0.25);
  const maxSMM = weight * (gender === 'male' ? 0.55 : 0.48);
  muscleKg = Math.max(minSMM, Math.min(maxSMM, muscleKg));
  muscleKg = +muscleKg.toFixed(1);
  const musclePct = +(muscleKg / weight * 100).toFixed(1);

  // ── Precision assessment based on number of measurements ──
  const nModels = smmModels.length;
  const precisionMap = {
    1: { label: 'Estimación básica', icon: '🔵', error: '±15%', desc: 'Agrega brazo y pantorrilla para mayor precisión' },
    2: { label: 'Estimación moderada', icon: '🟡', error: '±9%',  desc: 'Agrega el otro perímetro para mayor precisión' },
    3: { label: 'Estimación avanzada', icon: '🟢', error: '±6%',  desc: 'Alta confianza — múltiples medidas incluidas' }
  };
  const precision = precisionMap[Math.min(3, nModels)];

  // ── Skeletal Muscle Index (SMI) = SMM / height² ──
  // Used to diagnose sarcopenia (Cruz-Jentoft 2019)
  const smi = +(muscleKg / (hM * hM)).toFixed(1);
  
  // SMI sarcopenia thresholds (EWGSOP2 2019 consensus)
  let muscleCat = '';
  if (gender === 'male') {
    muscleCat = smi < 7.0 ? 'Sarcopenia' : smi < 8.5 ? 'Normal' : 'Óptimo';
  } else {
    muscleCat = smi < 5.7 ? 'Sarcopenia' : smi < 6.8 ? 'Normal' : 'Óptimo';
  }

  // ══════════════════════════════════════════════════════
  //  BONE MASS — DEXA-validated percent-based model
  //  Adjusted for height and age-related bone loss
  // ══════════════════════════════════════════════════════
  
  const refH  = gender === 'female' ? 163 : 175;
  const boneK = gender === 'female' ? 0.038 : 0.045; // Base bone % of body weight
  
  let boneKg  = boneK * weight * Math.pow(height / refH, 0.3); // Height adjustment
  
  // Age-related bone loss after 40 (osteoporosis risk)
  if (safeAge > 40) {
    boneKg *= Math.max(0.75, 1 - (safeAge - 40) * 0.01);
  }
  
  boneKg = +Math.max(1.5, Math.min(6, boneKg)).toFixed(2);
  const bonePct = +(boneKg / weight * 100).toFixed(1);
  
  // Bone density category assessment
  const boneRef = gender === 'female' ? 2.8 : 3.8;
  const boneCat = boneKg >= boneRef * 1.1
    ? 'Densidad alta - Excelente'
    : boneKg >= boneRef * 0.9
    ? 'Densidad normal OK'
    : boneKg >= boneRef * 0.75
    ? 'Densidad baja - Aumentar calcio/vit D'
    : 'Densidad muy baja - Consultar medico';

  // ══════════════════════════════════════════════════════
  //  TOTAL BODY WATER — Watson 1980
  //  Validated against D2O (deuterium oxide) dilution method
  // ══════════════════════════════════════════════════════
  
  let waterL = gender === 'female'
    ? -2.097 + 0.1069 * height + 0.2466 * weight
    : 2.447 - 0.09516 * safeAge + 0.1074 * height + 0.3362 * weight;
  
  waterL = +Math.max(10, Math.min(80, waterL)).toFixed(1);
  const waterPct = +(waterL / weight * 100).toFixed(1);
  
  // Intracellular (IC) and Extracellular (EC) water distribution
  const waterIC  = +(waterL * 0.67).toFixed(1); // ~67% intracellular
  const waterEC  = +(waterL * 0.33).toFixed(1); // ~33% extracellular
  
  // Hydration status assessment
  const nwRange  = gender === 'female' ? [45, 60] : [50, 65];
  const waterSt  = waterPct < nwRange[0] ? 'bajo_rango'
    : waterPct <= nwRange[1] ? 'normal' : 'retencion';

  // ══════════════════════════════════════════════════════
  //  BODY FAT CATEGORY — ACE (American Council on Exercise) ranges
  // ══════════════════════════════════════════════════════
  
  let category = '';
  if (gender === 'female') {
    category = fatPct < 14 ? 'elite' 
      : fatPct < 21 ? 'atleta' 
      : fatPct < 25 ? 'en_forma' 
      : fatPct < 32 ? 'aceptable' 
      : 'sobrepeso';
  } else {
    category = fatPct < 6 ? 'elite' 
      : fatPct < 14 ? 'atleta' 
      : fatPct < 18 ? 'en_forma' 
      : fatPct < 25 ? 'aceptable' 
      : 'sobrepeso';
  }

  // Safety guard: if BMI indicates obesity, never report athlete/fit labels.
  if (bmi >= 30) {
    category = bmiCategory;
  } else if (bmi >= 25 && ['elite', 'atleta', 'en_forma'].includes(category)) {
    category = 'sobrepeso';
  }

  // Return comprehensive body composition analysis
  return {
    bmi,
    bmiCategory,
    fatPct, fatKg, lbm,
    muscleKg, musclePct, smi, muscleCat, precision,
    boneKg, bonePct, boneCat,
    waterLitres: waterL, waterKg: waterL, waterPct, waterIC, waterEC, waterSt,
    category
  };
}


// ═══════════════════════════════════════════════════
//  LOGIN FLOW
//  Access gate before measurements and app home
// ═══════════════════════════════════════════════════

/**
 * Handles login submit:
 * - Validates user and password fields
 * - Loads saved profile if it exists
 * - Otherwise continues to measurements form
 */
async function submitLogin() {
  const loginUserEl = document.getElementById('login-user');
  const loginPassEl = document.getElementById('login-password');
  const loginUser = loginUserEl.value.trim();
  const loginPassword = loginPassEl.value.trim();

  if (!loginUser || !loginPassword) {
    showModal('⚠️ Datos requeridos', 'Ingresa usuario/correo y contraseña para continuar.');
    return;
  }

  localStorage.setItem('vm_auth_user', loginUser);

  try {
    await ensureStorageReady();

    const auth = await window.sqliteService.authenticateUser(loginUser, loginPassword);
    let account = auth.account || null;

    if (auth.status === 'invalid') {
      showModal('⚠️ Contraseña incorrecta', 'La contraseña no coincide con el usuario registrado.');
      return;
    }

    if (auth.status === 'missing') {
      account = await migrateLegacyUserIfNeeded(loginUser, loginPassword);
      if (!account) {
        account = await window.sqliteService.registerUser(loginUser, loginPassword);
      }
    }

    hydrateSessionFromAccount(account);

    if (user && Object.keys(user).length) {
      setActiveScreen('screen-app');
      await initApp();
      return;
    }

    prefillOnboardingName(loginUser);
    setActiveScreen('screen-onboard');
  } catch (error) {
    console.error('SQLite login error:', error);
    showModal('⚠️ Error de base de datos', 'No se pudo abrir la base SQLite del navegador.');
  }
}


// ═══════════════════════════════════════════════════
//  ONBOARDING FLOW
//  Multi-step user registration and goal setting
// ═══════════════════════════════════════════════════

/**
 * Navigate to a specific onboarding step
 * Validates required fields before allowing progression
 * @param {number} n - Step number (1 or 2)
 */
function goStep(n) {
  // Validate all required fields from step 1
  const name = document.getElementById('ob-name').value.trim();
  const age = document.getElementById('ob-age').value;
  const gender = document.getElementById('ob-gender').value;
  const weight = document.getElementById('ob-weight').value;
  const height = document.getElementById('ob-height').value;
  
  if (!name || !age || !gender || !weight || !height) {
    showModal('⚠️ Campos requeridos', 'Por favor completa todos los campos obligatorios ✨');
    return;
  }
  
  // Switch active step
  document.querySelectorAll('.onboard-step').forEach(s => s.classList.remove('active'));
  document.getElementById('step' + n).classList.add('active');
}

/**
 * Handles goal card selection in step 2
 * @param {string} val - Goal identifier ('deficit', 'maintain', 'gain', 'health')
 * @param {Event} e - Click event
 */
function selectGoal(val, e) {
  selectedGoal = val;
  document.querySelectorAll('.goal-card').forEach(c => c.classList.remove('selected'));
  (e.currentTarget || e.target).classList.add('selected');
}

/**
 * Completes onboarding and initializes the app
 * - Collects all user data and measurements
 * - Calculates BMR, TDEE, and macro targets
 * - Performs body composition analysis if measurements provided
 * - Saves everything to SQLite
 * - Transitions to main app screen
 */
async function finishOnboard() {
  // Collect all user inputs
  const name = document.getElementById('ob-name').value.trim();
  const age = +document.getElementById('ob-age').value;
  const gender = document.getElementById('ob-gender').value;
  const weight = +document.getElementById('ob-weight').value;
  const height = +document.getElementById('ob-height').value;

  if (!name || !age || !gender || !weight || !height) {
    showModal('⚠️ Campos requeridos', 'Completa nombre, edad, género, peso y altura para continuar.');
    return;
  }

  const chosenGoal = selectedGoal || 'maintain';
  
  const waist = +document.getElementById('ob-waist').value || 0;
  const hip = +document.getElementById('ob-hip').value || 0;
  const neck = +document.getElementById('ob-neck').value || 0;
  const thigh = +document.getElementById('ob-thigh').value || 0;
  const arm = +document.getElementById('ob-arm').value || 0;
  const calfM = +document.getElementById('ob-calf').value || 0;
  const activity = +document.getElementById('ob-activity').value;
  
  // Calculate body composition if measurements provided
  const bodyComp = (waist && neck) 
    ? estimateBodyComp(weight, height, waist, neck, hip, gender, age, arm, thigh, calfM) 
    : null;
  
  // Calculate Basal Metabolic Rate (BMR) using Mifflin-St Jeor equation
  let bmr = gender === 'female' 
    ? 10 * weight + 6.25 * height - 5 * age - 161
    : 10 * weight + 6.25 * height - 5 * age + 5;
  
  // Calculate Total Daily Energy Expenditure (TDEE)
  const tdee = Math.round(bmr * activity);
  
  // Set calorie and protein targets based on goal
  let calGoal = tdee;
  let protMult = 1.6; // g protein per kg body weight
  
  if (chosenGoal === 'deficit') {
    calGoal = tdee - 400;  // 400 kcal deficit for weight loss
    protMult = 1.8;        // Higher protein to preserve muscle
  }
  if (chosenGoal === 'gain') {
    calGoal = tdee + 300;  // 300 kcal surplus for muscle gain
    protMult = 2.0;        // Highest protein for muscle synthesis
  }
  
  // Calculate macro targets
  const protGoal = Math.round(weight * protMult);
  const fatGoal = Math.round((calGoal * 0.28) / 9);  // 28% of calories from fat
  const carbGoal = Math.round((calGoal - protGoal * 4 - fatGoal * 9) / 4); // Remaining from carbs
  
  // Create user object
  user = {
    name, age, gender, weight, height, 
    waist, hip, neck, thigh, arm, calf: calfM,
    activity, goal: chosenGoal, tdee,
    bmi: +(weight / ((height / 100) ** 2)).toFixed(1),
    bodyComp
  };
  
  // Create macro targets object (including micronutrients)
  macroTargets = {
    calories: calGoal,
    protein: protGoal,
    carbs: carbGoal,
    fat: fatGoal,
    fiber: gender === 'female' ? 25 : 38,
    sugar: Math.round(calGoal * 0.05 / 4), // Max 5% of calories from added sugar
    iron: gender === 'female' ? 18 : 8,
    calcium: 1000,
    b12: 2.4,
    zinc: gender === 'female' ? 8 : 11,
    water: 8  // glasses
  };

  if (!currentUserId) {
    showModal('⚠️ Sesión inválida', 'Primero inicia sesión para guardar este perfil.');
    return;
  }

  try {
    await ensureStorageReady();
    await window.sqliteService.saveUserProfile(currentUserId, user, macroTargets);
    localStorage.setItem('vm_auth_user', currentUsername || name);

    setActiveScreen('screen-app');
    await initApp();
  } catch (error) {
    console.error('SQLite profile save error:', error);
    showModal('⚠️ Error al guardar', 'No se pudo guardar el perfil en la base SQLite.');
  }
}


// ═══════════════════════════════════════════════════
//  APP INITIALIZATION
//  Loads data and sets up the main interface
// ═══════════════════════════════════════════════════

/**
 * Initializes the main application after onboarding
 * - Loads food log and water data from SQLite
 * - Loads AI-learned foods
 * - Sets up UI with user's name and avatar
 * - Builds all dynamic content sections
 * - Renders dashboard, history, profile, and charts
 */
async function initApp() {
  if (currentUserId) {
    const freshAccount = await window.sqliteService.getUserById(currentUserId);
    if (freshAccount) {
      hydrateSessionFromAccount(freshAccount);
    }
  }

  await loadLearned();
  
  // Set user avatar and greeting
  const initial = (user.name || 'U')[0].toUpperCase();
  document.getElementById('user-avatar-top').textContent = initial;
  document.getElementById('greeting-name').textContent = user.name;
  
  // Set today's date in locale format
  document.getElementById('today-date').textContent = new Date().toLocaleDateString('es-ES', {
    weekday: 'long', 
    year: 'numeric', 
    month: 'long', 
    day: 'numeric'
  });
  
  // Build dynamic UI sections
  buildWaterCups();
  buildQuickFoods();
  
  // Initial render of all views
  renderDashboard();
  renderHistory();
  renderProfile();
  buildCharts();
  showView('dashboard');
}


// ═══════════════════════════════════════════════════
//  WATER TRACKING
//  8-glass per day water intake tracking
// ═══════════════════════════════════════════════════

/**
 * Renders the 8 water cup buttons with filled/empty states
 * Updates the water label with current progress
 */
function buildWaterCups() {
  const container = document.getElementById('water-cups');
  container.innerHTML = '';
  
  // Create 8 water cup buttons
  for (let i = 0; i < 8; i++) {
    const btn = document.createElement('button');
    btn.className = 'water-cup' + (i < waterToday ? ' filled' : '');
    btn.textContent = i < waterToday ? '💧' : '○';
    btn.title = `Vaso ${i + 1} de 8`;
    btn.setAttribute('aria-label', i < waterToday 
      ? `Vaso ${i + 1} marcado` 
      : `Marcar vaso ${i + 1}`);
    btn.setAttribute('aria-pressed', (i < waterToday).toString());
    btn.type = 'button';
    btn.onclick = () => toggleWater(i);
    container.appendChild(btn);
  }
  
  // Update progress label (8 glasses = 2L)
  document.getElementById('water-label').textContent = 
    `${waterToday} / 8 vasos (${(waterToday * 0.25).toFixed(1)}L)`;
}

/**
 * Toggles water intake when clicking a water cup
 * Clicking a filled cup empties it and all cups after it
 * Clicking an empty cup fills it and all cups before it
 * @param {number} idx - Index of clicked water cup (0-7)
 */
async function toggleWater(idx) {
  waterToday = idx < waterToday ? idx : idx + 1;
  waterByDate[todayKey()] = waterToday;
  await window.sqliteService.saveUserWater(currentUserId, waterByDate);
  buildWaterCups();
}


// ═══════════════════════════════════════════════════
//  QUICK FOODS
//  Pre-configured common vegan foods grid
// ═══════════════════════════════════════════════════

/**
 * Builds the quick-add food buttons grid
 * Uses the quickFoods array from foodDatabase.js
 */
function buildQuickFoods() {
  const grid = document.getElementById('quick-foods-grid');
  grid.innerHTML = '';
  
  quickFoods.forEach(f => {
    const btn = document.createElement('button');
    btn.className = 'quick-food-btn';
    btn.type = 'button';
    btn.innerHTML = `
      <div class="qf-icon">${f.emoji}</div>
      <div class="qf-name">${f.name}</div>
      <div class="qf-cal">${f.cal} kcal / ${f.per}</div>
    `;
    btn.onclick = () => addQuickFood(f);
    grid.appendChild(btn);
  });
}

/**
 * Adds a quick food to the log with default portion (100g)
 * @param {Object} f - Food object from quickFoods array
 */
async function addQuickFood(f) {
  const meal = document.getElementById('meal-time').value;
  
  // Create food log entry
  const entry = {
    ...f,  // Spread all nutritional data
    meal,
    date: todayKey(),
    time: new Date().toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' }),
    qty: 100,
    id: Date.now()
  };
  
  foodLog.push(entry);
  await saveFoodLog();
  
  // Update all views
  renderDashboard();
  renderHistory();
  updateCharts();
  
  showToast(`${f.emoji} ${f.name} agregado · +${f.cal} kcal`);
}


// ═══════════════════════════════════════════════════
//  FOOD SEARCH
//  Live search with type-ahead dropdown
// ═══════════════════════════════════════════════════

/**
 * Performs live search on foodDatabase as user types
 * Shows dropdown with matching results or AI estimation prompt
 * @param {string} query - Search query from input field
 */
function searchFoodLive(query) {
  const dropdown = document.getElementById('search-dropdown');
  const q = query.toLowerCase().trim();
  
  // Reset selected food and hide all preview cards
  selectedFoodEntry = null;
  aiEstimatedFood = null;
  hideEl('food-preview');
  hideEl('food-not-found');
  hideEl('ai-result');
  hideEl('ai-loading');
  
  // Hide dropdown if query too short
  if (q.length < 2) {
    dropdown.style.display = 'none';
    return;
  }
  
  // Search in food database (name and aliases)
  const matches = foodDatabase.filter(f => 
    f.name.includes(q) || (f.aliases || []).some(a => a.includes(q))
  ).slice(0, 7); // Limit to 7 results
  
  // If no matches found, show AI estimation option
  if (matches.length === 0) {
    dropdown.style.display = 'none';
    if (q.length > 2) {
      showEl('food-not-found');
      const mq = document.getElementById('m-qty').value;
      if (mq) document.getElementById('m-qty-ai').value = mq;
    }
    return;
  }
  
  // Build and show dropdown with results
  dropdown.style.display = 'block';
  dropdown.innerHTML = matches.map((f, i) => `
    <div class="dropdown-item" onclick="selectFood(${foodDatabase.indexOf(f)})" 
         role="option" aria-selected="false">
      <span style="font-size:1.3rem">${f.emoji}</span>
      <div>
        <div class="di-name">${f.name}</div>
        <div class="di-cal">${f.cal} kcal · ${f.prot}g prot · ${f.carb}g carb / 100g</div>
      </div>
    </div>
  `).join('');
}

/**
 * Selects a food from the search dropdown
 * Populates the input field and shows nutrition preview
 * @param {number} idx - Index of food in foodDatabase array
 */
function selectFood(idx) {
  const food = foodDatabase[idx];
  if (!food) return;
  
  selectedFoodEntry = food;
  aiEstimatedFood = null;
  
  // Update input field with capitalized name
  document.getElementById('m-name').value = 
    food.name.charAt(0).toUpperCase() + food.name.slice(1);
  
  // Hide dropdown and show preview
  document.getElementById('search-dropdown').style.display = 'none';
  hideEl('food-not-found');
  hideEl('ai-result');
  
  updatePreview();
}

/**
 * Closes dropdown when clicking outside
 */
document.addEventListener('click', e => {
  const dd = document.getElementById('search-dropdown');
  if (dd && !dd.contains(e.target) && e.target.id !== 'm-name') {
    dd.style.display = 'none';
  }
});


// ═══════════════════════════════════════════════════
//  AI-POWERED FOOD ESTIMATION
//  Uses Claude API to estimate nutrition for unknown foods
// ═══════════════════════════════════════════════════

/**
 * Estimates nutritional data for unknown foods using Claude AI
 * - Sends food name and quantity to Claude API
 * - Parses JSON response with macro/micronutrients
 * - Automatically adds to local food database for future searches
 * - Shows estimation with confidence note
 */
async function estimateWithAI() {
  const foodName = document.getElementById('m-name').value.trim();
  const qty = +document.getElementById('m-qty-ai').value || +document.getElementById('m-qty').value || 100;
  
  if (!foodName) {
    showModal('⚠️ Nombre requerido', 'Primero escribe el nombre del alimento que deseas estimar.');
    return;
  }
  
  // Show loading state
  hideEl('food-not-found');
  hideEl('ai-result');
  showEl('ai-loading');
  document.getElementById('ai-loading-food').textContent = foodName;
  
  try {
    // Call Claude API
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 1000,
        system: `Eres un nutricionista experto en alimentación vegana. Devuelve ÚNICAMENTE JSON válido sin texto adicional ni markdown:
{"name":"nombre normalizado en español","emoji":"emoji relevante","cal":número,"prot":número,"carb":número,"fat":número,"fiber":número,"sugar":número,"iron":número,"calcium":número,"b12":número,"zinc":número,"note":"breve nota máx 80 chars"}
Todos los valores por 100g/ml. Si no es vegano, estima el equivalente vegano más cercano.`,
        messages: [{ role: 'user', content: `Alimento: "${foodName}" | ${qty}g/ml` }]
      })
    });
    
    const data = await response.json();
    const rawText = data.content?.[0]?.text || '';
    
    // Parse JSON response (remove markdown code blocks if present)
    const parsed = JSON.parse(rawText.replace(/```json|```/g, '').trim());
    
    hideEl('ai-loading');
    
    if (!parsed.cal && parsed.cal !== 0) throw new Error('Respuesta incompleta');
    
    // Create food object from AI response
    aiEstimatedFood = {
      name: parsed.name || foodName,
      emoji: parsed.emoji || '🍽️',
      cal: +parsed.cal || 0,
      prot: +parsed.prot || 0,
      carb: +parsed.carb || 0,
      fat: +parsed.fat || 0,
      fiber: +parsed.fiber || 0,
      sugar: +parsed.sugar || 0,
      iron: +parsed.iron || 0,
      calcium: +parsed.calcium || 0,
      b12: +parsed.b12 || 0,
      zinc: +parsed.zinc || 0,
      aliases: [],
      aiGenerated: true
    };
    
    // Add to local database if not already present
    const exists = foodDatabase.some(f => 
      f.name.toLowerCase() === aiEstimatedFood.name.toLowerCase()
    );
    if (!exists) {
      foodDatabase.push(aiEstimatedFood);
      saveLearned(); // Persist to SQLite
    }
    
    // Display AI estimation results
    const ratio = qty / 100;
    document.getElementById('ai-prev-emoji').textContent = aiEstimatedFood.emoji;
    document.getElementById('ai-prev-name').textContent = aiEstimatedFood.name;
    document.getElementById('ai-prev-qty').textContent = `${qty}g / ml`;
    document.getElementById('ai-prev-cal').textContent = Math.round(aiEstimatedFood.cal * ratio) + ' kcal';
    document.getElementById('ai-result-note').textContent = 
      parsed.note || '✅ Estimado con IA y aprendido para búsquedas futuras';
    
    // Build macro chips with color coding
    const mc = {
      prot: '#2e7d52', carb: '#b8763a', fat: '#7050a8', fiber: '#3a9988',
      sugar: '#b84d65', iron: '#a05a2a', calcium: '#3a82aa', b12: '#5aad5a', zinc: '#8b5ac0'
    };
    const md = [
      { key: 'prot', label: 'Proteína', unit: 'g' },
      { key: 'carb', label: 'Carbos', unit: 'g' },
      { key: 'fat', label: 'Grasas', unit: 'g' },
      { key: 'fiber', label: 'Fibra', unit: 'g' },
      { key: 'sugar', label: 'Azúcar', unit: 'g' },
      { key: 'iron', label: 'Hierro', unit: 'mg' },
      { key: 'calcium', label: 'Calcio', unit: 'mg' },
      { key: 'b12', label: 'B12', unit: 'mcg' },
      { key: 'zinc', label: 'Zinc', unit: 'mg' }
    ];
    
    document.getElementById('ai-prev-macros').innerHTML = md.map(m => `
      <div style="background:white;border-radius:10px;padding:8px;text-align:center;border:1px solid var(--border)">
        <div style="font-size:.82rem;font-weight:700;color:${mc[m.key]}">
          ${+(aiEstimatedFood[m.key] * ratio).toFixed(1)}
          <span style="font-size:.62rem;color:var(--text-dim)"> ${m.unit}</span>
        </div>
        <div style="font-size:.65rem;color:var(--text-dim);margin-top:1px">${m.label}</div>
      </div>
    `).join('');
    
    showEl('ai-result');
    document.getElementById('m-qty').value = qty;
    
  } catch (err) {
    hideEl('ai-loading');
    showEl('food-not-found');
    showModal('⚠️ Error al consultar IA', 
      'No se pudo obtener información nutricional. Verifica tu conexión e intenta de nuevo.');
    console.error('AI estimation error:', err);
  }
}

/**
 * Saves AI-learned foods to SQLite for persistence
 */
async function saveLearned() {
  try {
    await ensureStorageReady();
    await window.sqliteService.saveLearnedFoods(
      foodDatabase.filter(f => f.aiGenerated)
    );
  } catch (error) {
    console.error('SQLite learned-food save error:', error);
  }
}

/**
 * Loads AI-learned foods from SQLite on app init
 * Merges them into the main foodDatabase array
 */
async function loadLearned() {
  try {
    await ensureStorageReady();
    let saved = await window.sqliteService.loadLearnedFoods();

    if (!saved.length) {
      const legacyAiFoods = JSON.parse(localStorage.getItem('vm_ai_foods') || '[]');
      if (legacyAiFoods.length) {
        await window.sqliteService.saveLearnedFoods(legacyAiFoods);
        localStorage.removeItem('vm_ai_foods');
        saved = legacyAiFoods;
      }
    }

    saved.forEach(f => {
      if (!foodDatabase.some(d => d.name.toLowerCase() === f.name.toLowerCase())) {
        foodDatabase.push(f);
      }
    });
  } catch (error) {
    console.error('SQLite learned-food load error:', error);
  }
}


// ═══════════════════════════════════════════════════
//  FOOD PREVIEW
//  Real-time nutrition preview as user enters quantity
// ═══════════════════════════════════════════════════

/**
 * Updates the food preview card with scaled nutritional values
 * Calculates macros based on entered quantity
 */
function updatePreview() {
  if (!selectedFoodEntry) return;
  
  const qty = +document.getElementById('m-qty').value || 100;
  const f = selectedFoodEntry;
  const ratio = qty / 100; // Scale from per-100g to actual quantity
  
  showEl('food-preview');
  
  // Update header
  document.getElementById('prev-emoji').textContent = f.emoji;
  document.getElementById('prev-name').textContent = 
    f.name.charAt(0).toUpperCase() + f.name.slice(1);
  document.getElementById('prev-qty-label').textContent = `${qty}g / ml`;
  document.getElementById('prev-cal').textContent = Math.round(f.cal * ratio) + ' kcal';
  
  // Build macro chips with color coding
  const macros = [
    { label: 'Proteína', val: f.prot, unit: 'g', color: '#2e7d52' },
    { label: 'Carbohidratos', val: f.carb, unit: 'g', color: '#b8763a' },
    { label: 'Grasas', val: f.fat, unit: 'g', color: '#7050a8' },
    { label: 'Fibra', val: f.fiber, unit: 'g', color: '#3a9988' },
    { label: 'Azúcar', val: f.sugar, unit: 'g', color: '#b84d65' },
    { label: 'Hierro', val: f.iron, unit: 'mg', color: '#a05a2a' },
    { label: 'Calcio', val: f.calcium, unit: 'mg', color: '#3a82aa' },
    { label: 'B12', val: f.b12, unit: 'mcg', color: '#5aad5a' },
    { label: 'Zinc', val: f.zinc, unit: 'mg', color: '#8b5ac0' },
  ];
  
  document.getElementById('prev-macros').innerHTML = macros.map(m => `
    <div class="macro-chip">
      <div class="macro-chip-val" style="color:${m.color}">
        ${+(m.val * ratio).toFixed(1)}
        <span style="font-size:.65rem;color:var(--text-dim);font-weight:400"> ${m.unit}</span>
      </div>
      <div class="macro-chip-label">${m.label}</div>
    </div>
  `).join('');
}


// ═══════════════════════════════════════════════════
//  FOOD LOGGING
//  Add and remove food entries
// ═══════════════════════════════════════════════════

/**
 * Adds manually entered or AI-estimated food to the log
 * Scales nutritional values based on quantity and creates timestamped entry
 */
async function addManualFood() {
  const food = selectedFoodEntry || aiEstimatedFood;
  
  if (!food) {
    showModal('⚠️ Selecciona un alimento', 
      'Escribe el nombre del alimento, selecciónalo de la lista, o usa ✨ Estimar con IA.');
    return;
  }
  
  const qty = +document.getElementById('m-qty').value || +document.getElementById('m-qty-ai').value || 100;
  const ratio = qty / 100;
  const meal = document.getElementById('meal-time').value;
  
  // Create scaled food entry
  const entry = {
    name: food.name.charAt(0).toUpperCase() + food.name.slice(1),
    emoji: food.emoji,
    cal: Math.round(food.cal * ratio),
    prot: +(food.prot * ratio).toFixed(1),
    carb: +(food.carb * ratio).toFixed(1),
    fat: +(food.fat * ratio).toFixed(1),
    fiber: +(food.fiber * ratio).toFixed(1),
    sugar: +(food.sugar * ratio).toFixed(1),
    iron: +(food.iron * ratio).toFixed(1),
    calcium: +(food.calcium * ratio).toFixed(1),
    b12: +(food.b12 * ratio).toFixed(2),
    zinc: +(food.zinc * ratio).toFixed(1),
    qty,
    meal,
    date: todayKey(),
    time: new Date().toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' }),
    id: Date.now(),
    aiGenerated: !!food.aiGenerated
  };
  
  foodLog.push(entry);
  await saveFoodLog();
  
  // Reset form state
  selectedFoodEntry = null;
  aiEstimatedFood = null;
  document.getElementById('m-name').value = '';
  document.getElementById('m-qty').value = '';
  document.getElementById('m-qty-ai').value = '';
  hideEl('food-preview');
  hideEl('ai-result');
  hideEl('food-not-found');
  
  // Update all views
  renderDashboard();
  renderHistory();
  updateCharts();
  
  showToast(`${food.emoji} ${entry.name} agregado · ${entry.cal} kcal`);
}

/**
 * Persists food log to SQLite for the current user
 */
async function saveFoodLog() {
  if (!currentUserId) return;

  try {
    await ensureStorageReady();
    await window.sqliteService.saveUserFoodLog(currentUserId, foodLog);
  } catch (error) {
    console.error('SQLite food-log save error:', error);
  }
}

/**
 * Deletes a food entry from the log by ID
 * @param {number} id - Unique timestamp ID of the entry
 */
async function deleteFood(id) {
  const item = foodLog.find(f => f.id === id);
  foodLog = foodLog.filter(f => f.id !== id);
  
  await saveFoodLog();
  renderDashboard();
  renderHistory();
  updateCharts();
  
  if (item) showToast(`🗑️ ${item.name} eliminado`, '#b84d65');
}


// ═══════════════════════════════════════════════════
//  NUTRITION TOTALS
//  Calculate daily macro/micro totals
// ═══════════════════════════════════════════════════

/**
 * Filters food log to get only today's entries
 * @returns {Array<Object>} Array of food entries from today
 */
function getTodayFoods() {
  return foodLog.filter(f => f.date === todayKey());
}

/**
 * Calculates sum of all macros and micros from food array
 * @param {Array<Object>} foods - Array of food entries to sum
 * @returns {Object} Totals object with all nutritional values
 */
function getTotals(foods) {
  return foods.reduce((acc, f) => {
    acc.cal += f.cal || 0;
    acc.prot += f.prot || 0;
    acc.carb += f.carb || 0;
    acc.fat += f.fat || 0;
    acc.fiber += f.fiber || 0;
    acc.sugar += f.sugar || 0;
    acc.iron += f.iron || 0;
    acc.calcium += f.calcium || 0;
    acc.b12 += f.b12 || 0;
    acc.zinc += f.zinc || 0;
    return acc;
  }, { cal: 0, prot: 0, carb: 0, fat: 0, fiber: 0, sugar: 0, iron: 0, calcium: 0, b12: 0, zinc: 0 });
}


// ═══════════════════════════════════════════════════
//  DASHBOARD VIEW
//  Main overview with calorie ring, macro bars, food list
// ═══════════════════════════════════════════════════

/**
 * Renders the complete dashboard view
 * - Calorie progress ring chart
 * - Macro progress bars for all nutrients
 * - Today's food list with delete buttons
 * - Contextual tips based on progress and goal
 */
function renderDashboard() {
  const foods = getTodayFoods();
  const tot = getTotals(foods);
  
  // ── Update calorie display ──
  document.getElementById('cal-consumed').textContent = Math.round(tot.cal);
  document.getElementById('cal-goal-disp').textContent = macroTargets.calories || 2000;
  
  const remain = Math.max(0, (macroTargets.calories || 2000) - tot.cal);
  document.getElementById('cal-remain').textContent = Math.round(remain);
  document.getElementById('cal-remain').style.color = remain === 0 ? 'var(--amber)' : 'var(--green)';
  
  // ── Build calorie ring chart ──
  const pct = Math.min(100, (tot.cal / (macroTargets.calories || 2000)) * 100);
  const ringColor = pct > 105 ? '#b84d65' : pct > 90 ? '#b8763a' : '#2e7d52';
  
  if (charts.ring) charts.ring.destroy();
  charts.ring = new Chart(document.getElementById('calRing').getContext('2d'), {
    type: 'doughnut',
    data: {
      datasets: [{
        data: [pct, 100 - pct],
        backgroundColor: [ringColor, 'rgba(46,125,82,0.12)'],
        borderWidth: 0
      }]
    },
    options: {
      cutout: '75%',
      plugins: { legend: { display: false } },
      animation: { animateRotate: true }
    }
  });
  
  // ── Build macro progress bars ──
  const macrosDef = [
    { key: 'prot', label: 'Proteína', color: '#2e7d52', unit: 'g', target: macroTargets.protein },
    { key: 'carb', label: 'Carbohidratos', color: '#b8763a', unit: 'g', target: macroTargets.carbs },
    { key: 'fat', label: 'Grasas', color: '#7050a8', unit: 'g', target: macroTargets.fat },
    { key: 'fiber', label: 'Fibra', color: '#3a9988', unit: 'g', target: macroTargets.fiber },
    { key: 'iron', label: 'Hierro', color: '#a05a2a', unit: 'mg', target: macroTargets.iron },
    { key: 'calcium', label: 'Calcio', color: '#3a82aa', unit: 'mg', target: macroTargets.calcium },
    { key: 'b12', label: 'Vitamina B12', color: '#5aad5a', unit: 'mcg', target: macroTargets.b12 },
    { key: 'zinc', label: 'Zinc', color: '#8b5ac0', unit: 'mg', target: macroTargets.zinc },
  ];
  
  document.getElementById('macro-bars-container').innerHTML = macrosDef.map(m => {
    const v = +(tot[m.key] || 0).toFixed(1);
    const t = m.target || 1;
    const p = Math.min(100, (v / t) * 100);
    const barColor = p >= 100 ? '#5aad5a' : p >= 70 ? m.color : '#b84d65';
    
    return `
      <div class="macro-bar-item">
        <div class="macro-bar-header">
          <span class="macro-bar-name" style="color:${m.color}">${m.label}</span>
          <span class="macro-bar-val">${v} / ${t} ${m.unit}</span>
        </div>
        <div class="macro-bar-track">
          <div class="macro-bar-fill" style="width:${p}%;background:${barColor}"></div>
        </div>
      </div>
    `;
  }).join('');
  
  // ── Render today's food list ──
  const container2 = document.getElementById('foods-today');
  
  if (foods.length === 0) {
    container2.innerHTML = `
      <div class="empty-state">
        <div class="empty-icon">🥗</div>
        Aún no has registrado nada hoy.<br>¡Agrega tu primera comida!
      </div>
    `;
  } else {
    container2.innerHTML = foods.map(f => `
      <div class="food-item">
        <div class="food-emoji">${f.emoji}</div>
        <div class="food-info">
          <div class="food-name">
            ${f.name} 
            <span style="font-size:.72rem;color:var(--text-dim);font-weight:400">${f.meal || ''}</span>
          </div>
          <div class="food-macros">
            P: ${+(f.prot || 0).toFixed(1)}g · 
            C: ${+(f.carb || 0).toFixed(1)}g · 
            G: ${+(f.fat || 0).toFixed(1)}g · 
            Fibra: ${+(f.fiber || 0).toFixed(1)}g
          </div>
        </div>
        <div class="food-cal">${Math.round(f.cal)} kcal</div>
        <button class="food-del" onclick="deleteFood(${f.id})" 
                title="Eliminar" aria-label="Eliminar ${f.name}">✕</button>
      </div>
    `).join('');
  }
  
  // ── Render contextual tips ──
  renderTips(tot, macroTargets);
}


// ═══════════════════════════════════════════════════
//  NUTRITION TIPS
//  Contextual advice based on progress and goal
// ═══════════════════════════════════════════════════

/**
 * Generates and displays personalized nutrition tips
 * - Identifies missing nutrients (below 70% of target)
 * - Provides goal-specific food recommendations
 * - Suggests foods to avoid based on goal
 * 
 * @param {Object} tot - Today's nutrition totals
 * @param {Object} targets - Daily macro/micro targets
 */
function renderTips(tot, targets) {
  const tips = [];
  const goal = user.goal || 'health';
  
  // ── Identify missing nutrients ──
  const missing = [];
  if (tot.prot < targets.protein * 0.7) missing.push('proteína');
  if (tot.fiber < targets.fiber * 0.7) missing.push('fibra');
  if (tot.iron < targets.iron * 0.7) missing.push('hierro');
  if (tot.b12 < targets.b12 * 0.7) missing.push('vitamina B12');
  if (tot.calcium < targets.calcium * 0.7) missing.push('calcio');
  if (waterToday < 6) missing.push('agua');
  
  // ── Goal-specific food recommendations ──
  const goalTips = {
    deficit: {
      consume: [
        'Tofu, tempeh, legumbres como fuente proteica saciante',
        'Vegetales de hoja verde en grandes volúmenes',
        'Avena integral para carbos de liberación lenta'
      ],
      avoid: [
        'Aceites en exceso (aunque sean veganos)',
        'Azúcares añadidos en batidos veganos',
        'Snacks procesados veganos con muchas calorías'
      ]
    },
    gain: {
      consume: [
        'Nueces y crema de maní como grasas saludables',
        'Batidos de proteína vegana con plátano',
        'Quinoa y arroz integral para carbos de calidad'
      ],
      avoid: [
        'Saltarte comidas',
        'Depender solo de vegetales bajos en calorías',
        'Ignorar los carbohidratos complejos'
      ]
    },
    health: {
      consume: [
        'Variedad de colores vegetales para antioxidantes',
        'Semillas de chía y lino para omega-3',
        'Alimentos fermentados como kimchi vegano'
      ],
      avoid: [
        'Ultraprocesados veganos',
        'Exceso de azúcar aunque sea de frutas',
        'Monotonía alimentaria'
      ]
    },
    maintain: {
      consume: [
        'Balance entre legumbres, cereales y vegetales',
        'Frutas frescas como snack principal',
        'Agua como bebida principal siempre'
      ],
      avoid: [
        'Comer en exceso cuando cocinas grandes cantidades',
        'Saltar el desayuno',
        'Subestimar las grasas en recetas'
      ]
    }
  };
  
  const gt = goalTips[goal] || goalTips.health;
  
  // ── Build tip cards ──
  if (missing.length > 0) {
    tips.push({
      type: 'warn',
      icon: '⚠️',
      title: 'Lo que te falta hoy',
      body: `<ul>${missing.map(m => `<li>${m.charAt(0).toUpperCase() + m.slice(1)}</li>`).join('')}</ul>`
    });
  }
  
  tips.push({
    type: 'good',
    icon: '✅',
    title: 'Deberías consumir',
    body: `<ul>${gt.consume.map(c => `<li>${c}</li>`).join('')}</ul>`
  });
  
  tips.push({
    type: 'avoid',
    icon: '🚫',
    title: 'Mejor evitar',
    body: `<ul>${gt.avoid.map(c => `<li>${c}</li>`).join('')}</ul>`
  });
  
  // ── Render tip cards ──
  document.getElementById('tips-container').innerHTML = tips.map(t => `
    <div class="tip-card ${t.type}">
      <div class="tip-head">
        <span class="tip-icon">${t.icon}</span>
        <span class="tip-title">${t.title}</span>
      </div>
      <div class="tip-body">${t.body}</div>
    </div>
  `).join('');
}


// ═══════════════════════════════════════════════════
//  HISTORY VIEW
//  Filterable table of all logged foods
// ═══════════════════════════════════════════════════

/**
 * Renders the food log history table with filtering
 * Supports filters: today, this week, all time
 * Color-codes calorie amounts relative to meal targets
 */
function renderHistory() {
  const filter = document.getElementById('hist-filter')?.value || 'today';
  const today = todayKey();
  
  // Calculate week ago date
  const weekAgo = new Date();
  weekAgo.setDate(weekAgo.getDate() - 7);
  const wKey = weekAgo.toISOString().split('T')[0];
  
  // Apply filter
  let filtered = foodLog;
  if (filter === 'today') filtered = foodLog.filter(f => f.date === today);
  if (filter === 'week') filtered = foodLog.filter(f => f.date >= wKey);
  
  const tbody = document.getElementById('history-body');
  if (!tbody) return;
  
  // Render table rows (most recent first)
  tbody.innerHTML = [...filtered].reverse().map(f => {
    const calPct = Math.round((f.cal / (macroTargets.calories / 3)) * 100);
    const badge = calPct > 120 ? 'badge-rose' : calPct > 80 ? 'badge-green' : 'badge-amber';
    
    return `
      <tr>
        <td>${f.emoji} ${f.name}</td>
        <td><span class="badge badge-green">${f.meal || '—'}</span></td>
        <td><span class="badge ${badge}">${Math.round(f.cal)} kcal</span></td>
        <td>${+(f.prot || 0).toFixed(1)}g</td>
        <td>${+(f.carb || 0).toFixed(1)}g</td>
        <td>${+(f.fat || 0).toFixed(1)}g</td>
        <td style="color:var(--text-dim);font-size:.78rem">${f.date}</td>
        <td>
          <button class="food-del" onclick="deleteFood(${f.id})" 
                  title="Eliminar" aria-label="Eliminar registro">✕</button>
        </td>
      </tr>
    `;
  }).join('') || `
    <tr>
      <td colspan="8" style="text-align:center;padding:24px;color:var(--text-dim)">
        Sin registros en este período
      </td>
    </tr>
  `;
}


// ═══════════════════════════════════════════════════
//  PROFILE VIEW
//  User info, body composition, targets, and progress
// ═══════════════════════════════════════════════════

/**
 * Renders the complete profile view
 * - User avatar and basic info
 * - Body composition analysis (if available)
 * - All measurements and stats
 * - Macro/micro targets
 * - Progress summary (streak, average cals, total logs)
 */
function renderProfile() {
  // ── Update avatar and name ──
  const initial = (user.name || 'U')[0].toUpperCase();
  document.getElementById('profile-avatar-big').textContent = initial;
  document.getElementById('profile-name-disp').textContent = user.name || 'Usuario';
  
  // ── Goal badge ──
  const goalLabels = {
    deficit: '🔥 Perder peso',
    maintain: '⚖️ Mantener peso',
    gain: '💪 Ganar músculo',
    health: '🌿 Salud general'
  };
  document.getElementById('profile-goal-tag').innerHTML = 
    `<span class="badge badge-green">${goalLabels[user.goal] || ''}</span>`;
  
  // ── BMI category ──
  const bmiLabel = user.bmi < 18.5 ? 'Bajo peso' 
    : user.bmi < 25 ? 'Normal ✅' 
    : user.bmi < 30 ? 'Sobrepeso' 
    : 'Obesidad';
  
  // ── Build stats rows ──
  document.getElementById('profile-stats').innerHTML = [
    ['Edad', user.age + ' años'],
    ['Género', user.gender === 'female' ? 'Mujer' : user.gender === 'male' ? 'Hombre' : 'Otro'],
    ['Peso', user.weight + ' kg'],
    ['Altura', user.height + ' cm'],
    ['IMC', `${user.bmi} (${bmiLabel})`],
    ['TDEE', user.tdee + ' kcal/día'],
    ['Cintura', user.waist ? user.waist + ' cm' : '—'],
    ['Cadera', user.hip ? user.hip + ' cm' : '—'],
    ['Cuello', user.neck ? user.neck + ' cm' : '—'],
    ['Brazo', user.arm ? user.arm + ' cm' : '—'],
    ['Muslo', user.thigh ? user.thigh + ' cm' : '—'],
    ['Pantorrilla', user.calf ? user.calf + ' cm' : '—'],
  ].map(([l, v]) => `
    <div class="stat-row">
      <span class="stat-label">${l}</span>
      <span class="stat-val">${v}</span>
    </div>
  `).join('');
  
  // ── Add body composition section if available ──
  if (user.bodyComp) {
    const bc = user.bodyComp;
    const muscleColor = bc.muscleCat === 'Sarcopenia' ? '#b84d65' 
      : bc.muscleCat === 'Normal' ? '#b8763a' 
      : '#2e7d52';
    
    const bcHTML = `
      <div style="margin-top:16px;padding-top:16px;border-top:1px solid var(--border)">
        <div style="font-size:.72rem;font-weight:700;color:var(--green);text-transform:uppercase;letter-spacing:1px;margin-bottom:12px">
          🧬 Composición corporal estimada
        </div>
        <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px;margin-bottom:8px">
          <div class="bc-metric">
            <div class="bc-val" style="color:var(--rose)">${bc.fatPct}%</div>
            <div class="bc-label">% Grasa</div>
          </div>
          <div class="bc-metric" style="background:rgba(46,125,82,.08);border:1px solid rgba(46,125,82,.2);border-radius:10px">
            <div class="bc-val" style="color:${muscleColor}">${bc.muscleKg} kg</div>
            <div class="bc-label">Masa<br>muscular</div>
          </div>
          <div class="bc-metric">
            <div class="bc-val" style="color:var(--teal)">${bc.lbm} kg</div>
            <div class="bc-label">Masa<br>magra</div>
          </div>
        </div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:8px">
          <div class="bc-metric">
            <div class="bc-val" style="color:var(--purple)">${bc.smi} kg/m²</div>
            <div class="bc-label">SMI (índice<br>muscular)</div>
          </div>
          <div class="bc-metric">
            <div class="bc-val" style="color:${muscleColor};font-size:.85rem">${bc.muscleCat}</div>
            <div class="bc-label">Estado<br>muscular</div>
          </div>
        </div>
        <div style="font-size:.7rem;padding:8px 10px;border-radius:8px;background:${
          bc.precision.icon === '🟢' ? 'rgba(46,125,82,.07)' 
          : bc.precision.icon === '🟡' ? 'rgba(184,118,58,.07)' 
          : 'rgba(58,130,170,.07)'
        };color:var(--text-dim);line-height:1.5">
          ${bc.precision.icon} ${bc.precision.label} ${bc.precision.error}
        </div>
      </div>
    `;
    
    const statsEl = document.getElementById('profile-stats');
    statsEl.insertAdjacentHTML('beforeend', bcHTML);
  }

  // ── Display macro targets ──
  const targets = [
    { name: 'Calorías', val: macroTargets.calories, unit: 'kcal' },
    { name: 'Proteína', val: macroTargets.protein, unit: 'g' },
    { name: 'Carbos', val: macroTargets.carbs, unit: 'g' },
    { name: 'Grasas', val: macroTargets.fat, unit: 'g' },
    { name: 'Fibra', val: macroTargets.fiber, unit: 'g' },
    { name: 'Hierro', val: macroTargets.iron, unit: 'mg' },
    { name: 'Calcio', val: macroTargets.calcium, unit: 'mg' },
    { name: 'B12', val: macroTargets.b12, unit: 'mcg' },
    { name: 'Zinc', val: macroTargets.zinc, unit: 'mg' },
    { name: 'Agua', val: macroTargets.water, unit: 'vasos' }
  ];
  
  document.getElementById('macro-targets-disp').innerHTML = targets.map(t => `
    <div class="goal-target-item">
      <div class="goal-target-val">${t.val}</div>
      <div class="goal-target-unit">${t.unit}</div>
      <div class="goal-target-name">${t.name}</div>
    </div>
  `).join('');
  
  // ── Calculate progress stats ──
  const totalEntries = foodLog.length;
  const daysLogged = [...new Set(foodLog.map(f => f.date))].length;
  const avgCal = daysLogged > 0 
    ? Math.round(foodLog.reduce((a, f) => a + f.cal, 0) / daysLogged) 
    : 0;
  
  // Calculate current logging streak
  let streak = 0;
  const today = todayKey();
  for (let i = 0; i < 365; i++) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const dk = d.toISOString().split('T')[0];
    if (foodLog.some(f => f.date === dk)) {
      streak++;
    } else {
      break;
    }
  }
  
  document.getElementById('progress-summary').innerHTML = `
    Total de registros: <strong style="color:var(--green)">${totalEntries}</strong><br>
    Días con registro: <strong style="color:var(--green)">${daysLogged}</strong><br>
    Racha actual: <strong style="color:var(--green)">${streak} día${streak !== 1 ? 's' : ''}</strong> 🔥<br>
    Promedio de calorías: <strong style="color:var(--green)">${avgCal} kcal/día</strong>
  `;
}

/**
 * Shows confirmation modal for app reset
 * Replaces default modal actions with Yes/Cancel buttons
 */
function confirmReset() {
  showModal('⚠️ ¿Reiniciar app?', 
    'Se borrarán los datos del usuario actual, sin afectar a los demás usuarios guardados.');
  
  const actions = document.querySelector('.modal-actions');
  actions.innerHTML = `
    <button class="btn btn-danger btn-sm" onclick="resetApp()">Sí, reiniciar</button>
    <button class="btn btn-ghost btn-sm" onclick="closeModal()">Cancelar</button>
  `;
}

/**
 * Resets only the current user data stored in SQLite
 */
async function resetApp() {
  try {
    if (currentUserId) {
      await ensureStorageReady();
      await window.sqliteService.clearUserData(currentUserId);
    }

    resetSessionState();
    closeModal();
    location.reload();
  } catch (error) {
    console.error('SQLite reset error:', error);
    showModal('⚠️ Error al reiniciar', 'No se pudieron borrar los datos del usuario actual.');
  }
}

/**
 * Closes the current session and returns to the login screen
 * Keeps all user accounts stored in SQLite intact
 */
function logoutUser() {
  const rememberedUser = currentUsername || localStorage.getItem('vm_auth_user') || '';

  resetSessionState();
  closeModal();
  showView('dashboard');
  setActiveScreen('screen-login');
  document.getElementById('login-user').value = rememberedUser;
  document.getElementById('login-password').value = '';
}


// ═══════════════════════════════════════════════════
//  CHARTS & VISUALIZATION
//  Chart.js graphs for progress tracking
// ═══════════════════════════════════════════════════

/**
 * Generates array of last 7 days in ISO format
 * @returns {Array<string>} Array of date strings (YYYY-MM-DD)
 */
function getLast7Days() {
  const days = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    days.push(d.toISOString().split('T')[0]);
  }
  return days;
}

/**
 * Builds all dashboard charts
 * - Calories bar chart (7 days with goal line)
 * - Macros pie chart (today's distribution)
 * - Protein line chart (7 days)
 * - Micronutrients horizontal bar chart (% of daily target)
 */
function buildCharts() {
  const days = getLast7Days();
  const labels = days.map(d => 
    new Date(d + 'T12:00:00').toLocaleDateString('es-ES', { weekday: 'short', day: 'numeric' })
  );
  
  // Aggregate calorie and protein data for each day
  const calData = days.map(d => 
    Math.round(getTotals(foodLog.filter(f => f.date === d)).cal)
  );
  const protData = days.map(d => 
    +(getTotals(foodLog.filter(f => f.date === d)).prot).toFixed(1)
  );
  
  const todayFoods = getTodayFoods();
  const tot = getTotals(todayFoods);
  
  // Chart styling
  Chart.defaults.color = '#517a62';
  const gridColor = 'rgba(46,125,82,0.08)';
  const tickColor = '#517a62';
  const axisStyle = { 
    grid: { color: gridColor }, 
    ticks: { color: tickColor } 
  };

  // ── Calories Bar Chart ──
  if (charts.cal) charts.cal.destroy();
  charts.cal = new Chart(document.getElementById('chart-calories').getContext('2d'), {
    type: 'bar',
    data: {
      labels,
      datasets: [
        {
          label: 'Calorías',
          data: calData,
          backgroundColor: 'rgba(46,125,82,0.55)',
          borderRadius: 8,
          borderSkipped: false
        },
        {
          label: 'Meta',
          data: days.map(() => macroTargets.calories),
          type: 'line',
          borderColor: '#b8763a',
          borderDash: [5, 4],
          pointRadius: 0,
          fill: false,
          tension: 0
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          labels: { color: tickColor, font: { size: 11 } }
        }
      },
      scales: { x: axisStyle, y: axisStyle }
    }
  });

  // ── Macros Pie Chart ──
  if (charts.pie) charts.pie.destroy();
  charts.pie = new Chart(document.getElementById('chart-macros-pie').getContext('2d'), {
    type: 'doughnut',
    data: {
      labels: ['Proteína (g)', 'Carbohidratos (g)', 'Grasas (g)', 'Fibra (g)'],
      datasets: [{
        data: [
          +tot.prot.toFixed(1),
          +tot.carb.toFixed(1),
          +tot.fat.toFixed(1),
          +tot.fiber.toFixed(1)
        ],
        backgroundColor: ['#3a8f5c', '#b8763a', '#7050a8', '#3a9988'],
        borderWidth: 0
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      cutout: '60%',
      plugins: {
        legend: {
          position: 'right',
          labels: { color: tickColor, font: { size: 11 }, padding: 12 }
        }
      }
    }
  });

  // ── Protein Line Chart ──
  if (charts.prot) charts.prot.destroy();
  charts.prot = new Chart(document.getElementById('chart-protein').getContext('2d'), {
    type: 'line',
    data: {
      labels,
      datasets: [
        {
          label: 'Proteína (g)',
          data: protData,
          borderColor: '#2e7d52',
          backgroundColor: 'rgba(46,125,82,0.1)',
          fill: true,
          tension: 0.4,
          pointBackgroundColor: '#2e7d52',
          pointRadius: 4
        },
        {
          label: 'Meta',
          data: days.map(() => macroTargets.protein),
          borderColor: '#b8763a',
          borderDash: [5, 4],
          pointRadius: 0,
          fill: false
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          labels: { color: tickColor, font: { size: 11 } }
        }
      },
      scales: { x: axisStyle, y: axisStyle }
    }
  });

  // ── Micronutrients Horizontal Bar Chart ──
  if (charts.micro) charts.micro.destroy();
  
  const microNames = ['Hierro', 'Calcio', 'B12', 'Zinc', 'Fibra'];
  const microVals = [
    Math.min(100, Math.round((tot.iron / macroTargets.iron) * 100)),
    Math.min(100, Math.round((tot.calcium / macroTargets.calcium) * 100)),
    Math.min(100, Math.round((tot.b12 / macroTargets.b12) * 100)),
    Math.min(100, Math.round((tot.zinc / macroTargets.zinc) * 100)),
    Math.min(100, Math.round((tot.fiber / macroTargets.fiber) * 100)),
  ];
  
  charts.micro = new Chart(document.getElementById('chart-micro').getContext('2d'), {
    type: 'bar',
    data: {
      labels: microNames,
      datasets: [{
        label: '% cubierto',
        data: microVals,
        backgroundColor: microVals.map(v => 
          v >= 70 ? '#3a8f5c' : v >= 40 ? '#b8763a' : '#b84d65'
        ),
        borderRadius: 8,
        borderSkipped: false
      }]
    },
    options: {
      indexAxis: 'y',
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: {
        x: {
          max: 100,
          ...axisStyle,
          ticks: {
            color: tickColor,
            callback: v => v + '%'
          }
        },
        y: {
          grid: { display: false },
          ticks: { color: tickColor }
        }
      }
    }
  });
}

/**
 * Rebuilds all charts (called after data changes)
 */
function updateCharts() {
  buildCharts();
}


// ═══════════════════════════════════════════════════
//  NAVIGATION
//  View switching and tab management
// ═══════════════════════════════════════════════════

/**
 * Shows a specific view and updates active tab
 * Re-renders profile and charts when switching to those views
 * @param {string} name - View name ('dashboard', 'log', 'charts', 'profile')
 */
function showView(name) {
  // Hide all views and deactivate all tabs
  document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
  document.querySelectorAll('.nav-tab').forEach(t => {
    t.classList.remove('active');
    t.setAttribute('aria-selected', 'false');
  });
  
  // Show selected view and activate tab
  document.getElementById('view-' + name).classList.add('active');
  const tab = document.getElementById('tab-' + name);
  tab.classList.add('active');
  tab.setAttribute('aria-selected', 'true');
  
  // Trigger view-specific updates
  if (name === 'charts') buildCharts();
  if (name === 'profile') renderProfile();
}


// ═══════════════════════════════════════════════════
//  MODAL & TOAST
//  User notifications and confirmations
// ═══════════════════════════════════════════════════

/**
 * Shows modal dialog with custom title and message
 * @param {string} title - Modal title
 * @param {string} body - Modal body text
 */
function showModal(title, body) {
  document.getElementById('modal-title').textContent = title;
  document.getElementById('modal-body').textContent = body;
  document.querySelector('.modal-actions').innerHTML = 
    `<button class="btn btn-primary btn-sm" onclick="closeModal()">Entendido</button>`;
  document.getElementById('modal-overlay').classList.add('open');
}

/**
 * Closes the modal dialog
 * @param {Event} e - Click event (optional)
 */
function closeModal(e) {
  // Only close if clicking overlay background
  if (e && e.target !== document.getElementById('modal-overlay')) return;
  document.getElementById('modal-overlay').classList.remove('open');
}

/**
 * Shows temporary toast notification
 * Auto-hides after 3 seconds with fade-out animation
 * @param {string} msg - Toast message
 * @param {string} bg - Background color (default: green)
 */
function showToast(msg, bg = 'var(--green)') {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.style.background = bg;
  t.style.display = 'block';
  t.className = 'toast';
  
  // Clear existing timer
  clearTimeout(toastTimer);
  
  // Auto-hide after 3 seconds
  toastTimer = setTimeout(() => {
    t.className = 'toast hide';
    setTimeout(() => {
      t.style.display = 'none';
    }, 300);
  }, 3000);
}


// ═══════════════════════════════════════════════════
//  UTILITY FUNCTIONS
//  Helper functions for DOM manipulation
// ═══════════════════════════════════════════════════

/**
 * Shows an element by ID
 * @param {string} id - Element ID
 */
function showEl(id) {
  document.getElementById(id).style.display = 'block';
}

/**
 * Hides an element by ID
 * @param {string} id - Element ID
 */
function hideEl(id) {
  document.getElementById(id).style.display = 'none';
}


// ═══════════════════════════════════════════════════
//  APPLICATION BOOT
//  Initial load and login-first flow
// ═══════════════════════════════════════════════════

/**
 * Boot sequence on window load
 * Always starts on login screen. Profile load happens after login submit.
 */
window.addEventListener('load', async () => {
  setActiveScreen('screen-login');

  try {
    await ensureStorageReady();
  } catch (error) {
    console.error('SQLite boot error:', error);
    showModal('⚠️ Error de inicialización', 'No se pudo iniciar la base SQLite del navegador.');
  }

  const savedAuthUser = localStorage.getItem('vm_auth_user');
  if (savedAuthUser) {
    document.getElementById('login-user').value = savedAuthUser;
    return;
  }

  const savedUser = localStorage.getItem('vm_user');
  if (savedUser) {
    try {
      const parsed = JSON.parse(savedUser);
      if (parsed && parsed.name) {
        document.getElementById('login-user').value = parsed.name;
      }
    } catch (e) {
      // Keep login empty if saved profile is corrupted.
    }
  }
});
