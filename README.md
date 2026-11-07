# MateRueda — ¡Gira, juega y aprende matemática!

Aplicación educativa colaborativa para estudiantes de **1.° grado de primaria (6 a 7 años)** de la **Escuela Alberto Echandi Montero** (San Juan Norte de Poás, Alajuela, Costa Rica), desarrollada en el marco del Trabajo Comunal Universitario **TC-563** de la Universidad de Costa Rica y adaptada a partir del proyecto de código abierto *Word Wonders Link*.

---

## 🎯 Objetivos de Aprendizaje (OA1–OA6)

La ruleta de **MateRueda** gira entre **5 categorías matemáticas** alineadas al programa de primer año del MEP:

1. **Conteo de objetos (OA1):** Contar colecciones visuales de elementos cotidianos (manzanas, estrellas, globos, peces, flores y bloques) en niveles Básico (1 a 10) y Ampliado (hasta 20).
2. **Suma hasta 10 / 20 (OA2):** Resolver sumas con apoyo de grupos visuales de objetos.
3. **Resta sencilla (OA3):** Resolver restas con representación concreta (objetos tachados).
4. **Comparación de cantidades (OA4):** Identificar dónde hay más (`◀`, `▶`) o si ambos grupos tienen la misma cantidad (`=`).
5. **Figuras geométricas en objetos del hogar (OA5):** Reconocer formas geométricas en objetos cotidianos alternando ambas variantes pedagógicas:
   - **Círculo** ↔ *el reloj de pared*
   - **Cuadrado** ↔ *la ventana*
   - **Triángulo** ↔ *el pedazo de pizza*
   - **Rectángulo** ↔ *el celular*
6. **Trabajo colaborativo por mesas (OA6):** Fomentar turnos respetuosos, apoyo mutuo y celebración grupal de las estrellas obtenidas por toda el aula.

---

## 🖥️ Modos de Juego

Al tocar **CREAR SALA**, la persona docente puede elegir entre dos modalidades:

- **📱 1 dispositivo (Modo Aula Local):** Un único teléfono o tableta se rota por turnos entre las mesas o se proyecta frente a la pizarra. No requiere conexión a internet.
- **🌐 Varios dispositivos (Sincronizado en tiempo real):** La persona docente crea una sala con un código de 6 caracteres y cada mesa se une desde su propio dispositivo tocando **UNIRSE A SALA**. Todas las pantallas ven la ruleta girar en simultáneo, el reto activo, la retroalimentación y el podio final (cumpliendo **RNF05**: latencia de sincronización $\le 3\text{ s}$).

---

## 🛡️ Privacidad, Accesibilidad y Diseño Inclusivo (RNF01–RNF05)

- **RNF01 / RNF02 — Interfaz accesible y narración por voz (TTS):** Instrucciones breves de una sola línea acompañadas de lectura en voz alta en español (`flutter_tts`) e ilustraciones vectoriales claras para niños en etapa de lectoescritura inicial y estudiantes con condición del espectro autista.
- **RNF03 — Protección estricta de datos de personas menores de edad:**
  - **Cero permisos de cámara o micrófono** en `AndroidManifest.xml` e `Info.plist`.
  - **Sin cuentas personales ni captura multimedia:** las sesiones multidispositivo utilizan únicamente identificadores de mesa genéricos (*Mesa Sol*, *Mesa Luna*, *Mesa Estrella*, *Mesa Cometa*) y salas efímeras.
- **RF06 / RF07 — Retroalimentación siempre positiva:** Sin pantallas de castigo ni sonidos frustrantes; cada intento brinda acompañamiento pedagógico y reconocimiento por estrellas e insignias.

---

## 🚀 Cómo Ejecutar y Compilar

### Requisitos
- Flutter SDK `^3.9.2`

### Ejecutar en modo desarrollo
```bash
flutter pub get
flutter run
```

### Ejecutar pruebas automatizadas
```bash
flutter test
```

### Generar APK de instalación (Android)
```bash
flutter build apk --release
```
El instalador se genera en `build/app/outputs/flutter-apk/app-release.apk`.
