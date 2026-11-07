# Guía de Instalación, Pruebas y Despliegue — MateRueda

Esta guía detalla los pasos para instalar, ejecutar, probar y compilar **MateRueda** en un entorno de desarrollo local, así como la configuración en Firebase para las sesiones multidispositivo en el aula.

---

## Requisitos Previos

- **Flutter SDK**: Versión `^3.9.2` o superior (incluye Dart SDK).
- **IDE**: Visual Studio Code o Android Studio con los plugins de Flutter y Dart.
- **Android SDK**: API 21+ (Android 5.0 o superior, cumpliendo **RNF04** para teléfonos y tabletas de gama media).
- *(Opcional para administración de backend)*: **Node.js 18+** y **Firebase CLI** (`npm install -g firebase-tools`).

---

## Instalación Local

### 1. Clonar el repositorio
```bash
git clone https://github.com/TheFool7u7/Mate_Rueda.git
cd Mate_Rueda
```

### 2. Instalar dependencias
```bash
flutter pub get
```

### 3. Ejecutar la aplicación
Conecta un dispositivo físico Android (con depuración USB activa) o abre un emulador y ejecuta:
```bash
flutter run
```

> **Nota sobre conectividad:**
> - El modo **📱 1 dispositivo** funciona **100 % sin conexión a internet**, ideal para aulas sin cobertura Wi-Fi o sesiones proyectadas en pizarra.
> - El modo **🌐 Varios dispositivos** utiliza Firebase Authentication (Anónimo) y Firebase Realtime Database para sincronizar la partida en tiempo real entre el dispositivo docente y las mesas.

---

## Configuración de Firebase (Modo Multidispositivo)

El repositorio incluye `lib/firebase_options.dart` y `android/app/google-services.json` apuntando al proyecto de Firebase configurado. Si deseas conectar un proyecto nuevo desde cero:

1. **Crear proyecto en [Firebase Console](https://console.firebase.google.com/)**.
2. **Authentication → Sign-in method**:
   - Habilitar el proveedor **Anónimo (Anonymous)** para permitir que las mesas de primer grado se conecten sin recolectar correos ni datos personales (**RNF03**).
3. **Realtime Database**:
   - Crear la instancia de Realtime Database.
   - En la pestaña **Reglas**, pegar el contenido del archivo `database.rules.json` del repositorio y pulsar **Publicar**.
4. *(Opcional)* Desplegar reglas y Cloud Functions por consola:
   ```bash
   firebase login
   firebase deploy --only database,firestore:rules,functions
   ```

---

## Ejecución de Pruebas Automatizadas y Análisis Estático

El proyecto cuenta con pruebas unitarias, de widgets y de sincronización multidispositivo en la carpeta `test/`:

```bash
# Ejecutar toda la suite de pruebas (17 pruebas automatizadas)
flutter test

# Ejecutar una suite específica
flutter test test/figuras_objetos_test.dart
flutter test test/generador_retos_test.dart
flutter test test/local_game_test.dart
flutter test test/online_game_test.dart

# Verificar calidad de código y cero advertencias
flutter analyze
```

---

## Compilación de Producción (APK / App Bundle)

```bash
# Generar instalador APK optimizado (Android)
flutter build apk --release

# Generar Android App Bundle (AAB)
flutter build appbundle --release

# Regenerar íconos de lanzador desde assets/images/materueda/logotipo.png
dart run flutter_launcher_icons
```

El archivo APK listo para instalar se genera en:
`build/app/outputs/flutter-apk/app-release.apk`
