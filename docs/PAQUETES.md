# Paquetes y Dependencias

A continuación se detalla la lista de paquetes utilizados en el proyecto `Word Wonders Link`, sus versiones exactas (según `pubspec.yaml`) y el propósito dentro de la arquitectura de la aplicación.

| Paquete | Versión | Propósito | Dónde se usa |
|---------|---------|-----------|--------------|
| `flutter` | sdk: flutter | SDK principal de UI | Todo el proyecto |
| `firebase_core` | ^3.13.0 | Inicialización y conexión core de Firebase | `main.dart` |
| `firebase_auth` | ^5.5.2 | Autenticación de usuarios (Email/Google) | `auth_provider.dart`, `auth_service.dart` |
| `cloud_firestore` | ^5.6.6 | Base de datos persistente para perfiles y salas | `firestore_service.dart`, `home_screen.dart` |
| `firebase_database` | ^11.3.5 | Realtime Database para sincronización en vivo del juego | `realtime_db_service.dart`, `game_provider.dart` |
| `firebase_storage` | ^12.4.5 | Almacenamiento de archivos multimedia (castigos) | `storage_service.dart`, `punishment_provider.dart` |
| `google_sign_in` | ^6.2.2 | Flujo de autenticación con Google | `auth_service.dart`, `login_screen.dart` |
| `provider` | ^6.1.2 | Inyección de dependencias y gestión de estado global | Todo el proyecto (Presentation Layer) |
| `go_router` | ^14.8.1 | Enrutamiento declarativo y redirección basada en estado | `app_router.dart`, navegación entre pantallas |
| `camera` | ^0.11.0+2 | Captura de fotos para castigos | `camera_preview_widget.dart` |
| `record` | ^5.2.1 | Grabación de audio para castigos (cantar) | `audio_recorder_widget.dart` |
| `just_audio` | ^0.9.42 | Reproducción de música de fondo y efectos de sonido (SFX) | `audio_manager_service.dart`, todas las pantallas |
| `permission_handler` | ^11.3.1 | Solicitud de permisos (Cámara, Micrófono, Fotos) | `camera_preview_widget.dart`, `audio_recorder_widget.dart` |
| `shared_preferences` | ^2.2.3 | Persistencia local ligera (ajustes de volumen) | `audio_manager_service.dart`, `settings_screen.dart` |
| `cupertino_icons` | ^1.0.8 | Iconografía de estilo iOS | UI general |
| `flutter_svg` | ^2.0.0 | Renderizado de gráficos vectoriales (iconos personalizados) | `app_icon.dart`, UI general |
| `cached_network_image` | ^3.4.1 | Carga y caché de imágenes de perfil y castigos desde la red | `punishment_screen.dart`, avatares |
| `google_fonts` | ^6.2.1 | Tipografías personalizadas (Nunito) desde Google Fonts | `app_theme.dart`, UI general |
| `auto_size_text` | ^3.0.0 | Texto auto-ajustable (actualmente deprecado a favor de FittedBox) | Histórico de UI |
| `uuid` | ^4.5.1 | Generación de identificadores únicos para archivos y sesiones | `punishment_provider.dart`, etc. |
| `intl` | ^0.19.0 | Internacionalización y formateo de fechas/textos | `results_screen.dart`, etc. |
| `path_provider` | ^2.1.4 | Acceso a directorios del sistema de archivos local | Temporales de cámara y audio |
| `url_launcher` | ^6.3.2 | Abrir enlaces externos (términos y condiciones, ayuda) | `settings_screen.dart`, etc. |
| `record_linux` | ^1.3.0 | Dependencia override para compatibilidad de grabación | `pubspec.yaml` (dependency_overrides) |
| `flutter_launcher_icons` | ^0.14.4 | Generación automática de íconos de la app (dev_dependency) | Configuración de Android/iOS |
| `flutter_lints` | ^5.0.0 | Reglas de análisis estático de Dart (dev_dependency) | Linter |

> [!NOTE]
> La dependencia `record_linux` está sobreescrita explícitamente en el `pubspec.yaml` para resolver una incompatibilidad conocida entre `record_linux 0.7.2` y `record_platform_interface 1.5.0`.
