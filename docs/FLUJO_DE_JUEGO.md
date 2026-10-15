# Flujo del Juego

Este documento detalla el ciclo de vida completo de una partida en `Word Wonders Link`. El sistema está manejado casi exclusivamente a través del estado de la Realtime Database (`GamePhase`) coordinando clientes de forma simultánea.

## Fases del Juego (GamePhase)

La enumeración `GamePhase` rige en qué pantalla están los jugadores y qué pueden hacer. La transición entre fases suele estar orquestada por el Host, o automáticamente cuando el contador llega a 0.

### 1. `idle` (Lobby)
- **Vista**: Pantalla `LobbyScreen`.
- **Qué ocurre**: Los jugadores se unen introduciendo el código de la sala de 6 dígitos.
- **Base de Datos**: Los nuevos UIDs se agregan a la lista de jugadores de Firestore y se crean los nodos base en RTDB (con `isConnected: true`).
- **Transición**: El Host de la sala presiona "Iniciar Juego". El backend inicializa las letras del abecedario, asume una categoría inicial, y cambia el `status` de la sala a `playing` y la fase RTDB a `selecting`.

### 2. `selecting` (Ruleta de Letras)
- **Vista**: `GameScreen` con el componente `LetterWheelWidget`.
- **Qué ocurre**: Todos los jugadores ven la categoría actual y las letras del abecedario. Presionan el botón para girar su propia ruleta e intentan capturar una letra.
- **Base de Datos**: 
  - Aquí actúa el **Sistema de Concurrencia Seguro**. Al intentar bloquear una letra, el cliente lanza una transacción atómica a Firebase (`runTransaction`).
  - Si 2 jugadores caen en la letra "A" en el mismo milisegundo, la transacción asegura que solo el primer servidor reciba un éxito; el segundo cliente hace un rollback instantáneo.
- **Transición**: Cuando todas las letras disponibles para una categoría se agotan, o se cumple un tiempo límite, el juego transiciona a la fase `answering` seleccionando a un jugador aleatorio o al primero en la cola.

### 3. `answering` (Fase de Respuesta)
- **Vista**: `AnsweringScreen`.
- **Qué ocurre**: 
  - El jugador "Activo" (`activePlayer`) tiene en pantalla un teclado virtual y debe escribir una palabra que comience con la letra ganada, perteneciente a la categoría vigente (Ej: Animal con P → "Perro").
  - El resto de los jugadores ("Espectadores") ven una pantalla de "Esperando respuesta de [Usuario]..." y escuchan un audio de reloj ("tick-tock") para generar tensión.
- **Base de Datos**: Un temporizador se guarda en RTDB (`timerEnd`) y todos los clientes lo usan para descontar el reloj sincronizadamente.
- **Transición**: Ocurre si el jugador Activo envía una palabra antes de que el contador acabe, o si el tiempo llega a 0. Pasamos a la fase de `evaluating`.

### 4. `evaluating` (Sistema de Votación Seguro)
- **Vista**: `EvaluationScreen`.
- **Qué ocurre**: 
  - La palabra que ingresó el jugador Activo se envía al resto de los jugadores para ser evaluada.
  - Los oponentes califican la respuesta del 1 al 10 y otorgan un nivel de calidad (Común, Excelente, Sorprendente).
- **Base de Datos**: 
  - Los votos NO se escriben directamente sobre el puntaje del jugador evaluado (por seguridad).
  - En su lugar, se guardan en un registro de la base de datos (o subcolección). Un Cloud Function (o el Host como fallback) promedia estos votos y de manera segura asigna el puntaje en el nodo de ese jugador.
- **Transición**: Cuando todos los espectadores emiten su voto, la aplicación muestra el puntaje asignado, reproduce un audio ("positivo" o "negativo") y regresa a `selecting` para el siguiente turno.

### 5. `punishment` (Fase de Castigos)
- **Vista**: `PunishmentScreen`.
- **Cuándo ocurre**: Si al final de todas las rondas preestablecidas, un jugador queda en último lugar con el puntaje más bajo.
- **Qué ocurre**: 
  - El perdedor es forzado a realizar un castigo generado aleatoriamente.
  - Tipos de castigos:
    1. **Tomar Selfie**: Usando el paquete `camera`, captura su rostro en tiempo real.
    2. **Cantar**: Usando el paquete `record`, graba 10 segundos de audio cantando.
    3. **Encontrar un Color**: La app le asigna un color RGB, y con la cámara trasera debe enfocar un objeto de ese color exacto.
  - Los otros jugadores ven una pantalla de espera y escuchan un loop de risas de fondo (`risas.wav`).
- **Base de Datos**: 
  - Cuando el perdedor completa el castigo, el archivo multimedia se sube a **Firebase Storage**.
  - La URL del archivo se guarda en RTDB en la variable `punishmentMediaUrl`.
- **Transición**: Cuando Firebase avisa a todos los clientes que el `punishmentMediaUrl` ya no es nulo, los espectadores visualizan o escuchan el castigo, y el juego pasa a `results`.

### 6. `results` (Final de la Partida)
- **Vista**: `ResultsScreen`.
- **Qué ocurre**: 
  - Se muestra la tabla de posiciones (Leaderboard local de la sala).
  - El primer lugar escucha un audio de triunfo (`win.mp3`), mientras que los perdedores escuchan un audio de derrota (`perdedor.m4a`).
  - Animaciones de medallas (Oro, Plata, Bronce).
- **Base de Datos**: 
  - Se escriben los puntajes finales en el historial de los perfiles de Firestore.
  - El Host cambia el `status` principal de la sala a `finished`.
  - La sala se destruye o limpia de RTDB.
- **Fin del Flujo**: El usuario puede regresar a `HomeScreen`.

---

## Patrones de UX Críticos

### Optimistic UI y Rollback
Cuando un usuario bloquea una letra, la UI se actualiza inmediatamente poniéndola de color azul (asumiendo que la ganó). Si en los milisegundos siguientes Firebase rechaza la transacción porque otro jugador la tomó primero, la UI hace un *rollback* silencioso, cambiando la letra a rojo y bloqueándola para el usuario local, todo sin interrumpir gravemente la experiencia.

### El Rol del Host
Para evitar conflictos de estado (donde dos teléfonos intenten cambiar el estado de la RTDB al mismo tiempo), el juego asigna la "autoridad" de transiciones críticas exclusivamente al dispositivo cuyo UID coincida con el `hostUid` (el creador de la sala). Si el creador se desconecta, se deberá prever una mecánica de "Host Migration".
