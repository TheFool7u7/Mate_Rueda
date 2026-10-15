# Arquitectura del Proyecto

Word Wonders Link utiliza una arquitectura **Hybrid Feature-Based** adaptada para Flutter. Esta estructura agrupa el código principalmente por funcionalidad (features) en lugar de por capas técnicas, lo que facilita la escalabilidad, el mantenimiento y la navegación dentro del proyecto a medida que crece.

## Estructura de Carpetas

La raíz del código fuente se encuentra en `lib/` y está dividida de la siguiente manera:

- **`core/`**: Contiene la configuración global y transversal de la aplicación.
  - Constantes globales (colores, dimensiones, strings).
  - Configuración del tema (ThemeData).
  - Enrutador principal (`app_router.dart` usando `go_router`).
  - Utilidades genéricas.
  
- **`features/`**: El núcleo de la aplicación. Cada carpeta aquí representa un módulo independiente y contiene sus propias capas de datos (`data`), dominio (`domain`) y presentación (`presentation`).
  - **`auth/`**: Manejo de autenticación con Firebase (Email/Password y Google Sign-In), registro, login y modelo de usuario.
  - **`home/`**: Pantalla de inicio, menú principal y visualización del leaderboard.
  - **`room/`**: Lógica para la creación de salas, unión a salas mediante código y sala de espera (lobby).
  - **`game/`**: Motor del juego en tiempo real. Maneja la sincronización de fases a través de Firebase Realtime Database, turnos, ruleta de letras y envío de respuestas.
  - **`evaluation/`**: Sistema interactivo donde los jugadores votan y califican las respuestas de los demás.
  - **`punishment/`**: Gestión de los castigos para el perdedor de la ronda (foto selfie, cantar audios o encontrar un color). Incluye interacciones con cámara y micrófono.
  - **`results/`**: Pantalla final que muestra la tabla de posiciones de la partida, puntajes finales y sonidos de victoria o derrota.
  - **`splash/`**: Pantalla de carga inicial que verifica la sesión del usuario y la versión mínima requerida de la app.

- **`shared/`**: Elementos que se utilizan a través de múltiples features.
  - Widgets comunes (`AppButton`, `AppBackground`, `AppIcon`, teclados virtuales).
  - Servicios transversales (`AudioManagerService` para reproducción de efectos y música de fondo).
  - Modelos de datos genéricos.

- **`settings/`**: Módulo dedicado a las configuraciones locales del usuario (volumen de música y efectos, información de la app).

## Patrones de Diseño Utilizados

1. **Provider Pattern**: 
   Se utiliza el paquete `provider` para la gestión de estado de la UI y la Inyección de Dependencias (DI). Cada feature principal tiene su propio Provider (`AuthProvider`, `GameProvider`, `RoomProvider`, etc.) que expone el estado y los métodos a la capa de presentación.

2. **Repository / Service Pattern**:
   Las operaciones de acceso a datos y comunicación con Firebase están abstraídas en clases de servicio (`FirestoreService`, `RealtimeDbService`, `AuthService`). Los providers no acceden directamente a las APIs de terceros, sino que delegan en estos servicios.

3. **Singleton**:
   Se emplea en servicios específicos que requieren una única instancia global en todo el ciclo de vida de la aplicación. El ejemplo principal es `AudioManagerService`, el cual asegura que la música de fondo no se reinicie o se solape en cambios de ruta.

4. **Observer Pattern (con Firebase Streams)**:
   Debido a la naturaleza multijugador del juego, se depende fuertemente de flujos reactivos (`Streams`). La base de datos en tiempo real emite eventos (`onValue`) que son escuchados por los providers. Cuando el estado cambia, el provider actualiza sus variables locales y notifica a la UI mediante `notifyListeners()`.

## Flujo de Datos

El ciclo de vida de la información sigue una dirección reactiva unidireccional generalizada:

```text
[UI - Pantalla] 
       │ (1. Usuario interactúa: toca un botón, ingresa respuesta)
       ▼
[Provider - Gestor de Estado] 
       │ (2. Procesa regla de negocio local)
       ▼
[Service - Repositorio] 
       │ (3. Llama a la API de Firebase)
       ▼
[Firebase - RTDB/Firestore] 
       │ (4. Sincroniza datos con la nube y emite actualización)
       ▼
[Service - Listener] 
       │ (5. Recibe el nuevo estado mediante un Stream)
       ▼
[Provider - Actualizador] 
       │ (6. Actualiza sus variables internas y llama notifyListeners())
       ▼
[UI - Pantalla] 
         (7. Se reconstruye con los datos más recientes)
```

## Decisiones Arquitectónicas

- **Hybrid Feature-Based**: En lugar de separar por `models`, `views`, y `controllers` a nivel raíz, agrupar por features permite que si se necesita modificar o eliminar el módulo de "castigos", todo su código esté aislado en `features/punishment/`.
- **Firebase Dual (Firestore + RTDB)**: Se eligió *Firestore* para datos persistentes (perfiles, historial, leaderboard) por su capacidad de consultas complejas. Sin embargo, para el motor del juego que requiere milisegundos de latencia y sincronización de presencia, se integró *Realtime Database (RTDB)*.
- **Provider sobre Bloc/Riverpod**: Al ser un juego muy reactivo basado en Streams de Firebase, `ChangeNotifierProvider` resulta suficientemente potente y con menor boilerplate comparado con Bloc, permitiendo iteraciones ágiles y código legible.
