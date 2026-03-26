# 🚀 GUÍA DE INICIO RÁPIDO

## Pasos para ejecutar la app

### 1️⃣ Inicializar proyecto Flutter

```bash
cd flutter-migration

# Instalar dependencias
flutter pub get

# Verificar dispositivos
flutter devices
```

### 2️⃣ Ejecutar en modo desarrollo

```bash
# Ejecutar en dispositivo conectado
flutter run

# O específico para Android
flutter run -d android
```

### 3️⃣ Probar la base de datos

La app ya incluye:
- ✅ 12 alimentos quick foods precargados
- ✅ Búsqueda inteligente
- ✅ Log de alimentos
- ✅ Totales diarios

### 4️⃣ Cargar los 150+ alimentos

**Opción A: Manual**
```bash
# En Android Studio / VS Code
# Abre Database Inspector
# Ejecuta el archivo: database/seed_data.sql
```

**Opción B: Programática**
```dart
// Agrega en database_helper.dart en _seedInitialData():
final sqlFile = await rootBundle.loadString('database/seed_data.sql');
final statements = sqlFile.split(';');
for (var statement in statements) {
  if (statement.trim().isNotEmpty) {
    await db.execute(statement);
  }
}
```

### 5️⃣ Hot Reload

Mientras la app está corriendo:
- Presiona `r` - Reload
- Presiona `R` - Hot restart
- Presiona `q` - Quit

---

## 📱 Compilar APK

```bash
# APK de debug
flutter build apk --debug

# APK de release
flutter build apk --release

# Ubicación:
# build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔍 Debugging

### Ver logs
```bash
flutter logs
```

### Inspeccionar base de datos

**Android Studio:**
1. View → Tool Windows → App Inspection
2. Database Inspector
3. Selecciona verdemeta.db

**VS Code + SQLite extension:**
1. Instala SQLite extension
2. Cmd/Ctrl + P → SQLite: Open Database
3. Navega a app databases

---

## 🎨 Personalizar

### Cambiar colores
Edita `lib/main.dart`:
```dart
primaryColor: Color(0xFF2e7d52), // Tu color verde
```

### Cambiar fuentes
1. Descarga Google Fonts
2. Agrega en `pubspec.yaml`:
```yaml
fonts:
  - family: Fraunces
    fonts:
      - asset: assets/fonts/Fraunces-Regular.ttf
```

---

## ⚡ Próximos pasos

1. **Crear más pantallas:**
   - Dashboard detallado
   - Búsqueda de alimentos
   - Gráficas
   - Perfil

2. **Implementar:**
   - Composición corporal
   - Integración Claude AI
   - Water tracking
   - Charts con fl_chart

3. **Publicar:**
   - Configurar keystore
   - Build app bundle
   - Subir a Play Store

---

## 🐛 Problemas comunes

### Error: Gradle sync failed
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Error: Device not found
```bash
# Inicia un emulador
flutter emulators
flutter emulators --launch <emulator_id>
```

### Error: Cannot find sqflite
```bash
flutter clean
flutter pub get
```

---

## 📚 Documentación útil

- [Flutter Cookbook](https://flutter.dev/docs/cookbook)
- [Sqflite Package](https://pub.dev/packages/sqflite)
- [Material Design](https://material.io/components?platform=android)
- [Debugging Flutter Apps](https://flutter.dev/docs/testing/debugging)

---

**¡Tu app está lista para crecer!** 🌱→🌿→🌳
