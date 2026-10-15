# Guía de Instalación y Despliegue

Esta guía proporciona los pasos detallados para configurar, compilar y desplegar `Word Wonders Link` desde cero en un entorno de desarrollo local.

## Requisitos Previos

Antes de comenzar, asegúrate de tener instalado el siguiente software en tu máquina:

- **Flutter SDK**: Versión `^3.9.2` o superior.
- **Dart SDK**: Incluido con Flutter.
- **IDE**: Android Studio, IntelliJ IDEA, o Visual Studio Code con los plugins de Flutter/Dart instalados.
- **Node.js y npm**: Necesarios para desplegar las Cloud Functions (versión 16+ recomendada).
- **Firebase CLI**: Herramienta de línea de comandos de Firebase (`npm install -g firebase-tools`).

## Pasos de Instalación Local

### 1. Clonar el repositorio
```bash
git clone <URL_DEL_REPOSITORIO>
cd wordwonderslink
```

### 2. Instalar dependencias
Descarga e instala todos los paquetes requeridos por el proyecto:
```bash
flutter pub get
```

### 3. Configurar credenciales de Firebase
Para que la app se conecte al backend, necesitas el archivo de configuración nativo.
1. Ve a la consola de Firebase y selecciona el proyecto.
2. Ve a **Project Settings** > **General**.
3. Descarga el archivo `google-services.json` para la aplicación Android.
4. Ubica este archivo en el directorio: `android/app/google-services.json`.

### 4. Compilar y ejecutar
Conecta un dispositivo físico Android o inicia un emulador, y ejecuta:
```bash
flutter run
```

---

## Configurar Firebase desde cero

Si vas a levantar un backend de Firebase completamente nuevo para este proyecto, sigue estos pasos:

### 1. Crear el Proyecto en Firebase Console
- Accede a [Firebase Console](https://console.firebase.google.com/) y crea un proyecto nuevo.
- Habilita Google Analytics (opcional pero recomendado).

### 2. Habilitar Servicios
Debes activar explícitamente los siguientes servicios en la consola:
- **Authentication**: Habilita los proveedores de **Correo/Contraseña** y **Google**.
- **Cloud Firestore**: Crea la base de datos en modo producción.
- **Realtime Database**: Crea la base de datos y elige la región.
- **Storage**: Inicia tu bucket de almacenamiento.

### 3. Desplegar Cloud Functions y Reglas
Inicia sesión en Firebase CLI desde tu terminal:
```bash
firebase login
```
Vincula tu proyecto local con el de Firebase:
```bash
firebase use --add <TU_PROJECT_ID>
```
Despliega las reglas de seguridad y las funciones en la nube:
```bash
# Desplegar reglas de Firestore, RTDB y Storage
firebase deploy --only firestore:rules,database:rules,storage:rules

# Desplegar las Cloud Functions
firebase deploy --only functions
```

### 4. Configurar variables base en Firestore
Para que la app lea la versión mínima soportada, debes crear un documento de configuración inicial en Firestore.
- **Colección**: `config`
- **Documento**: `app`
- **Campos**:
  - `minVersion` (String): `"1.0.0"`
  - `downloadUrl` (String): `"https://tu-url-de-descarga.com"`

---

## Comandos Útiles

A continuación, una lista de comandos frecuentes durante el desarrollo:

**Ejecución y Depuración**
```bash
flutter run                  # Corre la app en modo debug
flutter run --release        # Corre la app en modo release (optimizado)
```

**Generación de APK (Producción)**
```bash
flutter build apk --release  # Genera el instalador APK en build/app/outputs/flutter-apk/
flutter build appbundle      # Genera el AAB para subir a la Google Play Store
```

**Gestión de Firebase**
```bash
firebase deploy --only functions         # Actualiza solo las Cloud Functions
firebase deploy --only firestore:rules   # Actualiza solo las reglas de Firestore
```
