# Documentación de Firebase y Seguridad — MateRueda

**MateRueda** utiliza Firebase como backend Serverless opcional para habilitar el modo **🌐 Varios dispositivos**, manteniendo al mismo tiempo un modo **📱 1 dispositivo** completamente autónomo sin internet.

---

## Servicios Activos

1. **Firebase Authentication (Proveedor Anónimo)**:
   - Cada dispositivo que crea o se une a una sala obtiene automáticamente un `uid` anónimo temporal (`signInAnonymously()`).
   - **Cumplimiento RNF03**: No se solicitan nombres reales, correos electrónicos, fotografías ni grabaciones de voz a los estudiantes de primer grado; únicamente se emplean nombres de equipo genéricos (*Mesa Sol*, *Mesa Luna*, *Mesa Estrella*, *Mesa Cometa*).
2. **Firebase Realtime Database (RTDB)**:
   - Sincroniza en milisegundos el estado de la partida bajo el nodo `/mate/{code}` para cumplir holgadamente con **RNF05** (al menos 9 de cada 10 acciones reflejadas en $\le 3\text{ s}$).
3. **Firebase Storage — Deshabilitado (RNF03)**:
   - No se almacena ningún archivo multimedia de usuarios.

---

## Estructura en Realtime Database (`/mate/{code}`)

Cada sala activa se identifica mediante un código alfanumérico de 6 caracteres (ej. `K7M4P9`):

```json
{
  "mate": {
    "K7M4P9": {
      "hostUid": "uid_docente_anonimo",
      "createdAt": 1762490000000,
      "state": {
        "phase": "challenge",
        "round": 2,
        "totalRounds": 8,
        "turnIndex": 1,
        "level": "basico",
        "categories": ["conteo", "suma", "resta", "comparacion", "figuras"],
        "selectedCategory": "figuras",
        "spinNonce": 2,
        "challenge": {
          "category": "figuras",
          "question": "¿Qué forma tiene el reloj de pared?",
          "visual": "figura",
          "object": "manzana",
          "countA": 0,
          "countB": 0,
          "shape": "circulo",
          "shapeAsObject": true,
          "options": [
            { "label": "Círculo", "shape": "circulo", "asObject": false },
            { "label": "Triángulo", "shape": "triangulo", "asObject": false },
            { "label": "Rectángulo", "shape": "rectangulo", "asObject": false }
          ],
          "correctIndex": 0
        },
        "lastSelectedOption": null,
        "lastWasCorrect": null,
        "scores": [2, 1],
        "sentAt": 1762490015230
      },
      "members": {
        "uid_mesa_1": {
          "name": "Mesa Sol",
          "colorIndex": 0,
          "joinedAt": 1762490004000
        },
        "uid_mesa_2": {
          "name": "Mesa Luna",
          "colorIndex": 1,
          "joinedAt": 1762490006500
        }
      },
      "answer": {
        "round": 2,
        "turnIndex": 1,
        "optionIndex": 0,
        "teamUid": "uid_mesa_2",
        "sentAt": 1762490018900
      }
    }
  }
}
```

### Descripción de subnodos

- **`hostUid`**: UID anónimo del dispositivo de la persona docente que controla el inicio de la partida y el avance de rondas (**RF10**).
- **`state`**: Fuente única de verdad de la partida (`lobby`, `spinning`, `challenge`, `feedback`, `results`), categoría actual, reto serializado, puntajes por mesa y marca de tiempo `sentAt` para calcular la latencia de sincronización (**RNF05**).
- **`members/{uid}`**: Mesas conectadas en la sala de espera junto con su nombre de equipo e índice de color.
- **`answer`**: Respuesta enviada por la mesa en turno; el dispositivo anfitrión la procesa de forma atómica, valida si es correcta (**RF05**), acredita la estrella correspondiente (**RF07 / RF08**) y publica la fase `feedback`.

---

## Reglas de Seguridad (`database.rules.json`)

Las reglas en `database.rules.json` exigen que todo cliente esté autenticado (`auth != null`, cubierto de forma transparente por Firebase Anonymous Auth):

- **Lectura (`/mate/$roomId`)**: Permitida a participantes autenticados con el código de sala.
- **`state`**: Solo el anfitrión creador de la sala (`hostUid`) puede escribir el estado global de la partida.
- **`members/$uid`**: Cada mesa únicamente puede registrar o eliminar su propio nodo `$uid`.
- **`answer`**: Las mesas autenticadas pueden enviar su selección de respuesta del turno activo y el anfitrión puede limpiarla al iniciar la siguiente ronda.
