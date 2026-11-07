# Arquitectura del Proyecto — MateRueda

**MateRueda** utiliza una arquitectura **Feature-Based (basada en funcionalidades)** en Flutter, adaptada a partir del motor de código abierto *Word Wonders Link* para ofrecer un ambiente multimedia colaborativo dirigido a niños y niñas de **1.° grado de primaria (6 a 7 años)**.

---

## Estructura de Carpetas (`lib/`)

- **`main.dart` y `main_demo.dart`**:
  - Punto de entrada unificado de la aplicación. Inicializa los servicios de audio y voz, configura el controlador de partida (`LocalGameController`) y registra el enrutador reactivo con `go_router`.

- **`core/`**: Configuración global y transversal:
  - `constants/`: Colores de identidad visual de MateRueda (`mate_colors.dart`), textos (`app_strings.dart`), rutas y dimensiones responsivas.
  - `theme/`: Tema visual amigable con tipografía redondeada (`Fredoka` / `Nunito`), alto contraste y botones táctiles amplios (**RNF01**).
  - `utils/`: Generador de códigos de sala alfanuméricos de 6 caracteres (`room_code_generator.dart`, sin caracteres ambiguos como `0/O` o `1/I`).

- **`features/`**: Módulos principales del dominio educativo:
  - **`challenge/`**:
    - `domain/math_challenge.dart`: Modelo inmutable `MathChallenge`, serialización JSON (`toJson` / `fromJson`), niveles configurables (`ChallengeSettings.basico` hasta 10 y `ampliado` hasta 20) y `MathChallengeGenerator` para las **5 categorías matemáticas (OA1–OA5)**.
    - `presentation/widgets/challenge_illustrations.dart`: Ilustraciones vectoriales con `CustomPainter` para colecciones de conteo (manzanas, estrellas, globos, peces, flores, bloques), figuras geométricas y **objetos cotidianos del hogar** (*reloj de pared*, *ventana*, *pedazo de pizza* y *celular*).
    - `presentation/screens/math_challenge_screen.dart`: Tarjeta interactiva del reto matemático con lectura en voz alta y botones de respuesta de un solo toque (**RF04**).
  - **`local_game/`**:
    - `domain/local_game_controller.dart`: Controlador central (`ChangeNotifier`) que orquesta tanto las partidas en **1 dispositivo** como las partidas sincronizadas en **varios dispositivos**, gestionando turnos por mesa, puntaje de estrellas, retroalimentación y métricas de latencia (**RNF05**).
    - `presentation/screens/`: Las **8 pantallas** de MateRueda (Splash, Menú con Numi, Crear/Unirse a Sala, Sala de Espera, Ruleta de 5 categorías, Reto Matemático, Retroalimentación positiva y Podio grupal de Resultados).
    - `presentation/widgets/mate_widgets.dart`: Componentes visuales reutilizables (`MateBackground`, `MateButton`, `MateCard`, `MateOutlinedText`, `TeamAvatar`).
  - **`online_game/`**:
    - `data/mate_room_backend.dart`: Interfaz `MateRoomBackend` con dos implementaciones intercambiables:
      1. `FirebaseMateRoomBackend`: Sincronización en tiempo real sobre Firebase Realtime Database (`mate/{code}`) con autenticación anónima automática.
      2. `InMemoryMateRoomBackend`: Backend determinista en memoria con `Stream.multi` para pruebas automatizadas sin depender de red externa.

- **`shared/`**: Servicios transversales reutilizables:
  - `data/tts_service.dart`: Singleton `TtsService` sobre `flutter_tts` (`es-MX`, velocidad pausada para 1.° grado y `awaitSpeakCompletion(true)`) que garantiza que las consignas habladas nunca se corten durante transiciones de pantalla (**RNF02**).
  - `data/audio_manager_service.dart`: Singleton `AudioManagerService` sobre `just_audio` para música de fondo y efectos sonoros con atenuación independiente (`volumeFactor`).

---

## Patrones de Diseño Aplicados

1. **ChangeNotifier + AnimatedBuilder / Listenable**:
   `LocalGameController` centraliza el estado de la sesión y notifica de inmediato tanto a las vistas como al `refreshListenable` de `GoRouter`, redirigiendo automáticamente a todas las pantallas conectadas cuando cambia la fase de la partida.

2. **Strategy / Backend Adapter (`MateRoomBackend`)**:
   Desacoplar el transporte de red mediante la interfaz `MateRoomBackend` permite que las mismas 8 pantallas operen sin cambios en modo local (offline), en modo Firebase RTDB (aula conectada) y en pruebas automatizadas en memoria.

3. **Singleton en Audio y Voz (`TtsService` y `AudioManagerService`)**:
   Evita instancias duplicadas del motor nativo de síntesis de voz o reproductores de audio al navegar entre la ruleta, el reto y la pantalla de retroalimentación.

4. **Privacidad desde el Diseño — Cumplimiento RNF03**:
   Se eliminaron de raíz los módulos heredados de votación competitiva y castigos multimedia (`evaluation/` y `punishment/`), así como cualquier dependencia o permiso de cámara, micrófono o almacenamiento de fotos/audios de personas menores de edad.

---

## Flujo Reactivo en Modo Multidispositivo

```text
[Docente / Mesa toca pantalla]
              │
              ▼
   [LocalGameController]
              │  publica estado o respuesta con marca de tiempo (sentAt)
              ▼
  [FirebaseMateRoomBackend]  ───►  RTDB (/mate/{code})
                                          │
              ◄───────────────────────────┘  Stream en tiempo real
              ▼
   [LocalGameController]
    • Calcula latencia de recepción (RNF05 ≤ 3 s)
    • Actualiza fase, reto y estrellas
    • Dispara redirección automática en GoRouter
              │
              ▼
     [Pantallas sincronizadas]
```
