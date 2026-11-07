# Paquetes y Dependencias — MateRueda

A continuación se documentan todas las dependencias activas en `pubspec.yaml` para **MateRueda**, su versión y su rol dentro de la aplicación.

---

## Dependencias de Producción (`dependencies`)

| Paquete | Versión | Propósito en MateRueda | Ubicación principal |
|---|---|---|---|
| `flutter` | `sdk: flutter` | Framework principal de interfaz multiplataforma | Todo el proyecto |
| `firebase_core` | `^3.13.0` | Inicialización de Firebase cuando se usa el modo multidispositivo | `mate_room_backend.dart`, `main.dart` |
| `firebase_auth` | `^5.5.2` | Autenticación anónima automática sin datos personales (**RNF03**) | `mate_room_backend.dart` |
| `firebase_database` | `^11.3.5` | Sincronización en tiempo real de salas bajo `/mate/{code}` (**RNF05**) | `mate_room_backend.dart` |
| `cloud_firestore` | `^5.6.6` | Soporte de servicios auxiliares heredados de configuración | `lib/features/room/data/` |
| `google_sign_in` | `^6.2.2` | Soporte opcional heredado en módulo de autenticación docente | `lib/features/auth/` |
| `provider` | `^6.1.2` | Gestión reactiva de estado | `lib/features/` |
| `go_router` | `^14.8.1` | Navegación declarativa de las 8 pantallas y redirección reactiva | `main_demo.dart`, `local_routes.dart` |
| `flutter_tts` | `^4.2.5` | Síntesis de voz en español para leer retos y retroalimentación (**RNF02**) | `tts_service.dart` |
| `just_audio` | `^0.9.42` | Reproducción de música suave y efectos sonoros con control de volumen | `audio_manager_service.dart` |
| `shared_preferences` | `^2.2.3` | Persistencia local ligera de preferencias de audio/vibración | `audio_manager_service.dart` |
| `flutter_svg` | `^2.0.0` | Renderizado de íconos y recursos vectoriales | `shared/presentation/widgets/` |
| `google_fonts` | `^6.2.1` | Tipografías infantiles legibles y redondeadas (`Fredoka` / `Nunito`) | `app_theme.dart` |
| `auto_size_text` | `^3.0.0` | Ajuste adaptable de textos en distintas resoluciones (**RNF04**) | Widgets compartidos |
| `cached_network_image` | `^3.4.1` | Caché eficiente de recursos gráficos | Widgets compartidos |
| `cupertino_icons` | `^1.0.8` | Iconografía base complementaria | UI general |
| `uuid` | `^4.5.1` | Generación de identificadores únicos | Utilidades |
| `intl` | `^0.19.0` | Formateo regional en español | Utilidades |
| `path_provider` | `^2.1.4` | Acceso seguro a rutas locales de caché de la aplicación | Servicios locales |
| `url_launcher` | `^6.3.2` | Apertura segura de enlaces informativos | Ajustes |

---

## Dependencias de Desarrollo (`dev_dependencies`)

| Paquete | Versión | Propósito |
|---|---|---|
| `flutter_test` | `sdk: flutter` | Pruebas unitarias, de widgets y de flujo completo local/multidispositivo (`test/`) |
| `flutter_lints` | `^5.0.0` | Reglas oficiales de análisis estático (`flutter analyze` con 0 advertencias) |
| `flutter_launcher_icons` | `^0.14.4` | Generación automática de íconos oficiales en Android e iOS desde `assets/images/materueda/logotipo.png` |

---

## Paquetes Eliminados por Privacidad Infantil (Cumplimiento RNF03)

En cumplimiento estricto del requerimiento no funcional **RNF03** (*no solicitar permisos de cámara o micrófono ni capturar imágenes, audios o datos personales de menores de edad*), se removieron por completo del proyecto y de `AndroidManifest.xml`:

- ❌ `camera`
- ❌ `record` y `record_linux`
- ❌ `firebase_storage`
- ❌ `permission_handler`
