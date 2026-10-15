# Word Wonders Link

¡Bienvenido al repositorio oficial de **Word Wonders Link**! 🎮

Este es un emocionante juego multijugador en tiempo real para dispositivos móviles (Android/iOS) donde la rapidez mental y el vocabulario son tus mejores armas. Gira la ruleta, sé el primero en ganar una letra, escribe la palabra más sorprendente de la categoría en menos de 30 segundos, y asegúrate de que la comunidad vote a tu favor. ¡El jugador con menos puntos recibirá un castigo interactivo!

---

## 🎯 Objetivo del Juego

El juego consta de varias rondas donde la aplicación genera categorías aleatorias (Ej. "Animales", "Países", "Comida").
1. **Ruleta Rápida:** Una ruleta de letras aparece en el centro de la pantalla. Los jugadores deben presionar su botón para bloquear la letra que deseen. Es una carrera de reflejos, una letra solo puede ser tomada por un jugador.
2. **Respuesta bajo presión:** El que consigue una letra tiene que escribir una palabra que empiece con esa letra y que pertenezca a la categoría vigente antes de que el reloj marque cero. El resto espera y escucha la tensión del reloj.
3. **Votación:** Los demás jugadores deciden si la palabra es válida, y qué tan buena fue, dándole una puntuación del 1 al 10, y una insignia (Común, Excelente, Sorprendente).
4. **Castigo:** Al terminar las rondas, el jugador con menor puntaje sufre un castigo (ej. tomarse una selfie graciosa, cantar, o encontrar un color en el mundo real con la cámara). ¡Los demás se reirán de los resultados en tiempo real!

---

## 📸 Pantallas Principales

- **Menú y Salas:** Ingresa tu usuario, visualiza a los mejores jugadores en el Leaderboard global. Crea una sala compartiendo un código de 6 dígitos, o únete a la de tus amigos.
- **La Ruleta (Game Screen):** Una interfaz inmersiva con el abecedario. Se actualiza en tiempo real mostrando quién capturó qué letra con un sistema "first-come, first-served".
- **Respuesta y Tensión:** Un teclado inteligente con temporizador animado y una ruleta de tiempo.
- **La Votación:** Botones modernos de votación con animaciones sutiles que desaparecen para consolidar el puntaje final del turno.
- **La Pantalla de Castigo (Punishment Screen):** Integramos la cámara frontal, trasera, y el micrófono para penalizar a los perdedores, compartiendo el resultado multimedia al resto de la sala inmediatamente mediante Firebase Storage.

---

## 🛠 Tecnologías Utilizadas

- **Framework UI:** Flutter SDK (`^3.9.2`) usando la arquitectura Hybrid Feature-Based.
- **Lenguaje:** Dart.
- **Gestión de Estado:** `provider` acoplado con Streams reactivos.
- **Navegación:** `go_router` con guards basados en sesión.
- **Backend (Serverless):** Firebase
  - **Firebase Authentication:** (Login por Google y Email).
  - **Firebase Realtime Database:** (Latencia <100ms para el estado del juego y bloqueos atómicos).
  - **Cloud Firestore:** (Persistencia segura a largo plazo y leaderboard).
  - **Firebase Storage:** (Subida y bajada de fotos y audios temporales).
  - **Cloud Functions:** (Seguridad en conteo de votos).
- **Multimedia:** `camera`, `record` y `just_audio` (Música y SFX inmersivos).

---

## 📁 Estructura del Proyecto y Documentación

Hemos diseñado este repositorio priorizando la legibilidad y escalabilidad. Te invitamos a leer la documentación detallada dentro de la carpeta `/docs`:

1. [Instalación local y Firebase desde cero](docs/INSTALACION.md)
2. [Arquitectura Hybrid Feature-Based](docs/ARQUITECTURA.md)
3. [Estructuras en Firebase (Colecciones y Reglas)](docs/FIREBASE.md)
4. [Flujo lógico del juego paso a paso](docs/FLUJO_DE_JUEGO.md)
5. [Mapeo de pantallas y navegación](docs/PANTALLAS.md)
6. [Librerías y dependencias usadas](docs/PAQUETES.md)

---

## ⚙️ Requisitos y Cómo Correr el Proyecto

Para levantar el proyecto en tu entorno local:

1. **Requisitos:** Flutter SDK, Android Studio, Node.js y una cuenta activa de Firebase.
2. **Clonar Repo e Instalar Dependencias:**
   ```bash
   git clone <REPO_URL>
   cd wordwonderslink
   flutter pub get
   ```
3. **Credenciales:** Descarga el archivo `google-services.json` de tu proyecto de Firebase y ponlo en `android/app/`.
4. **Ejecutar:**
   ```bash
   flutter run
   ```
*Para instrucciones detalladas sobre cómo configurar Firebase desde cero y desplegar las Cloud Functions, revisa [INSTALACION.md](docs/INSTALACION.md).*

---

## 👨‍💻 Créditos y Autoría

Desarrollado y mantenido con ❤️ para la comunidad de Flutter. 
*Word Wonders Link - Innovando la diversión multijugador móvil en tiempo real.*
