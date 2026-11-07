# Mapa de Pantallas y Navegación — MateRueda

**MateRueda** implementa un flujo limpio de **8 pantallas** gestionado declarativamente con `go_router` (`lib/features/local_game/presentation/local_routes.dart` y `lib/main_demo.dart`). En modo multidispositivo, un `redirect` reactivo sincroniza automáticamente la ruta activa en todos los teléfonos y tabletas según la fase publicada en la sala.

---

## Resumen de Rutas (`LocalRoutes`)

| # | Pantalla | Ruta | Archivo | Propósito principal |
|---|---|---|---|---|
| 1 | `LocalSplashScreen` | `/` | `local_intro_screens.dart` | Bienvenida animada con logotipo oficial de MateRueda y transición suave al menú |
| 2 | `LocalMenuScreen` | `/menu` | `local_intro_screens.dart` | Menú principal con saludo a la docente, mascota **Numi** y botones **Crear sala** / **Unirse a sala** |
| 3A | `LocalSetupScreen` | `/setup` | `local_intro_screens.dart` | Configuración docente: selector **1 dispositivo / Varios dispositivos**, mesas, rondas, nivel (hasta 10 o 20) y categorías activas |
| 3B | `LocalJoinScreen` | `/join` | `local_intro_screens.dart` | Ingreso de código de 6 caracteres, selección de nombre de mesa (*Mesa Sol*, *Luna*, *Estrella*, *Cometa*) y color de avatar |
| 4 | `LocalLobbyScreen` | `/lobby` | `local_intro_screens.dart` | Sala de espera con código gigante de sala, tarjetas animadas de mesas conectadas y botón **Iniciar partida** para la docente |
| 5 | `LocalSpinScreen` | `/spin` | `local_spin_screen.dart` | Ruleta interactiva de las 5 categorías matemáticas con indicador de turno por mesa, giro animado y efectos de sonido calibrados |
| 6 | `LocalChallengeScreen` | `/challenge` | `local_challenge_feedback_screens.dart` | Presentación del reto visual (`MathChallengeScreen`), botón de repetición de voz TTS y 3 opciones táctiles grandes |
| 7 | `LocalFeedbackScreen` | `/feedback` | `local_challenge_feedback_screens.dart` | Retroalimentación inmediata positiva, muestra de respuesta correcta cuando aplica, marcador de estrellas y botón de avance |
| 8 | `LocalResultsScreen` | `/results` | `local_results_screen.dart` | Celebración grupal con contador animado de estrellas del aula, podio de equipos, indicador **RNF05** y retorno al menú |

---

## Accesibilidad Visual y Auditiva en Pantalla (RNF01 / RNF02)

1. **Consignas breves + Voz automática (`TtsService`)**:
   - Cada reto consta de una sola oración corta acompañada de narración automática en español latinoamericano y un botón de altavoz (`🔊`) para volver a escuchar la pregunta cuantas veces lo necesite el grupo.
2. **Botones táctiles amplios de un solo toque (`RF04`)**:
   - Todas las opciones de respuesta tienen gran tamaño, bordes redondeados, sombra táctil e ilustraciones vectoriales nítidas pensadas para motricidad fina de 6 a 7 años.
3. **Estímulos sensoriales amigables (Inclusión TEA)**:
   - Colores armónicos, ausencia de temporizadores estresantes o alarmas estridentes, volumen de ruleta atenuado y retroalimentación 100 % libre de castigos.
