# Documentación de Firebase

Word Wonders Link utiliza Firebase como backend Serverless (BaaS). El proyecto emplea una arquitectura de datos dual, combinando la persistencia y consultas de **Cloud Firestore** con la baja latencia y sincronización instantánea de **Realtime Database**.

## Servicios Utilizados

- **Firebase Authentication**: Autenticación de usuarios mediante Email/Contraseña y Google Sign-In.
- **Cloud Firestore**: Base de datos de documentos para guardar perfiles, historial de partidas, salas creadas y ranking global.
- **Firebase Realtime Database (RTDB)**: Base de datos en tiempo real utilizada exclusivamente para el motor del juego activo (fases, bloqueo atómico de letras, temporizadores, estado de conexión).
- **Firebase Storage**: Almacenamiento de archivos binarios (fotos y audios) generados durante la fase de castigos.
- **Cloud Functions**: Funciones backend en NodeJS utilizadas para asegurar transacciones críticas y limpiar archivos temporales (ej. agregación de votos, eliminación de castigos tras 24h).

---

## Estructura de Cloud Firestore

### Colección: `/users/{uid}`
Almacena el perfil de los usuarios autenticados.
- `uid` (String): ID único del usuario de Auth.
- `username` (String): Alias del jugador (mínimo 6, máximo 12 caracteres).
- `email` (String): Correo electrónico asociado.
- `avatarUrl` (String): URL de la imagen de perfil (opcional).
- `totalPoints` (Number): Puntos totales acumulados en su historia.
- `gamesPlayed` (Number): Partidas jugadas totales.
- `gamesWon` (Number): Partidas ganadas.
- `createdAt` (Timestamp): Fecha de registro en la app.
- `isDisabled` (Boolean): Bandera de baneo/desactivación.

### Colección: `/rooms/{roomCode}`
Registra el historial y configuración de las salas.
- `roomCode` (String): Código alfanumérico único de 6 caracteres (ej. "A4XT9B").
- `hostUid` (String): UID del creador de la sala.
- `maxPlayers` (Number): Límite de jugadores en la sala (default: 4).
- `timePerTurn` (Number): Tiempo en segundos por turno (default: 30).
- `status` (String): Estado global (`waiting`, `playing`, `finished`).
- `players` (Array<Map>): Lista embebida de `PlayerRef` (uid, username, avatarUrl) para lectura rápida.
- `createdAt` (Timestamp): Momento de creación.

*(Nota: En versiones más avanzadas, de aquí pueden colgar subcolecciones como `/rounds` o `/responses` si se requiere auditar el juego post-partida)*

### Colección: `/leaderboard/{uid}`
Documentos proyectados para consultas ultrarrápidas del Top global.
- `username` (String)
- `totalPoints` (Number)

### Colección: `/config/app`
Configuraciones maestras de la aplicación.
- `minVersion` (String): Versión mínima soportada (ej. "1.0.0").
- `downloadUrl` (String): Enlace para actualizar la aplicación si está desactualizada.

### Colección: `/admins/{uid}`
Privilegios de acceso para paneles de administración.
- `email` (String)
- `role` (String)

---

## Estructura de Realtime Database (Estado en Vivo)

El motor del juego reside bajo el nodo principal `/games/{roomCode}`.

### Nodo: `/games/{roomCode}/state`
Controla el reloj global y el flujo de la ronda.
- `phase` (String): Fase actual (`selecting`, `answering`, `evaluating`, `punishment`, `results`).
- `currentLetter` (String): La letra seleccionada para esta ronda.
- `currentCategory` (String): La categoría en juego.
- `roundId` (String): ID temporal de la ronda.
- `timerEnd` (Number): Epoch timestamp de cuándo termina el contador.
- `activePlayer` (String): UID del jugador que tiene el turno.
- `loserUid` (String): UID del perdedor de la partida (solo en fase `punishment`).
- `finalScores` (Map<String, Number>): Mapa de UIDs a puntajes finales (solo en fase `results`).
- `punishmentMediaUrl` (String): URL del castigo subido a Storage.
- `punishmentType` (String): Tipo de castigo (`selfie`, `audio`, `color`).
- `punishmentTargetColor` (String): Si el castigo es color, guarda el color asignado.

### Nodo: `/games/{roomCode}/letters/{char}`
El abecedario del juego (A-Z). Se usa `runTransaction()` aquí para evitar condiciones de carrera (dos jugadores girando la ruleta y agarrando la misma letra a la vez).
- `status` (String): Estado de la letra (`free`, `locked`, `used`).
- `lockedBy` (String): UID de quien ganó la letra.
- `lockedByUsername` (String): Alias del jugador que la bloqueó.

### Nodo: `/games/{roomCode}/players/{uid}`
Estado en vivo de la conexión y puntaje temporal.
- `roundScore` (Number): Puntos ganados en la ronda actual.
- `isConnected` (Boolean): Manejado por OnDisconnect hooks de Firebase para saber si el jugador se salió.

---

## Cloud Functions

1. **`onVoteWrite`**: (Trigger de Firestore o RTDB, según subcolección). Se dispara cuando los jugadores envían sus calificaciones (0-10 o calidad) a una respuesta. La función consolida los votos y calcula el promedio, escribiéndolo de vuelta en el score del jugador. Esto evita que los clientes modifiquen maliciosamente sus propios puntajes.
2. **`onRoundComplete`**: Se dispara al finalizar la ronda. Procesa los `roundScore` de los jugadores, los suma al puntaje de la sala y reinicia las variables temporales para preparar la siguiente ronda.
3. **`cleanupPunishments`**: Cron Job o TTL trigger que elimina los archivos multimedia (fotos y audios) del bucket de Firebase Storage que tienen más de 24 horas de antigüedad, para ahorrar costos.

---

## Reglas de Seguridad (Security Rules)

### Firestore Rules
- **Lectura**: Solo usuarios autenticados pueden leer `/users` (excepto la colección `/config` y `/leaderboard` que son públicas de lectura).
- **Escritura**: Un usuario solo puede editar su propio documento en `/users/{uid}`.
- **Salas**: Solo usuarios autenticados pueden crear salas. Solo el anfitrión (`hostUid`) puede cambiar el estado principal de `/rooms/{roomCode}` a `finished`.

### Realtime Database Rules
- El acceso está restringido a usuarios autenticados.
- **Letras**: Cualquier usuario en la sala puede intentar bloquear una letra (transacción), pero si `status` es distinto de `free`, la regla rechaza la escritura.
- **Estado (State)**: Los cambios de fase y timer solo pueden ser alterados por el `hostUid` o el `activePlayer` (el que está respondiendo en ese momento).

### Storage Rules
- Solo usuarios autenticados pueden subir archivos a `/punishments/{roomCode}/`.
- Limitado a un tamaño máximo de subida (ej. 5MB para audio, 10MB para fotos) y estrictamente a los Content-Types de imagen o audio permitidos.
