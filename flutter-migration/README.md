# 🌿 VerdeMeta - Flutter con SQLite

## 📱 Tu aplicación vegana profesional para Android

Conversión completa de tu web app a **Flutter con SQLite** usando **Sqflite**.

---

## 🚀 Estructura del proyecto

```
flutter-migration/
├── database/
│   ├── schema.sql           ← Schema completo de la BD
│   └── seed_data.sql        ← 150+ alimentos veganos listos
├── lib/
│   ├── models/
│   │   └── food_models.dart ← Modelos: Food, FoodLogEntry, UserProfile
│   ├── database/
│   │   └── database_helper.dart ← Maneja SQLite con Sqflite
│   ├── repositories/
│   │   └── food_repository.dart ← Lógica de negocio y queries
│   └── main.dart            ← (Crea este archivo para tu app)
└── pubspec.yaml             ← Dependencias Flutter
```

---

## ⚙️ Instalación

### 1. Instala Flutter
```bash
# Descarga Flutter desde: https://flutter.dev/docs/get-started/install
# Verifica la instalación:
flutter doctor
```

### 2. Instala dependencias
```bash
cd flutter-migration
flutter pub get
```

### 3. Configura Android
```bash
# Acepta las licencias de Android
flutter doctor --android-licenses

# Conecta un dispositivo o inicia un emulador
flutter devices
```

---

## 💻 Uso básico

### Ejemplo de uso del FoodRepository:

```dart
import 'package:verdemeta/repositories/food_repository.dart';
import 'package:verdemeta/models/food_models.dart';

void main() async {
  final repo = FoodRepository();
  
  // 🔍 Buscar alimentos
  final results = await repo.searchFoods('tofu');
  print('Resultados: ${results.length}');
  
  // 🥑 Obtener quick foods
  final quickFoods = await repo.getQuickFoods();
  print('Quick foods: ${quickFoods.length}');
  
  // ➕ Registrar alimento consumido
  final tofu = results.first;
  final entry = FoodLogEntry.fromFood(
    food: tofu,
    quantity: 150, // gramos
    mealTime: 'Desayuno',
  );
  await repo.logFood(entry);
  
  // 📊 Obtener totales del día
  final today = DateTime.now().toIso8601String().split('T')[0];
  final totals = await repo.getDailyTotals(today);
  print('Calorías consumidas hoy: ${totals.calories}');
  
  // 💧 Registrar agua
  await repo.saveWaterIntake(6, today); // 6 vasos
  
  // 👤 Guardar perfil
  final profile = UserProfile(
    name: 'Jeniffer',
    age: 28,
    gender: 'female',
    weight: 65,
    height: 165,
    goal: 'health',
    calorieTarget: 2000,
    proteinTarget: 100,
    carbsTarget: 250,
    fatTarget: 65,
  );
  await repo.saveUserProfile(profile);
}
```

---

## 📦 Dependencias clave

- **sqflite** `^2.3.0` - Base de datos SQLite para Flutter
- **path_provider** `^2.1.1` - Rutas del sistema de archivos
- **fl_chart** `^0.65.0` - Gráficas hermosas
- **provider** `^6.1.1` - Gestión de estado (opcional)
- **http** `^1.1.2` - Llamadas a API de Claude AI

---

## 🗄️ Base de datos

### Tablas incluidas:

1. **foods** - 150+ alimentos veganos con macros y micros
2. **food_aliases** - Búsqueda inteligente con sinónimos
3. **food_log** - Registro de alimentos consumidos
4. **user_profile** - Datos del usuario y metas
5. **water_log** - Consumo de agua diario
6. **ai_learned_foods** - Cache de alimentos estimados por IA

### Para cargar todos los alimentos (150+):

```bash
# Opción 1: Ejecuta el seed_data.sql manualmente
# Opción 2: Modifica database_helper.dart para cargar el archivo completo
```

---

## 📱 Compilar para Android

### Modo debug (para pruebas):
```bash
flutter run
```

### Modo release (APK para distribución):
```bash
flutter build apk --release
# APK estará en: build/app/outputs/flutter-apk/app-release.apk
```

### Bundle para Play Store:
```bash
flutter build appbundle --release
# AAB estará en: build/app/outputs/bundle/release/app-release.aab
```

---

## 🎨 Siguiente paso: UI

Crea tu interfaz usando los widgets de Flutter:

```dart
// Ejemplo de pantalla de dashboard
class DashboardScreen extends StatelessWidget {
  final FoodRepository repo = FoodRepository();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('VerdeMeta 🌿'),
      ),
      body: FutureBuilder<List<Food>>(
        future: repo.getQuickFoods(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }
          
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final food = snapshot.data![index];
              return ListTile(
                leading: Text(food.emoji, style: TextStyle(fontSize: 32)),
                title: Text(food.name),
                subtitle: Text('${food.calories} kcal'),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## 🚀 Publicar en Play Store

1. **Configura el app ID** en `android/app/build.gradle`:
   ```gradle
   applicationId "com.tuempresa.verdemeta"
   ```

2. **Crea un keystore** para firmar:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

3. **Configura el signing** en `android/app/build.gradle`

4. **Compila el bundle**:
   ```bash
   flutter build appbundle --release
   ```

5. **Sube a Play Console** en https://play.google.com/console

---

## ✨ Ventajas de esta arquitectura

✅ **Offline-first** - Funciona sin internet  
✅ **Rápido** - SQLite es muy veloz  
✅ **Escalable** - Fácil agregar más alimentos  
✅ **Búsqueda inteligente** - Con alias y sinónimos  
✅ **Cache IA** - Alimentos estimados se guardan  
✅ **Android + iOS** - Mismo código para ambos  

---

## 📚 Recursos

- [Documentación Flutter](https://flutter.dev/docs)
- [Sqflite Package](https://pub.dev/packages/sqflite)
- [Publicar en Play Store](https://flutter.dev/docs/deployment/android)
- [Material Design](https://material.io/design)

---

## 🤝 Próximos pasos

1. ✅ Base de datos configurada
2. ✅ Modelos y repositorio listos
3. 🔲 Crear pantallas UI (Dashboard, Log, Charts, Profile)
4. 🔲 Implementar la composición corporal
5. 🔲 Integrar Claude AI para alimentos desconocidos
6. 🔲 Añadir gráficas con fl_chart
7. 🔲 Diseñar onboarding
8. 🔲 Testear y publicar en Play Store

---

**¿Listo para crear la UI?** 🚀

Empieza creando el archivo `lib/main.dart` y las pantallas principales!
