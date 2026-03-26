# 🏗️ ARQUITECTURA DEL PROYECTO

## 📂 Estructura completa

```
flutter-migration/
│
├── 📁 database/                    # SQL y migrations
│   ├── schema.sql                  # Estructura completa de BD
│   └── seed_data.sql               # 150+ alimentos + alias
│
├── 📁 lib/                         # Código Dart
│   │
│   ├── 📁 models/                  # Modelos de datos
│   │   └── food_models.dart        # Food, FoodLogEntry, UserProfile, NutritionInfo
│   │
│   ├── 📁 database/                # Gestión de SQLite
│   │   └── database_helper.dart   # Singleton, migrations, inicialización
│   │
│   ├── 📁 repositories/            # Lógica de negocio
│   │   └── food_repository.dart   # CRUD alimentos, logs, perfil, agua
│   │
│   ├── 📁 screens/                 # Pantallas (crear)
│   │   ├── onboarding_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── log_screen.dart
│   │   ├── charts_screen.dart
│   │   └── profile_screen.dart
│   │
│   ├── 📁 widgets/                 # Componentes reutilizables (crear)
│   │   ├── macro_bar.dart
│   │   ├── food_card.dart
│   │   ├── water_tracker.dart
│   │   └── calorie_ring.dart
│   │
│   ├── 📁 services/                # Servicios externos (crear)
│   │   └── ai_service.dart         # Claude AI para alimentos desconocidos
│   │
│   └── main.dart                   # Punto de entrada ✅
│
├── 📁 assets/                      # Recursos (crear si necesario)
│   └── fonts/
│       ├── Fraunces-Regular.ttf
│       └── PlusJakartaSans-Regular.ttf
│
├── pubspec.yaml                    # Dependencias ✅
├── README.md                       # Documentación principal ✅
└── QUICKSTART.md                   # Guía de inicio rápido ✅
```

---

## 🔄 Flujo de datos

```
┌─────────────┐
│   UI Layer  │  (Screens + Widgets)
└──────┬──────┘
       │
       ↓
┌─────────────┐
│ Repository  │  (FoodRepository)
│   Layer     │  • searchFoods()
└──────┬──────┘  • logFood()
       │         • getDailyTotals()
       ↓
┌─────────────┐
│  Database   │  (DatabaseHelper + Sqflite)
│   Layer     │  • SQL queries
└─────────────┘  • Transactions
       │
       ↓
┌─────────────┐
│   SQLite    │  (verdemeta.db)
│   Storage   │  • Local device storage
└─────────────┘
```

---

## 🎯 Responsabilidades por capa

### 1️⃣ **Models** (`food_models.dart`)
- Definir estructura de datos
- Conversión Map ↔ Object
- Cálculos nutricionales

```dart
Food food = Food.fromMap(dbRow);
NutritionInfo info = food.calculateForQuantity(150);
```

### 2️⃣ **Database Helper** (`database_helper.dart`)
- Singleton de base de datos
- Crear/migrar tablas
- Gestionar conexión
- Seed data inicial

```dart
Database db = await DatabaseHelper.instance.database;
```

### 3️⃣ **Repository** (`food_repository.dart`)
- CRUD operations
- Búsqueda inteligente
- Agregaciones (totales diarios)
- Lógica de negocio

```dart
List<Food> results = await repo.searchFoods('tofu');
await repo.logFood(entry);
NutritionInfo totals = await repo.getDailyTotals(date);
```

### 4️⃣ **Screens** (crear)
- Presentación UI
- Navegación
- Estado local (StatefulWidget)
- Interacción usuario

```dart
class DashboardScreen extends StatefulWidget { }
```

### 5️⃣ **Widgets** (crear)
- Componentes reutilizables
- Sin lógica de negocio
- Props/configurables

```dart
MacroBar(current: 120, target: 150, label: 'Proteína')
```

---

## 📊 Tablas de la base de datos

### **foods** (150+ alimentos)
```sql
id | name | emoji | calories | protein | carbs | fat | fiber | ... | is_quick_food
```
- Alimentos veganos con info nutricional completa
- `is_quick_food = 1` para botones rápidos

### **food_aliases** (300+ sinónimos)
```sql
id | food_id | alias
```
- Búsqueda inteligente: "palta" → aguacate

### **food_log** (registros de consumo)
```sql
id | food_id | food_name | meal_time | quantity | calories | ... | date
```
- Log de todo lo consumido
- Desnormalizado para rendimiento

### **user_profile** (un solo registro)
```sql
id=1 | name | age | gender | weight | height | goals | body_comp | ...
```
- Datos del usuario
- Metas de macros
- Composición corporal estimada

### **water_log** (consumo diario)
```sql
id | cups | date
```
- Vasos de agua por día
- UNIQUE(date)

### **ai_learned_foods** (cache de IA)
```sql
id | name | macros... | confidence | times_used
```
- Alimentos estimados por Claude AI
- Se reutilizan en búsquedas futuras

---

## 🔐 Ventajas de esta arquitectura

### ✅ Separación de responsabilidades
- Cada capa tiene un propósito claro
- Fácil de mantener y testear

### ✅ Escalabilidad
- Agregar alimentos: solo SQL
- Nuevas features: nuevos repositorios
- UI independiente de la BD

### ✅ Performance
- Índices en columnas críticas
- Queries optimizadas
- Búsqueda con LIKE + índices

### ✅ Offline-first
- Todo funciona sin internet
- SQLite es local
- Solo IA requiere conexión

### ✅ Testing
```dart
// Repositorio mockeable
class MockFoodRepository extends FoodRepository {
  @override
  Future<List<Food>> searchFoods(String query) async {
    return [testFood1, testFood2];
  }
}
```

---

## 🚀 Orden de implementación sugerido

### Fase 1: Base (✅ COMPLETA)
- [x] Modelos
- [x] DatabaseHelper
- [x] FoodRepository
- [x] main.dart básico

### Fase 2: UI Core (siguiente)
- [ ] DashboardScreen completo
- [ ] LogScreen con búsqueda
- [ ] Navegación entre screens
- [ ] Widgets de macros

### Fase 3: Features avanzadas
- [ ] ChartsScreen con fl_chart
- [ ] ProfileScreen con body comp
- [ ] OnboardingScreen
- [ ] Water tracking widget

### Fase 4: Integraciones
- [ ] Claude AI service
- [ ] Exportar datos (CSV/PDF)
- [ ] Notificaciones locales
- [ ] Widget de home screen

### Fase 5: Publicación
- [ ] Splash screen
- [ ] App icon
- [ ] Screenshots
- [ ] Play Store listing
- [ ] Build & Upload

---

## 💡 Buenas prácticas implementadas

1. **Singleton para DB**: Una sola instancia compartida
2. **Foreign Keys**: Integridad referencial activada
3. **Índices**: Búsquedas rápidas
4. **Validaciones**: CHECK constraints en SQL
5. **Timestamps**: Para históricos y sincronización
6. **Desnormalización inteligente**: food_name en log para velocidad
7. **Tipado fuerte**: Dart con null-safety
8. **Documentación**: JSDoc en todos los métodos

---

## 📖 Referencias

- **Sqflite docs**: https://pub.dev/packages/sqflite
- **Flutter DB best practices**: https://flutter.dev/docs/cookbook/persistence
- **Repository pattern**: https://martinfowler.com/eaaCatalog/repository.html

---

**Tu arquitectura está lista para construir una app profesional** 🏗️✨
