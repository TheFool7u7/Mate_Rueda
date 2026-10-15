# Pantallas y Navegación

Word Wonders Link utiliza `go_router` para su sistema de navegación declarativa, lo que permite un manejo de rutas robusto y guardias de autenticación (`redirects`). A continuación, se detallan todas las pantallas (Screens) principales de la aplicación.

---

### 1. SplashScreen
- **Ruta:** `AppRoutes.splash` (`/`)
- **Propósito:** Pantalla inicial de carga. Verifica si hay un usuario autenticado activo (guardando tokens) y valida si la versión local cumple con la `minVersion` exigida por Firebase.
- **Widgets Principales:** Animación de carga, logo estático.
- **Providers Consumidos:** `AuthProvider`
- **Navegación:** Si está logueado → `/home`. Si no → `/login`.

### 2. LoginScreen
- **Ruta:** `AppRoutes.login` (`/login`)
- **Propósito:** Permitir al usuario iniciar sesión con sus credenciales o cuenta de terceros.
- **Widgets Principales:** `AppTextField` (píldoras para email/password), `AppButton` primario (Iniciar Sesión), `AppButton.social` (Botón ancho de Iniciar con Google). Diálogo personalizado para "Olvidé mi contraseña".
- **Providers Consumidos:** `AuthProvider`
- **Navegación:** Al loguearse con éxito → `/home`. Opción de crear cuenta → `/register`.

### 3. RegisterScreen
- **Ruta:** `AppRoutes.register` (`/register`)
- **Propósito:** Registro de cuentas nuevas. Exige Email, Contraseña y un `Username` que servirá de alias durante las partidas.
- **Widgets Principales:** `AppTextField`, `AppBackground`, `AppButton.orange` (gradiente).
- **Providers Consumidos:** `AuthProvider`
- **Navegación:** Tras registrarse → Regresa a `/login` o hace login automático a `/home`.

### 4. ChangePasswordScreen
- **Ruta:** `AppRoutes.changePassword` (`/change-password`)
- **Propósito:** Permitir a usuarios ya autenticados cambiar su contraseña de forma segura desde el panel de ajustes.
- **Widgets Principales:** `AppTextField` para contraseña actual y nueva.
- **Providers Consumidos:** `AuthProvider`
- **Navegación:** Accedida desde `/settings`. Al completar, hace pop a `/settings`.

### 5. HomeScreen
- **Ruta:** `AppRoutes.home` (`/home`)
- **Propósito:** El menú principal del jugador. Muestra saludo, accesos para crear/unirse a sala y un Leaderboard Global proyectado en tiempo real.
- **Widgets Principales:** Tarjeta superior (Saludo + Ajustes), Botones de menú (`AppButton.red`, `AppButton.blue`, `AppButton.green`), `_LeaderboardCard`, Estadísticas de usuario con gradientes morados (`statsGradient`). Modal inferior de "Cómo jugar".
- **Providers Consumidos:** `AuthProvider` (para UID), `FirestoreService` (directo para leaderboard local).
- **Navegación:** 
  - Engranaje → `/settings`
  - Crear Sala → `/create-room`
  - Unirse → `/join-room`

### 6. CreateRoomScreen
- **Ruta:** `AppRoutes.createRoom` (`/create-room`)
- **Propósito:** Formulario para configurar una nueva partida (categoría inicial, tiempo por turno).
- **Widgets Principales:** Selectores numéricos, Botón primario de crear.
- **Providers Consumidos:** `RoomProvider`
- **Navegación:** Al crear la sala en Firestore → `/lobby`.

### 7. JoinRoomScreen
- **Ruta:** `AppRoutes.joinRoom` (`/join-room`)
- **Propósito:** Permite a un jugador entrar a una sala escribiendo el código alfanumérico del Host.
- **Widgets Principales:** Input de 6 dígitos en mayúsculas, validaciones.
- **Providers Consumidos:** `RoomProvider`
- **Navegación:** Al encontrar y unirse a la sala → `/lobby`.

### 8. LobbyScreen
- **Ruta:** `AppRoutes.lobby` (`/lobby`)
- **Propósito:** Sala de espera. Los jugadores se van apilando mientras ven los avatares y nombres de los demás conectados.
- **Widgets Principales:** Lista de `PlayerRef`, Código de sala gigante. El Host ve un botón exclusivo de "Empezar Juego".
- **Providers Consumidos:** `RoomProvider`, `GameProvider`.
- **Navegación:** Al iniciar el host → `/game`.

### 9. GameScreen (Fase Selecting)
- **Ruta:** `AppRoutes.game` (`/game`)
- **Propósito:** Mostrar la ruleta del abecedario. Aquí los jugadores compiten en tiempo real por agarrar una letra para iniciar su turno.
- **Widgets Principales:** `LetterWheelWidget`, Indicador de categoría. Efectos de sonido (tick-tic ruleta).
- **Providers Consumidos:** `GameProvider`.
- **Navegación:** Automática a `/answering` controlada por Firebase RTDB.

### 10. AnsweringScreen
- **Ruta:** `AppRoutes.answering` (`/answering`)
- **Propósito:** Pantalla asíncrona dual. El jugador Activo ve un teclado y un Input para escribir. Los espectadores ven un temporizador en cuenta regresiva y esperan pasivamente.
- **Widgets Principales:** `Teclado Virtual`, Reloj de cuenta atrás.
- **Providers Consumidos:** `GameProvider`.
- **Navegación:** Automática a `/evaluation` controlada por Firebase RTDB.

### 11. EvaluationScreen
- **Ruta:** `AppRoutes.evaluation` (`/evaluation`)
- **Propósito:** Votación comunitaria de la palabra entregada.
- **Widgets Principales:** 
  - Grid numérico 1-10.
  - Tarjetas de Calidad (Común, Excelente, Sorprendente) construidas nativamente con `FittedBox` dinámicos (sin librerías).
- **Providers Consumidos:** `EvaluationProvider`, `GameProvider`.
- **Navegación:** Automática a `/game` (siguiente ronda) o a `/punishment`.

### 12. PunishmentScreen
- **Ruta:** `AppRoutes.punishment` (`/punishment`)
- **Propósito:** Forzar al perdedor a cumplir su castigo y que el resto de los jugadores pueda presenciarlo en pantalla y reír.
- **Widgets Principales:** `CameraPreviewWidget`, `AudioRecorderWidget`, Módulo de encontrar colores en vivo por cámara.
- **Providers Consumidos:** `PunishmentProvider`, `GameProvider`.
- **Navegación:** Automática a `/results` cuando Firebase notifica el castigo subido.

### 13. ResultsScreen
- **Ruta:** `AppRoutes.results` (`/results`)
- **Propósito:** Cierre de la partida. Muestra medallas, puntos finales y una opción limpia de salida. Reproduce audios `.mp3` / `.m4a` de victoria/derrota.
- **Widgets Principales:** Podio final.
- **Providers Consumidos:** `GameProvider`, `RoomProvider`.
- **Navegación:** Salir de la sala → `/home`.

### 14. SettingsScreen
- **Ruta:** `AppRoutes.settings` (`/settings`)
- **Propósito:** Menú estático de configuración, permisos, términos y cerrar sesión.
- **Widgets Principales:** Sliders de volumen (`SharedPreferences`), Botones de acción, enlaces de política de privacidad.
- **Providers Consumidos:** `AuthProvider`.
- **Navegación:** Cerrar Sesión → Redirige globalmente a `/login` a través del guard. Cambio de contraseña → `/change-password`.
